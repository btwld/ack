import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:source_gen/source_gen.dart';

import '../models/field_info.dart';
import '../models/model_info.dart';

/// Default representation type for object schemas
const String _kMapType = 'Map<String, Object?>';

/// Analyzes schema variables by walking the AST
///
/// This analyzer inspects the AST structure of schema definitions
/// (like `Ack.object({...})`) to extract field type information without
/// requiring const evaluation or string parsing.
class SchemaAstAnalyzer {
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
    MethodInvocation? current = invocation;
    MethodInvocation? baseInvocation;

    while (current != null) {
      final target = current.target;

      // Check if this is the Ack.xxx() base call
      if (target is SimpleIdentifier && target.name == 'Ack') {
        baseInvocation = current;
        break;
      }

      // Move to the next method in the chain
      if (target is MethodInvocation) {
        current = target;
      } else {
        break;
      }
    }

    if (baseInvocation == null) {
      throw InvalidGenerationSourceError(
        'Schema must be an Ack.xxx() method call (e.g., Ack.object(), Ack.string())',
        element: element,
      );
    }

    final methodName = baseInvocation.methodName.name;

    // Parse based on schema type
    switch (methodName) {
      case 'object':
        return _parseObjectSchema(
          variableName,
          baseInvocation,
          invocation, // Pass original invocation to check for chained methods
          element,
          customTypeName: customTypeName,
        );
      case 'string':
        return _parseStringSchema(
          variableName,
          baseInvocation,
          element,
          customTypeName: customTypeName,
        );
      case 'integer':
        return _parseIntegerSchema(
          variableName,
          baseInvocation,
          element,
          customTypeName: customTypeName,
        );
      case 'double':
        return _parseDoubleSchema(
          variableName,
          baseInvocation,
          element,
          customTypeName: customTypeName,
        );
      case 'boolean':
        return _parseBooleanSchema(
          variableName,
          baseInvocation,
          element,
          customTypeName: customTypeName,
        );
      case 'list':
        return _parseListSchema(
          variableName,
          baseInvocation,
          element,
          customTypeName: customTypeName,
        );
      case 'literal':
        return _parseLiteralSchema(
          variableName,
          baseInvocation,
          element,
          customTypeName: customTypeName,
        );
      case 'enumString':
        return _parseEnumStringSchema(
          variableName,
          baseInvocation,
          element,
          customTypeName: customTypeName,
        );
      case 'enumValues':
        return _parseEnumValuesSchema(
          variableName,
          baseInvocation,
          element,
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
        final target = current.target;
        if (target is SimpleIdentifier && target.name == 'Ack') {
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
        // Nested objects represented as Map<String, dynamic>
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
  /// Handles both:
  /// - Method invocations: `Ack.list(Ack.string())` → `List<String>`
  /// - Schema references: `Ack.list(addressSchema)` → `List<Map<String, dynamic>>`
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

    // Handle Ack.list(Ack.string()) - nested method invocation
    if (firstArg is MethodInvocation) {
      // Check if this is an Ack.xxx() call
      if (firstArg.target is SimpleIdentifier &&
          (firstArg.target as SimpleIdentifier).name == 'Ack') {
        // Recursively extract the element type (no schema ref for primitives)
        final (elementType, _) = _mapSchemaTypeToDartType(firstArg, element);
        return (typeProvider.listType(elementType), null);
      }
    }

    // Handle Ack.list(addressSchema) - schema variable reference
    if (firstArg is SimpleIdentifier) {
      final schemaVarName = firstArg.name;
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
          // Schema variable exists - return List<Map<String, dynamic>>
          // AND preserve the schema variable name for type builder
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
    }

    // Fallback for unknown argument types
    return (typeProvider.listType(typeProvider.dynamicType), null);
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
    );
  }

  /// Parses Ack.integer() schema
  ModelInfo _parseIntegerSchema(
    String variableName,
    MethodInvocation invocation,
    Element2 element, {
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
    );
  }

  /// Parses Ack.double() schema
  ModelInfo _parseDoubleSchema(
    String variableName,
    MethodInvocation invocation,
    Element2 element, {
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
    );
  }

  /// Parses Ack.boolean() schema
  ModelInfo _parseBooleanSchema(
    String variableName,
    MethodInvocation invocation,
    Element2 element, {
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
  ModelInfo _parseListSchema(
    String variableName,
    MethodInvocation invocation,
    Element2 element, {
    String? customTypeName,
  }) {
    final typeName = _resolveModelClassName(
      variableName,
      element,
      customTypeName: customTypeName,
    );

    // Extract element type from first argument: Ack.list(elementSchema)
    final args = invocation.argumentList.arguments;
    String elementType = 'dynamic';

    if (args.isNotEmpty) {
      final firstArg = args.first;

      // Check if the element is an Ack.xxx() schema call
      // This handles: Ack.list(Ack.string()), Ack.list(Ack.list(Ack.integer())), etc.
      if (firstArg is MethodInvocation &&
          firstArg.target is SimpleIdentifier &&
          (firstArg.target as SimpleIdentifier).name == 'Ack') {
        final elementSchemaType = firstArg.methodName.name;
        // Recursively resolve element type (handles nested lists)
        elementType = _mapSchemaMethodToType(elementSchemaType);
      }
      // Note: Schema variable references (e.g., Ack.list(addressSchema))
      // fall through to 'dynamic' - this is a known limitation
    }

    return ModelInfo(
      className: typeName,
      schemaClassName: variableName,
      fields: [],
      isFromSchemaVariable: true,
      representationType: 'List<$elementType>',
    );
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
    );
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
}
