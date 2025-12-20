import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:code_builder/code_builder.dart';

import '../models/field_info.dart';
import '../models/model_info.dart';

/// Builds Dart 3 extension types for models annotated with `@AckType`
///
/// Extension types provide zero-cost type-safe wrappers over validated
/// `Map<String, Object?>` data returned by schema validation.
class TypeBuilder {
  /// Builds an extension type for the given model
  ///
  /// Returns null if the model should not generate an extension type:
  /// - Discriminated base classes (use sealed classes instead)
  /// - Primitive schemas (String, int, double, bool) - users can use safeParse() directly
  ExtensionType? buildExtensionType(
    ModelInfo model,
    List<ModelInfo> allModels,
  ) {
    // Discriminated base classes get sealed classes, not extension types
    if (model.isDiscriminatedBase) {
      return null;
    }

    // Skip extension type generation for primitives (String, int, double, bool, List, etc.)
    // Only generate extension types for object schemas (Map<String, Object?>)
    if (!model.shouldGenerateExtensionType) {
      return null;
    }

    final typeName = _getExtensionTypeName(model);
    final schemaVarName = _toCamelCase(model.schemaClassName);

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
          ..._buildGetters(model, allModels),
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
          // Override discriminator to return literal value
          Method(
            (m) => m
              ..type = MethodType.getter
              ..name = baseModel.discriminatorKey!
              ..returns = refer('String')
              ..annotations.add(refer('override'))
              ..lambda = true
              ..body = Code("'${model.discriminatorValue}'"),
          ),
          // Add regular field getters
          ..._buildGetters(model, allModels),
        ]),
    );
  }

  /// Sorts models in topological order (dependencies before dependents)
  ///
  /// If circular dependencies are detected, falls back to the original
  /// input order instead of throwing. Extension types based on Map<String, Object?>
  /// work correctly with cycles since they all wrap the same underlying type.
  List<ModelInfo> topologicalSort(List<ModelInfo> models) {
    final sorted = <ModelInfo>[];
    final visiting = <String>{};
    final visited = <String>{};
    var hasCycle = false;

    // Build dependency map
    final dependencies = <String, Set<String>>{};
    for (final model in models) {
      dependencies[model.className] = _extractDependencies(model, models);
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
      final model = models.firstWhere((m) => m.className == className);
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
      return models;
    }

    return sorted;
  }

  // --- Private Helper Methods ---

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
          ..returns = refer('SchemaResult<$typeName>')
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

    final cases = <String>[];
    for (final entry in subtypes.entries) {
      final discriminatorValue = entry.key;
      final subtypeElement = entry.value;
      final subtypeTypeName = '${subtypeElement.name3}Type';

      cases.add("      '$discriminatorValue' => $subtypeTypeName(validated)");
    }

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
return switch (validated['$discriminatorKey']) {
${cases.join(',\n')},
  _ => throw StateError('Unknown $discriminatorKey: \${validated["$discriminatorKey"]}'),
};'''),
    );
  }

  Method _buildDiscriminatedSafeParse(ModelInfo model, String schemaVarName) {
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
        ..returns = refer('SchemaResult<Map<String, dynamic>>')
        ..body = Code('return $schemaVarName.safeParse(data);'),
    );
  }

  List<Method> _buildGetters(ModelInfo model, List<ModelInfo> allModels) {
    return model.fields.map((field) {
      return Method(
        (m) => m
          ..type = MethodType.getter
          ..name = field.name
          ..returns = _buildReturnType(field, allModels)
          ..lambda = true
          ..body = Code(_buildGetterBody(field, allModels)),
      );
    }).toList();
  }

  Reference _buildReturnType(FieldInfo field, List<ModelInfo> allModels) {
    final baseType = _resolveFieldType(field, allModels);
    // Optional fields need nullable return types because the key might be missing.
    final shouldBeNullable = field.isNullable || !field.isRequired;
    final typeString = shouldBeNullable ? '$baseType?' : baseType;
    return refer(typeString);
  }

  String _buildGetterBody(FieldInfo field, List<ModelInfo> allModels) {
    final key = field.jsonKey;
    // Both nullable and optional fields need null-safe access.
    final needsNullHandling = field.isNullable || !field.isRequired;

    if (needsNullHandling) {
      return _buildNullableGetter(field, allModels, key);
    } else {
      return _buildNonNullableGetter(field, allModels, key);
    }
  }

  String _buildNonNullableGetter(
    FieldInfo field,
    List<ModelInfo> allModels,
    String key,
  ) {
    // Primitives
    if (field.isPrimitive) {
      return "_data['$key'] as ${_resolveFieldType(field, allModels)}";
    }

    // Enums (validated by schema, returns the enum value)
    if (field.isEnum) {
      return "_data['$key'] as ${field.type.getDisplayString(withNullability: false)}";
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
      return _buildListGetter(field, allModels, key);
    }

    // Nested schema variable reference (e.g., 'address': addressSchema).
    if (field.nestedSchemaRef != null) {
      final referencedModel =
          _findSchemaModel(field.nestedSchemaRef!, allModels);
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
      return _buildSetGetter(field, allModels, key);
    }

    // Nested schema
    if (field.isNestedSchema && _hasAckType(field, allModels)) {
      final typeConstructor = _getTypeConstructor(field);
      return "$typeConstructor(_data['$key'] as Map<String, Object?>)";
    }

    // Generic or unknown - return as Object?
    return "_data['$key']";
  }

  String _buildNullableGetter(
    FieldInfo field,
    List<ModelInfo> allModels,
    String key,
  ) {
    // For primitives and enums, nullable cast works
    if (field.isPrimitive || field.isEnum) {
      return "_data['$key'] as ${_resolveFieldType(field, allModels)}?";
    }

    // Special types need conversion with null check
    if (_isSpecialType(field.type)) {
      return _buildSpecialTypeGetter(field, key, nullable: true);
    }

    // For complex types, check null first
    final nonNullPart = _buildNonNullableGetter(field, allModels, key);
    return "_data['$key'] != null ? $nonNullPart : null";
  }

  /// Builds getter code for special types (DateTime, Uri, Duration)
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
    final element = field.type.element3;
    final typeName = element?.name3;

    if (nullable) {
      // Nullable version: check if value exists before converting
      switch (typeName) {
        case 'DateTime':
          return "_data['$key'] != null ? DateTime.parse(_data['$key'] as String) : null";
        case 'Uri':
          return "_data['$key'] != null ? Uri.parse(_data['$key'] as String) : null";
        case 'Duration':
          return "_data['$key'] != null ? Duration(milliseconds: _data['$key'] as int) : null";
        default:
          return "_data['$key']";
      }
    } else {
      // Non-nullable version: direct conversion
      switch (typeName) {
        case 'DateTime':
          return "DateTime.parse(_data['$key'] as String)";
        case 'Uri':
          return "Uri.parse(_data['$key'] as String)";
        case 'Duration':
          return "Duration(milliseconds: _data['$key'] as int)";
        default:
          return "_data['$key']";
      }
    }
  }

  String _buildListGetter(
    FieldInfo field,
    List<ModelInfo> allModels,
    String key,
  ) => _buildCollectionGetter(field, allModels, key, isSet: false);

  String _buildSetGetter(
    FieldInfo field,
    List<ModelInfo> allModels,
    String key,
  ) => _buildCollectionGetter(field, allModels, key, isSet: true);

  /// Builds getter code for List or Set collections
  String _buildCollectionGetter(
    FieldInfo field,
    List<ModelInfo> allModels,
    String key, {
    required bool isSet,
  }) {
    final elementType = isSet
        ? _getSetElementType(field, allModels)
        : _getListElementType(field, allModels);

    final suffix = isSet ? '.toSet()' : '';

    // Check if element type is a custom type with @AckType
    if (_isCustomElementType(field, allModels)) {
      // Return eager List for object lists (per requirements: List<T>, not Iterable<T>)
      final listSuffix = isSet ? '' : '.toList()';
      final castType = _getCustomElementCastType(field, elementType, allModels);
      return "(_data['$key'] as List).map((e) => ${elementType}Type(e as $castType))$listSuffix$suffix";
    }

    // Primitive lists/sets - direct cast
    return "(_data['$key'] as List).cast<$elementType>()$suffix";
  }

  String _resolveFieldType(FieldInfo field, List<ModelInfo> allModels) {
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
      final elementType = _getListElementType(field, allModels);
      // Use List for all list types (eager evaluation per requirements)
      if (_isCustomElementType(field, allModels)) {
        return 'List<${elementType}Type>';
      }
      return 'List<$elementType>';
    }

    // Nested schema variable reference (e.g., 'address': addressSchema).
    if (field.nestedSchemaRef != null) {
      final referencedModel =
          _findSchemaModel(field.nestedSchemaRef!, allModels);
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
      final elementType = _getSetElementType(field, allModels);
      return 'Set<$elementType>';
    }

    // Generic types
    if (field.isGeneric) {
      return 'Object?';
    }

    // Nested schema
    if (field.isNestedSchema && _hasAckType(field, allModels)) {
      final baseType = field.type.getDisplayString(withNullability: false);
      return '${baseType}Type';
    }

    // Fallback to Object?
    return 'Object?';
  }

  String _getListElementType(FieldInfo field, List<ModelInfo> allModels) {
    // Check for schema variable reference first (e.g., Ack.list(addressSchema))
    if (field.listElementSchemaRef != null) {
      final referencedModel =
          _findSchemaModel(field.listElementSchemaRef!, allModels);
      if (referencedModel != null) {
        return referencedModel.className;
      }
      return kMapType;
    }

    if (field.type is! ParameterizedType) return 'dynamic';

    final listType = field.type as ParameterizedType;
    if (listType.typeArguments.isEmpty) return 'dynamic';

    return _resolveTypeReference(listType.typeArguments[0], allModels);
  }

  String _getSetElementType(FieldInfo field, List<ModelInfo> allModels) {
    if (field.type is! ParameterizedType) return 'dynamic';

    final setType = field.type as ParameterizedType;
    if (setType.typeArguments.isEmpty) return 'dynamic';

    return _resolveTypeReference(setType.typeArguments[0], allModels);
  }

  String _resolveTypeReference(DartType type, List<ModelInfo> allModels) {
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
      if (_hasAckTypeForElement(element, allModels)) {
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

  bool _hasAckType(FieldInfo field, List<ModelInfo> allModels) {
    final element = field.type.element3;
    if (element is! InterfaceElement2) return false;

    return _hasAckTypeForElement(element, allModels);
  }

  bool _hasAckTypeForElement(
    InterfaceElement2 element,
    List<ModelInfo> allModels,
  ) {
    return allModels.any((m) => m.className == element.name3);
  }

  bool _isCustomElementType(FieldInfo field, List<ModelInfo> allModels) {
    // Check for schema variable reference first (e.g., Ack.list(addressSchema))
    if (field.listElementSchemaRef != null) {
      return _findSchemaModel(field.listElementSchemaRef!, allModels) != null;
    }

    if (field.type is! ParameterizedType) return false;

    final paramType = field.type as ParameterizedType;
    if (paramType.typeArguments.isEmpty) return false;

    final elementType = paramType.typeArguments[0];
    final element = elementType.element3;

    if (element is! InterfaceElement2) return false;

    return _hasAckTypeForElement(element, allModels);
  }

  String _getTypeConstructor(FieldInfo field) {
    final baseType = field.type.getDisplayString(withNullability: false);
    return '${baseType}Type';
  }

  ModelInfo? _findSchemaModel(String schemaVarName, List<ModelInfo> allModels) {
    return allModels
        .where((m) => m.schemaClassName == schemaVarName)
        .firstOrNull;
  }

  String _getCustomElementCastType(
    FieldInfo field,
    String elementType,
    List<ModelInfo> allModels,
  ) {
    if (field.listElementSchemaRef != null) {
      final referencedModel =
          _findSchemaModel(field.listElementSchemaRef!, allModels);
      if (referencedModel != null) {
        return referencedModel.representationType;
      }
    }

    final elementModel =
        allModels.where((m) => m.className == elementType).firstOrNull;
    return elementModel?.representationType ?? kMapType;
  }

  Set<String> _extractDependencies(ModelInfo model, List<ModelInfo> allModels) {
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

        if (allModels.any((m) => m.className == typeName)) {
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
              if (allModels.any((m) => m.className == element.name3)) {
                dependencies.add(element.name3!);
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
      final typeString = field.type.getDisplayString(withNullability: false);

      return Parameter(
        (p) => p
          ..name = field.name
          ..type = refer('$typeString?')
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

/// Error thrown when circular dependencies are detected
class CircularDependencyError extends Error {
  final String message;

  CircularDependencyError(this.message);

  @override
  String toString() => 'CircularDependencyError: $message';
}
