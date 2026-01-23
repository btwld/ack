import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:logging/logging.dart';
import 'package:source_gen/source_gen.dart';

import '../models/field_info.dart';
import '../models/model_info.dart';

/// Logger for schema AST analysis warnings and diagnostics.
final _log = Logger('SchemaAstAnalyzer');

/// Default representation type for object schemas
const String _kMapType = 'Map<String, Object?>';

/// Dart reserved keywords that cannot be used as identifiers
const _dartKeywords = {
  'abstract',
  'as',
  'assert',
  'async',
  'await',
  'base',
  'break',
  'case',
  'catch',
  'class',
  'const',
  'continue',
  'covariant',
  'default',
  'deferred',
  'do',
  'dynamic',
  'else',
  'enum',
  'export',
  'extends',
  'extension',
  'external',
  'factory',
  'false',
  'final',
  'finally',
  'for',
  'Function',
  'get',
  'hide',
  'if',
  'implements',
  'import',
  'in',
  'interface',
  'is',
  'late',
  'library',
  'mixin',
  'new',
  'null',
  'on',
  'operator',
  'part',
  'required',
  'rethrow',
  'return',
  'sealed',
  'set',
  'show',
  'static',
  'super',
  'switch',
  'sync',
  'this',
  'throw',
  'true',
  'try',
  'typedef',
  'var',
  'void',
  'when',
  'while',
  'with',
  'yield',
};

/// Analyzes schema variables by walking the AST
///
/// This analyzer inspects the AST structure of schema definitions
/// (like `Ack.object({...})`) to extract field type information without
/// requiring const evaluation or string parsing.
class SchemaAstAnalyzer {
  final Map<String, String> _schemaVariableTypeCache = {};
  final Set<String> _schemaVariableTypeStack = {};

  /// Analyzes a schema variable annotated with @AckType
  ///
  /// Walks the AST to extract type information from the schema definition.
  ModelInfo? analyzeSchemaVariable(
    TopLevelVariableElement2 element, {
    String? customTypeName,
  }) {
    // Get the AST node for this variable using the fragment
    final fragment = element.firstFragment;
    final session = fragment.libraryFragment.element.session;
    final library = element.library2;

    final parsedLibResult = session.getParsedLibraryByElement2(library);

    // getParsedLibraryByElement returns a SomeParsedLibraryResult which might not have getElementDeclaration
    // We need to check if it's actually a ParsedLibraryResult
    if (parsedLibResult is! ParsedLibraryResult) {
      throw InvalidGenerationSourceError(
        'Could not get parsed library for "${element.name3}"',
        element: element,
      );
    }

    final declaration = parsedLibResult.getFragmentDeclaration(fragment);
    if (declaration == null || declaration.node is! VariableDeclaration) {
      throw InvalidGenerationSourceError(
        'Could not find variable declaration for "${element.name3}"',
        element: element,
      );
    }

    final varDecl = declaration.node as VariableDeclaration;
    final initializer = varDecl.initializer;

    if (initializer == null) {
      throw InvalidGenerationSourceError(
        'Schema variable "${element.name3}" must have an initializer',
        element: element,
      );
    }

    // Check if the initializer is Ack.object({...})
    if (initializer is! MethodInvocation) {
      throw InvalidGenerationSourceError(
        'Schema variable "${element.name3}" must be initialized with a schema '
        '(e.g., Ack.object({...}))',
        element: element,
      );
    }

    return _parseSchemaFromAST(
      element.name3!,
      initializer,
      element,
      customTypeName: customTypeName,
    );
  }

  /// Parses a schema from a MethodInvocation AST node
  ModelInfo? _parseSchemaFromAST(
    String variableName,
    MethodInvocation invocation,
    Element2 element, {
    String? customTypeName,
  }) {
    // Walk the method chain to find the base Ack.xxx() call
    // E.g., Ack.string().min(8) -> walk back to find Ack.string()
    final baseInvocation = _findBaseAckInvocation(invocation);

    if (baseInvocation == null) {
      throw InvalidGenerationSourceError(
        'Schema must be an Ack.xxx() method call (e.g., Ack.object(), Ack.string())',
        element: element,
      );
    }

    final methodName = baseInvocation.methodName.name;
    final isNullable = _hasModifier(invocation, 'nullable');

    // Parse based on schema type
    switch (methodName) {
      case 'object':
        return _parseObjectSchema(
          variableName,
          baseInvocation,
          invocation, // Pass original invocation to check for chained methods
          element,
          isNullable: isNullable,
          customTypeName: customTypeName,
        );
      case 'string':
        return _parseStringSchema(
          variableName,
          baseInvocation,
          element,
          isNullable: isNullable,
          customTypeName: customTypeName,
        );
      case 'integer':
        return _parseIntegerSchema(
          variableName,
          baseInvocation,
          element,
          isNullable: isNullable,
          customTypeName: customTypeName,
        );
      case 'double':
        return _parseDoubleSchema(
          variableName,
          baseInvocation,
          element,
          isNullable: isNullable,
          customTypeName: customTypeName,
        );
      case 'boolean':
        return _parseBooleanSchema(
          variableName,
          baseInvocation,
          element,
          isNullable: isNullable,
          customTypeName: customTypeName,
        );
      case 'list':
        return _parseListSchema(
          variableName,
          baseInvocation,
          element,
          isNullable: isNullable,
          customTypeName: customTypeName,
        );
      case 'literal':
        return _parseLiteralSchema(
          variableName,
          baseInvocation,
          element,
          isNullable: isNullable,
          customTypeName: customTypeName,
        );
      case 'enumString':
        return _parseEnumStringSchema(
          variableName,
          baseInvocation,
          element,
          isNullable: isNullable,
          customTypeName: customTypeName,
        );
      case 'enumValues':
        return _parseEnumValuesSchema(
          variableName,
          baseInvocation,
          element,
          isNullable: isNullable,
          customTypeName: customTypeName,
        );
      default:
        throw InvalidGenerationSourceError(
          'Unsupported schema type for @AckType: Ack.$methodName(). '
          'Supported types: object, string, integer, double, boolean, list, literal, enumString, enumValues',
          element: element,
        );
    }
  }

  /// Parses Ack.object() schema
  ModelInfo _parseObjectSchema(
    String variableName,
    MethodInvocation baseInvocation,
    MethodInvocation fullInvocation,
    Element2 element, {
    required bool isNullable,
    String? customTypeName,
  }) {
    // Extract the properties map from the first argument
    final args = baseInvocation.argumentList.arguments;
    if (args.isEmpty) {
      throw InvalidGenerationSourceError(
        'Ack.object() requires a properties map argument',
        element: element,
      );
    }

    final firstArg = args.first;
    if (firstArg is! SetOrMapLiteral) {
      throw InvalidGenerationSourceError(
        'Ack.object() first argument must be a map literal',
        element: element,
      );
    }

    // Extract fields from the map literal
    final fields = _extractFieldsFromMapLiteral(firstArg, element);

    // Check if additionalProperties is enabled via passthrough() or parameter
    bool hasAdditionalProperties = false;

    // First check for named parameter in the base Ack.object() call
    for (final arg in baseInvocation.argumentList.arguments) {
      if (arg is NamedExpression &&
          arg.name.label.name == 'additionalProperties') {
        if (arg.expression is BooleanLiteral) {
          hasAdditionalProperties = (arg.expression as BooleanLiteral).value;
        }
      }
    }

    // Then walk forward from fullInvocation to find passthrough() in the chain
    // The chain looks like: Ack.object({...}).passthrough()
    // fullInvocation is the outermost call (passthrough if present)
    // We need to check if passthrough() was called
    MethodInvocation? current = fullInvocation;
    while (current != null && current != baseInvocation) {
      final methodName = current.methodName.name;

      if (methodName == 'passthrough') {
        hasAdditionalProperties = true;
        break;
      }

      // Move down the chain towards the base
      final target = current.target;
      if (target is MethodInvocation) {
        current = target;
      } else {
        break;
      }
    }

    // Generate extension type name from variable name or custom override
    final typeName = _resolveModelClassName(
      variableName,
      element,
      customTypeName: customTypeName,
    );

    return ModelInfo(
      className: typeName,
      schemaClassName: variableName,
      fields: fields,
      isFromSchemaVariable: true,
      additionalProperties: hasAdditionalProperties,
      isNullableSchema: isNullable,
    );
  }

  /// Extracts field information from a map literal
  List<FieldInfo> _extractFieldsFromMapLiteral(
    SetOrMapLiteral mapLiteral,
    Element2 element,
  ) {
    final fields = <FieldInfo>[];

    for (final mapElement in mapLiteral.elements) {
      if (mapElement is! MapLiteralEntry) continue;

      final key = mapElement.key;
      final value = mapElement.value;

      // Key should be a string literal
      if (key is! SimpleStringLiteral) {
        throw InvalidGenerationSourceError(
          'Map keys must be string literals in schema definition',
          element: element,
        );
      }

      final fieldName = key.value;

      // Validate that the field name is a valid Dart identifier
      _validateFieldName(fieldName, element);

      final fieldInfo = _parseFieldValue(fieldName, value, element);
      if (fieldInfo != null) {
        fields.add(fieldInfo);
      }
    }

    return fields;
  }

  /// Parses a field's value expression to determine its type
  FieldInfo? _parseFieldValue(
    String fieldName,
    Expression value,
    Element2 element,
  ) {
    // Handle Ack.xxx() method calls
    if (value is MethodInvocation) {
      return _parseSchemaMethod(fieldName, value, element);
    }

    // Handle references to other schema variables (for nested objects)
    if (value is SimpleIdentifier) {
      // Schema variable reference: store the variable name for type resolution.
      final schemaVarName = value.name;
      final library = element.library2;

      final typeProvider = library?.typeProvider;
      if (typeProvider == null) {
        throw InvalidGenerationSourceError(
          'Could not get type provider for library',
          element: element,
        );
      }

      return FieldInfo(
        name: fieldName,
        jsonKey: fieldName,
        type: typeProvider.mapType(
          typeProvider.stringType,
          typeProvider.dynamicType,
        ),
        isRequired: true,
        isNullable: false,
        constraints: [],
        nestedSchemaRef: schemaVarName,
      );
    }

    return null;
  }

  /// Parses a schema method call (e.g., Ack.string(), Ack.integer().optional())
  FieldInfo _parseSchemaMethod(
    String fieldName,
    MethodInvocation invocation,
    Element2 element,
  ) {
    // Walk the method chain to find modifiers and base type
    var isOptional = false;
    var isNullable = false;
    MethodInvocation? current = invocation;
    MethodInvocation? baseInvocation;

    while (current != null) {
      final methodName = current.methodName.name;

      if (methodName == 'optional') {
        isOptional = true;
      } else if (methodName == 'nullable') {
        isNullable = true;
      } else {
        // This might be the base schema type (Ack.string(), etc.)
        // Supports prefixed Ack (e.g., ack.Ack.string()) via _isAckTarget
        final target = current.target;
        if (_isAckTarget(target)) {
          baseInvocation = current;
          break;
        }
      }

      // Move to the next method in the chain
      final target = current.target;
      if (target is MethodInvocation) {
        current = target;
      } else {
        break;
      }
    }

    if (baseInvocation == null) {
      throw InvalidGenerationSourceError(
        'Could not determine schema type for field "$fieldName"',
        element: element,
      );
    }

    // Map schema type to Dart type (passing full invocation for context)
    // Also captures schema variable reference for list fields with nested schemas
    final (dartType, listElementSchemaRef) =
        _mapSchemaTypeToDartType(baseInvocation, element);

    return FieldInfo(
      name: fieldName,
      jsonKey: fieldName,
      type: dartType,
      isRequired: !isOptional,
      isNullable: isNullable,
      constraints: [],
      listElementSchemaRef: listElementSchemaRef,
    );
  }

  /// Maps a schema method invocation to a Dart type and optional schema reference
  ///
  /// Returns a record of (DartType, schemaVariableName?) where the second
  /// element is the schema variable name for list fields with nested schema refs.
  (DartType, String?) _mapSchemaTypeToDartType(
    MethodInvocation invocation,
    Element2 element,
  ) {
    final schemaMethod = invocation.methodName.name;

    // We need to get the type provider from the element's library
    final library = element.library2!;

    final typeProvider = library.typeProvider;

    switch (schemaMethod) {
      case 'string':
        return (typeProvider.stringType, null);
      case 'integer':
        return (typeProvider.intType, null);
      case 'double':
        return (typeProvider.doubleType, null);
      case 'boolean':
        return (typeProvider.boolType, null);
      case 'list':
        // Extract element type from Ack.list(elementSchema) argument
        // This may return a schema variable reference for nested schemas
        return _extractListType(invocation, element, typeProvider);
      case 'object':
        // Nested objects represented as Map<String, Object?>
        // Note: Using dynamicType for analyzer; generated code uses Object?
        return (
          typeProvider.mapType(
            typeProvider.stringType,
            typeProvider.dynamicType,
          ),
          null,
        );
      default:
        throw InvalidGenerationSourceError(
          'Unsupported schema method: Ack.$schemaMethod()',
          element: element,
        );
    }
  }

  /// Extracts the element type from Ack.list(elementSchema) calls
  ///
  /// Handles:
  /// - Method invocations: `Ack.list(Ack.string())` → `List<String>`
  /// - Method chains: `Ack.list(Ack.string().describe(...))` → `List<String>`
  /// - Schema references: `Ack.list(addressSchema)` → `List<Map<String, Object?>>`
  /// - Schema ref chains: `Ack.list(addressSchema.optional())` → `List<Map<String, Object?>>`
  ///
  /// Returns a record of (DartType, schemaVariableName?) where the second
  /// element is the schema variable name for nested schema references.
  (DartType, String?) _extractListType(
    MethodInvocation listInvocation,
    Element2 element,
    TypeProvider typeProvider,
  ) {
    final args = listInvocation.argumentList.arguments;

    // If no arguments or empty, fall back to List<dynamic>
    if (args.isEmpty) {
      return (typeProvider.listType(typeProvider.dynamicType), null);
    }

    final firstArg = args.first;

    // Handle Ack.list(Ack.string()) or Ack.list(Ack.string().describe('...'))
    if (firstArg is MethodInvocation) {
      // First try: Walk the method chain to find the base Ack.xxx() call
      final baseInvocation = _findBaseAckInvocation(firstArg);
      if (baseInvocation != null) {
        final (elementType, _) = _mapSchemaTypeToDartType(baseInvocation, element);
        return (typeProvider.listType(elementType), null);
      }

      // Second try: Check for schema variable with method chain
      // e.g., Ack.list(itemSchema.optional())
      final schemaVarName = _findSchemaVariableBase(firstArg);
      if (schemaVarName != null) {
        return _resolveSchemaVariableType(
          schemaVarName,
          element,
          typeProvider,
        );
      }
    }

    // Handle Ack.list(addressSchema) - direct schema variable reference
    if (firstArg is SimpleIdentifier) {
      return _resolveSchemaVariableType(
        firstArg.name,
        element,
        typeProvider,
      );
    }

    // Fallback for unknown argument types
    return (typeProvider.listType(typeProvider.dynamicType), null);
  }

  /// Resolves a schema variable name to its list element type.
  ///
  /// Looks up the schema variable in the library and returns the appropriate
  /// list type with the schema variable name for code generation.
  (DartType, String?) _resolveSchemaVariableType(
    String schemaVarName,
    Element2 element,
    TypeProvider typeProvider,
  ) {
    final baseTypeName = _generateTypeNameFromVariable(schemaVarName);
    final library = element.library2;

    if (library != null) {
      // Try @AckModel class lookup
      final classElement = library.classes.cast<ClassElement2?>().firstWhere(
            (c) => c?.name3 == baseTypeName,
            orElse: () => null,
          );

      if (classElement != null) {
        // For @AckModel classes, use the class type (no schema ref needed)
        return (typeProvider.listType(classElement.thisType), null);
      }

      // Try @AckType schema variable lookup
      final schemaVar =
          library.topLevelVariables.cast<TopLevelVariableElement2?>().firstWhere(
                (v) => v?.name3 == schemaVarName,
                orElse: () => null,
              );

      if (schemaVar != null) {
        // Schema variable exists - return List<Map<String, Object?>>
        // Note: Using dynamicType here for analyzer compatibility,
        // but generated code will use Map<String, Object?>
        return (
          typeProvider.listType(
            typeProvider.mapType(
              typeProvider.stringType,
              typeProvider.dynamicType,
            ),
          ),
          schemaVarName,
        );
      }
    }

    // Not found - fall back to List<dynamic>
    return (typeProvider.listType(typeProvider.dynamicType), null);
  }

  /// Resolves a schema variable name to its representation type string.
  ///
  /// This is used for top-level list schemas so we can cast to the correct
  /// element type (e.g., `String` for `Ack.string()` schema variables).
  /// Falls back to `dynamic` if the schema variable cannot be resolved.
  String _resolveSchemaVariableElementTypeString(
    String schemaVarName,
    Element2 element,
  ) {
    final library = element.library2;
    // Use library-scoped cache key to prevent collisions across libraries
    final cacheKey = '${library?.uri ?? 'unknown'}::$schemaVarName';

    final cached = _schemaVariableTypeCache[cacheKey];
    if (cached != null) {
      return cached;
    }

    if (_schemaVariableTypeStack.contains(cacheKey)) {
      _log.warning(
        'Detected circular schema variable reference for "$schemaVarName". '
        'Falling back to dynamic.',
      );
      return 'dynamic';
    }

    _schemaVariableTypeStack.add(cacheKey);

    String resolvedType = 'dynamic';
    try {
      if (library == null) {
        return resolvedType;
      }

      final schemaVar =
          library.topLevelVariables.cast<TopLevelVariableElement2?>().firstWhere(
                (v) => v?.name3 == schemaVarName,
                orElse: () => null,
              );

      if (schemaVar == null) {
        return resolvedType;
      }

      final modelInfo = analyzeSchemaVariable(schemaVar);
      if (modelInfo == null) {
        return resolvedType;
      }

      resolvedType = modelInfo.representationType;
      return resolvedType;
    } catch (e) {
      _log.warning(
        'Failed to resolve schema variable "$schemaVarName" for list element type: $e',
      );
      return resolvedType;
    } finally {
      _schemaVariableTypeStack.remove(cacheKey);
      _schemaVariableTypeCache[cacheKey] = resolvedType;
    }
  }

  /// Extracts the identifier name from different expression forms.
  ///
  /// Supports simple identifiers, prefixed identifiers (`prefix.name`),
  /// and property accesses (`expr.name`).
  String? _identifierName(Expression? expression) {
    if (expression == null) return null;

    if (expression is SimpleIdentifier) {
      return expression.name;
    }

    if (expression is PrefixedIdentifier) {
      return expression.identifier.name;
    }

    if (expression is PropertyAccess) {
      return expression.propertyName.name;
    }

    return null;
  }

  bool _isAckTarget(Expression? target) {
    return _identifierName(target) == 'Ack';
  }

  String? _extractSchemaVariableName(Expression? target) {
    final name = _identifierName(target);
    if (name == null || name == 'Ack') {
      return null;
    }
    return name;
  }

  /// Walks a method chain to find the base Ack.xxx() invocation.
  ///
  /// For `Ack.string().describe('...').optional()`, returns `Ack.string()`.
  /// For `Ack.integer().min(0).max(100)`, returns `Ack.integer()`.
  ///
  /// Returns `null` if no Ack.xxx() base is found.
  MethodInvocation? _findBaseAckInvocation(MethodInvocation invocation) {
    MethodInvocation current = invocation;

    // Safety limit to prevent infinite loops on malformed AST
    const maxDepth = 20;
    var depth = 0;

    while (depth < maxDepth) {
      final target = current.target;

      // Found base: target is 'Ack' identifier (supports prefixed Ack)
      if (_isAckTarget(target)) {
        return current;
      }

      // Continue walking the chain
      if (target is MethodInvocation) {
        current = target;
        depth++;
      } else {
        // Unknown target type
        return null;
      }
    }

    // Exceeded depth limit - likely malformed AST
    _log.warning('Method chain exceeded max depth of $maxDepth. '
        'List element type will fall back to dynamic.');
    return null;
  }

  /// Walks a method chain to find a schema variable base identifier.
  ///
  /// For `itemSchema.optional().nullable()`, returns `'itemSchema'`.
  /// For `addressSchema.describe('...')`, returns `'addressSchema'`.
  ///
  /// Returns `null` if the chain doesn't end with a schema variable identifier
  /// (e.g., if it's an Ack.xxx() chain or unknown structure).
  ///
  String? _findSchemaVariableBase(MethodInvocation invocation) {
    MethodInvocation current = invocation;

    const maxDepth = 20;
    var depth = 0;

    while (depth < maxDepth) {
      final target = current.target;

      final schemaVarName = _extractSchemaVariableName(target);
      if (schemaVarName != null) {
        return schemaVarName;
      }

      // If target resolves to Ack, this is an Ack.xxx() chain
      if (_isAckTarget(target)) {
        return null;
      }

      // Continue walking the chain
      if (target is MethodInvocation) {
        current = target;
        depth++;
      } else {
        return null;
      }
    }

    // Exceeded depth limit - likely malformed AST
    _log.warning('Schema variable method chain exceeded max depth of $maxDepth. '
        'List element type will fall back to dynamic.');
    return null;
  }

  /// Resolves the base class name for a schema variable, honoring custom overrides.
  String _resolveModelClassName(
    String variableName,
    Element2 element, {
    String? customTypeName,
  }) {
    if (customTypeName == null) {
      return _generateTypeNameFromVariable(variableName);
    }

    final trimmed = customTypeName.trim();
    if (trimmed.isEmpty) {
      throw InvalidGenerationSourceError(
        'Custom @AckType name cannot be empty',
        element: element,
        todo: 'Provide a non-empty type name in the @AckType annotation.',
      );
    }

    const identifierPattern = r'^[A-Za-z_][A-Za-z0-9_]*$';
    if (!RegExp(identifierPattern).hasMatch(trimmed)) {
      throw InvalidGenerationSourceError(
        'Invalid custom @AckType name "$customTypeName". '
        'Type names must start with a letter or underscore and can only contain letters, numbers, and underscores.',
        element: element,
        todo: 'Update the @AckType annotation to use a valid Dart identifier.',
      );
    }

    // Ensure leading character is uppercase for consistency.
    if (trimmed.length == 1) {
      return trimmed.toUpperCase();
    }

    return trimmed[0].toUpperCase() + trimmed.substring(1);
  }

  /// Generates an extension type name from a schema variable name
  ///
  /// Examples:
  /// - "userSchema" → "User"
  /// - "addressSchema" → "Address"
  /// - "myDataSchema" → "MyData"
  String _generateTypeNameFromVariable(String variableName) {
    // Remove "Schema" suffix if present
    var name = variableName;
    if (name.endsWith('Schema')) {
      name = name.substring(0, name.length - 'Schema'.length);
    }

    // Capitalize first letter
    if (name.isEmpty) return 'Type';
    return name[0].toUpperCase() + name.substring(1);
  }

  /// Parses Ack.string() schema
  ModelInfo _parseStringSchema(
    String variableName,
    MethodInvocation invocation,
    Element2 element, {
    required bool isNullable,
    String? customTypeName,
  }) {
    final typeName = _resolveModelClassName(
      variableName,
      element,
      customTypeName: customTypeName,
    );

    return ModelInfo(
      className: typeName,
      schemaClassName: variableName,
      fields: [],
      isFromSchemaVariable: true,
      representationType: 'String',
      isNullableSchema: isNullable,
    );
  }

  /// Parses Ack.integer() schema
  ModelInfo _parseIntegerSchema(
    String variableName,
    MethodInvocation invocation,
    Element2 element, {
    required bool isNullable,
    String? customTypeName,
  }) {
    final typeName = _resolveModelClassName(
      variableName,
      element,
      customTypeName: customTypeName,
    );

    return ModelInfo(
      className: typeName,
      schemaClassName: variableName,
      fields: [],
      isFromSchemaVariable: true,
      representationType: 'int',
      isNullableSchema: isNullable,
    );
  }

  /// Parses Ack.double() schema
  ModelInfo _parseDoubleSchema(
    String variableName,
    MethodInvocation invocation,
    Element2 element, {
    required bool isNullable,
    String? customTypeName,
  }) {
    final typeName = _resolveModelClassName(
      variableName,
      element,
      customTypeName: customTypeName,
    );

    return ModelInfo(
      className: typeName,
      schemaClassName: variableName,
      fields: [],
      isFromSchemaVariable: true,
      representationType: 'double',
      isNullableSchema: isNullable,
    );
  }

  /// Parses Ack.boolean() schema
  ModelInfo _parseBooleanSchema(
    String variableName,
    MethodInvocation invocation,
    Element2 element, {
    required bool isNullable,
    String? customTypeName,
  }) {
    final typeName = _resolveModelClassName(
      variableName,
      element,
      customTypeName: customTypeName,
    );

    return ModelInfo(
      className: typeName,
      schemaClassName: variableName,
      fields: [],
      isFromSchemaVariable: true,
      representationType: 'bool',
      isNullableSchema: isNullable,
    );
  }

  /// Parses Ack.list() schema
  ///
  /// Extracts the element type from list schema definitions to generate
  /// correctly typed extension types (e.g., `List<String>` not `List<dynamic>`).
  ///
  /// Examples:
  /// - `Ack.list(Ack.string())` → `List<String>`
  /// - `Ack.list(Ack.integer())` → `List<int>`
  /// - `Ack.list(Ack.list(Ack.double()))` → `List<List<double>>` (nested)
  /// - `Ack.list(addressSchema)` → `List<Map<String, Object?>>` (schema reference)
  ModelInfo _parseListSchema(
    String variableName,
    MethodInvocation invocation,
    Element2 element, {
    required bool isNullable,
    String? customTypeName,
  }) {
    final typeName = _resolveModelClassName(
      variableName,
      element,
      customTypeName: customTypeName,
    );

    // Extract element type from first argument: Ack.list(elementSchema)
    final elementType = _extractListElementTypeString(invocation, element);

    return ModelInfo(
      className: typeName,
      schemaClassName: variableName,
      fields: [],
      isFromSchemaVariable: true,
      representationType: 'List<$elementType>',
      isNullableSchema: isNullable,
    );
  }

  /// Extracts the element type as a string representation for top-level list schemas.
  ///
  /// This handles:
  /// - Primitive schemas: `Ack.list(Ack.string())` → 'String'
  /// - Nested lists: `Ack.list(Ack.list(Ack.int()))` → 'List<int>'
  /// - Schema references: `Ack.list(addressSchema)` → resolves to the referenced schema's representation type
  String _extractListElementTypeString(
    MethodInvocation listInvocation,
    Element2 element,
  ) {
    final args = listInvocation.argumentList.arguments;

    if (args.isEmpty) {
      return 'dynamic';
    }

    final firstArg = args.first;

    // Handle Ack.list(Ack.xxx().chain()) - nested method invocation
    if (firstArg is MethodInvocation) {
      final baseInvocation = _findBaseAckInvocation(firstArg);
      if (baseInvocation != null) {
        final methodName = baseInvocation.methodName.name;

        // Handle nested lists recursively
        if (methodName == 'list') {
          final nestedType =
              _extractListElementTypeString(baseInvocation, element);
          return 'List<$nestedType>';
        }

        // Map primitive schema types
        return _mapSchemaMethodToType(methodName);
      }

      // Handle schema variable reference with method chain (e.g., schema.optional())
      final schemaVarName = _findSchemaVariableBase(firstArg);
      if (schemaVarName != null) {
        return _resolveSchemaVariableElementTypeString(schemaVarName, element);
      }
    }

    // Handle Ack.list(schemaVariableName) - schema variable reference (simple or prefixed)
    final schemaVarName = _extractSchemaVariableName(firstArg);
    if (schemaVarName != null) {
      return _resolveSchemaVariableElementTypeString(schemaVarName, element);
    }

    return 'dynamic';
  }

  /// Parses Ack.literal() schema
  ///
  /// Literal schemas are StringSchema with a literal constraint.
  /// The constraint is enforced at runtime, not in the extension type.
  ///
  /// Example: Ack.literal('active') → extension type StatusType(String)
  ModelInfo _parseLiteralSchema(
    String variableName,
    MethodInvocation invocation,
    Element2 element, {
    required bool isNullable,
    String? customTypeName,
  }) {
    final typeName = _resolveModelClassName(
      variableName,
      element,
      customTypeName: customTypeName,
    );

    return ModelInfo(
      className: typeName,
      schemaClassName: variableName,
      fields: [],
      isFromSchemaVariable: true,
      representationType: 'String',
      isNullableSchema: isNullable,
    );
  }

  /// Parses Ack.enumString() schema
  ///
  /// EnumString schemas are StringSchema with enum constraint.
  /// The allowed values are enforced at runtime, not in the extension type.
  ///
  /// Example: Ack.enumString(['a', 'b']) → extension type XType(String)
  ModelInfo _parseEnumStringSchema(
    String variableName,
    MethodInvocation invocation,
    Element2 element, {
    required bool isNullable,
    String? customTypeName,
  }) {
    final typeName = _resolveModelClassName(
      variableName,
      element,
      customTypeName: customTypeName,
    );

    return ModelInfo(
      className: typeName,
      schemaClassName: variableName,
      fields: [],
      isFromSchemaVariable: true,
      representationType: 'String',
      isNullableSchema: isNullable,
    );
  }

  /// Parses `Ack.enumValues<T>()` schema
  ///
  /// EnumValues schemas wrap Dart enum types with validation.
  /// The representation type is the enum type itself.
  ///
  /// Example: `Ack.enumValues<UserRole>([...])` → extension type XType(UserRole)
  ModelInfo _parseEnumValuesSchema(
    String variableName,
    MethodInvocation invocation,
    Element2 element, {
    required bool isNullable,
    String? customTypeName,
  }) {
    final typeName = _resolveModelClassName(
      variableName,
      element,
      customTypeName: customTypeName,
    );

    // Strategy 1: Try to extract from type arguments: Ack.enumValues<UserRole>([...])
    final typeArgs = invocation.typeArguments?.arguments;
    String? enumTypeName;

    if (typeArgs != null && typeArgs.isNotEmpty) {
      // Get the first type argument (the enum type)
      final typeArg = typeArgs.first;
      enumTypeName = typeArg.toString();
    } else {
      // Strategy 2: Try to infer from argument list: Ack.enumValues(UserRole.values)
      final args = invocation.argumentList.arguments;
      if (args.isNotEmpty) {
        final firstArg = args.first;

        // Check if it's EnumType.values (PrefixedIdentifier)
        if (firstArg is PrefixedIdentifier) {
          final prefix = firstArg.prefix.name;
          final identifier = firstArg.identifier.name;

          if (identifier == 'values') {
            // UserRole.values → use 'UserRole'
            enumTypeName = prefix;
          }
        }
      }
    }

    // If we couldn't extract the enum type, throw an error
    if (enumTypeName == null) {
      throw InvalidGenerationSourceError(
        'Could not determine enum type for Ack.enumValues(). '
        'Use explicit type argument: Ack.enumValues<YourEnum>([...]) '
        'or pass enum.values: Ack.enumValues(YourEnum.values)',
        element: element,
      );
    }

    return ModelInfo(
      className: typeName,
      schemaClassName: variableName,
      fields: [],
      isFromSchemaVariable: true,
      representationType: enumTypeName,
      isNullableSchema: isNullable,
    );
  }

  bool _hasModifier(MethodInvocation invocation, String modifierName) {
    MethodInvocation? current = invocation;
    while (current != null) {
      if (current.methodName.name == modifierName) {
        return true;
      }

      final target = current.target;
      if (target is MethodInvocation) {
        current = target;
      } else {
        break;
      }
    }

    return false;
  }

  /// Maps Ack schema method names to Dart type strings
  ///
  /// Used for generating string representations of types in list element contexts.
  /// For nested lists, this function is called recursively via [_parseListSchema].
  String _mapSchemaMethodToType(String methodName) {
    switch (methodName) {
      case 'string':
        return 'String';
      case 'integer':
        return 'int';
      case 'double':
        return 'double';
      case 'boolean':
        return 'bool';
      case 'object':
        return _kMapType;
      case 'list':
        // Note: Nested lists are handled by _parseListSchema recursively
        // This case exists for consistency but should not be reached in normal flow
        return 'List<dynamic>';
      default:
        return 'dynamic';
    }
  }

  /// Validates that a field name is a valid Dart identifier
  ///
  /// Throws [InvalidGenerationSourceError] if the field name:
  /// - Contains invalid characters (must match [a-zA-Z_$][a-zA-Z0-9_$]*)
  /// - Is a Dart reserved keyword
  void _validateFieldName(String fieldName, Element2 element) {
    // Check if key is a valid Dart identifier
    final identifierRegex = RegExp(r'^[a-zA-Z_$][a-zA-Z0-9_$]*$');
    if (!identifierRegex.hasMatch(fieldName)) {
      throw InvalidGenerationSourceError(
        'JSON key "$fieldName" is not a valid Dart identifier. '
        'Keys must start with a letter, underscore, or dollar sign, and can only '
        'contain letters, numbers, underscores, and dollar signs.',
        element: element,
        todo:
            'Use a valid Dart identifier as the key, or consider transforming '
            'the key to a valid identifier (e.g., "user-id" → "userId").',
      );
    }

    // Check for reserved keywords
    if (_dartKeywords.contains(fieldName)) {
      throw InvalidGenerationSourceError(
        'JSON key "$fieldName" is a Dart reserved keyword and cannot be used as a field name.',
        element: element,
        todo:
            'Use a different key that is not a Dart reserved keyword, or prefix it '
            '(e.g., "class" → "classValue" or "klass").',
      );
    }
  }
}
