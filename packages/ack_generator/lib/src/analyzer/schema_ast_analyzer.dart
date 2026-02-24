import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart' show Keyword;
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:ack_annotations/ack_annotations.dart';
import 'package:logging/logging.dart';
import 'package:source_gen/source_gen.dart';

import '../models/field_info.dart';
import '../models/model_info.dart';

/// Logger for schema AST analysis warnings and diagnostics.
final _log = Logger('SchemaAstAnalyzer');

/// Default representation type for object schemas
const String _kMapType = 'Map<String, Object?>';

typedef _SchemaReference = ({String name, String? prefix});
typedef _ListElementRef = ({
  MethodInvocation? ackBase,
  _SchemaReference? schemaRef,
});

typedef _SchemaTypeMapping = ({
  DartType dartType,
  String? listElementSchemaRef,
  String? listElementDisplayTypeOverride,
  String? listElementCastTypeOverride,
  bool listElementIsCustomType,
});

class _ResolvedSchemaReference {
  final String schemaName;
  final ModelInfo modelInfo;
  final String? importPrefix;
  final bool hasAckTypeAnnotation;

  const _ResolvedSchemaReference({
    required this.schemaName,
    required this.modelInfo,
    required this.importPrefix,
    required this.hasAckTypeAnnotation,
  });
}

/// Analyzes schema variables by walking the AST
///
/// This analyzer inspects the AST structure of schema definitions
/// (like `Ack.object({...})`) to extract field type information without
/// requiring const evaluation or string parsing.
class SchemaAstAnalyzer {
  final Map<String, String> _schemaVariableTypeCache = {};
  final Set<String> _schemaVariableTypeStack = {};
  final Map<String, _ResolvedSchemaReference?> _schemaReferenceCache = {};
  final Set<String> _schemaReferenceResolutionStack = {};
  final Map<LibraryElement2, Map<String, ClassElement2>> _classByNameCache = {};
  final Map<LibraryElement2, Map<String, TopLevelVariableElement2>>
  _schemaVarByNameCache = {};
  final Map<LibraryElement2, Map<String, GetterElement>>
  _schemaGetterByNameCache = {};

  Map<String, ClassElement2> _classesByName(LibraryElement2 library) {
    return _classByNameCache.putIfAbsent(library, () {
      final map = <String, ClassElement2>{};
      for (final classElement in library.classes) {
        final name = classElement.name3;
        if (name != null) {
          map.putIfAbsent(name, () => classElement);
        }
      }
      return map;
    });
  }

  Map<String, TopLevelVariableElement2> _schemaVarsByName(
    LibraryElement2 library,
  ) {
    return _schemaVarByNameCache.putIfAbsent(library, () {
      final map = <String, TopLevelVariableElement2>{};
      for (final variable in library.topLevelVariables) {
        final name = variable.name3;
        if (name != null) {
          map.putIfAbsent(name, () => variable);
        }
      }
      return map;
    });
  }

  Map<String, GetterElement> _schemaGettersByName(LibraryElement2 library) {
    return _schemaGetterByNameCache.putIfAbsent(library, () {
      final map = <String, GetterElement>{};
      for (final getter in library.getters) {
        if (getter.isSynthetic) continue;

        final name = getter.name3;
        if (name != null) {
          map.putIfAbsent(name, () => getter);
        }
      }
      return map;
    });
  }

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

    if (initializer is MethodInvocation) {
      return _parseSchemaFromAST(
        element.name3!,
        initializer,
        element,
        customTypeName: customTypeName,
      );
    }

    final schemaReference = _extractSchemaReference(initializer);
    if (schemaReference != null) {
      return _parseSchemaAlias(
        variableName: element.name3!,
        reference: schemaReference,
        element: element,
        customTypeName: customTypeName,
      );
    }

    throw InvalidGenerationSourceError(
      'Schema variable "${element.name3}" must be initialized with a schema '
      '(e.g., Ack.object({...}))',
      element: element,
    );
  }

  /// Analyzes a top-level schema getter annotated with @AckType.
  ///
  /// Supported forms:
  /// - `AckSchema get userSchema => Ack.object({...});`
  /// - `AckSchema get userSchema { return Ack.object({...}); }`
  ModelInfo? analyzeSchemaGetter(
    GetterElement element, {
    String? customTypeName,
  }) {
    final fragment = element.firstFragment;
    final session = fragment.libraryFragment.element.session;
    final library = element.library2;

    final parsedLibResult = session.getParsedLibraryByElement2(library);
    if (parsedLibResult is! ParsedLibraryResult) {
      throw InvalidGenerationSourceError(
        'Could not get parsed library for getter "${element.name3}"',
        element: element,
      );
    }

    final declaration = parsedLibResult.getFragmentDeclaration(fragment);
    if (declaration == null || declaration.node is! FunctionDeclaration) {
      throw InvalidGenerationSourceError(
        'Could not find getter declaration for "${element.name3}"',
        element: element,
      );
    }

    final getterDecl = declaration.node as FunctionDeclaration;
    if (!getterDecl.isGetter) {
      throw InvalidGenerationSourceError(
        '"${element.name3}" is not a getter declaration',
        element: element,
      );
    }

    final body = getterDecl.functionExpression.body;
    Expression? schemaExpression;

    if (body is ExpressionFunctionBody) {
      schemaExpression = body.expression;
    } else if (body is BlockFunctionBody) {
      final statements = body.block.statements;
      if (statements.length != 1 || statements.first is! ReturnStatement) {
        throw InvalidGenerationSourceError(
          'Schema getter "${element.name3}" must return a schema expression',
          element: element,
          todo:
              'Use an expression body or a single return statement (e.g., return Ack.object({...});).',
        );
      }

      final returnStatement = statements.first as ReturnStatement;
      schemaExpression = returnStatement.expression;
    }

    if (schemaExpression is! MethodInvocation) {
      throw InvalidGenerationSourceError(
        'Schema getter "${element.name3}" must return an Ack schema invocation',
        element: element,
        todo:
            'Return a schema expression such as Ack.object({...}) or Ack.string().',
      );
    }

    return _parseSchemaFromAST(
      element.name3!,
      schemaExpression,
      element,
      customTypeName: customTypeName,
    );
  }

  ModelInfo _parseSchemaAlias({
    required String variableName,
    required _SchemaReference reference,
    required Element2 element,
    String? customTypeName,
  }) {
    final resolved = _resolveSchemaReference(reference, element);
    if (resolved == null) {
      final referenceLabel = _formatSchemaReference(reference);
      throw InvalidGenerationSourceError(
        'Could not resolve schema alias "$variableName" '
        'to "$referenceLabel"',
        element: element,
      );
    }

    final aliasTypeName = _resolveModelClassName(
      variableName,
      element,
      customTypeName: customTypeName,
    );
    final sourceModel = resolved.modelInfo;

    return ModelInfo(
      className: aliasTypeName,
      schemaClassName: variableName,
      fields: sourceModel.fields,
      additionalProperties: sourceModel.additionalProperties,
      isFromSchemaVariable: true,
      representationType: sourceModel.representationType,
      isNullableSchema: sourceModel.isNullableSchema,
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
    final hasAdditionalProperties = _hasAdditionalPropertiesFromInvocation(
      baseInvocation,
      fullInvocation,
    );

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

  bool _hasAdditionalPropertiesFromInvocation(
    MethodInvocation baseInvocation,
    MethodInvocation fullInvocation,
  ) {
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

    return hasAdditionalProperties;
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
      final schemaReferenceField = _parseSchemaReferenceMethod(
        fieldName,
        value,
        element,
      );
      if (schemaReferenceField != null) {
        return schemaReferenceField;
      }
      return _parseSchemaMethod(fieldName, value, element);
    }

    // Handle references to other schema variables (for nested objects)
    final schemaReference = _extractSchemaReference(value);
    if (schemaReference != null) {
      return _buildFieldInfoForSchemaReference(
        fieldName: fieldName,
        schemaReference: schemaReference,
        element: element,
      );
    }

    return null;
  }

  FieldInfo? _parseSchemaReferenceMethod(
    String fieldName,
    MethodInvocation invocation,
    Element2 element,
  ) {
    final schemaReference = _findSchemaVariableBase(invocation);
    if (schemaReference == null) {
      return null;
    }

    var isOptional = false;
    var isNullable = false;
    final (chain, _) = _collectMethodChain(invocation);
    for (final current in chain) {
      final methodName = current.methodName.name;
      if (methodName == 'optional') {
        isOptional = true;
      } else if (methodName == 'nullable') {
        isNullable = true;
      }
    }

    return _buildFieldInfoForSchemaReference(
      fieldName: fieldName,
      schemaReference: schemaReference,
      element: element,
      isRequired: !isOptional,
      isNullable: isNullable,
    );
  }

  FieldInfo _buildFieldInfoForSchemaReference({
    required String fieldName,
    required _SchemaReference schemaReference,
    required Element2 element,
    bool isRequired = true,
    bool isNullable = false,
  }) {
    final schemaVarName = schemaReference.name;
    final library = element.library2;

    final typeProvider = library?.typeProvider;
    if (typeProvider == null) {
      throw InvalidGenerationSourceError(
        'Could not get type provider for library',
        element: element,
      );
    }

    final resolvedReference = _resolveSchemaReference(schemaReference, element);
    if (resolvedReference == null) {
      throw InvalidGenerationSourceError(
        'Could not resolve schema reference "$schemaVarName" for field '
        '"$fieldName".',
        element: element,
        todo:
            'Ensure "$schemaVarName" exists, is imported, and is declared as an Ack schema.',
      );
    }

    final hasTypedReference = resolvedReference.hasAckTypeAnnotation;
    final isObjectRepresentation =
        resolvedReference.modelInfo.representationType == _kMapType;
    if (isObjectRepresentation && !hasTypedReference) {
      throw InvalidGenerationSourceError(
        'Field "$fieldName" references object schema "$schemaVarName" '
        'without @AckType. This would fall back to Map<String, Object?>.',
        element: element,
        todo:
            'Annotate "$schemaVarName" with @AckType() so the generator can emit a typed wrapper.',
      );
    }

    final mappedType = _representationTypeToDartType(
      resolvedReference.modelInfo.representationType,
      typeProvider,
    );
    final typeBaseName = hasTypedReference
        ? _qualifyTypeBaseName(
            resolvedReference.modelInfo.className,
            resolvedReference.importPrefix,
          )
        : null;

    return FieldInfo(
      name: fieldName,
      jsonKey: fieldName,
      type: mappedType,
      isRequired: isRequired,
      isNullable: isNullable,
      constraints: [],
      nestedSchemaRef: hasTypedReference ? schemaVarName : null,
      displayTypeOverride: hasTypedReference ? '${typeBaseName}Type' : null,
      nestedSchemaCastTypeOverride: hasTypedReference
          ? resolvedReference.modelInfo.representationType
          : null,
    );
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

    final schemaMethod = baseInvocation.methodName.name;

    if (schemaMethod == 'object') {
      throw InvalidGenerationSourceError(
        'Field "$fieldName" uses anonymous inline Ack.object(...). '
        'Strict typed generation requires a named schema reference.',
        element: element,
        todo:
            'Extract this inline object schema into a top-level @AckType() variable and reference it by name.',
      );
    }

    // Map schema type to Dart type (passing full invocation for context)
    // Also captures schema variable reference and list metadata for typed wrappers.
    final mappedType = _mapSchemaTypeToDartType(baseInvocation, element);

    String? displayTypeOverride;
    var collectionElementDisplayTypeOverride =
        mappedType.listElementDisplayTypeOverride;

    if (schemaMethod == 'enumValues') {
      displayTypeOverride = _extractEnumTypeNameFromInvocation(baseInvocation);
    } else if (schemaMethod == 'list') {
      collectionElementDisplayTypeOverride =
          _extractListEnumElementTypeName(baseInvocation) ??
          collectionElementDisplayTypeOverride;
    }

    return FieldInfo(
      name: fieldName,
      jsonKey: fieldName,
      type: mappedType.dartType,
      isRequired: !isOptional,
      isNullable: isNullable,
      constraints: [],
      listElementSchemaRef: mappedType.listElementSchemaRef,
      displayTypeOverride: displayTypeOverride,
      collectionElementDisplayTypeOverride:
          collectionElementDisplayTypeOverride,
      collectionElementCastTypeOverride: mappedType.listElementCastTypeOverride,
      collectionElementIsCustomType: mappedType.listElementIsCustomType,
    );
  }

  /// Maps a schema method invocation to a Dart type and optional schema reference
  ///
  /// Returns a record containing the field [DartType] plus list metadata used
  /// by the type builder for typed list getters.
  _SchemaTypeMapping _mapSchemaTypeToDartType(
    MethodInvocation invocation,
    Element2 element,
  ) {
    final schemaMethod = invocation.methodName.name;

    // We need to get the type provider from the element's library
    final library = element.library2!;

    final typeProvider = library.typeProvider;

    switch (schemaMethod) {
      case 'string':
        return (
          dartType: typeProvider.stringType,
          listElementSchemaRef: null,
          listElementDisplayTypeOverride: null,
          listElementCastTypeOverride: null,
          listElementIsCustomType: false,
        );
      case 'integer':
        return (
          dartType: typeProvider.intType,
          listElementSchemaRef: null,
          listElementDisplayTypeOverride: null,
          listElementCastTypeOverride: null,
          listElementIsCustomType: false,
        );
      case 'double':
        return (
          dartType: typeProvider.doubleType,
          listElementSchemaRef: null,
          listElementDisplayTypeOverride: null,
          listElementCastTypeOverride: null,
          listElementIsCustomType: false,
        );
      case 'boolean':
        return (
          dartType: typeProvider.boolType,
          listElementSchemaRef: null,
          listElementDisplayTypeOverride: null,
          listElementCastTypeOverride: null,
          listElementIsCustomType: false,
        );
      case 'list':
        // Extract element type from Ack.list(elementSchema) argument
        // This may return a schema variable reference for nested schemas
        return _extractListType(invocation, element, typeProvider);
      case 'object':
        // Nested objects represented as Map<String, Object?>
        // Note: Using dynamicType for analyzer; generated code uses Object?
        return (
          dartType: typeProvider.mapType(
            typeProvider.stringType,
            typeProvider.dynamicType,
          ),
          listElementSchemaRef: null,
          listElementDisplayTypeOverride: null,
          listElementCastTypeOverride: null,
          listElementIsCustomType: false,
        );
      case 'enumString':
      case 'literal':
        return (
          dartType: typeProvider.stringType,
          listElementSchemaRef: null,
          listElementDisplayTypeOverride: null,
          listElementCastTypeOverride: null,
          listElementIsCustomType: false,
        );
      case 'enumValues':
        final resolvedType = _resolveEnumValuesType(
          invocation,
          library: library,
        );
        if (resolvedType != null) {
          return (
            dartType: resolvedType,
            listElementSchemaRef: null,
            listElementDisplayTypeOverride: null,
            listElementCastTypeOverride: null,
            listElementIsCustomType: false,
          );
        }
        // Fallback to `dynamic` if the enum type can't be resolved.
        // This avoids incorrectly assuming `String` when EnumSchema<T>.parse()
        // returns the enum value type T.
        _log.warning(
          'Could not resolve enum type for Ack.enumValues(); falling back to dynamic.',
        );
        return (
          dartType: typeProvider.dynamicType,
          listElementSchemaRef: null,
          listElementDisplayTypeOverride: null,
          listElementCastTypeOverride: null,
          listElementIsCustomType: false,
        );
      default:
        throw InvalidGenerationSourceError(
          'Unsupported schema method: Ack.$schemaMethod()',
          element: element,
        );
    }
  }

  /// Extracts the enum type name from an `Ack.enumValues<T>(...)` invocation.
  ///
  /// Prefers source text only when it contains a qualifier
  /// (e.g., `alias.UserRole`) so import prefixes are preserved in generated
  /// part files.
  ///
  /// For non-qualified names, prefers resolved static types to avoid
  /// incorrectly treating arbitrary `.values` receivers as enum type names
  /// (for example, `holder.values` should resolve to the list element type).
  String? _extractEnumTypeNameFromInvocation(MethodInvocation invocation) {
    final sourceTypeName = _extractEnumTypeNameFromSource(invocation);
    if (sourceTypeName != null && sourceTypeName.contains('.')) {
      return sourceTypeName;
    }

    final resolvedType = _resolveEnumValuesType(invocation);
    if (resolvedType != null) {
      return resolvedType.getDisplayString(withNullability: false);
    }

    return sourceTypeName;
  }

  String? _extractEnumTypeNameFromSource(MethodInvocation invocation) {
    // From type argument: Ack.enumValues<UserRole>(...) or Ack.enumValues<foo.UserRole>(...)
    final typeArgs = invocation.typeArguments?.arguments;
    if (typeArgs != null && typeArgs.isNotEmpty) {
      return typeArgs.first.toSource();
    }

    // From argument pattern: Ack.enumValues(UserRole.values) / Ack.enumValues(alias.UserRole.values)
    final args = invocation.argumentList.arguments;
    if (args.isNotEmpty) {
      final firstArg = args.first;
      if (firstArg is PrefixedIdentifier &&
          firstArg.identifier.name == 'values') {
        final targetSource = firstArg.prefix.toSource();
        if (_looksLikeTypeReference(targetSource)) {
          return targetSource;
        }
      }
      if (firstArg is PropertyAccess &&
          firstArg.propertyName.name == 'values') {
        final targetSource = firstArg.target?.toSource();
        if (targetSource != null && _looksLikeTypeReference(targetSource)) {
          return targetSource;
        }
      }
    }

    return null;
  }

  bool _looksLikeTypeReference(String source) {
    final trimmed = source.trim();
    if (trimmed.isEmpty) return false;

    final identifier = trimmed.split('.').last;
    if (identifier.isEmpty) return false;

    final firstCodeUnit = identifier.codeUnitAt(0);
    const uppercaseA = 65;
    const uppercaseZ = 90;
    const underscore = 95;
    return (firstCodeUnit >= uppercaseA && firstCodeUnit <= uppercaseZ) ||
        firstCodeUnit == underscore;
  }

  String? _extractListEnumElementTypeName(MethodInvocation listInvocation) {
    final args = listInvocation.argumentList.arguments;
    if (args.isEmpty) return null;

    final ref = _resolveListElementRef(args.first);
    final elementSchema = ref.ackBase;
    if (elementSchema == null ||
        elementSchema.methodName.name != 'enumValues') {
      return null;
    }

    return _extractEnumTypeNameFromInvocation(elementSchema);
  }

  /// Resolves enum type `T` from an `Ack.enumValues<T>(...)` invocation.
  ///
  /// Resolution strategy (in order):
  /// 1. Explicit type argument's resolved type (`Ack.enumValues<T>(...)`)
  /// 2. Invocation static type argument (`EnumSchema<T>`)
  /// 3. First argument static type (`List<T>` from `T.values`)
  /// 4. Source name lookup in the library/import scope
  DartType? _resolveEnumValuesType(
    MethodInvocation invocation, {
    LibraryElement2? library,
  }) {
    final typeArgs = invocation.typeArguments?.arguments;
    if (typeArgs != null && typeArgs.isNotEmpty) {
      final explicitType = typeArgs.first.type;
      if (explicitType is InterfaceType) {
        return explicitType;
      }
    }

    final invocationType = invocation.staticType;
    if (invocationType is InterfaceType &&
        invocationType.typeArguments.isNotEmpty) {
      final schemaTypeArg = invocationType.typeArguments.first;
      if (schemaTypeArg is InterfaceType) {
        return schemaTypeArg;
      }
    }

    final args = invocation.argumentList.arguments;
    if (args.isNotEmpty) {
      final resolvedFromArgument = _resolveEnumValuesTypeFromArgument(
        args.first,
        library: library,
      );
      if (resolvedFromArgument != null) {
        return resolvedFromArgument;
      }
    }

    if (library != null) {
      final enumTypeName = _extractEnumTypeNameFromSource(invocation);
      if (enumTypeName != null) {
        final resolvedByName = _resolveTypeByName(enumTypeName, library);
        if (resolvedByName != null) {
          return resolvedByName;
        }
      }
    }

    return null;
  }

  DartType? _resolveEnumValuesTypeFromArgument(
    Expression argument, {
    LibraryElement2? library,
  }) {
    final enumFromStaticType = _extractEnumTypeFromCandidate(
      argument.staticType,
    );
    if (enumFromStaticType != null) {
      return enumFromStaticType;
    }

    if (library == null) {
      return null;
    }

    final resolvedExpressionType = _resolveExpressionType(argument, library);
    return _extractEnumTypeFromCandidate(resolvedExpressionType);
  }

  DartType? _extractEnumTypeFromCandidate(DartType? candidate) {
    if (candidate is! InterfaceType) {
      return null;
    }

    if (candidate.element3 is EnumElement2) {
      return candidate;
    }

    if (candidate.isDartCoreList && candidate.typeArguments.isNotEmpty) {
      final elementType = candidate.typeArguments.first;
      if (elementType is InterfaceType &&
          elementType.element3 is EnumElement2) {
        return elementType;
      }
    }

    return null;
  }

  DartType? _resolveExpressionType(
    Expression expression,
    LibraryElement2 library,
  ) {
    final staticType = expression.staticType;
    if (staticType != null && staticType is! DynamicType) {
      return staticType;
    }

    if (expression is SimpleIdentifier) {
      final variableType = _schemaVarsByName(library)[expression.name]?.type;
      if (variableType != null) {
        return variableType;
      }

      final getterType = _schemaGettersByName(
        library,
      )[expression.name]?.returnType;
      if (getterType != null) {
        return getterType;
      }

      return _resolveTypeByName(expression.name, library);
    }

    if (expression is PrefixedIdentifier) {
      final targetType = _resolveExpressionType(expression.prefix, library);
      if (targetType is InterfaceType) {
        final memberType = _resolveClassMemberType(
          targetType: targetType,
          memberName: expression.identifier.name,
          library: library,
        );
        if (memberType != null) {
          return memberType;
        }
      }

      return _resolveTypeByName(expression.toSource(), library);
    }

    if (expression is PropertyAccess) {
      final target = expression.target;
      if (target != null) {
        final targetType = _resolveExpressionType(target, library);
        if (targetType is InterfaceType) {
          final memberType = _resolveClassMemberType(
            targetType: targetType,
            memberName: expression.propertyName.name,
            library: library,
          );
          if (memberType != null) {
            return memberType;
          }
        }
      }
    }

    return null;
  }

  DartType? _resolveClassMemberType({
    required InterfaceType targetType,
    required String memberName,
    required LibraryElement2 library,
  }) {
    final className = targetType.element3.name3;
    if (className == null) return null;

    final classElement = _classesByName(library)[className];
    if (classElement == null) return null;

    final allFields = [
      ...classElement.fields2,
      ...classElement.allSupertypes.expand((type) => type.element3.fields2),
    ];

    final field = allFields.cast<FieldElement2?>().firstWhere(
      (current) => current?.name3 == memberName,
      orElse: () => null,
    );
    if (field != null) {
      return field.type;
    }

    final allGetters = [
      ...classElement.getters2,
      ...classElement.allSupertypes.expand((type) => type.element3.getters2),
    ];

    final getter = allGetters.cast<GetterElement?>().firstWhere(
      (current) => current?.name3 == memberName,
      orElse: () => null,
    );
    return getter?.returnType;
  }

  DartType? _resolveTypeByName(String typeName, LibraryElement2 library) {
    final normalizedTypeName = typeName.trim();
    if (normalizedTypeName.isEmpty) return null;

    final scopeResult = library.firstFragment.scope.lookup(normalizedTypeName);
    final scopeType = _resolveTypeFromElement(scopeResult.getter2);
    if (scopeType != null) {
      return scopeType;
    }

    // Try import namespaces directly as a fallback for simple imported names.
    for (final import in library.firstFragment.libraryImports2) {
      final importedElement = import.namespace.get2(normalizedTypeName);
      final importedType = _resolveTypeFromElement(importedElement);
      if (importedType != null) {
        return importedType;
      }
    }

    // Last-resort local lookup.
    for (final enumElement in library.enums) {
      if (enumElement.name3 == normalizedTypeName) {
        return enumElement.thisType;
      }
    }
    for (final classElement in library.classes) {
      if (classElement.name3 == normalizedTypeName) {
        return classElement.thisType;
      }
    }

    return null;
  }

  DartType? _resolveTypeFromElement(Element2? element) {
    if (element is EnumElement2) {
      return element.thisType;
    }

    if (element is ClassElement2) {
      return element.thisType;
    }

    if (element is TypeAliasElement2) {
      final aliasedType = element.aliasedType;
      if (aliasedType is InterfaceType) {
        return aliasedType;
      }
    }

    return null;
  }

  _ListElementRef _resolveListElementRef(Expression firstArg) {
    if (firstArg is MethodInvocation) {
      final baseInvocation = _findBaseAckInvocation(firstArg);
      if (baseInvocation != null) {
        return (ackBase: baseInvocation, schemaRef: null);
      }

      final schemaRef = _findSchemaVariableBase(firstArg);
      if (schemaRef != null) {
        return (ackBase: null, schemaRef: schemaRef);
      }

      return (ackBase: null, schemaRef: null);
    }

    final schemaRef = _extractSchemaReference(firstArg);
    if (schemaRef != null) {
      return (ackBase: null, schemaRef: schemaRef);
    }

    return (ackBase: null, schemaRef: null);
  }

  /// Extracts the element type from Ack.list(elementSchema) calls
  ///
  /// Handles:
  /// - Method invocations: `Ack.list(Ack.string())` → `List<String>`
  /// - Method chains: `Ack.list(Ack.string().describe(...))` → `List<String>`
  /// - Schema references: `Ack.list(addressSchema)` → `List<Map<String, Object?>>`
  /// - Schema ref chains: `Ack.list(addressSchema.optional())` → `List<Map<String, Object?>>`
  ///
  /// Returns a mapping with the list [DartType] and optional metadata used to
  /// build typed list wrappers when the element references another schema.
  _SchemaTypeMapping _extractListType(
    MethodInvocation listInvocation,
    Element2 element,
    TypeProvider typeProvider,
  ) {
    final args = listInvocation.argumentList.arguments;

    if (args.isEmpty) {
      throw InvalidGenerationSourceError(
        'Ack.list(...) requires an element schema argument for strict typed generation.',
        element: element,
        todo:
            'Provide a concrete element schema, e.g. Ack.list(Ack.string()) or Ack.list(namedSchema).',
      );
    }

    final firstArg = args.first;

    final ref = _resolveListElementRef(firstArg);
    if (ref.ackBase != null) {
      final methodName = ref.ackBase!.methodName.name;
      if (methodName == 'object') {
        throw InvalidGenerationSourceError(
          'Ack.list(Ack.object(...)) uses an anonymous inline object schema. '
          'Strict typed generation requires a named schema reference.',
          element: element,
          todo:
              'Extract the inline object to a top-level @AckType() variable and use Ack.list(namedSchema).',
        );
      }

      final nestedMapping = _mapSchemaTypeToDartType(ref.ackBase!, element);
      return (
        dartType: typeProvider.listType(nestedMapping.dartType),
        listElementSchemaRef: null,
        listElementDisplayTypeOverride: null,
        listElementCastTypeOverride: null,
        listElementIsCustomType: false,
      );
    }

    if (ref.schemaRef != null) {
      return _resolveSchemaVariableType(ref.schemaRef!, element, typeProvider);
    }

    final rawExpression = firstArg.toSource();
    throw InvalidGenerationSourceError(
      'Could not statically resolve Ack.list($rawExpression) element type.',
      element: element,
      todo:
          'Use Ack.list(Ack.<primitive>()), Ack.list(enumSchema), or Ack.list(namedSchema) so the generator can infer a concrete element type.',
    );
  }

  /// Resolves a schema reference to its list element type.
  ///
  /// Looks up the schema in local/imported namespaces and returns the
  /// appropriate list type plus metadata needed by the type builder.
  _SchemaTypeMapping _resolveSchemaVariableType(
    _SchemaReference schemaReference,
    Element2 element,
    TypeProvider typeProvider,
  ) {
    final resolved = _resolveSchemaReference(schemaReference, element);
    if (resolved == null) {
      throw InvalidGenerationSourceError(
        'Could not resolve schema reference "${schemaReference.name}" '
        'used in Ack.list(...)',
        element: element,
        todo:
            'Ensure "${schemaReference.name}" exists, is imported, and is declared as an Ack schema.',
      );
    }

    final modelInfo = resolved.modelInfo;
    final isObjectRepresentation = modelInfo.representationType == _kMapType;
    if (isObjectRepresentation && !resolved.hasAckTypeAnnotation) {
      throw InvalidGenerationSourceError(
        'Ack.list(${schemaReference.name}) references object schema '
        '"${schemaReference.name}" without @AckType. This would fall back to '
        'Map<String, Object?>.',
        element: element,
        todo:
            'Annotate "${schemaReference.name}" with @AckType() so list getters can emit typed wrappers.',
      );
    }

    final elementDartType = _representationTypeToDartType(
      modelInfo.representationType,
      typeProvider,
    );

    final hasTypedReference = resolved.hasAckTypeAnnotation;
    final typeBaseName = hasTypedReference
        ? _qualifyTypeBaseName(modelInfo.className, resolved.importPrefix)
        : null;

    return (
      dartType: typeProvider.listType(elementDartType),
      listElementSchemaRef: resolved.schemaName,
      listElementDisplayTypeOverride: typeBaseName,
      listElementCastTypeOverride: modelInfo.representationType,
      listElementIsCustomType: hasTypedReference,
    );
  }

  /// Resolves a schema reference to its representation type string.
  ///
  /// This is used for top-level list schemas so we can cast to the correct
  /// element type (e.g., `String` for `Ack.string()` schema variables).
  ///
  /// Throws when the schema variable cannot be resolved or if a circular
  /// reference is detected.
  String _resolveSchemaVariableElementTypeString(
    _SchemaReference schemaReference,
    Element2 element,
  ) {
    final library = element.library2;
    // Use library-scoped cache key to prevent collisions across libraries
    final prefix = schemaReference.prefix ?? '';
    final cacheKey =
        '${library?.uri ?? 'unknown'}::$prefix::${schemaReference.name}';

    final cached = _schemaVariableTypeCache[cacheKey];
    if (cached != null) {
      return cached;
    }

    if (_schemaVariableTypeStack.contains(cacheKey)) {
      throw InvalidGenerationSourceError(
        'Circular schema variable reference detected for '
        '"${schemaReference.name}" in Ack.list(...).',
        element: element,
        todo:
            'Break the circular Ack.list(...) schema references so element types '
            'can be resolved statically.',
      );
    }

    _schemaVariableTypeStack.add(cacheKey);

    String? resolvedType;
    try {
      if (library == null) {
        throw InvalidGenerationSourceError(
          'Could not resolve library while analyzing schema reference '
          '"${schemaReference.name}"',
          element: element,
        );
      }

      final resolved = _resolveSchemaReference(schemaReference, element);
      if (resolved == null) {
        throw InvalidGenerationSourceError(
          'Could not resolve schema reference "${schemaReference.name}" '
          'used in Ack.list(...)',
          element: element,
          todo:
              'Ensure "${schemaReference.name}" exists, is imported, and is declared as an Ack schema.',
        );
      }

      if (resolved.modelInfo.representationType == _kMapType &&
          !resolved.hasAckTypeAnnotation) {
        throw InvalidGenerationSourceError(
          'Ack.list(${schemaReference.name}) references object schema '
          '"${schemaReference.name}" without @AckType. This would fall back to '
          'Map<String, Object?>.',
          element: element,
          todo:
              'Annotate "${schemaReference.name}" with @AckType() so list getters can emit typed wrappers.',
        );
      }

      resolvedType = resolved.modelInfo.representationType;
      return resolvedType;
    } finally {
      _schemaVariableTypeStack.remove(cacheKey);
      if (resolvedType != null) {
        _schemaVariableTypeCache[cacheKey] = resolvedType;
      }
    }
  }

  _ResolvedSchemaReference? _resolveSchemaReference(
    _SchemaReference reference,
    Element2 contextElement,
  ) {
    final library = contextElement.library2;
    if (library == null) {
      return null;
    }

    final cacheKey = _schemaReferenceCacheKey(reference, library);
    final cached = _schemaReferenceCache[cacheKey];
    if (cached != null || _schemaReferenceCache.containsKey(cacheKey)) {
      return cached;
    }

    if (_schemaReferenceResolutionStack.contains(cacheKey)) {
      final referenceLabel = _formatSchemaReference(reference);
      throw InvalidGenerationSourceError(
        'Circular schema reference detected for "$referenceLabel".',
        element: contextElement,
        todo:
            'Break the circular alias/reference chain between @AckType schemas.',
      );
    }

    _schemaReferenceResolutionStack.add(cacheKey);

    _ResolvedSchemaReference? resolvedReference;
    var shouldCacheResult = false;

    try {
      final resolvedElement = _resolveSchemaElement(reference, library);
      if (resolvedElement == null) {
        shouldCacheResult = true;
        resolvedReference = null;
        return null;
      }

      TopLevelVariableElement2? schemaVariable;
      GetterElement? schemaGetter;

      if (resolvedElement is TopLevelVariableElement2) {
        schemaVariable = resolvedElement;
      } else if (resolvedElement is GetterElement) {
        if (resolvedElement.isSynthetic) {
          final variable = resolvedElement.variable3;
          if (variable is TopLevelVariableElement2) {
            schemaVariable = variable;
          }
        } else {
          schemaGetter = resolvedElement;
        }
      } else if (resolvedElement is PropertyAccessorElement2) {
        if (resolvedElement is GetterElement && resolvedElement.isSynthetic) {
          final variable = resolvedElement.variable3;
          if (variable is TopLevelVariableElement2) {
            schemaVariable = variable;
          }
        }
      }

      if (schemaVariable == null && schemaGetter == null) {
        shouldCacheResult = true;
        resolvedReference = null;
        return null;
      }

      final schemaName = schemaVariable?.name3 ?? schemaGetter?.name3;
      if (schemaName == null) {
        shouldCacheResult = true;
        resolvedReference = null;
        return null;
      }

      final hasAckTypeAnnotation = schemaVariable != null
          ? _hasAckTypeAnnotation(schemaVariable)
          : _hasAckTypeAnnotation(schemaGetter!);

      final customTypeName = schemaVariable != null
          ? _extractAckTypeName(schemaVariable)
          : _extractAckTypeName(schemaGetter!);

      ModelInfo? modelInfo;
      if (schemaVariable != null) {
        modelInfo = analyzeSchemaVariable(
          schemaVariable,
          customTypeName: customTypeName,
        );
      } else if (schemaGetter != null) {
        modelInfo = analyzeSchemaGetter(
          schemaGetter,
          customTypeName: customTypeName,
        );
      }
      if (modelInfo == null) {
        shouldCacheResult = true;
        resolvedReference = null;
        return null;
      }

      resolvedReference = _ResolvedSchemaReference(
        schemaName: schemaName,
        modelInfo: modelInfo,
        importPrefix: reference.prefix,
        hasAckTypeAnnotation: hasAckTypeAnnotation,
      );
      shouldCacheResult = true;
      return resolvedReference;
    } on InvalidGenerationSourceError {
      rethrow;
    } catch (_) {
      shouldCacheResult = true;
      resolvedReference = null;
      return null;
    } finally {
      _schemaReferenceResolutionStack.remove(cacheKey);
      if (shouldCacheResult) {
        _schemaReferenceCache[cacheKey] = resolvedReference;
      }
    }
  }

  Element2? _resolveSchemaElement(
    _SchemaReference reference,
    LibraryElement2 library,
  ) {
    if (reference.prefix != null) {
      // Prefer an exact prefix match when the source used `prefix.symbol`.
      for (final import in library.firstFragment.libraryImports2) {
        final prefixName = _elementName(import.prefix2?.element);
        if (prefixName != reference.prefix) continue;

        final importedElement = import.namespace.get2(reference.name);
        if (importedElement != null) {
          return importedElement;
        }

        final exportedElement = import.importedLibrary2?.exportNamespace.get2(
          reference.name,
        );
        if (exportedElement != null) {
          return exportedElement;
        }
      }

      // Strict behavior: when a prefix is specified, never resolve from a
      // different namespace.
      return null;
    }

    final scopeResult = library.firstFragment.scope.lookup(reference.name);
    final scopedElement = scopeResult.getter2;
    if (scopedElement != null) {
      return scopedElement;
    }

    for (final import in library.firstFragment.libraryImports2) {
      final importedElement = import.namespace.get2(reference.name);
      if (importedElement != null) {
        return importedElement;
      }
    }

    return null;
  }

  String? _elementName(Element2? element) {
    final modernName = element?.name3;
    if (modernName != null && modernName.isNotEmpty) {
      return modernName;
    }
    return null;
  }

  bool _hasAckTypeAnnotation(Element2 element) {
    return TypeChecker.typeNamed(AckType).hasAnnotationOfExact(element);
  }

  String? _extractAckTypeName(Element2 element) {
    final annotation = TypeChecker.typeNamed(
      AckType,
    ).firstAnnotationOfExact(element);
    if (annotation == null) return null;

    final nameField = ConstantReader(annotation).peek('name');
    return (nameField != null && !nameField.isNull)
        ? nameField.stringValue
        : null;
  }

  String _qualifyTypeBaseName(String baseTypeName, String? prefix) {
    if (prefix == null || prefix.isEmpty) {
      return baseTypeName;
    }
    return '$prefix.$baseTypeName';
  }

  String _schemaReferenceCacheKey(
    _SchemaReference reference,
    LibraryElement2 library,
  ) {
    final prefix = reference.prefix ?? '';
    return '${library.uri}::$prefix::${reference.name}';
  }

  String _formatSchemaReference(_SchemaReference reference) {
    final prefix = reference.prefix;
    if (prefix == null || prefix.isEmpty) {
      return reference.name;
    }
    return '$prefix.${reference.name}';
  }

  DartType _representationTypeToDartType(
    String representationType,
    TypeProvider typeProvider,
  ) {
    return switch (representationType) {
      'String' => typeProvider.stringType,
      'int' => typeProvider.intType,
      'double' => typeProvider.doubleType,
      'bool' => typeProvider.boolType,
      'num' => typeProvider.numType,
      _ when representationType.startsWith('Map<') => typeProvider.mapType(
        typeProvider.stringType,
        typeProvider.dynamicType,
      ),
      _ when representationType.startsWith('List<') => typeProvider.listType(
        typeProvider.dynamicType,
      ),
      _ => typeProvider.dynamicType,
    };
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

  _SchemaReference? _extractSchemaReference(Expression? target) {
    if (target == null) return null;

    if (target is SimpleIdentifier) {
      if (target.name == 'Ack') return null;
      return (name: target.name, prefix: null);
    }

    if (target is PrefixedIdentifier) {
      final name = target.identifier.name;
      if (name == 'Ack') return null;
      return (name: name, prefix: target.prefix.name);
    }

    if (target is PropertyAccess) {
      final name = target.propertyName.name;
      if (name == 'Ack') return null;

      final targetExpression = target.target;
      String? prefix;
      if (targetExpression is SimpleIdentifier) {
        prefix = targetExpression.name;
      } else if (targetExpression is PrefixedIdentifier) {
        prefix = targetExpression.identifier.name;
      }

      return (name: name, prefix: prefix);
    }

    return null;
  }

  (List<MethodInvocation>, bool) _collectMethodChain(
    MethodInvocation invocation,
  ) {
    final chain = <MethodInvocation>[];
    MethodInvocation? current = invocation;

    // Safety limit to prevent infinite loops on malformed AST
    const maxDepth = 20;
    var depth = 0;

    while (current != null && depth < maxDepth) {
      chain.add(current);
      final target = current.target;
      if (target is MethodInvocation) {
        current = target;
        depth++;
      } else {
        break;
      }
    }

    return (chain, depth >= maxDepth);
  }

  /// Walks a method chain to find the base Ack.xxx() invocation.
  ///
  /// For `Ack.string().describe('...').optional()`, returns `Ack.string()`.
  /// For `Ack.integer().min(0).max(100)`, returns `Ack.integer()`.
  ///
  /// Returns `null` if no Ack.xxx() base is found.
  MethodInvocation? _findBaseAckInvocation(MethodInvocation invocation) {
    final (chain, truncated) = _collectMethodChain(invocation);

    for (final current in chain) {
      final target = current.target;
      if (_isAckTarget(target)) {
        return current;
      }
    }

    if (truncated) {
      _log.warning(
        'Method chain exceeded max depth of 20. '
        'List element type will fall back to dynamic.',
      );
    }
    return null;
  }

  /// Walks a method chain to find a schema variable base reference.
  ///
  /// For `itemSchema.optional().nullable()`, returns `(name: itemSchema)`.
  /// For `deck.slideSchema.describe('...')`, returns
  /// `(name: slideSchema, prefix: deck)`.
  ///
  /// Returns `null` if the chain doesn't end with a schema variable identifier
  /// (e.g., if it's an Ack.xxx() chain or unknown structure).
  ///
  _SchemaReference? _findSchemaVariableBase(MethodInvocation invocation) {
    final (chain, truncated) = _collectMethodChain(invocation);

    for (final current in chain) {
      final target = current.target;

      final schemaReference = _extractSchemaReference(target);
      if (schemaReference != null) {
        return schemaReference;
      }

      // If target resolves to Ack, this is an Ack.xxx() chain
      if (_isAckTarget(target)) {
        return null;
      }
    }

    if (truncated) {
      _log.warning(
        'Schema variable method chain exceeded max depth of 20. '
        'List element type will fall back to dynamic.',
      );
    }
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
  /// - Nested lists: `Ack.list(Ack.list(Ack.int()))` → `List<int>`
  /// - Schema references: `Ack.list(addressSchema)` → resolves to the referenced schema's representation type
  String _extractListElementTypeString(
    MethodInvocation listInvocation,
    Element2 element,
  ) {
    final args = listInvocation.argumentList.arguments;

    if (args.isEmpty) {
      throw InvalidGenerationSourceError(
        'Ack.list(...) requires an element schema argument for strict typed generation.',
        element: element,
        todo:
            'Provide a concrete element schema, e.g. Ack.list(Ack.string()) or Ack.list(namedSchema).',
      );
    }

    final firstArg = args.first;
    final ref = _resolveListElementRef(firstArg);

    if (ref.ackBase != null) {
      final methodName = ref.ackBase!.methodName.name;

      // Handle nested lists recursively
      if (methodName == 'list') {
        final nestedType = _extractListElementTypeString(ref.ackBase!, element);
        return 'List<$nestedType>';
      }

      if (methodName == 'enumValues') {
        return _extractEnumTypeNameFromInvocation(ref.ackBase!) ?? 'dynamic';
      }

      if (methodName == 'object') {
        throw InvalidGenerationSourceError(
          'Ack.list(Ack.object(...)) uses an anonymous inline object schema. '
          'Strict typed generation requires a named schema reference.',
          element: element,
          todo:
              'Extract the inline object to a top-level @AckType() variable and use Ack.list(namedSchema).',
        );
      }

      // Map primitive schema types
      return _mapSchemaMethodToType(methodName);
    }

    if (ref.schemaRef != null) {
      return _resolveSchemaVariableElementTypeString(ref.schemaRef!, element);
    }

    final rawExpression = firstArg.toSource();
    throw InvalidGenerationSourceError(
      'Could not statically resolve Ack.list($rawExpression) element type.',
      element: element,
      todo:
          'Use Ack.list(Ack.<primitive>()), Ack.list(enumSchema), or Ack.list(namedSchema) so the generator can infer a concrete element type.',
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

    final enumTypeName = _extractEnumTypeNameFromInvocation(invocation);

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
    final (chain, _) = _collectMethodChain(invocation);
    for (final current in chain) {
      if (current.methodName.name == modifierName) {
        return true;
      }
    }
    return false;
  }

  /// Maps Ack schema method names to Dart type strings
  ///
  /// Used for generating string representations of types in list element contexts.
  /// For nested lists, this function is called recursively via [_parseListSchema].
  String _mapSchemaMethodToType(String methodName) {
    return switch (methodName) {
      'string' || 'enumString' || 'literal' => 'String',
      'integer' => 'int',
      'double' => 'double',
      'boolean' => 'bool',
      'object' => _kMapType,
      'list' => 'List<dynamic>',
      _ => 'dynamic',
    };
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

    // Reject only reserved words. Built-in and pseudo keywords are allowed
    // as identifiers in many contexts (for example `of`, `augment`).
    final keyword = Keyword.keywords[fieldName];
    if (keyword?.isReservedWord == true) {
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
