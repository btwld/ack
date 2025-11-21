library;

import 'package:ack/ack.dart';

/// Converts ACK schemas to the new JsonSchema (formerly OpenAPI-style) model.
extension AckToJsonSchemaModel on AckSchema {
  JsonSchema toJsonSchemaModel() => _convert(this);
}

JsonSchema _convert(AckSchema schema) {
  // If schema already has a toJsonSchema map, parse it for metadata when useful
  final jsonSchema = JsonSchema.fromJson(schema.toJsonSchema());

  if (schema is TransformedSchema) {
    final base = _convert(schema.schema);
    return base.copyWith(
      description: schema.description ?? base.description,
      nullable: schema.isNullable || base.nullable == true,
    );
  }

  return switch (schema) {
    StringSchema() => _string(schema, jsonSchema),
    IntegerSchema() => _integer(schema, jsonSchema),
    DoubleSchema() => _number(schema, jsonSchema),
    BooleanSchema() => _boolean(schema, jsonSchema),
    EnumSchema() => _enum(schema, jsonSchema),
    ListSchema() => _array(schema, jsonSchema),
    ObjectSchema() => _object(schema, jsonSchema),
    AnyOfSchema() => _anyOf(schema),
    AnySchema() => _any(schema, jsonSchema),
    DiscriminatedObjectSchema() => _discriminated(schema, jsonSchema),
    _ => throw UnsupportedError(
        'Schema type ${schema.runtimeType} not supported for JsonSchema conversion.',
      ),
  };
}

JsonSchema _string(StringSchema _, JsonSchema json) {
  final isEnum = json.enumValues != null && json.enumValues!.isNotEmpty;
  return JsonSchema(
    type: JsonSchemaType.string,
    format: json.format,
    description: json.description,
    title: json.title,
    enumValues: isEnum ? json.enumValues : null,
    minLength: json.minLength,
    maxLength: json.maxLength,
    pattern: json.pattern,
    nullable: json.nullable,
  );
}

JsonSchema _integer(IntegerSchema _, JsonSchema json) {
  return JsonSchema(
    type: JsonSchemaType.integer,
    description: json.description,
    title: json.title,
    minimum: json.minimum?.toInt(),
    maximum: json.maximum?.toInt(),
    nullable: json.nullable,
  );
}

JsonSchema _number(DoubleSchema _, JsonSchema json) {
  return JsonSchema(
    type: JsonSchemaType.number,
    description: json.description,
    title: json.title,
    minimum: json.minimum?.toDouble(),
    maximum: json.maximum?.toDouble(),
    nullable: json.nullable,
  );
}

JsonSchema _boolean(BooleanSchema _, JsonSchema json) {
  return JsonSchema(
    type: JsonSchemaType.boolean,
    description: json.description,
    title: json.title,
    nullable: json.nullable,
  );
}

JsonSchema _enum(EnumSchema schema, JsonSchema json) {
  final values = [for (final v in schema.values) v.name];
  return JsonSchema(
    type: JsonSchemaType.string,
    description: json.description,
    title: json.title,
    enumValues: values,
    nullable: json.nullable,
  );
}

JsonSchema _array(ListSchema schema, JsonSchema json) {
  final items = _convert(schema.itemSchema);
  return JsonSchema(
    type: JsonSchemaType.array,
    items: items,
    description: json.description,
    title: json.title,
    minItems: json.minItems,
    maxItems: json.maxItems,
    nullable: json.nullable,
  );
}

JsonSchema _object(ObjectSchema schema, JsonSchema json) {
  final props = <String, JsonSchema>{};
  final required = <String>[];
  final ordering = <String>[];

  for (final entry in schema.properties.entries) {
    ordering.add(entry.key);
    props[entry.key] = _convert(entry.value);
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
    additionalPropertiesSchema: json.additionalPropertiesSchema,
    additionalPropertiesAllowed: json.additionalPropertiesAllowed,
    nullable: json.nullable,
  );
}

JsonSchema _anyOf(AnyOfSchema schema) {
  final branches = schema.schemas.map(_convert).toList(growable: false);
  return JsonSchema(
    anyOf: branches,
    nullable: schema.isNullable,
  );
}

JsonSchema _any(AnySchema schema, JsonSchema json) {
  final primitives = [
    JsonSchema(type: JsonSchemaType.string, description: json.description),
    JsonSchema(type: JsonSchemaType.number, description: json.description),
    JsonSchema(type: JsonSchemaType.integer, description: json.description),
    JsonSchema(type: JsonSchemaType.boolean, description: json.description),
    JsonSchema(type: JsonSchemaType.object, description: json.description),
  ];

  final arrayBranch = JsonSchema(
    type: JsonSchemaType.array,
    items: JsonSchema(anyOf: primitives),
    description: json.description,
  );

  return JsonSchema(
    anyOf: [...primitives, arrayBranch],
    nullable: schema.isNullable,
    description: json.description,
  );
}

JsonSchema _discriminated(
  DiscriminatedObjectSchema schema,
  JsonSchema json,
  ) {
  if (schema.schemas.isEmpty) {
    return JsonSchema(
      type: JsonSchemaType.object,
      properties: const {},
      required: const [],
      nullable: schema.isNullable,
      description: schema.description ?? json.description,
    );
  }

  final discriminatorKey = schema.discriminatorKey;
  final branches = <JsonSchema>[];

  for (final entry in schema.schemas.entries) {
    final label = entry.key;
    final branchSchema = entry.value;
    if (branchSchema is! ObjectSchema) {
      branches.add(_convert(branchSchema));
      continue;
    }

    if (branchSchema.properties.containsKey(discriminatorKey)) {
      throw ArgumentError(
        'Discriminator key "$discriminatorKey" conflicts with existing property in branch "$label".',
      );
    }

    final normalized = branchSchema.copyWith(
      properties: {
        ...branchSchema.properties,
        discriminatorKey: Ack.string().enumString([label]),
      },
    );

     branches.add(_convert(normalized));
   }
 
  return JsonSchema(
    oneOf: branches,
    discriminator: JsonSchemaDiscriminator(propertyName: discriminatorKey),
    description: schema.description ?? json.description,
    nullable: schema.isNullable,
  );
}
