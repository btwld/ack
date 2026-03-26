import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart' show log;
import 'package:code_builder/code_builder.dart';

import '../models/field_info.dart';
import '../models/model_info.dart';

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

enum _GeneratedHelper { listCast, setCast }

/// Builds Dart 3 extension types for models annotated with `@AckType`
///
/// Extension types provide zero-cost type-safe wrappers over validated
/// `Map<String, Object?>` data returned by schema validation.
class TypeBuilder {
  String? _ackImportPrefix;

  /// Configures the import prefix used for `package:ack/ack.dart` in the
  /// source library that owns the generated part file.
  ///
  /// When Ack is imported as `import 'package:ack/ack.dart' as ack;`,
  /// generated references must use `ack.SchemaResult` in part files.
  void setAckImportPrefix(String? prefix) {
    _ackImportPrefix = prefix;
  }

  /// Builds top-level private helper functions used by generated extension
  /// types.
  ///
  /// Helpers are emitted only when needed to avoid analyzer warnings in
  /// generated files.
  List<Method> buildTopLevelHelpers(List<ModelInfo> models) {
    if (models.isEmpty) return const [];

    final lookups = _ModelLookups(models);
    final helpers = <_GeneratedHelper>{};

    for (final model in models) {
      for (final field in model.fields) {
        if ((field.isList || field.isSet) &&
            !_isCustomElementType(field, lookups)) {
          helpers.add(
            field.isSet ? _GeneratedHelper.setCast : _GeneratedHelper.listCast,
          );
        }
      }
    }

    final result = <Method>[];
    if (helpers.contains(_GeneratedHelper.listCast)) {
      result.add(_buildListCastHelper());
    }
    if (helpers.contains(_GeneratedHelper.setCast)) {
      result.add(_buildSetCastHelper());
    }

    return result;
  }

  /// Builds an extension type for the given model
  ///
  /// Returns null if the model should not generate an extension type:
  /// - Discriminated base classes (generated separately via
  ///   [buildDiscriminatedExtensionBase] or [buildSealedClass])
  /// - Nullable schema variables (representation is non-nullable)
  ExtensionType? buildExtensionType(
    ModelInfo model,
    List<ModelInfo> allModels,
  ) {
    // Discriminated base classes get sealed classes, not extension types
    if (model.isDiscriminatedBaseDefinition) {
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
          // Add parsed getter for top-level transformed wrappers
          if (model.hasDistinctParsedType && !isObjectSchema)
            _buildParsedGetter(model, schemaVarName, valueVarName),
          ..._buildGetters(model, lookups),
          // Only add args and copyWith for object schemas
          if (isObjectSchema) ...[
            if (model.additionalProperties) _buildArgsGetter(model),
            if (model.fields.isNotEmpty) _buildCopyWith(model, lookups),
          ],
        ]),
    );
  }

  /// Builds a sealed class for discriminated base types
  Class? buildSealedClass(ModelInfo model, List<ModelInfo> allModels) {
    if (!model.isDiscriminatedBaseDefinition) {
      return null;
    }

    final typeName = _getExtensionTypeName(model);
    final schemaVarName = _toCamelCase(model.schemaClassName);
    final subtypeNames = model.subtypeNames;

    if (subtypeNames == null || subtypeNames.isEmpty) {
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
          _buildDiscriminatedFactory(model, schemaVarName, subtypeNames),
          // Add safeParse static method
          _buildDiscriminatedSafeParse(model, schemaVarName, subtypeNames),
        ]),
    );
  }

  /// Builds an extension type for discriminated @AckType base schemas.
  ExtensionType? buildDiscriminatedExtensionBase(
    ModelInfo model,
    List<ModelInfo> allModels,
  ) {
    if (!model.isDiscriminatedBaseDefinition) {
      return null;
    }

    final typeName = _getExtensionTypeName(model);
    final schemaVarName = _toCamelCase(model.schemaClassName);
    final subtypeNames = model.subtypeNames;

    if (subtypeNames == null || subtypeNames.isEmpty) {
      return null;
    }

    // Resolve schemaClassName → className for the switch expression.
    // subtypeNames stores schemaClassName for @AckType models;
    // _buildDiscriminatorSwitchExpression needs className to emit TypeName.
    final resolvedSubtypeNames = <String, String>{};
    for (final entry in subtypeNames.entries) {
      final branchModel = allModels.firstWhere(
        (m) => m.schemaClassName == entry.value,
        orElse: () => throw StateError(
          'Failed to resolve discriminated subtype "${entry.value}" '
          '(discriminator "${entry.key}") for base '
          '"${model.schemaClassName}" while building '
          'extension type "$typeName".',
        ),
      );
      resolvedSubtypeNames[entry.key] = branchModel.className;
    }

    return ExtensionType(
      (b) => b
        ..name = typeName
        ..docs.addAll(_buildDocs(model))
        ..representationDeclaration = RepresentationDeclaration(
          (r) => r
            ..declaredRepresentationType = refer('Map<String, Object?>')
            ..name = '_data',
        )
        ..implements.add(refer('Map<String, Object?>'))
        ..methods.addAll([
          Method(
            (m) => m
              ..type = MethodType.getter
              ..name = model.discriminatorKey!
              ..returns = refer('String')
              ..lambda = true
              ..body = Code("_data['${model.discriminatorKey}'] as String"),
          ),
          _buildToJson(model),
          _buildDiscriminatedFactory(
            model,
            schemaVarName,
            resolvedSubtypeNames,
          ),
          _buildDiscriminatedSafeParse(
            model,
            schemaVarName,
            resolvedSubtypeNames,
          ),
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
    final discriminatorKey = baseModel.discriminatorKey!;
    final nonDiscriminatorFields = model.fields
        .where((field) => field.jsonKey != discriminatorKey)
        .toList();
    final schemaVarName = _toCamelCase(model.schemaClassName);

    return ExtensionType(
      (b) => b
        ..name = typeName
        ..docs.addAll(_buildDocs(model))
        ..representationDeclaration = RepresentationDeclaration(
          (r) => r
            ..declaredRepresentationType = refer('Map<String, Object?>')
            ..name = '_data',
        )
        ..implements.addAll([
          refer(baseTypeName),
          refer('Map<String, Object?>'),
        ])
        ..methods.addAll([
          // Override discriminator to read from _data for consistency with toJson()
          // Factory constructors already validate the discriminator value matches
          Method(
            (m) => m
              ..type = MethodType.getter
              ..name = discriminatorKey
              ..returns = refer('String')
              ..lambda = true
              ..body = Code("_data['$discriminatorKey'] as String"),
          ),
          _buildToJson(model),
          // This builder is currently used by @AckType schema-variable
          // discriminated flows; keep these guards explicit to preserve behavior.
          if (model.isFromSchemaVariable)
            ..._buildStaticFactories(model, schemaVarName),
          // Add regular field getters
          ..._buildGetters(model, lookups, skipJsonKeys: {discriminatorKey}),
          if (model.additionalProperties) _buildArgsGetter(model),
          if (model.isFromSchemaVariable && nonDiscriminatorFields.isNotEmpty)
            _buildCopyWithForFields(
              model,
              nonDiscriminatorFields,
              lookups: lookups,
              fixedAssignments: {
                discriminatorKey: model.discriminatorValue != null
                    ? _singleQuotedLiteral(model.discriminatorValue!)
                    : 'this.$discriminatorKey',
              },
            ),
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
    final cycleParticipants = <String>{};

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
        cycleParticipants.add(className);
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
        'Circular dependency detected between extension types: '
        '${cycleParticipants.join(', ')}. '
        'Using original declaration order (safe for Map-based types).',
      );
      return models;
    }

    return sorted;
  }

  // --- Private Helper Methods ---

  String _qualifyAckSymbol(String symbol) {
    final prefix = _ackImportPrefix;
    if (prefix == null || prefix.isEmpty) return symbol;
    return '$prefix.$symbol';
  }

  Reference _schemaResultRef(Reference innerType) {
    return TypeReference(
      (b) => b
        ..symbol = _qualifyAckSymbol('SchemaResult')
        ..types.add(innerType),
    );
  }

  Reference _referenceFromDartType(
    DartType type, {
    bool forceNullable = false,
    bool stripNullability = false,
  }) {
    final isNullable =
        forceNullable || (!stripNullability && _isNullable(type));

    if (type is ParameterizedType) {
      final element = type.element3;
      final symbol =
          element?.name3 ?? type.getDisplayString(withNullability: false);
      final url = _urlForElement(element);
      final typeArgs = type.typeArguments
          .map(
            (arg) =>
                _referenceFromDartType(arg, stripNullability: stripNullability),
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
    return _typeReference(symbol, url: url, isNullable: isNullable);
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

  Method _buildParsedGetter(
    ModelInfo model,
    String schemaVarName,
    String valueVarName,
  ) {
    return Method(
      (m) => m
        ..type = MethodType.getter
        ..name = 'parsed'
        ..returns = refer(model.parsedType)
        ..lambda = true
        ..body = Code('$schemaVarName.parse($valueVarName)!'),
    );
  }

  List<Method> _buildStaticFactories(ModelInfo model, String schemaVarName) {
    final typeName = _getExtensionTypeName(model);
    final castType = model.representationType;
    final castExpr = _buildRepresentationCast(castType);

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
return $schemaVarName.parseRepresentationAs(
  data,
  (validated) => $typeName($castExpr),
);'''),
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
return $schemaVarName.safeParseRepresentationAs(
  data,
  (validated) => $typeName($castExpr),
);'''),
      ),
    ];
  }

  /// Builds the cast expression for validated representation values.
  ///
  /// List types need `.cast<T>()` because the runtime type is `List<Object?>`.
  /// Set types similarly need `.cast<T>()`.
  String _buildRepresentationCast(String castType) {
    final listMatch = RegExp(r'^List<(.+)>$').firstMatch(castType);
    if (listMatch != null) {
      return '(validated as List).cast<${listMatch.group(1)}>()';
    }
    final setMatch = RegExp(r'^Set<(.+)>$').firstMatch(castType);
    if (setMatch != null) {
      return '(validated as Set).cast<${setMatch.group(1)}>()';
    }
    return 'validated as $castType';
  }

  Method _buildDiscriminatedFactory(
    ModelInfo model,
    String schemaVarName,
    Map<String, String> subtypeNames,
  ) {
    final typeName = _getExtensionTypeName(model);
    final discriminatorKey = model.discriminatorKey!;
    final switchExpression = _buildDiscriminatorSwitchExpression(
      'map',
      discriminatorKey,
      subtypeNames,
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
return $schemaVarName.parseRepresentationAs(
  data,
  (validated) {
    final map = validated as Map<String, Object?>;
    return $switchExpression;
  },
);'''),
    );
  }

  Method _buildDiscriminatedSafeParse(
    ModelInfo model,
    String schemaVarName,
    Map<String, String> subtypeNames,
  ) {
    final typeName = _getExtensionTypeName(model);
    final discriminatorKey = model.discriminatorKey!;
    final switchExpression = _buildDiscriminatorSwitchExpression(
      'map',
      discriminatorKey,
      subtypeNames,
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
return $schemaVarName.safeParseRepresentationAs(
  data,
  (validated) {
    final map = validated as Map<String, Object?>;
    return $switchExpression;
  },
);'''),
    );
  }

  String _buildDiscriminatorSwitchExpression(
    String mapVarName,
    String discriminatorKey,
    Map<String, String> subtypeNames,
  ) {
    final cases = <String>[];
    for (final entry in subtypeNames.entries) {
      final discriminatorValue = entry.key;
      final subtypeClassName = entry.value;
      final subtypeTypeName = '${subtypeClassName}Type';

      cases.add("  '$discriminatorValue' => $subtypeTypeName($mapVarName)");
    }

    return '''
switch ($mapVarName['$discriminatorKey']) {
${cases.join(',\n')},
  _ => throw StateError('Unknown $discriminatorKey: \${$mapVarName['$discriminatorKey']}'),
}''';
  }

  List<Method> _buildGetters(
    ModelInfo model,
    _ModelLookups lookups, {
    Set<String> skipJsonKeys = const {},
  }) {
    final schemaVarName = _toCamelCase(model.schemaClassName);
    final methods = <Method>[];
    for (final field in model.fields) {
      if (skipJsonKeys.contains(field.jsonKey)) continue;
      methods.add(_buildGetter(field, lookups));
      final parsedGetter = _buildFieldParsedGetter(
        field,
        lookups,
        schemaVarName,
      );
      if (parsedGetter != null) methods.add(parsedGetter);
    }
    return methods;
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

  /// Builds a `<fieldName>Parsed` getter for fields with transformed representations.
  ///
  /// Returns null when the field has no distinct parsed type.
  Method? _buildFieldParsedGetter(
    FieldInfo field,
    _ModelLookups lookups,
    String schemaVarName,
  ) {
    if (!field.isTransformedRepresentation) return null;

    // Determine parsed type string
    final parsedTypeStr = _resolveParsedFieldType(field, lookups);
    if (parsedTypeStr == null) return null;

    // Check if parsed type differs from representation type
    final reprType = _resolveFieldType(field, lookups);
    if (parsedTypeStr == reprType) return null;

    final needsNullHandling = field.isNullable || !field.isRequired;
    final returnType = _applyNullability(parsedTypeStr, needsNullHandling);
    final key = field.jsonKey;
    final name = field.name;

    final String body;
    if (field.nestedSchemaRef != null) {
      // Named ref: delegate to wrapper's .parsed
      if (needsNullHandling) {
        body = '$name?.parsed';
      } else {
        body = '$name.parsed';
      }
    } else if (field.isList && _isCustomElementType(field, lookups)) {
      // List of named refs
      if (needsNullHandling) {
        body = '$name?.map((e) => e.parsed).toList()';
      } else {
        body = '$name.map((e) => e.parsed).toList()';
      }
    } else {
      // Inline transform or built-in transform: use schema property parse
      if (needsNullHandling) {
        body =
            "_data['$key'] != null ? $schemaVarName.properties['$key']!.parse(_data['$key']) as $parsedTypeStr : null";
      } else {
        body =
            "$schemaVarName.properties['$key']!.parse(_data['$key']) as $parsedTypeStr";
      }
    }

    return Method(
      (m) => m
        ..type = MethodType.getter
        ..name = '${name}Parsed'
        ..returns = refer(returnType)
        ..lambda = true
        ..body = Code(body),
    );
  }

  /// Resolves the parsed/output type string for a field.
  String? _resolveParsedFieldType(FieldInfo field, _ModelLookups lookups) {
    if (field.parsedDisplayTypeOverride != null) {
      return field.parsedDisplayTypeOverride!;
    }

    final parsedType = field.parsedType;

    // Check for named ref with distinct parsed type
    if (field.nestedSchemaRef != null) {
      final referencedModel = _findSchemaModel(field.nestedSchemaRef!, lookups);
      if (referencedModel != null && referencedModel.hasDistinctParsedType) {
        return referencedModel.parsedType;
      }
      return null;
    }

    // List of named refs with distinct parsed type
    if ((field.isList || field.isSet) && field.listElementSchemaRef != null) {
      final elementModel = _findSchemaModel(
        field.listElementSchemaRef!,
        lookups,
      );
      if (elementModel != null && elementModel.hasDistinctParsedType) {
        final collType = field.isSet ? 'Set' : 'List';
        return '$collType<${elementModel.parsedType}>';
      }
      return null;
    }

    // Check if parsedType differs from type
    if (parsedType != field.type) {
      return parsedType.getDisplayString(withNullability: false);
    }

    return null;
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
    // Nested schema variable reference (e.g., 'status': statusSchema).
    if (field.nestedSchemaRef != null) {
      if (field.displayTypeOverride != null) {
        final castType = field.nestedSchemaCastTypeOverride ?? kMapType;
        return "${field.displayTypeOverride!}(_data['$key'] as $castType)";
      }

      final referencedModel = _findSchemaModel(field.nestedSchemaRef!, lookups);
      if (referencedModel != null) {
        final typeName = '${referencedModel.className}Type';
        final castType = referencedModel.representationType;
        return "$typeName(_data['$key'] as $castType)";
      }
      return "_data['$key'] as Map<String, Object?>";
    }

    // Primitive and already-validated core value types.
    if (field.isPrimitive || _isSpecialType(field.type)) {
      return "_data['$key'] as $baseType";
    }

    // Enums (validated by schema, returns the enum value)
    if (field.isEnum) {
      return "_data['$key'] as $baseType";
    }

    if (field.displayTypeOverride != null) {
      return "_data['$key'] as $baseType";
    }

    // Lists
    if (field.isList) {
      return _buildListGetter(field, lookups, key);
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
    if (field.nestedSchemaRef != null) {
      final nonNullPart = _buildNonNullableGetter(
        field,
        lookups,
        key,
        baseType: baseType,
      );
      return "_data['$key'] != null ? $nonNullPart : null";
    }

    // For primitives, enums, and already-validated core value types,
    // nullable cast works directly on the validated map payload.
    if (field.isPrimitive || field.isEnum || _isSpecialType(field.type)) {
      return "_data['$key'] as $baseType?";
    }

    if (field.displayTypeOverride != null) {
      return "_data['$key'] as $baseType?";
    }

    // For complex types, check null first
    final nonNullPart = _buildNonNullableGetter(
      field,
      lookups,
      key,
      baseType: baseType,
    );
    return "_data['$key'] != null ? $nonNullPart : null";
  }

  String _buildListGetter(FieldInfo field, _ModelLookups lookups, String key) =>
      _buildCollectionGetter(field, lookups, key, isSet: false);

  String _buildSetGetter(FieldInfo field, _ModelLookups lookups, String key) =>
      _buildCollectionGetter(field, lookups, key, isSet: true);

  /// Builds getter code for List or Set collections
  String _buildCollectionGetter(
    FieldInfo field,
    _ModelLookups lookups,
    String key, {
    required bool isSet,
  }) {
    final elementType = _getCollectionElementType(field, lookups, isSet: isSet);

    final suffix = isSet ? '.toSet()' : '';

    // Check if element type is a custom type with @AckType
    if (_isCustomElementType(field, lookups)) {
      // Return eager List for object lists (per requirements: List<T>, not Iterable<T>)
      final listSuffix = isSet ? '' : '.toList()';
      final castType = _getCustomElementCastType(field, elementType, lookups);
      final constructorName = field.collectionElementIsCustomType
          ? _asExtensionTypeName(elementType)
          : '${elementType}Type';
      return "(_data['$key'] as List).map((e) => $constructorName(e as $castType))$listSuffix$suffix";
    }

    // Primitive lists/sets - direct cast
    if (isSet) {
      return "_\$ackSetCast<$elementType>(_data['$key'])";
    }
    return "_\$ackListCast<$elementType>(_data['$key'])";
  }

  Method _buildListCastHelper() {
    return Method(
      (m) => m
        ..name = '_\$ackListCast'
        ..types.add(refer('T'))
        ..returns = TypeReference(
          (b) => b
            ..symbol = 'List'
            ..types.add(refer('T')),
        )
        ..requiredParameters.add(
          Parameter(
            (p) => p
              ..name = 'value'
              ..type = refer('Object?'),
          ),
        )
        ..lambda = true
        ..body = Code('(value as List).cast<T>()'),
    );
  }

  Method _buildSetCastHelper() {
    return Method(
      (m) => m
        ..name = '_\$ackSetCast'
        ..types.add(refer('T'))
        ..returns = TypeReference(
          (b) => b
            ..symbol = 'Set'
            ..types.add(refer('T')),
        )
        ..requiredParameters.add(
          Parameter(
            (p) => p
              ..name = 'value'
              ..type = refer('Object?'),
          ),
        )
        ..lambda = true
        ..body = Code('(value as List).cast<T>().toSet()'),
    );
  }

  String _resolveFieldType(FieldInfo field, _ModelLookups lookups) {
    // Nested schema variable reference (e.g., 'status': statusSchema).
    if (field.nestedSchemaRef != null) {
      if (field.displayTypeOverride != null) {
        return field.displayTypeOverride!;
      }

      final referencedModel = _findSchemaModel(field.nestedSchemaRef!, lookups);
      if (referencedModel != null) {
        return '${referencedModel.className}Type';
      }
      return kMapType;
    }

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
      return field.displayTypeOverride ??
          field.type.getDisplayString(withNullability: false);
    }

    // Lists
    if (field.isList) {
      final elementType = _getCollectionElementType(
        field,
        lookups,
        isSet: false,
      );
      // Use List for all list types (eager evaluation per requirements)
      if (_isCustomElementType(field, lookups)) {
        final customElementType = field.collectionElementIsCustomType
            ? _asExtensionTypeName(elementType)
            : '${elementType}Type';
        return 'List<$customElementType>';
      }
      return 'List<$elementType>';
    }

    // Maps
    if (field.isMap) {
      return 'Map<String, Object?>';
    }

    // Sets
    if (field.isSet) {
      final elementType = _getCollectionElementType(
        field,
        lookups,
        isSet: true,
      );
      if (_isCustomElementType(field, lookups)) {
        final customElementType = field.collectionElementIsCustomType
            ? _asExtensionTypeName(elementType)
            : '${elementType}Type';
        return 'Set<$customElementType>';
      }
      return 'Set<$elementType>';
    }

    // Generic types
    if (field.isGeneric) {
      return 'Object?';
    }

    if (field.displayTypeOverride != null) {
      return field.displayTypeOverride!;
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
    if (field.collectionElementDisplayTypeOverride != null) {
      return field.collectionElementDisplayTypeOverride!;
    }

    // Check for schema variable reference first (e.g., Ack.list(addressSchema))
    if (!isSet && field.listElementSchemaRef != null) {
      final referencedModel = _findSchemaModel(
        field.listElementSchemaRef!,
        lookups,
      );
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

  bool _hasAckTypeForElement(InterfaceElement2 element, _ModelLookups lookups) {
    final name = element.name3;
    if (name == null) return false;
    return lookups.byClassName.containsKey(name);
  }

  bool _isCustomElementType(FieldInfo field, _ModelLookups lookups) {
    if (field.collectionElementIsCustomType) {
      return true;
    }

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

  String _asExtensionTypeName(String typeName) {
    return typeName.endsWith('Type') ? typeName : '${typeName}Type';
  }

  ModelInfo? _findSchemaModel(String schemaVarName, _ModelLookups lookups) {
    return lookups.schemaByName(schemaVarName);
  }

  String _getCustomElementCastType(
    FieldInfo field,
    String elementType,
    _ModelLookups lookups,
  ) {
    if (field.collectionElementCastTypeOverride != null) {
      return field.collectionElementCastTypeOverride!;
    }

    if (field.listElementSchemaRef != null) {
      final referencedModel = _findSchemaModel(
        field.listElementSchemaRef!,
        lookups,
      );
      if (referencedModel != null) {
        return referencedModel.representationType;
      }
    }

    final elementModel = lookups.classByName(elementType);
    return elementModel?.representationType ?? kMapType;
  }

  Set<String> _extractDependencies(ModelInfo model, _ModelLookups lookups) {
    final dependencies = <String>{};

    final discriminatedBaseClassName = model.discriminatedBaseClassName;
    if (discriminatedBaseClassName != null &&
        lookups.byClassName.containsKey(discriminatedBaseClassName)) {
      dependencies.add(discriminatedBaseClassName);
    }

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

  Method _buildCopyWith(ModelInfo model, _ModelLookups lookups) {
    return _buildCopyWithForFields(model, model.fields, lookups: lookups);
  }

  Method _buildCopyWithForFields(
    ModelInfo model,
    List<FieldInfo> fields, {
    required _ModelLookups lookups,
    Map<String, String> fixedAssignments = const {},
  }) {
    final typeName = _getExtensionTypeName(model);

    // Build parameters - all parameters are nullable to support copyWith semantics
    final parameters = fields.map((field) {
      return Parameter(
        (p) => p
          ..name = field.name
          ..type = _buildCopyWithParameterType(field, lookups)
          ..named = true,
      );
    }).toList();

    // Build field assignments
    final assignments = <String>[
      ...fixedAssignments.entries.map(
        (entry) => '      ${_singleQuotedLiteral(entry.key)}: ${entry.value}',
      ),
      ...fields.map((field) {
        final key = field.jsonKey;
        final name = field.name;
        final toJson = _copyWithToJson(field, lookups);
        final fallback = "_data['$key']";

        if (!field.isRequired && !field.isNullable) {
          // Optional non-nullable: preserve omission when not explicitly provided
          return "      if ($name != null || _data.containsKey('$key')) '$key': $toJson ?? $fallback";
        } else if (field.isNullable) {
          // Nullable: preserve existing containsKey logic
          return "      if ($name != null || _data.containsKey('$key')) '$key': $toJson ?? $fallback";
        } else {
          // Required non-nullable: simple fallback
          return "      '$key': $toJson ?? $fallback";
        }
      }),
    ];

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

  /// Produces the expression for the parameter value in copyWith.
  ///
  /// When the field's getter returns a wrapper type (named ref or list of
  /// named refs), the copyWith parameter accepts the wrapper type and needs
  /// `.toJson()` to unwrap it before writing into the raw map.
  String _copyWithToJson(FieldInfo field, _ModelLookups lookups) {
    final name = field.name;

    // Named ref fields: unwrap with .toJson() when wrapper type exists
    if (field.nestedSchemaRef != null &&
        _findSchemaModel(field.nestedSchemaRef!, lookups) != null) {
      return '$name?.toJson()';
    }

    // List/Set of named refs: map each element
    if ((field.isList || field.isSet) && _isCustomElementType(field, lookups)) {
      final suffix = field.isSet ? '.toSet()' : '';
      return '$name?.map((e) => e.toJson()).toList()$suffix';
    }

    return name;
  }

  String _singleQuotedLiteral(String value) {
    final escaped = value.replaceAll(r'\', r'\\').replaceAll("'", r"\'");
    return "'$escaped'";
  }

  Reference _buildCopyWithParameterType(
    FieldInfo field,
    _ModelLookups lookups,
  ) {
    if (field.isEnum && field.displayTypeOverride != null) {
      return _typeReference(field.displayTypeOverride!, isNullable: true);
    }

    if ((field.isList || field.isSet) &&
        field.collectionElementDisplayTypeOverride != null) {
      final collectionType = field.isSet ? 'Set' : 'List';
      final elementType = field.collectionElementIsCustomType
          ? _asExtensionTypeName(field.collectionElementDisplayTypeOverride!)
          : field.collectionElementDisplayTypeOverride!;
      return _typeReference(
        collectionType,
        types: [_typeReference(elementType)],
        isNullable: true,
      );
    }

    // Named ref fields: use the wrapper type
    if (field.nestedSchemaRef != null) {
      final referencedModel = _findSchemaModel(field.nestedSchemaRef!, lookups);
      if (referencedModel != null) {
        return _typeReference(
          '${referencedModel.className}Type',
          isNullable: true,
        );
      }
    }

    return _referenceFromDartType(
      field.type,
      forceNullable: true,
      stripNullability: true,
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
