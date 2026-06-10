import 'dart:convert';

import 'package:collection/collection.dart';

import '../constraints/constraint.dart';
import '../constraints/datetime_constraint.dart';
import '../context.dart';
import '../json_schema/json_schema_utils.dart';
import '../schemas/schema.dart';
import 'package:schema_model/schema_model.dart';

extension AckSchemaModelExtension<
  Boundary extends Object,
  Runtime extends Object
>
    on AckSchema<Boundary, Runtime> {
  SchemaModel toSchemaModel() => _SchemaModelBuilder().build(this);
}

final class _SchemaModelBuilder {
  final _definitions = <String, SchemaModel?>{};
  final _targets = <String, Object>{};

  SchemaModel build(AckSchema<dynamic, dynamic> schema) {
    final root = _build(schema);
    if (_definitions.isEmpty) return root;

    return root.withExtensions({
      ...root.extensions,
      'definitions': _mergeRootDefinitions(root.extensions['definitions']),
    });
  }

  Map<String, Object?> _mergeRootDefinitions(Object? existingDefinitions) {
    final lazyDefinitions = <String, Object?>{
      for (final entry in _definitions.entries)
        if (entry.value case final model?) entry.key: model.toJsonSchema(),
    };
    if (existingDefinitions == null) return lazyDefinitions;
    if (existingDefinitions is! Map) {
      throw ArgumentError(
        'Root JSON Schema definitions must be a map when Ack.lazy definitions '
        'are exported.',
      );
    }

    final merged = <String, Object?>{};
    for (final entry in existingDefinitions.entries) {
      final key = entry.key;
      if (key is! String) {
        throw ArgumentError(
          'Root JSON Schema definitions keys must be strings when Ack.lazy '
          'definitions are exported.',
        );
      }
      merged[key] = entry.value;
    }

    const equality = DeepCollectionEquality();
    for (final entry in lazyDefinitions.entries) {
      if (merged.containsKey(entry.key)) {
        if (!equality.equals(merged[entry.key], entry.value)) {
          throw ArgumentError(
            'Ack.lazy definition "${entry.key}" collides with an existing root '
            'JSON Schema definition. Use a unique lazy name or rename the '
            'existing definition.',
          );
        }
        continue;
      }
      merged[entry.key] = entry.value;
    }
    return merged;
  }

  SchemaModel _build(AckSchema<dynamic, dynamic> schema) {
    if (schema is WrapperSchema) {
      final base = _build(schema.inner);
      // Defaults wrap their inner without transforming the boundary value, so
      // they should not advertise themselves as a transformed schema.
      final extensions = schema is DefaultSchema
          ? base.extensions
          : {...base.extensions, 'x-transformed': true};
      final layered = base
          .withDescription(schema.description ?? base.description)
          .withNullable(schema.isNullable || base.nullable)
          .withExtensions(extensions);
      // `DefaultSchema.constraints` is a passthrough to `inner.constraints`,
      // which `_build(schema.inner)` already applied. Re-running them here
      // would emit duplicate warnings (e.g. datetime range under a default).
      var wrapped = schema is DefaultSchema
          ? layered
          : _applyConstraints(layered, schema);

      if (schema is DefaultSchema) {
        final exportDefault = _defaultExportValueOrNull(schema);
        if (exportDefault != null) {
          wrapped = wrapped.withDefaultValue(exportDefault);
        } else {
          wrapped = wrapped.withWarnings([
            ...wrapped.warnings,
            SchemaModelWarning(
              code: 'default_not_export_safe',
              message:
                  'Schema default was omitted because it cannot be represented safely in exported JSON-compatible schema models.',
            ),
          ]);
        }
      }

      return wrapped;
    }

    final model = switch (schema) {
      StringSchema() => _string(schema),
      IntegerSchema() => _integer(schema),
      DoubleSchema() => _number(
        description: schema.description,
        nullable: schema.isNullable,
      ),
      NumberSchema() => _number(
        description: schema.description,
        nullable: schema.isNullable,
      ),
      BooleanSchema() => _boolean(schema),
      EnumSchema() => _enum(schema),
      ListSchema() => _array(schema),
      ObjectSchema() => _object(schema),
      AnyOfSchema() => _anyOf(schema),
      AnySchema() => _any(schema),
      InstanceSchema() => _instance(schema),
      DiscriminatedObjectSchema() => _discriminated(schema),
      LazySchema<dynamic, dynamic>() => _lazy(schema),
      _ => throw UnsupportedError(
        'Schema type ${schema.runtimeType} is not supported for SchemaModel conversion.',
      ),
    };

    return schema is LazySchema ? model : _applyConstraints(model, schema);
  }

  SchemaModel _string(StringSchema schema) {
    return StringSchemaModel(
      description: schema.description,
      nullable: schema.isNullable,
    );
  }

  SchemaModel _integer(IntegerSchema schema) {
    return IntegerSchemaModel(
      description: schema.description,
      nullable: schema.isNullable,
    );
  }

  SchemaModel _number({String? description, required bool nullable}) {
    return NumberSchemaModel(description: description, nullable: nullable);
  }

  SchemaModel _boolean(BooleanSchema schema) {
    return BooleanSchemaModel(
      description: schema.description,
      nullable: schema.isNullable,
    );
  }

  SchemaModel _enum(EnumSchema schema) {
    return StringSchemaModel(
      description: schema.description,
      enumValues: [for (final value in schema.values) value.name],
      nullable: schema.isNullable,
    );
  }

  SchemaModel _array(ListSchema schema) {
    return ArraySchemaModel(
      description: schema.description,
      nullable: schema.isNullable,
      items: _build(schema.itemSchema),
    );
  }

  SchemaModel _object(ObjectSchema schema) {
    final properties = <String, SchemaModel>{};
    final required = <String>[];
    final ordering = <String>[];

    for (final entry in schema.properties.entries) {
      ordering.add(entry.key);
      properties[entry.key] = wrapPropertyConversion(
        entry.key,
        () => _build(entry.value),
      );
      if (_isRequiredObjectProperty(entry.value)) {
        required.add(entry.key);
      }
    }

    return ObjectSchemaModel(
      description: schema.description,
      nullable: schema.isNullable,
      properties: properties.isEmpty ? null : properties,
      required: required.isEmpty ? null : required,
      propertyOrdering: ordering.isEmpty ? null : ordering,
      additionalProperties: schema.additionalProperties
          ? const AdditionalPropertiesAllowed()
          : const AdditionalPropertiesDisallowed(),
    );
  }

  SchemaModel _anyOf(AnyOfSchema schema) {
    return AnyOfSchemaModel(
      schemas: schema.schemas.map(_build).toList(growable: false),
      nullable: schema.isNullable,
      description: schema.description,
    );
  }

  SchemaModel _instance(InstanceSchema schema) {
    // InstanceSchema accepts arbitrary Dart instances of a runtime type with no
    // direct JSON representation. Adapters that flow through a codec see the
    // boundary schema instead; this is the fallback for a bare instance.
    return AnyOfSchemaModel(
      schemas: [
        StringSchemaModel(description: schema.description),
        NumberSchemaModel(description: schema.description),
        IntegerSchemaModel(description: schema.description),
        BooleanSchemaModel(description: schema.description),
        ObjectSchemaModel(description: schema.description),
        ArraySchemaModel(description: schema.description),
      ],
      nullable: schema.isNullable,
      description: schema.description,
      warnings: const [
        SchemaModelWarning(
          code: 'ack_instance_json_boundary',
          message:
              'Ack.instance<T>() accepts arbitrary Dart instances at runtime; JSON-like adapters can only represent JSON-compatible values.',
        ),
      ],
    );
  }

  SchemaModel _any(AnySchema schema) {
    final description = schema.description;
    final primitiveBranches = [
      StringSchemaModel(description: description),
      NumberSchemaModel(description: description),
      IntegerSchemaModel(description: description),
      BooleanSchemaModel(description: description),
      ObjectSchemaModel(description: description),
      ArraySchemaModel(description: description),
    ];

    return AnyOfSchemaModel(
      schemas: primitiveBranches,
      nullable: schema.isNullable,
      description: description,
      warnings: const [
        SchemaModelWarning(
          code: 'ack_any_json_boundary',
          message:
              'Ack.any() accepts non-null JSON-safe values at runtime, matching the JSON-compatible values adapters can represent.',
        ),
      ],
    );
  }

  SchemaModel _discriminated(DiscriminatedObjectSchema schema) {
    if (schema.schemas.isEmpty) {
      return ObjectSchemaModel(
        properties: const {},
        required: const [],
        nullable: schema.isNullable,
        description: schema.description,
      );
    }

    final branches = <SchemaModel>[];
    for (final entry in schema.schemas.entries) {
      final converted = _build(schema.effectiveBranch(entry.key));
      if (converted is! ObjectSchemaModel) {
        throw ArgumentError(
          'Discriminated branch "${entry.key}" must export as an object schema model.',
        );
      }
      branches.add(converted);
    }

    return AnyOfSchemaModel(
      schemas: branches,
      discriminator: SchemaDiscriminatorModel(
        propertyName: schema.discriminatorKey,
      ),
      description: schema.description,
      nullable: schema.isNullable,
    );
  }

  SchemaModel _lazy(LazySchema<dynamic, dynamic> schema) {
    final name = schema.name;
    final target = schema.target;
    final priorTarget = _targets[name];
    if (priorTarget != null) {
      if (!identical(priorTarget, target)) {
        throw ArgumentError(
          'Two Ack.lazy entries share name "$name" but resolve to different '
          'schemas. Use unique names per recursive target.',
        );
      }
      return _lazyRef(schema);
    }

    _targets[name] = target;
    _definitions[name] = null;
    _definitions[name] = _build(target);
    return _lazyRef(schema);
  }

  SchemaModel _lazyRef(LazySchema<dynamic, dynamic> schema) {
    var model = RefSchemaModel(
      refName: schema.name,
      description: schema.description,
      nullable: schema.isNullable,
    );
    final constraintCount = schema.runtimeConstraintCount;
    final refinementCount = schema.runtimeRefinementCount;
    if (constraintCount == 0 && refinementCount == 0) {
      return model;
    }

    return model.withWarnings([
      ...model.warnings,
      SchemaModelWarning(
        code: 'lazy_runtime_checks_not_export_safe',
        message:
            'Ack.lazy constraints and refinements were omitted because JSON Schema refs cannot safely carry runtime-only validation checks.',
        context: {
          'constraintCount': constraintCount,
          'refinementCount': refinementCount,
        },
      ),
    ]);
  }
}

SchemaModel _applyConstraints(
  SchemaModel model,
  AckSchema<dynamic, dynamic> schema,
) {
  var next = model;
  for (final constraint in schema.constraints) {
    if (constraint is DateTimeConstraint) {
      next = _applyDateTimeConstraint(next, constraint);
      continue;
    }

    if (constraint is JsonSchemaSpec) {
      next = next.withJsonSchemaKeywords(constraint.toJsonSchema());
    }
  }

  return next;
}

SchemaModel _applyDateTimeConstraint(
  SchemaModel model,
  DateTimeConstraint constraint,
) {
  return model.withWarnings([
    ...model.warnings,
    SchemaModelWarning(
      code: 'datetime_constraint_not_draft7',
      message:
          'DateTime range constraints are not emitted because JSON Schema Draft-7 has no standard format range keywords.',
      context: {
        'constraint': constraint.comparisonType,
        'reference': constraint.formattedReference,
        'format': constraint.jsonSchemaFormat,
      },
    ),
  ]);
}

/// Best-effort export of a [DefaultSchema] default value.
///
/// Encodes the runtime default through the wrapped schema so codec
/// transformations are applied, then verifies the result is JSON-safe before
/// returning it. Returns `null` when no JSON-safe representation is reachable.
Object? _defaultExportValueOrNull(DefaultSchema<dynamic, dynamic> schema) {
  final resolved = schema.resolveDefaultWithContext(
    _defaultExportContext(schema),
  );
  if (resolved.isFail) return null;

  final defaultValue = resolved.getOrNull();
  if (defaultValue == null) return null;

  final encoded = schema.inner.safeEncode(defaultValue);
  if (encoded.isFail) return null;

  return _jsonRoundTripOrNull(encoded.getOrNull());
}

bool _isRequiredObjectProperty(AckSchema<dynamic, dynamic> schema) {
  if (schema.isOptional) return false;
  if (schema is DefaultSchema &&
      schema.resolveDefaultWithContext(_defaultExportContext(schema)).isOk) {
    return false;
  }

  return true;
}

/// Throwaway [SchemaContext] used only to drive
/// [DefaultSchema.resolveDefaultWithContext]. Errors produced through this
/// context are never surfaced — both callers consume only `.isOk` /
/// `.getOrNull()` — so the rooted error path is intentional.
SchemaContext _defaultExportContext(DefaultSchema<dynamic, dynamic> schema) {
  return SchemaContext(
    name: schema.schemaTypeName,
    schema: schema as AnyAckSchema,
    value: null,
  );
}

Object? _jsonRoundTripOrNull(Object? value) {
  if (value == null) return null;
  try {
    return jsonDecode(jsonEncode(value));
  } catch (_) {
    return null;
  }
}
