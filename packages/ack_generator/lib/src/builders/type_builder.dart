import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart' show log;
import 'package:code_builder/code_builder.dart';

import '../models/field_info.dart';
import '../models/model_info.dart';

const _ackPackageUrl = 'package:ack/ack.dart';

class _ModelLookups {
  final Map<String, ModelInfo> byClassName;
  final Map<String, ModelInfo> bySchemaClassName;

  _ModelLookups(List<ModelInfo> models)
      : byClassName = _buildByClassName(models),
        bySchemaClassName = _buildBySchemaClassName(models);

  ModelInfo? classByName(String name) => byClassName[name];
  ModelInfo? schemaByName(String name) => bySchemaClassName[name];

  static Map<String, ModelInfo> _buildByClassName(List<ModelInfo> models) {
    final map = <String, ModelInfo>{};
    for (final model in models) {
      map.putIfAbsent(model.className, () => model);
    }
    return map;
  }

  static Map<String, ModelInfo> _buildBySchemaClassName(
    List<ModelInfo> models,
  ) {
    final map = <String, ModelInfo>{};
    for (final model in models) {
      map.putIfAbsent(model.schemaClassName, () => model);
    }
    return map;
  }
}

/// Builds Dart 3 extension types for models annotated with `@AckType`
///
/// Extension types provide zero-cost type-safe wrappers over validated
/// `Map<String, Object?>` data returned by schema validation.
class TypeBuilder {
  /// Builds an extension type for the given model
  ///
  /// Returns null if the model should not generate an extension type:
  /// - Discriminated base classes (use sealed classes instead)
  /// - Nullable schema variables (representation is non-nullable)
  ExtensionType? buildExtensionType(
    ModelInfo model,
    List<ModelInfo> allModels,
  ) {
    // Discriminated base classes get sealed classes, not extension types
    if (model.isDiscriminatedBase) {
      return null;
    }

    // Nullable schema variables can't be safely wrapped (representation is non-nullable).
    if (model.isFromSchemaVariable && model.isNullableSchema) {
      return null;
    }

    final typeName = _getExtensionTypeName(model);
    final schemaVarName = _toCamelCase(model.schemaClassName);
    final lookups = _ModelLookups(allModels);

    final isObjectSchema = model.representationType == kMapType;
    final valueVarName = isObjectSchema ? '_data' : '_value';

    return ExtensionType(
      (b) => b
        ..name = typeName
        ..docs.addAll(_buildDocs(model))
        ..representationDeclaration = RepresentationDeclaration(
          (r) => r
            ..declaredRepresentationType = refer(model.representationType)
            ..name = valueVarName,
        )
        ..implements.add(refer(model.representationType))
        ..methods.addAll([
          ..._buildStaticFactories(model, schemaVarName),
          _buildToJson(model),
          ..._buildGetters(model, lookups),
          // Only add args and copyWith for object schemas
          if (isObjectSchema) ...[
            if (model.additionalProperties) _buildArgsGetter(model),
            if (model.fields.isNotEmpty) _buildCopyWith(model),
          ],
        ]),
    );
  }

  /// Builds a sealed class for discriminated base types
  Class? buildSealedClass(ModelInfo model, List<ModelInfo> allModels) {
    if (!model.isDiscriminatedBase) {
      return null;
    }

    final typeName = _getExtensionTypeName(model);
    final schemaVarName = _toCamelCase(model.schemaClassName);
    final subtypes = model.subtypes;

    if (subtypes == null || subtypes.isEmpty) {
      return null;
    }

    return Class(
      (b) => b
        ..name = typeName
        ..sealed = true
        ..docs.addAll(_buildDocs(model))
        ..fields.add(
          Field(
            (f) => f
              ..name = '_data'
              ..type = refer('Map<String, Object?>')
              ..modifier = FieldModifier.final$,
          ),
        )
        ..constructors.add(
          Constructor(
            (c) => c
              ..constant = true
              ..requiredParameters.add(
                Parameter(
                  (p) => p
                    ..name = '_data'
                    ..toThis = true,
                ),
              ),
          ),
        )
        ..methods.addAll([
          // Add discriminator getter
          Method(
            (m) => m
              ..type = MethodType.getter
              ..name = model.discriminatorKey!
              ..returns = refer('String')
              ..lambda = true
              ..body = Code("_data['${model.discriminatorKey}'] as String"),
          ),
          _buildToJson(model),
          // Add factory constructor for parsing
          _buildDiscriminatedFactory(model, schemaVarName, subtypes),
          // Add safeParse static method
          _buildDiscriminatedSafeParse(model, schemaVarName),
        ]),
    );
  }

  /// Builds extension type for discriminated subtypes
  ExtensionType? buildDiscriminatedSubtype(
    ModelInfo model,
    ModelInfo baseModel,
    List<ModelInfo> allModels,
  ) {
    if (!model.isDiscriminatedSubtype) {
      return null;
    }

    final typeName = _getExtensionTypeName(model);
    final baseTypeName = _getExtensionTypeName(baseModel);
    final lookups = _ModelLookups(allModels);

    return ExtensionType(
      (b) => b
        ..name = typeName
        ..docs.addAll(_buildDocs(model))
        ..representationDeclaration = RepresentationDeclaration(
          (r) => r
            ..declaredRepresentationType = refer('Map<String, Object?>')
            ..name = '_data',
        )
        ..implements.add(refer(baseTypeName)) // Implement sealed base class
        ..methods.addAll([
          // Override discriminator to read from _data for consistency with toJson()
          // Factory constructors already validate the discriminator value matches
          Method(
            (m) => m
              ..type = MethodType.getter
              ..name = baseModel.discriminatorKey!
              ..returns = refer('String')
              ..annotations.add(refer('override'))
              ..lambda = true
              ..body = Code("_data['${baseModel.discriminatorKey}'] as String"),
          ),
          _buildToJson(model),
          // Add regular field getters
          ..._buildGetters(model, lookups),
        ]),
    );
  }

  /// Sorts models in topological order (dependencies before dependents).
  ///
  /// If circular dependencies are detected, logs a warning and falls back to the
  /// original input order. Extension types based on `Map<String, Object?>` work
  /// correctly with cycles since they all wrap the same underlying type.
  List<ModelInfo> topologicalSort(List<ModelInfo> models) {
    final lookups = _ModelLookups(models);
    final sorted = <ModelInfo>[];
    final visiting = <String>{};
    final visited = <String>{};
    var hasCycle = false;

    // Build dependency map
    final dependencies = <String, Set<String>>{};
    for (final model in models) {
      dependencies[model.className] = _extractDependencies(model, lookups);
    }

    void visit(String className) {
      if (visited.contains(className)) return;

      if (visiting.contains(className)) {
        // Cycle detected - mark flag but continue
        // Extension types with Map representation work fine with cycles
        hasCycle = true;
        return;
      }

      visiting.add(className);

      // Visit dependencies first
      final deps = dependencies[className] ?? {};
      for (final dep in deps) {
        if (dependencies.containsKey(dep)) {
          visit(dep);
        }
      }

      visiting.remove(className);
      visited.add(className);

      // Add to sorted list
      final model = lookups.classByName(className);
      if (model == null) {
        throw StateError('Missing model for class name: $className');
      }
      sorted.add(model);
    }

    // Visit all models
    for (final model in models) {
      visit(model.className);
    }

    // If cycle detected, fall back to original order
    // This is safe because extension types wrap Map<String, Object?> which doesn't
    // require declaration order
    if (hasCycle) {
      log.warning(
        'Circular dependency detected in extension types. '
        'Using original declaration order (safe for Map-based types).',
      );
      return models;
    }

    return sorted;
  }

  // --- Private Helper Methods ---

  Reference _schemaResultRef(Reference innerType) {
    return TypeReference(
      (b) => b
        ..symbol = 'SchemaResult'
        ..url = _ackPackageUrl
        ..types.add(innerType),
    );
  }

  Reference _referenceFromDartType(
    DartType type, {
    bool forceNullable = false,
    bool stripNullability = false,
  }) {
    final isNullable = forceNullable || (!stripNullability && _isNullable(type));

    if (type is ParameterizedType) {
      final element = type.element3;
      final symbol =
          element?.name3 ?? type.getDisplayString(withNullability: false);
      final url = _urlForElement(element);
      final typeArgs = type.typeArguments
          .map(
            (arg) => _referenceFromDartType(
              arg,
              stripNullability: stripNullability,
            ),
          )
          .toList();
      return _typeReference(
        symbol,
        url: url,
        types: typeArgs,
        isNullable: isNullable,
      );
    }

    final element = type.element3;
    final symbol =
        element?.name3 ?? type.getDisplayString(withNullability: false);
    final url = _urlForElement(element);
    return _typeReference(
      symbol,
      url: url,
      isNullable: isNullable,
    );
  }

  bool _isNullable(DartType type) {
    return type.nullabilitySuffix == NullabilitySuffix.question ||
        type.nullabilitySuffix == NullabilitySuffix.star;
  }

  Reference _typeReference(
    String symbol, {
    String? url,
    Iterable<Reference> types = const [],
    bool isNullable = false,
  }) {
    if (types.isEmpty && !isNullable) {
      return refer(symbol, url);
    }
    return TypeReference(
      (b) => b
        ..symbol = symbol
        ..url = url
        ..types.addAll(types)
        ..isNullable = isNullable,
    );
  }

  String? _urlForElement(Element2? element) {
    final uri = element?.library2?.uri;
    if (uri == null) return null;
    if (uri.scheme == 'dart' || uri.scheme == 'package') {
      return uri.toString();
    }
    return null;
  }

  String _getExtensionTypeName(ModelInfo model) {
    return '${model.className}Type';
  }

  String _toCamelCase(String text) {
    if (text.isEmpty) return text;
    return text[0].toLowerCase() + text.substring(1);
  }

  List<String> _buildDocs(ModelInfo model) {
    final docs = <String>['/// Extension type for ${model.className}'];
    if (model.description != null) {
      docs.add('/// ${model.description}');
    }
    return docs;
  }

  Method _buildToJson(ModelInfo model) {
    final isObjectSchema = model.representationType == kMapType;
    final valueVarName = isObjectSchema ? '_data' : '_value';

    return Method(
      (m) => m
        ..name = 'toJson'
        ..returns = refer(model.representationType)
        ..lambda = true
        ..body = Code(valueVarName),
    );
  }

  List<Method> _buildStaticFactories(ModelInfo model, String schemaVarName) {
    final typeName = _getExtensionTypeName(model);
    final castType = model.representationType;

    return [
      // Static parse factory
      Method(
        (m) => m
          ..name = 'parse'
          ..static = true
          ..returns = refer(typeName)
          ..requiredParameters.add(
            Parameter(
              (p) => p
                ..name = 'data'
                ..type = refer('Object?'),
            ),
          )
          ..body = Code('''
final validated = $schemaVarName.parse(data);
return $typeName(validated as $castType);
'''),
      ),
      // Static safeParse method
      Method(
        (m) => m
          ..name = 'safeParse'
          ..static = true
          ..returns = _schemaResultRef(refer(typeName))
          ..requiredParameters.add(
            Parameter(
              (p) => p
                ..name = 'data'
                ..type = refer('Object?'),
            ),
          )
          ..body = Code('''
final result = $schemaVarName.safeParse(data);
return result.match(
  onOk: (validated) => SchemaResult.ok($typeName(validated as $castType)),
  onFail: (error) => SchemaResult.fail(error),
);'''),
      ),
    ];
  }

  Method _buildDiscriminatedFactory(
    ModelInfo model,
    String schemaVarName,
    Map<String, ClassElement2> subtypes,
  ) {
    final typeName = _getExtensionTypeName(model);
    final discriminatorKey = model.discriminatorKey!;
    final switchExpression = _buildDiscriminatorSwitchExpression(
      'validated',
      discriminatorKey,
      subtypes,
    );

    return Method(
      (m) => m
        ..name = 'parse'
        ..static = true
        ..requiredParameters.add(
          Parameter(
            (p) => p
              ..name = 'data'
              ..type = refer('Object?'),
          ),
        )
        ..returns = refer(typeName)
        ..body = Code('''
final validated = $schemaVarName.parse(data) as Map<String, Object?>;
return $switchExpression;'''),
    );
  }

  Method _buildDiscriminatedSafeParse(
    ModelInfo model,
    String schemaVarName,
  ) {
    final typeName = _getExtensionTypeName(model);
    final discriminatorKey = model.discriminatorKey!;
    final subtypes = model.subtypes!;
    final switchExpression = _buildDiscriminatorSwitchExpression(
      'map',
      discriminatorKey,
      subtypes,
    );

    return Method(
      (m) => m
        ..name = 'safeParse'
        ..static = true
        ..requiredParameters.add(
          Parameter(
            (p) => p
              ..name = 'data'
              ..type = refer('Object?'),
          ),
        )
        ..returns = _schemaResultRef(refer(typeName))
        ..body = Code('''
final result = $schemaVarName.safeParse(data);
return result.match(
  onOk: (validated) {
    final map = validated as Map<String, Object?>;
    final parsed = $switchExpression;
    return SchemaResult.ok(parsed);
  },
  onFail: (error) => SchemaResult.fail(error),
);'''),
    );
  }

  String _buildDiscriminatorSwitchExpression(
    String mapVarName,
    String discriminatorKey,
    Map<String, ClassElement2> subtypes,
  ) {
    final cases = <String>[];
    for (final entry in subtypes.entries) {
      final discriminatorValue = entry.key;
      final subtypeElement = entry.value;
      final subtypeTypeName = '${subtypeElement.name3}Type';

      cases.add("  '$discriminatorValue' => $subtypeTypeName($mapVarName)");
    }

    return '''
switch ($mapVarName['$discriminatorKey']) {
${cases.join(',\n')},
  _ => throw StateError('Unknown $discriminatorKey: \${$mapVarName["$discriminatorKey"]}'),
}''';
  }

  List<Method> _buildGetters(ModelInfo model, _ModelLookups lookups) {
    return model.fields.map((field) {
      return _buildGetter(field, lookups);
    }).toList();
  }

  Method _buildGetter(FieldInfo field, _ModelLookups lookups) {
    final baseType = _resolveFieldType(field, lookups);
    // Optional fields need nullable return types because the key might be missing.
    final needsNullHandling = field.isNullable || !field.isRequired;
    final returnType = _applyNullability(baseType, needsNullHandling);
    final body = _buildGetterBody(
      field,
      lookups,
      baseType: baseType,
      needsNullHandling: needsNullHandling,
    );

    return Method(
      (m) => m
        ..type = MethodType.getter
        ..name = field.name
        ..returns = refer(returnType)
        ..lambda = true
        ..body = Code(body),
    );
  }

  String _applyNullability(String baseType, bool shouldBeNullable) {
    if (!shouldBeNullable) return baseType;
    if (baseType.endsWith('?')) return baseType;
    return '$baseType?';
  }

  String _buildGetterBody(
    FieldInfo field,
    _ModelLookups lookups, {
    required String baseType,
    required bool needsNullHandling,
  }) {
    final key = field.jsonKey;

    if (needsNullHandling) {
      return _buildNullableGetter(field, lookups, key, baseType: baseType);
    } else {
      return _buildNonNullableGetter(field, lookups, key, baseType: baseType);
    }
  }

  String _buildNonNullableGetter(
    FieldInfo field,
    _ModelLookups lookups,
    String key, {
    required String baseType,
  }) {
    // Primitives
    if (field.isPrimitive) {
      return "_data['$key'] as $baseType";
    }

    // Enums (validated by schema, returns the enum value)
    if (field.isEnum) {
      return "_data['$key'] as $baseType";
    }

    // Special types need conversion from raw data
    // - DateTime: stored as ISO 8601 string, needs DateTime.parse()
    // - Uri: stored as string, needs Uri.parse()
    // - Duration: stored as int (milliseconds), needs Duration(milliseconds:)
    if (_isSpecialType(field.type)) {
      return _buildSpecialTypeGetter(field, key, nullable: false);
    }

    // Lists
    if (field.isList) {
      return _buildListGetter(field, lookups, key);
    }

    // Nested schema variable reference (e.g., 'address': addressSchema).
    if (field.nestedSchemaRef != null) {
      final referencedModel =
          _findSchemaModel(field.nestedSchemaRef!, lookups);
      if (referencedModel != null) {
        final typeName = '${referencedModel.className}Type';
        final castType = referencedModel.representationType;
        return "$typeName(_data['$key'] as $castType)";
      }
      return "_data['$key'] as Map<String, Object?>";
    }

    // Maps
    if (field.isMap) {
      return "_data['$key'] as Map<String, Object?>";
    }

    // Sets
    if (field.isSet) {
      return _buildSetGetter(field, lookups, key);
    }

    // Nested schema
    if (field.isNestedSchema && _hasAckType(field, lookups)) {
      final typeConstructor = _getTypeConstructor(field);
      return "$typeConstructor(_data['$key'] as Map<String, Object?>)";
    }

    // Generic or unknown - return as Object?
    return "_data['$key']";
  }

  String _buildNullableGetter(
    FieldInfo field,
    _ModelLookups lookups,
    String key, {
    required String baseType,
  }) {
    // For primitives and enums, nullable cast works
    if (field.isPrimitive || field.isEnum) {
      return "_data['$key'] as $baseType?";
    }

    // Special types need conversion with null check
    if (_isSpecialType(field.type)) {
      return _buildSpecialTypeGetter(field, key, nullable: true);
    }

    // For complex types, check null first
    final nonNullPart =
        _buildNonNullableGetter(field, lookups, key, baseType: baseType);
    return "_data['$key'] != null ? $nonNullPart : null";
  }

  /// Builds getter code for special types (DateTime, Uri, Duration).
  ///
  /// These types require conversion from their JSON representation:
  /// - DateTime: ISO 8601 string -> DateTime.parse()
  /// - Uri: string -> Uri.parse()
  /// - Duration: int (milliseconds) -> Duration(milliseconds:)
  String _buildSpecialTypeGetter(
    FieldInfo field,
    String key, {
    required bool nullable,
  }) {
    final typeName = field.type.element3?.name3;

    final conversion = switch (typeName) {
      'DateTime' => "DateTime.parse(_data['$key'] as String)",
      'Uri' => "Uri.parse(_data['$key'] as String)",
      'Duration' => "Duration(milliseconds: _data['$key'] as int)",
      _ => null,
    };

    if (conversion == null) return "_data['$key']";

    return nullable
        ? "_data['$key'] != null ? $conversion : null"
        : conversion;
  }

  String _buildListGetter(
    FieldInfo field,
    _ModelLookups lookups,
    String key,
  ) => _buildCollectionGetter(field, lookups, key, isSet: false);

  String _buildSetGetter(
    FieldInfo field,
    _ModelLookups lookups,
    String key,
  ) => _buildCollectionGetter(field, lookups, key, isSet: true);

  /// Builds getter code for List or Set collections
  String _buildCollectionGetter(
    FieldInfo field,
    _ModelLookups lookups,
    String key, {
    required bool isSet,
  }) {
    final elementType =
        _getCollectionElementType(field, lookups, isSet: isSet);

    final suffix = isSet ? '.toSet()' : '';

    // Check if element type is a custom type with @AckType
    if (_isCustomElementType(field, lookups)) {
      // Return eager List for object lists (per requirements: List<T>, not Iterable<T>)
      final listSuffix = isSet ? '' : '.toList()';
      final castType =
          _getCustomElementCastType(field, elementType, lookups);
      return "(_data['$key'] as List).map((e) => ${elementType}Type(e as $castType))$listSuffix$suffix";
    }

    // Primitive lists/sets - direct cast
    return "(_data['$key'] as List).cast<$elementType>()$suffix";
  }

  String _resolveFieldType(FieldInfo field, _ModelLookups lookups) {
    // Primitives
    if (field.type.isDartCoreString) return 'String';
    if (field.type.isDartCoreInt) return 'int';
    if (field.type.isDartCoreDouble) return 'double';
    if (field.type.isDartCoreBool) return 'bool';
    if (field.type.isDartCoreNum) return 'num';

    // Special types
    if (_isSpecialType(field.type)) {
      return field.type.getDisplayString(withNullability: false);
    }

    // Enums
    if (field.isEnum) {
      return field.type.getDisplayString(withNullability: false);
    }

    // Lists
    if (field.isList) {
      final elementType = _getCollectionElementType(field, lookups, isSet: false);
      // Use List for all list types (eager evaluation per requirements)
      if (_isCustomElementType(field, lookups)) {
        return 'List<${elementType}Type>';
      }
      return 'List<$elementType>';
    }

    // Nested schema variable reference (e.g., 'address': addressSchema).
    if (field.nestedSchemaRef != null) {
      final referencedModel =
          _findSchemaModel(field.nestedSchemaRef!, lookups);
      if (referencedModel != null) {
        return '${referencedModel.className}Type';
      }
      return kMapType;
    }

    // Maps
    if (field.isMap) {
      return 'Map<String, Object?>';
    }

    // Sets
    if (field.isSet) {
      final elementType = _getCollectionElementType(field, lookups, isSet: true);
      if (_isCustomElementType(field, lookups)) {
        return 'Set<${elementType}Type>';
      }
      return 'Set<$elementType>';
    }

    // Generic types
    if (field.isGeneric) {
      return 'Object?';
    }

    // Nested schema
    if (field.isNestedSchema && _hasAckType(field, lookups)) {
      final baseType = field.type.getDisplayString(withNullability: false);
      return '${baseType}Type';
    }

    // Fallback to Object?
    return 'Object?';
  }

  String _getCollectionElementType(
    FieldInfo field,
    _ModelLookups lookups, {
    required bool isSet,
  }) {
    // Check for schema variable reference first (e.g., Ack.list(addressSchema))
    if (!isSet && field.listElementSchemaRef != null) {
      final referencedModel =
          _findSchemaModel(field.listElementSchemaRef!, lookups);
      if (referencedModel != null) {
        return referencedModel.className;
      }
      return kMapType;
    }

    if (field.type is! ParameterizedType) return 'dynamic';

    final paramType = field.type as ParameterizedType;
    if (paramType.typeArguments.isEmpty) return 'dynamic';

    return _resolveTypeReference(paramType.typeArguments[0], lookups);
  }

  String _resolveTypeReference(DartType type, _ModelLookups lookups) {
    final baseType = type.getDisplayString(withNullability: false);

    // Primitives
    if (type.isDartCoreString) return 'String';
    if (type.isDartCoreInt) return 'int';
    if (type.isDartCoreDouble) return 'double';
    if (type.isDartCoreBool) return 'bool';
    if (type.isDartCoreNum) return 'num';

    // Special types
    if (_isSpecialType(type)) return baseType;

    // Check if this is a custom type with @AckType
    final element = type.element3;
    if (element is InterfaceElement2) {
      if (_hasAckTypeForElement(element, lookups)) {
        return baseType;
      }
    }

    return baseType;
  }

  bool _isSpecialType(DartType type) {
    final element = type.element3;
    if (element == null) return false;

    final name = element.name3;
    final library = element.library2?.name3;

    return (name == 'DateTime' && library == 'dart.core') ||
        (name == 'Uri' && library == 'dart.core') ||
        (name == 'Duration' && library == 'dart.core');
  }

  bool _hasAckType(FieldInfo field, _ModelLookups lookups) {
    final element = field.type.element3;
    if (element is! InterfaceElement2) return false;

    return _hasAckTypeForElement(element, lookups);
  }

  bool _hasAckTypeForElement(
    InterfaceElement2 element,
    _ModelLookups lookups,
  ) {
    final name = element.name3;
    if (name == null) return false;
    return lookups.byClassName.containsKey(name);
  }

  bool _isCustomElementType(FieldInfo field, _ModelLookups lookups) {
    // Check for schema variable reference first (e.g., Ack.list(addressSchema))
    if (field.listElementSchemaRef != null) {
      return _findSchemaModel(field.listElementSchemaRef!, lookups) != null;
    }

    if (field.type is! ParameterizedType) return false;

    final paramType = field.type as ParameterizedType;
    if (paramType.typeArguments.isEmpty) return false;

    final elementType = paramType.typeArguments[0];
    final element = elementType.element3;

    if (element is! InterfaceElement2) return false;

    return _hasAckTypeForElement(element, lookups);
  }

  String _getTypeConstructor(FieldInfo field) {
    final baseType = field.type.getDisplayString(withNullability: false);
    return '${baseType}Type';
  }

  ModelInfo? _findSchemaModel(String schemaVarName, _ModelLookups lookups) {
    return lookups.schemaByName(schemaVarName);
  }

  String _getCustomElementCastType(
    FieldInfo field,
    String elementType,
    _ModelLookups lookups,
  ) {
    if (field.listElementSchemaRef != null) {
      final referencedModel =
          _findSchemaModel(field.listElementSchemaRef!, lookups);
      if (referencedModel != null) {
        return referencedModel.representationType;
      }
    }

    final elementModel = lookups.classByName(elementType);
    return elementModel?.representationType ?? kMapType;
  }

  Set<String> _extractDependencies(ModelInfo model, _ModelLookups lookups) {
    final dependencies = <String>{};

    for (final field in model.fields) {
      if (field.isPrimitive ||
          field.isEnum ||
          field.isGeneric ||
          _isSpecialType(field.type)) {
        continue;
      }

      // Nested schema
      if (field.isNestedSchema) {
        final typeName = field.type.getDisplayString(withNullability: false);

        // Skip self-references - circular schemas are valid for Map-based extension types
        // Extension types don't require declaration order since they all wrap Map<String, Object?>
        if (typeName == model.className) {
          continue; // Self-reference doesn't create a dependency
        }

        if (lookups.byClassName.containsKey(typeName)) {
          dependencies.add(typeName);
        }
      }

      // List/Set of objects
      if (field.isList || field.isSet) {
        if (field.type is ParameterizedType) {
          final paramType = field.type as ParameterizedType;
          if (paramType.typeArguments.isNotEmpty) {
            final elementType = paramType.typeArguments[0];
            final element = elementType.element3;

            if (element is InterfaceElement2) {
              final name = element.name3;
              if (name != null && lookups.byClassName.containsKey(name)) {
                dependencies.add(name);
              }
            }
          }
        }
      }
    }

    return dependencies;
  }

  Method _buildCopyWith(ModelInfo model) {
    final typeName = _getExtensionTypeName(model);

    // Build parameters - all parameters are nullable to support copyWith semantics
    final parameters = model.fields.map((field) {
      return Parameter(
        (p) => p
          ..name = field.name
          ..type = _referenceFromDartType(
            field.type,
            forceNullable: true,
            stripNullability: true,
          )
          ..named = true,
      );
    }).toList();

    // Build field assignments
    final assignments = model.fields.map((field) {
      final key = field.jsonKey;
      final name = field.name;

      if (field.isNullable) {
        // For nullable fields, check if explicitly provided or exists in data
        return "      if ($name != null || _data.containsKey('$key')) '$key': $name ?? this.$name";
      } else {
        return "      '$key': $name ?? this.$name";
      }
    }).toList();

    return Method(
      (m) => m
        ..name = 'copyWith'
        ..optionalParameters.addAll(parameters)
        ..returns = refer(typeName)
        ..body = Block(
          (b) => b.statements.add(
            Code('''
return $typeName.parse({
${assignments.join(',\n')},
});'''),
          ),
        ),
    );
  }

  /// Builds the `args` getter that returns additional properties
  ///
  /// Returns a Map containing only properties that are not explicitly
  /// defined in the schema. This is useful when additionalProperties: true.
  Method _buildArgsGetter(ModelInfo model) {
    final knownKeys = model.fields.map((f) => f.jsonKey).toSet();

    // Generate filter condition inline for better performance
    final conditions = knownKeys.map((k) => "e.key != '$k'").toList();
    final filterExpr = conditions.isEmpty
        ? '_data'
        : 'Map.fromEntries(_data.entries.where((e) => ${conditions.join(' && ')}))';

    return Method(
      (m) => m
        ..type = MethodType.getter
        ..name = 'args'
        ..returns = refer('Map<String, Object?>')
        ..lambda = true
        ..body = Code(filterExpr),
    );
  }
}
