library;

import 'package:ack/ack.dart' hide JsonMap;

/// Converts ACK schemas to the OpenAPI-leaning [OpenApiSchema] model.
extension AckToOpenApiSchema on AckSchema {
  OpenApiSchema toOpenApiSchema() => _convert(this);
}

OpenApiSchema _convert(AckSchema schema) {
  final jsonSchema = JsonSchema.fromJson(schema.toJsonSchema());
  final effectiveJson = _unwrapNullable(jsonSchema);

  if (schema is TransformedSchema) {
    // Convert underlying, then apply description/nullable on top.
    final base = _convert(schema.schema);
    return base.copyWith(
      description: schema.description ?? base.description,
      nullable: schema.isNullable || base.nullable == true,
    );
  }

  return switch (schema) {
    StringSchema() => _string(schema, effectiveJson),
    IntegerSchema() => _integer(schema, effectiveJson),
    DoubleSchema() => _number(schema, effectiveJson),
    BooleanSchema() => _boolean(schema, effectiveJson),
    EnumSchema() => _enum(schema, effectiveJson),
    ListSchema() => _array(schema, effectiveJson),
    ObjectSchema() => _object(schema, effectiveJson),
    AnyOfSchema() => _anyOf(schema),
    AnySchema() => _any(schema, effectiveJson),
    DiscriminatedObjectSchema() => _discriminated(schema, effectiveJson),
    _ => throw UnsupportedError(
        'Schema type ${schema.runtimeType} not supported for OpenApiSchema conversion.',
      ),
  };
}

OpenApiSchema _string(StringSchema _, JsonSchema json) {
  final isEnum = json.enum_ != null && json.enum_!.isNotEmpty;
  return OpenApiSchema(
    type: OpenApiSchemaType.string,
    format: json.format,
    description: json.description,
    title: json.title,
    enumValues: isEnum ? json.enum_ : null,
    minLength: json.minLength,
    maxLength: json.maxLength,
    pattern: json.pattern,
    nullable: _acceptsNull(json),
  );
}

OpenApiSchema _integer(IntegerSchema _, JsonSchema json) {
  return OpenApiSchema(
    type: OpenApiSchemaType.integer,
    description: json.description,
    title: json.title,
    minimum: json.minimum?.toInt(),
    maximum: json.maximum?.toInt(),
    nullable: _acceptsNull(json),
  );
}

OpenApiSchema _number(DoubleSchema _, JsonSchema json) {
  return OpenApiSchema(
    type: OpenApiSchemaType.number,
    description: json.description,
    title: json.title,
    minimum: json.minimum?.toDouble(),
    maximum: json.maximum?.toDouble(),
    nullable: _acceptsNull(json),
  );
}

OpenApiSchema _boolean(BooleanSchema _, JsonSchema json) {
  return OpenApiSchema(
    type: OpenApiSchemaType.boolean,
    description: json.description,
    title: json.title,
    nullable: _acceptsNull(json),
  );
}

OpenApiSchema _enum(EnumSchema schema, JsonSchema json) {
  final values = [for (final v in schema.values) v.name];
  return OpenApiSchema(
    type: OpenApiSchemaType.string,
    description: json.description,
    title: json.title,
    enumValues: values,
    nullable: _acceptsNull(json),
  );
}

OpenApiSchema _array(ListSchema schema, JsonSchema json) {
  final items = _convert(schema.itemSchema);
  return OpenApiSchema(
    type: OpenApiSchemaType.array,
    items: items,
    description: json.description,
    title: json.title,
    minItems: json.minItems,
    maxItems: json.maxItems,
    nullable: _acceptsNull(json),
  );
}

OpenApiSchema _object(ObjectSchema schema, JsonSchema json) {
  final props = <String, OpenApiSchema>{};
  final required = <String>[];
  final ordering = <String>[];

  for (final entry in schema.properties.entries) {
    ordering.add(entry.key);
    props[entry.key] = _convert(entry.value);
    if (!entry.value.isOptional) {
      required.add(entry.key);
    }
  }

  return OpenApiSchema(
    type: OpenApiSchemaType.object,
    properties: props.isEmpty ? null : props,
    required: required.isEmpty ? null : required,
    propertyOrdering: ordering.isEmpty ? null : ordering,
    description: json.description,
    title: json.title,
    additionalPropertiesSchema: json.additionalProperties == false
        ? null
        : null, // schema-valued addlProps not emitted by Ack JSON today
    additionalPropertiesAllowed: json.additionalProperties,
    nullable: _acceptsNull(json),
  );
}

OpenApiSchema _anyOf(AnyOfSchema schema) {
  final branches = schema.schemas.map(_convert).toList(growable: false);
  return OpenApiSchema(
    anyOf: branches,
    nullable: schema.isNullable,
  );
}

OpenApiSchema _any(AnySchema schema, JsonSchema json) {
  // Represent "any" as a composition of primitives + object + array(any).
  final primitives = [
    OpenApiSchema(type: OpenApiSchemaType.string, description: json.description),
    OpenApiSchema(type: OpenApiSchemaType.number, description: json.description),
    OpenApiSchema(type: OpenApiSchemaType.integer, description: json.description),
    OpenApiSchema(type: OpenApiSchemaType.boolean, description: json.description),
    OpenApiSchema(type: OpenApiSchemaType.object, description: json.description),
  ];

  final arrayBranch = OpenApiSchema(
    type: OpenApiSchemaType.array,
    items: OpenApiSchema(anyOf: primitives),
    description: json.description,
  );

  return OpenApiSchema(
    anyOf: [...primitives, arrayBranch],
    nullable: schema.isNullable,
    description: json.description,
  );
}

OpenApiSchema _discriminated(
  DiscriminatedObjectSchema schema,
  JsonSchema json,
  ) {
  if (schema.schemas.isEmpty) {
    return OpenApiSchema(
      type: OpenApiSchemaType.object,
      properties: const {},
      required: const [],
      nullable: schema.isNullable,
      description: schema.description ?? json.description,
    );
  }

  final discriminatorKey = schema.discriminatorKey;
  final branches = <OpenApiSchema>[];

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

    final branchJson = JsonSchema.fromJson(normalized.toJsonSchema());
    branches.add(_object(normalized, branchJson));
  }

  return OpenApiSchema(
    oneOf: branches,
    discriminator: OpenApiDiscriminator(propertyName: discriminatorKey),
    description: schema.description ?? json.description,
    nullable: schema.isNullable,
  );
}

// Helpers

JsonSchema _unwrapNullable(JsonSchema jsonSchema) {
  final anyOf = jsonSchema.anyOf;
  if (anyOf == null || anyOf.isEmpty) return jsonSchema;

  final nonNull =
      anyOf.where((candidate) => !_isNullSchema(candidate)).toList(growable: false);
  if (nonNull.length == 1) return nonNull.first;
  return jsonSchema;
}

bool _acceptsNull(JsonSchema schema) {
  if (schema.acceptsNull) return true;
  final anyOf = schema.anyOf;
  if (anyOf == null) return false;
  return anyOf.any(_isNullSchema);
}

bool _isNullSchema(JsonSchema schema) {
  if (schema.singleType == JsonSchemaType.null_) return true;
  final types = schema.type;
  if (types != null && types.contains(JsonSchemaType.null_)) {
    return types.length == 1;
  }
  final nested = schema.anyOf;
  if (nested == null || nested.isEmpty) return false;
  return nested.every(_isNullSchema);
}

extension on OpenApiSchema {
  OpenApiSchema copyWith({
    String? title,
    String? description,
    bool? nullable,
  }) {
    return OpenApiSchema(
      type: type,
      format: format,
      title: title ?? this.title,
      description: description ?? this.description,
      nullable: nullable ?? this.nullable,
      enumValues: enumValues,
      items: items,
      properties: properties,
      required: required,
      propertyOrdering: propertyOrdering,
      anyOf: anyOf,
      oneOf: oneOf,
      minItems: minItems,
      maxItems: maxItems,
      minProperties: minProperties,
      maxProperties: maxProperties,
      minLength: minLength,
      maxLength: maxLength,
      pattern: pattern,
      minimum: minimum,
      maximum: maximum,
      discriminator: discriminator,
      additionalPropertiesSchema: additionalPropertiesSchema,
      additionalPropertiesAllowed: additionalPropertiesAllowed,
    );
  }
}
