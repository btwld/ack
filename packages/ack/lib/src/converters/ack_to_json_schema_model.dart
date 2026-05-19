library;

import 'package:ack/ack.dart';

/// Converts ACK schemas to the new JsonSchema (canonical) model.
extension AckToJsonSchemaModel on AnyAckSchema {
  JsonSchema toJsonSchemaModel() => _convert(this);
}

JsonSchema _convert(AnyAckSchema schema) {
  final parsed = JsonSchema.fromJson(schema.toJsonSchema());
  final effective = _unwrapNullable(parsed);
  final nullableFlag = schema.isNullable;

  // Wrapper schemas delegate boundary structure to their inner schema, then
  // merge wrapper-emitted metadata such as description, nullability, format,
  // enum values, and constraints back onto the converted model.
  final wrappedInner = switch (schema) {
    WrapperSchema(:final inner) => inner,
    _ => null,
  };
  if (wrappedInner != null) {
    final base = _convert(wrappedInner);
    return _mergeWrapperMetadata(
      base: base,
      wrapper: effective,
      schema: schema,
      nullableFlag: nullableFlag,
    );
  }

  return switch (schema) {
    StringSchema() => _string(effective, nullableFlag),
    IntegerSchema() => _integer(effective, nullableFlag),
    DoubleSchema() => _number(effective, nullableFlag),
    NumberSchema() => _number(effective, nullableFlag),
    BooleanSchema() => _boolean(effective, nullableFlag),
    EnumSchema() => _enum(schema, effective, nullableFlag),
    ListSchema() => _array(schema, effective, nullableFlag),
    ObjectSchema() => _object(schema, effective, nullableFlag),
    AnyOfSchema() => _anyOf(schema),
    AnySchema() => _any(schema, effective, nullableFlag),
    InstanceSchema() => _any(schema, effective, nullableFlag),
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

JsonSchema _mergeWrapperMetadata({
  required JsonSchema base,
  required JsonSchema wrapper,
  required AnyAckSchema schema,
  required bool nullableFlag,
}) {
  return base.copyWith(
    description: schema.description ?? wrapper.description ?? base.description,
    defaultValue: wrapper.defaultValue ?? base.defaultValue,
    title: wrapper.title ?? base.title,
    nullable: nullableFlag || wrapper.nullable == true || base.nullable == true,
    format: wrapper.format ?? base.format,
    enumValues: wrapper.enumValues ?? base.enumValues,
    minItems: wrapper.minItems ?? base.minItems,
    maxItems: wrapper.maxItems ?? base.maxItems,
    minProperties: wrapper.minProperties ?? base.minProperties,
    maxProperties: wrapper.maxProperties ?? base.maxProperties,
    minLength: wrapper.minLength ?? base.minLength,
    maxLength: wrapper.maxLength ?? base.maxLength,
    pattern: wrapper.pattern ?? base.pattern,
    minimum: wrapper.minimum ?? base.minimum,
    maximum: wrapper.maximum ?? base.maximum,
    exclusiveMinimum: wrapper.exclusiveMinimum ?? base.exclusiveMinimum,
    exclusiveMaximum: wrapper.exclusiveMaximum ?? base.exclusiveMaximum,
    multipleOf: wrapper.multipleOf ?? base.multipleOf,
    uniqueItems: wrapper.uniqueItems ?? base.uniqueItems,
  );
}

JsonSchema _string(JsonSchema json, bool nullableFlag) {
  final hasEnum = json.enumValues?.isNotEmpty ?? false;
  return JsonSchema(
    type: JsonSchemaType.string,
    format: json.format,
    description: json.description,
    title: json.title,
    enumValues: hasEnum ? json.enumValues : null,
    minLength: json.minLength,
    maxLength: json.maxLength,
    pattern: json.pattern,
    nullable: nullableFlag,
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
    nullable: nullableFlag,
  );
}

JsonSchema _boolean(JsonSchema json, bool nullableFlag) {
  return JsonSchema(
    type: JsonSchemaType.boolean,
    description: json.description,
    title: json.title,
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
    if (!entry.value.isOptional &&
        entry.value is! DefaultSchema<dynamic, dynamic>) {
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
    nullable: nullableFlag,
  );
}

JsonSchema _anyOf(AnyOfSchema schema) {
  final branches = schema.schemas.map(_convert).toList(growable: false);
  return JsonSchema(
    anyOf: branches,
    nullable: schema.isNullable,
    description: schema.description,
  );
}

JsonSchema _any(AnyAckSchema schema, JsonSchema json, bool nullableFlag) {
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
  );
}

JsonSchema _discriminated(
  DiscriminatedObjectSchema schema,
  JsonSchema json,
  bool nullableFlag,
) {
  final discriminatorKey = schema.discriminatorKey;
  final branches = <JsonSchema>[];

  for (final entry in schema.schemas.entries) {
    final label = entry.key;
    final originalBranchSchema = entry.value;
    final convertedBranch = _convert(originalBranchSchema);
    final properties = <String, JsonSchema>{
      ...?convertedBranch.properties,
      discriminatorKey: JsonSchema(
        type: JsonSchemaType.string,
        enumValues: [label],
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
      description: base.description ?? jsonSchema.description,
      title: base.title ?? jsonSchema.title,
      format: base.format ?? jsonSchema.format,
    );
  }
  return jsonSchema;
}
