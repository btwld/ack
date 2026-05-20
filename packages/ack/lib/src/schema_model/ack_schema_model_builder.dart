import 'dart:convert';

import '../constraints/constraint.dart';
import '../constraints/datetime_constraint.dart';
import '../json_schema/json_schema_utils.dart';
import '../schemas/schema.dart';
import 'ack_schema_model.dart';
import 'ack_schema_model_warning.dart';

extension AckSchemaModelExtension on AckSchema {
  AckSchemaModel toSchemaModel() => _build(this);
}

AckSchemaModel _build(AckSchema schema) {
  if (schema is TransformedSchema) {
    final base = _build(schema.schema);
    final transformed = _applyConstraints(
      base
          .withDescription(schema.description ?? base.description)
          .withNullable(schema.isNullable || base.nullable)
          .withExtensions({...base.extensions, 'x-transformed': true}),
      schema,
      boundaryFormat: base.format,
    );
    return _withDefaultAndWarnings(transformed, schema);
  }

  final model = switch (schema) {
    StringSchema() => _string(schema),
    IntegerSchema() => _integer(schema),
    DoubleSchema() => _number(schema),
    BooleanSchema() => _boolean(schema),
    EnumSchema() => _enum(schema),
    ListSchema() => _array(schema),
    ObjectSchema() => _object(schema),
    AnyOfSchema() => _anyOf(schema),
    AnySchema() => _any(schema),
    DiscriminatedObjectSchema() => _discriminated(schema),
    _ => throw UnsupportedError(
      'Schema type ${schema.runtimeType} is not supported for AckSchemaModel conversion.',
    ),
  };

  return _withDefaultAndWarnings(_applyConstraints(model, schema), schema);
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

AckSchemaModel _number(DoubleSchema schema) {
  return AckNumberSchemaModel(
    description: schema.description,
    nullable: schema.isNullable,
  );
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
  if (schema.itemSchema.isNullable) {
    throw ArgumentError(
      'Ack.list(...) does not support nullable item schemas yet.',
    );
  }

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
    if (!entry.value.isOptional) {
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
            'Ack.any() accepts arbitrary non-null Dart objects at runtime, but JSON-like adapters can only represent JSON-compatible values.',
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
    branches.add(converted);
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

AckSchemaModel _applyConstraints(
  AckSchemaModel model,
  AckSchema schema, {
  String? boundaryFormat,
}) {
  var next = model;
  for (final constraint in schema.constraints) {
    if (constraint is DateTimeConstraint) {
      next = _applyDateTimeConstraint(
        next,
        constraint,
        boundaryFormat: boundaryFormat ?? next.format,
      );
      continue;
    }

    if (constraint is JsonSchemaSpec) {
      final spec = constraint as JsonSchemaSpec<dynamic>;
      next = next.withJsonSchemaKeywords(spec.toJsonSchema());
    }
  }

  return next;
}

AckSchemaModel _applyDateTimeConstraint(
  AckSchemaModel model,
  DateTimeConstraint constraint, {
  required String? boundaryFormat,
}) {
  final formatted = switch (boundaryFormat) {
    'date' => _dateOnly(constraint.reference),
    'date-time' => constraint.reference.toIso8601String(),
    _ => constraint.reference.toIso8601String(),
  };

  return model.withWarnings([
    ...model.warnings,
    AckSchemaModelWarning(
      code: 'datetime_constraint_not_draft7',
      message:
          'DateTime range constraints are not emitted because JSON Schema Draft-7 has no standard format range keywords.',
      context: {
        'constraint': constraint.type.name,
        'reference': formatted,
        if (boundaryFormat != null) 'format': boundaryFormat,
      },
    ),
  ]);
}

AckSchemaModel _withDefaultAndWarnings(AckSchemaModel model, AckSchema schema) {
  final defaultValue = schema.defaultValue;
  if (defaultValue == null) return model;

  final exportDefault = _exportSafeDefaultOrNull(schema, defaultValue);
  if (exportDefault != null) {
    return model.withDefaultValue(exportDefault);
  }

  return model.withWarnings([
    ...model.warnings,
    AckSchemaModelWarning(
      code: 'default_not_export_safe',
      message:
          'Schema default was omitted because it cannot be represented safely in exported JSON-compatible schema models.',
    ),
  ]);
}

Object? _exportSafeDefaultOrNull(AckSchema schema, Object defaultValue) {
  if (schema is TransformedSchema) {
    return null;
  }

  if (schema is EnumSchema && defaultValue is Enum) {
    return defaultValue.name;
  }

  if (defaultValue is String ||
      defaultValue is num ||
      defaultValue is bool ||
      defaultValue is List ||
      defaultValue is Map) {
    try {
      return jsonDecode(jsonEncode(defaultValue));
    } catch (_) {
      return null;
    }
  }

  return null;
}

String _dateOnly(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
