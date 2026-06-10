part of 'schema_model.dart';

final class _JsonSchemaParser {
  SchemaModel parse(Map<String, Object?> json) {
    return _parse(json, path: '');
  }

  SchemaModel _parse(
    Map<String, Object?> json, {
    required String path,
    bool nullable = false,
  }) {
    final nullableUnion = _readNullableUnion(json);
    if (nullableUnion != null) {
      final parsed = _parse(
        nullableUnion.schema,
        path: _joinPath(path, 'anyOf/${nullableUnion.schemaIndex}'),
        nullable: true,
      );
      return _applyKeywords(parsed, json, const {'anyOf'});
    }

    final wrappedRefName = _readWrappedDefinitionsRef(json);
    if (wrappedRefName != null) {
      return _applyKeywords(
        RefSchemaModel(refName: wrappedRefName, nullable: nullable),
        json,
        const {'allOf'},
      );
    }

    if (json[r'$ref'] case final String ref) {
      final refName = _definitionsRefName(ref);
      if (refName != null) {
        return _applyKeywords(
          RefSchemaModel(refName: refName, nullable: nullable),
          json,
          const {r'$ref'},
        );
      }

      return _fallback(
        json,
        path: path,
        nullable: nullable,
        warning: _warning(
          code: 'unsupported_ref',
          message:
              'Only local #/definitions/ JSON Schema references can be imported.',
          path: path,
          context: {'ref': ref},
        ),
      );
    }

    if (json['type'] case final List<Object?> types) {
      return _parseTypeList(json, types, path: path, nullable: nullable);
    }

    if (json['anyOf'] case final List<Object?> schemas) {
      return _parseComposition(
        'anyOf',
        schemas,
        json,
        path: path,
        nullable: nullable,
      );
    }
    if (json['oneOf'] case final List<Object?> schemas) {
      return _parseComposition(
        'oneOf',
        schemas,
        json,
        path: path,
        nullable: nullable,
      );
    }
    if (json['allOf'] case final List<Object?> schemas) {
      return _parseComposition(
        'allOf',
        schemas,
        json,
        path: path,
        nullable: nullable,
      );
    }

    if (json['type'] case final String type) {
      return switch (type) {
        'string' => _applyKeywords(
          StringSchemaModel(nullable: nullable),
          json,
          const {'type'},
        ),
        'integer' => _applyKeywords(
          IntegerSchemaModel(nullable: nullable),
          json,
          const {'type'},
        ),
        'number' => _applyKeywords(
          NumberSchemaModel(nullable: nullable),
          json,
          const {'type'},
        ),
        'boolean' => _applyKeywords(
          BooleanSchemaModel(nullable: nullable),
          json,
          const {'type'},
        ),
        'array' => _parseArray(json, path: path, nullable: nullable),
        'object' => _parseObject(json, path: path, nullable: nullable),
        'null' => _applyKeywords(const NullSchemaModel(), json, const {'type'}),
        _ => _fallback(
          json,
          path: path,
          nullable: nullable,
          warning: _warning(
            code: 'unsupported_type',
            message: 'JSON Schema type "$type" is not supported.',
            path: path,
            context: {'type': type},
          ),
        ),
      };
    }

    return _fallback(
      json,
      path: path,
      nullable: nullable,
      warning: _warning(
        code: 'unsupported_schema_shape',
        message: 'JSON Schema shape could not be mapped to a SchemaModel.',
        path: path,
      ),
    );
  }

  SchemaModel _parseArray(
    Map<String, Object?> json, {
    required String path,
    required bool nullable,
  }) {
    final warnings = <SchemaModelWarning>[];
    SchemaModel? items;

    if (json.containsKey('items')) {
      final itemMap = _asStringMap(json['items']);
      if (itemMap != null) {
        items = _parse(itemMap, path: _joinPath(path, 'items'));
      } else {
        warnings.add(
          _warning(
            code: 'unsupported_items_schema',
            message:
                'Boolean or non-object JSON Schema items are not imported.',
            path: _joinPath(path, 'items'),
          ),
        );
      }
    }

    return _applyKeywords(
      ArraySchemaModel(items: items, nullable: nullable, warnings: warnings),
      json,
      const {'type', 'items'},
    );
  }

  SchemaModel _parseObject(
    Map<String, Object?> json, {
    required String path,
    required bool nullable,
  }) {
    final warnings = <SchemaModelWarning>[];
    Map<String, SchemaModel>? properties;
    List<String>? required;
    List<String>? propertyOrdering;
    AdditionalPropertiesModel? additionalProperties;

    final propertiesJson = _asStringMap(json['properties']);
    if (propertiesJson != null) {
      final parsed = <String, SchemaModel>{};
      for (final entry in propertiesJson.entries) {
        final propertyJson = _asStringMap(entry.value);
        parsed[entry.key] = propertyJson == null
            ? _fallback(
                const {},
                path: _joinPath(path, 'properties/${entry.key}'),
                warning: _warning(
                  code: 'unsupported_property_schema',
                  message: 'Object property schemas must be JSON objects.',
                  path: _joinPath(path, 'properties/${entry.key}'),
                ),
              )
            : _parse(
                propertyJson,
                path: _joinPath(path, 'properties/${entry.key}'),
              );
      }
      properties = parsed.isEmpty ? null : parsed;
      propertyOrdering = parsed.keys.toList(growable: false);
    }

    if (json['required'] case final List<Object?> values) {
      required = [
        for (final value in values)
          if (value is String) value,
      ];
      if (required.isEmpty) required = null;
    }

    if (json.containsKey('additionalProperties')) {
      switch (json['additionalProperties']) {
        case true:
          additionalProperties = const AdditionalPropertiesAllowed();
        case false:
          additionalProperties = const AdditionalPropertiesDisallowed();
        case final Object? value when _asStringMap(value) != null:
          additionalProperties = AdditionalPropertiesSchema(
            _parse(
              _asStringMap(value)!,
              path: _joinPath(path, 'additionalProperties'),
            ),
          );
        default:
          warnings.add(
            _warning(
              code: 'unsupported_additional_properties',
              message:
                  'additionalProperties must be a boolean or JSON Schema object.',
              path: _joinPath(path, 'additionalProperties'),
            ),
          );
      }
    }

    return _applyKeywords(
      ObjectSchemaModel(
        properties: properties,
        required: required,
        propertyOrdering: propertyOrdering,
        additionalProperties: additionalProperties,
        nullable: nullable,
        warnings: warnings,
      ),
      json,
      const {'type', 'properties', 'required', 'additionalProperties'},
    );
  }

  SchemaModel _parseComposition(
    String keyword,
    List<Object?> schemas,
    Map<String, Object?> json, {
    required String path,
    required bool nullable,
  }) {
    final parsedSchemas = <SchemaModel>[];
    final warnings = <SchemaModelWarning>[];

    for (var i = 0; i < schemas.length; i += 1) {
      final schema = _asStringMap(schemas[i]);
      if (schema == null) {
        warnings.add(
          _warning(
            code: 'unsupported_composition_branch',
            message: 'Composition branches must be JSON Schema objects.',
            path: _joinPath(path, '$keyword/$i'),
          ),
        );
        continue;
      }
      parsedSchemas.add(_parse(schema, path: _joinPath(path, '$keyword/$i')));
    }

    final model = switch (keyword) {
      'anyOf' => AnyOfSchemaModel(
        schemas: parsedSchemas,
        nullable: nullable,
        warnings: warnings,
      ),
      'oneOf' => OneOfSchemaModel(
        schemas: parsedSchemas,
        nullable: nullable,
        warnings: warnings,
      ),
      'allOf' => AllOfSchemaModel(
        schemas: parsedSchemas,
        nullable: nullable,
        warnings: warnings,
      ),
      _ => throw StateError('Unsupported composition keyword $keyword'),
    };

    return _applyKeywords(model, json, {keyword});
  }

  SchemaModel _parseTypeList(
    Map<String, Object?> json,
    List<Object?> types, {
    required String path,
    required bool nullable,
  }) {
    final hasNull = types.contains('null');
    final schemas = <SchemaModel>[];

    for (final type in types) {
      if (type is! String || type == 'null') continue;
      schemas.add(_parse({...json, 'type': type}, path: path));
    }

    final warning = _warning(
      code: 'unsupported_type_array',
      message:
          'JSON Schema type arrays are imported as a best-effort composition.',
      path: path,
      context: {'type': types},
    );

    if (schemas.isEmpty) {
      return _fallback(
        json,
        path: path,
        nullable: nullable || hasNull,
      ).withWarnings([warning]);
    }

    return AnyOfSchemaModel(
      schemas: schemas,
      nullable: nullable || hasNull,
      warnings: [warning],
    );
  }

  SchemaModel _fallback(
    Map<String, Object?> json, {
    required String path,
    bool nullable = false,
    SchemaModelWarning? warning,
  }) {
    final fallback = AnyOfSchemaModel(
      schemas: const [
        StringSchemaModel(),
        NumberSchemaModel(),
        IntegerSchemaModel(),
        BooleanSchemaModel(),
        ObjectSchemaModel(),
        ArraySchemaModel(),
      ],
      nullable: nullable,
      warnings: [if (warning != null) warning],
    );
    return json.isEmpty ? fallback : fallback.withJsonSchemaKeywords(json);
  }

  SchemaModel _applyKeywords(
    SchemaModel model,
    Map<String, Object?> json,
    Set<String> handled,
  ) {
    final keywords = Map<String, Object?>.fromEntries(
      json.entries.where((entry) => !handled.contains(entry.key)),
    );
    return keywords.isEmpty ? model : model.withJsonSchemaKeywords(keywords);
  }

  _NullableUnion? _readNullableUnion(Map<String, Object?> json) {
    if (json['anyOf'] case final List<Object?> schemas) {
      if (schemas.length != 2) return null;

      final first = _asStringMap(schemas[0]);
      final second = _asStringMap(schemas[1]);
      if (first == null || second == null) return null;

      if (_isNullSchema(first)) {
        return _NullableUnion(schema: second, schemaIndex: 1);
      }
      if (_isNullSchema(second)) {
        return _NullableUnion(schema: first, schemaIndex: 0);
      }
    }
    return null;
  }

  String? _readWrappedDefinitionsRef(Map<String, Object?> json) {
    if (json['allOf'] case final List<Object?> schemas) {
      if (schemas.length != 1) return null;
      final refSchema = _asStringMap(schemas.single);
      if (refSchema == null || refSchema.length != 1) return null;
      if (refSchema[r'$ref'] case final String ref) {
        return _definitionsRefName(ref);
      }
    }
    return null;
  }

  bool _isNullSchema(Map<String, Object?> json) {
    return json.length == 1 && json['type'] == 'null';
  }

  String? _definitionsRefName(String ref) {
    const prefix = '#/definitions/';
    if (!ref.startsWith(prefix)) return null;
    return _unescapeJsonPointerToken(ref.substring(prefix.length));
  }

  Map<String, Object?>? _asStringMap(Object? value) {
    if (value is Map<String, Object?>) return value;
    if (value is! Map<Object?, Object?>) return null;

    final result = <String, Object?>{};
    for (final entry in value.entries) {
      final key = entry.key;
      if (key is! String) return null;
      result[key] = entry.value;
    }
    return result;
  }

  SchemaModelWarning _warning({
    required String code,
    required String message,
    required String path,
    Map<String, Object?> context = const {},
  }) {
    return SchemaModelWarning(
      code: code,
      message: message,
      path: path.isEmpty ? null : path,
      context: context,
    );
  }

  String _joinPath(String parent, String child) {
    if (parent.isEmpty) return child;
    return '$parent/$child';
  }

  String _unescapeJsonPointerToken(String value) {
    return value.replaceAll('~1', '/').replaceAll('~0', '~');
  }
}

final class _NullableUnion {
  const _NullableUnion({required this.schema, required this.schemaIndex});

  final Map<String, Object?> schema;
  final int schemaIndex;
}
