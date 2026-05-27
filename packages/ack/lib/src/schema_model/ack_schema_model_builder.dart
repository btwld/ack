import 'dart:convert';

import '../constraints/constraint.dart';
import '../constraints/datetime_constraint.dart';
import '../context.dart';
import '../json_schema/json_schema_utils.dart';
import '../schemas/schema.dart';
import 'ack_schema_model.dart';
import 'ack_schema_model_warning.dart';

extension AckSchemaModelExtension<
  Boundary extends Object,
  Runtime extends Object
>
    on AckSchema<Boundary, Runtime> {
  AckSchemaModel toSchemaModel() => _SchemaModelBuilder().build(this);
}

final class _SchemaModelBuilder {
  final _defs = <String, AckSchemaModel?>{};
  final _targets = <String, Object>{};

  AckSchemaModel build(AckSchema<dynamic, dynamic> schema) {
    final root = _build(schema);
    if (_defs.isEmpty) return root;

    final defs = <String, Object?>{
      for (final entry in _defs.entries)
        if (entry.value case final model?) entry.key: model.toJsonSchema(),
    };
    return root.withExtensions({...root.extensions, r'$defs': defs});
  }

  AckSchemaModel _build(AckSchema<dynamic, dynamic> schema) {
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
            AckSchemaModelWarning(
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
        'Schema type ${schema.runtimeType} is not supported for AckSchemaModel conversion.',
      ),
    };

    return schema is LazySchema ? model : _applyConstraints(model, schema);
  }

  AckSchemaModel _string(StringSchema schema) {
    return AckStringSchemaModel(
      description: schema.description,
      nullable: schema.isNullable,
    );
  }

  AckSchemaModel _integer(IntegerSchema schema) {
    return AckIntegerSchemaModel(
      description: schema.description,
      nullable: schema.isNullable,
    );
  }

  AckSchemaModel _number({String? description, required bool nullable}) {
    return AckNumberSchemaModel(description: description, nullable: nullable);
  }

  AckSchemaModel _boolean(BooleanSchema schema) {
    return AckBooleanSchemaModel(
      description: schema.description,
      nullable: schema.isNullable,
    );
  }

  AckSchemaModel _enum(EnumSchema schema) {
    return AckStringSchemaModel(
      description: schema.description,
      enumValues: [for (final value in schema.values) value.name],
      nullable: schema.isNullable,
    );
  }

  AckSchemaModel _array(ListSchema schema) {
    return AckArraySchemaModel(
      description: schema.description,
      nullable: schema.isNullable,
      items: _build(schema.itemSchema),
    );
  }

  AckSchemaModel _object(ObjectSchema schema) {
    final properties = <String, AckSchemaModel>{};
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

    return AckObjectSchemaModel(
      description: schema.description,
      nullable: schema.isNullable,
      properties: properties.isEmpty ? null : properties,
      required: required.isEmpty ? null : required,
      propertyOrdering: ordering.isEmpty ? null : ordering,
      additionalProperties: schema.additionalProperties
          ? const AckAdditionalPropertiesAllowed()
          : const AckAdditionalPropertiesDisallowed(),
    );
  }

  AckSchemaModel _anyOf(AnyOfSchema schema) {
    return AckAnyOfSchemaModel(
      schemas: schema.schemas.map(_build).toList(growable: false),
      nullable: schema.isNullable,
      description: schema.description,
    );
  }

  AckSchemaModel _instance(InstanceSchema schema) {
    // InstanceSchema accepts arbitrary Dart instances of a runtime type with no
    // direct JSON representation. Adapters that flow through a codec see the
    // boundary schema instead; this is the fallback for a bare instance.
    return AckAnyOfSchemaModel(
      schemas: [
        AckStringSchemaModel(description: schema.description),
        AckNumberSchemaModel(description: schema.description),
        AckIntegerSchemaModel(description: schema.description),
        AckBooleanSchemaModel(description: schema.description),
        AckObjectSchemaModel(description: schema.description),
        AckArraySchemaModel(description: schema.description),
      ],
      nullable: schema.isNullable,
      description: schema.description,
      warnings: const [
        AckSchemaModelWarning(
          code: 'ack_instance_json_boundary',
          message:
              'Ack.instance<T>() accepts arbitrary Dart instances at runtime; JSON-like adapters can only represent JSON-compatible values.',
        ),
      ],
    );
  }

  AckSchemaModel _any(AnySchema schema) {
    final description = schema.description;
    final primitiveBranches = [
      AckStringSchemaModel(description: description),
      AckNumberSchemaModel(description: description),
      AckIntegerSchemaModel(description: description),
      AckBooleanSchemaModel(description: description),
      AckObjectSchemaModel(description: description),
      AckArraySchemaModel(description: description),
    ];

    return AckAnyOfSchemaModel(
      schemas: primitiveBranches,
      nullable: schema.isNullable,
      description: description,
      warnings: const [
        AckSchemaModelWarning(
          code: 'ack_any_json_boundary',
          message:
              'Ack.any() accepts non-null JSON-safe values at runtime, matching the JSON-compatible values adapters can represent.',
        ),
      ],
    );
  }

  AckSchemaModel _discriminated(DiscriminatedObjectSchema schema) {
    if (schema.schemas.isEmpty) {
      return AckObjectSchemaModel(
        properties: const {},
        required: const [],
        nullable: schema.isNullable,
        description: schema.description,
      );
    }

    final branches = <AckSchemaModel>[];
    for (final entry in schema.schemas.entries) {
      final converted = _build(schema.effectiveBranch(entry.key));
      if (converted is! AckObjectSchemaModel) {
        throw ArgumentError(
          'Discriminated branch "${entry.key}" must export as an object schema model.',
        );
      }
      branches.add(
        _withRequiredDiscriminator(converted, schema.discriminatorKey),
      );
    }

    return AckAnyOfSchemaModel(
      schemas: branches,
      discriminator: AckSchemaDiscriminatorModel(
        propertyName: schema.discriminatorKey,
      ),
      description: schema.description,
      nullable: schema.isNullable,
    );
  }

  AckSchemaModel _lazy(LazySchema<dynamic, dynamic> schema) {
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
    _defs[name] = null;
    _defs[name] = _build(target);
    return _lazyRef(schema);
  }

  AckSchemaModel _lazyRef(LazySchema<dynamic, dynamic> schema) {
    var model = AckRefSchemaModel(
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
      AckSchemaModelWarning(
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

/// Strips the synthetic [DefaultSchema] default from the discriminator
/// property in an exported branch model and marks the property as required.
///
/// `effectiveDiscriminatedObjectBranch` attaches `.withDefault(...)` to the
/// synthesized literal so encode can inject the discriminator when the branch
/// runtime omits it; that default is an encode-time convenience, not part of
/// the published JSON Schema.
AckObjectSchemaModel _withRequiredDiscriminator(
  AckObjectSchemaModel model,
  String discriminatorKey,
) {
  final properties = model.properties;
  if (properties == null || !properties.containsKey(discriminatorKey)) {
    return model;
  }

  final discriminator = properties[discriminatorKey]!;
  final normalizedProperties = discriminator.defaultValue == null
      ? properties
      : {...properties, discriminatorKey: discriminator.withDefaultValue(null)};
  final required = model.required ?? const <String>[];
  final alreadyRequired = required.contains(discriminatorKey);
  if (alreadyRequired && identical(normalizedProperties, properties)) {
    return model;
  }

  return AckObjectSchemaModel(
    properties: normalizedProperties,
    required: alreadyRequired ? required : [discriminatorKey, ...required],
    propertyOrdering: model.propertyOrdering,
    minProperties: model.minProperties,
    maxProperties: model.maxProperties,
    additionalProperties: model.additionalProperties,
    title: model.title,
    description: model.description,
    nullable: model.nullable,
    defaultValue: model.defaultValue,
    warnings: model.warnings,
    extensions: model.extensions,
  );
}

AckSchemaModel _applyConstraints(
  AckSchemaModel model,
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

AckSchemaModel _applyDateTimeConstraint(
  AckSchemaModel model,
  DateTimeConstraint constraint,
) {
  return model.withWarnings([
    ...model.warnings,
    AckSchemaModelWarning(
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
