library;

import 'package:ack/ack.dart';

import '../helpers.dart';

/// Converts ACK schemas to the new JsonSchema (canonical) model.
extension AckToJsonSchemaModel on AckSchema {
  JsonSchema toJsonSchemaModel() => _convert(this);
}

JsonSchema _convert(AckSchema schema) {
  // Parse JSON Schema for constraint metadata (minLength, format, etc.)
  final parsed = JsonSchema.fromJson(schema.toJsonSchema());
  final effective = _unwrapNullable(parsed);
  // Use schema.isNullable directly - canonical source of truth
  final nullableFlag = schema.isNullable;

  if (schema is CodecSchema) {
    final base = _copyScalarMetadata(_convert(schema.inputSchema), effective);
    return base.copyWith(
      description: schema.description ?? base.description,
      nullable: nullableFlag,
    );
  }

  if (schema is DefaultSchema) {
    final base = _copyScalarMetadata(_convert(schema.inner), effective);
    return base.copyWith(
      description: schema.description ?? base.description,
      nullable: nullableFlag || base.nullable == true,
    );
  }

  return switch (schema) {
    StringSchema() => _string(effective, nullableFlag),
    IntegerSchema() => _integer(effective, nullableFlag),
    DoubleSchema() => _number(effective, nullableFlag),
    BooleanSchema() => _boolean(effective, nullableFlag),
    EnumSchema() => _enum(schema, effective, nullableFlag),
    ListSchema() => _array(schema, effective, nullableFlag),
    ObjectSchema() => _object(schema, effective, nullableFlag),
    AnyOfSchema() => _anyOf(schema, effective),
    AnySchema() => _any(schema, effective, nullableFlag),
    DiscriminatedObjectSchema() => _discriminated(
      schema,
      effective,
      nullableFlag,
    ),
    _ => throw UnsupportedError(
      'Schema type ${schema.runtimeType} not supported for JsonSchema conversion.',
    ),
  };
}

JsonSchema _string(JsonSchema json, bool nullableFlag) {
  final isEnum = json.enumValues != null && json.enumValues!.isNotEmpty;
  return _copyCompositionMetadata(
    JsonSchema(
      type: JsonSchemaType.string,
      format: json.format,
      description: json.description,
      title: json.title,
      enumValues: isEnum ? json.enumValues : null,
      constValue: json.constValue,
      hasConstValue: json.hasConstValue,
      defaultValue: json.defaultValue,
      hasDefaultValue: json.hasDefaultValue,
      minLength: json.minLength,
      maxLength: json.maxLength,
      pattern: json.pattern,
      nullable: nullableFlag,
    ),
    json,
  );
}

JsonSchema _integer(JsonSchema json, bool nullableFlag) {
  return JsonSchema(
    type: JsonSchemaType.integer,
    description: json.description,
    title: json.title,
    minimum: json.minimum?.toInt(),
    maximum: json.maximum?.toInt(),
    exclusiveMinimum: json.exclusiveMinimum?.toInt(),
    exclusiveMaximum: json.exclusiveMaximum?.toInt(),
    multipleOf: json.multipleOf?.toInt(),
    constValue: json.constValue,
    hasConstValue: json.hasConstValue,
    defaultValue: json.defaultValue,
    hasDefaultValue: json.hasDefaultValue,
    nullable: nullableFlag,
  );
}

JsonSchema _number(JsonSchema json, bool nullableFlag) {
  return JsonSchema(
    type: JsonSchemaType.number,
    description: json.description,
    title: json.title,
    minimum: json.minimum?.toDouble(),
    maximum: json.maximum?.toDouble(),
    exclusiveMinimum: json.exclusiveMinimum,
    exclusiveMaximum: json.exclusiveMaximum,
    multipleOf: json.multipleOf,
    constValue: json.constValue,
    hasConstValue: json.hasConstValue,
    defaultValue: json.defaultValue,
    hasDefaultValue: json.hasDefaultValue,
    nullable: nullableFlag,
  );
}

JsonSchema _boolean(JsonSchema json, bool nullableFlag) {
  return JsonSchema(
    type: JsonSchemaType.boolean,
    description: json.description,
    title: json.title,
    constValue: json.constValue,
    hasConstValue: json.hasConstValue,
    defaultValue: json.defaultValue,
    hasDefaultValue: json.hasDefaultValue,
    nullable: nullableFlag,
  );
}

JsonSchema _enum(EnumSchema schema, JsonSchema json, bool nullableFlag) {
  final values = [for (final v in schema.values) v.name];
  return JsonSchema(
    type: JsonSchemaType.string,
    description: json.description,
    title: json.title,
    enumValues: values,
    defaultValue: json.defaultValue,
    hasDefaultValue: json.hasDefaultValue,
    nullable: nullableFlag,
  );
}

JsonSchema _array(ListSchema schema, JsonSchema json, bool nullableFlag) {
  final items = _convert(schema.itemSchema);
  return JsonSchema(
    type: JsonSchemaType.array,
    items: items,
    description: json.description,
    title: json.title,
    minItems: json.minItems,
    maxItems: json.maxItems,
    uniqueItems: json.uniqueItems,
    defaultValue: json.defaultValue,
    hasDefaultValue: json.hasDefaultValue,
    nullable: nullableFlag,
  );
}

JsonSchema _object(ObjectSchema schema, JsonSchema json, bool nullableFlag) {
  final props = <String, JsonSchema>{};
  final required = <String>[];
  final ordering = <String>[];

  for (final entry in schema.properties.entries) {
    ordering.add(entry.key);
    props[entry.key] = wrapPropertyConversion(
      entry.key,
      () => _convert(entry.value),
    );
    if (!entry.value.isOptional) {
      required.add(entry.key);
    }
  }

  return JsonSchema(
    type: JsonSchemaType.object,
    properties: props.isEmpty ? null : props,
    required: required.isEmpty ? null : required,
    propertyOrdering: ordering.isEmpty ? null : ordering,
    description: json.description,
    title: json.title,
    minProperties: json.minProperties,
    maxProperties: json.maxProperties,
    additionalPropertiesSchema: json.additionalPropertiesSchema,
    additionalPropertiesAllowed: json.additionalPropertiesAllowed,
    defaultValue: json.defaultValue,
    hasDefaultValue: json.hasDefaultValue,
    nullable: nullableFlag,
  );
}

JsonSchema _anyOf(AnyOfSchema schema, JsonSchema json) {
  final branches = schema.schemas.map(_convert).toList(growable: false);
  return JsonSchema(
    anyOf: branches,
    nullable: schema.isNullable,
    description: schema.description ?? json.description,
    title: json.title,
    defaultValue: json.defaultValue,
    hasDefaultValue: json.hasDefaultValue,
  );
}

JsonSchema _any(AnySchema schema, JsonSchema json, bool nullableFlag) {
  final description = json.description ?? schema.description;
  final primitives = [
    JsonSchema(type: JsonSchemaType.string, description: description),
    JsonSchema(type: JsonSchemaType.number, description: description),
    JsonSchema(type: JsonSchemaType.integer, description: description),
    JsonSchema(type: JsonSchemaType.boolean, description: description),
    JsonSchema(type: JsonSchemaType.object, description: description),
  ];

  final arrayBranch = JsonSchema(
    type: JsonSchemaType.array,
    description: description,
  );

  return JsonSchema(
    anyOf: [...primitives, arrayBranch],
    nullable: nullableFlag,
    description: description,
    defaultValue: json.defaultValue,
    hasDefaultValue: json.hasDefaultValue,
  );
}

JsonSchema _discriminated(
  DiscriminatedObjectSchema schema,
  JsonSchema json,
  bool nullableFlag,
) {
  if (schema.schemas.isEmpty) {
    return JsonSchema(
      type: JsonSchemaType.object,
      properties: const {},
      required: const [],
      nullable: nullableFlag,
      description: schema.description ?? json.description,
    );
  }

  final discriminatorKey = schema.discriminatorKey;
  final branches = <JsonSchema>[];

  for (final entry in schema.schemas.entries) {
    final label = entry.key;
    final originalBranchSchema = entry.value;
    final baseBranchSchema = unwrapWrappers(originalBranchSchema);
    if (baseBranchSchema is! ObjectSchema) {
      throw ArgumentError(
        'Discriminated branches must be object-backed schemas.',
      );
    }

    final conflict = checkDiscriminatorBranchConflict(
      baseBranch: baseBranchSchema,
      discriminatorKey: discriminatorKey,
      label: label,
    );
    if (conflict != null) throw conflict;

    final convertedBranch = _convert(originalBranchSchema);
    final properties = <String, JsonSchema>{
      ...?convertedBranch.properties,
      discriminatorKey: JsonSchema(
        type: JsonSchemaType.string,
        enumValues: [label],
        constValue: label,
      ),
    };
    final required = <String>[
      discriminatorKey,
      ...?convertedBranch.required?.where((field) => field != discriminatorKey),
    ];

    branches.add(
      convertedBranch.copyWith(
        type: JsonSchemaType.object,
        properties: properties,
        required: required,
      ),
    );
  }

  return JsonSchema(
    oneOf: branches,
    discriminator: JsonSchemaDiscriminator(propertyName: discriminatorKey),
    description: schema.description ?? json.description,
    title: json.title,
    defaultValue: json.defaultValue,
    hasDefaultValue: json.hasDefaultValue,
    nullable: nullableFlag,
  );
}

JsonSchema _unwrapNullable(JsonSchema jsonSchema) {
  final anyOf = jsonSchema.anyOf;
  if (anyOf == null || anyOf.isEmpty) return jsonSchema;
  final nonNull = anyOf.where((c) => c.type != JsonSchemaType.null_).toList();
  if (nonNull.length == 1) {
    final base = nonNull.first;
    return base.copyWith(
      nullable: jsonSchema.nullable ?? true,
      // Preserve wrapper metadata if the inner schema didn’t set it.
      description: base.description ?? jsonSchema.description,
      title: base.title ?? jsonSchema.title,
      format: base.format ?? jsonSchema.format,
      constValue: base.hasConstValue ? base.constValue : jsonSchema.constValue,
      hasConstValue: base.hasConstValue || jsonSchema.hasConstValue,
      defaultValue: base.hasDefaultValue
          ? base.defaultValue
          : jsonSchema.defaultValue,
      hasDefaultValue: base.hasDefaultValue || jsonSchema.hasDefaultValue,
    );
  }
  return jsonSchema;
}

JsonSchema _copyCompositionMetadata(JsonSchema base, JsonSchema source) {
  return base.copyWith(
    allOf: source.allOf ?? base.allOf,
    anyOf: source.anyOf ?? base.anyOf,
    oneOf: source.oneOf ?? base.oneOf,
    discriminator: source.discriminator ?? base.discriminator,
  );
}

JsonSchema _copyScalarMetadata(JsonSchema base, JsonSchema source) {
  return base.copyWith(
    format: source.format ?? base.format,
    title: source.title ?? base.title,
    description: source.description ?? base.description,
    enumValues: source.enumValues ?? base.enumValues,
    constValue: source.hasConstValue ? source.constValue : base.constValue,
    hasConstValue: source.hasConstValue || base.hasConstValue,
    defaultValue: source.hasDefaultValue
        ? source.defaultValue
        : base.defaultValue,
    hasDefaultValue: source.hasDefaultValue || base.hasDefaultValue,
    minItems: source.minItems ?? base.minItems,
    maxItems: source.maxItems ?? base.maxItems,
    minProperties: source.minProperties ?? base.minProperties,
    maxProperties: source.maxProperties ?? base.maxProperties,
    minLength: source.minLength ?? base.minLength,
    maxLength: source.maxLength ?? base.maxLength,
    pattern: source.pattern ?? base.pattern,
    minimum: source.minimum ?? base.minimum,
    maximum: source.maximum ?? base.maximum,
    exclusiveMinimum: source.exclusiveMinimum ?? base.exclusiveMinimum,
    exclusiveMaximum: source.exclusiveMaximum ?? base.exclusiveMaximum,
    multipleOf: source.multipleOf ?? base.multipleOf,
    uniqueItems: source.uniqueItems ?? base.uniqueItems,
    allOf: source.allOf ?? base.allOf,
    anyOf: source.anyOf ?? base.anyOf,
    oneOf: source.oneOf ?? base.oneOf,
    discriminator: source.discriminator ?? base.discriminator,
    additionalPropertiesSchema:
        source.additionalPropertiesSchema ?? base.additionalPropertiesSchema,
    additionalPropertiesAllowed:
        source.additionalPropertiesAllowed ?? base.additionalPropertiesAllowed,
  );
}
