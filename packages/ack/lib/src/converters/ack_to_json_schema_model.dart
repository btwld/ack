library;

import 'package:ack/ack.dart';

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

  if (schema is TransformedSchema) {
    final base = _convert(schema.schema);
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
    AnyOfSchema() => _anyOf(schema),
    AnySchema() => _any(schema, effective, nullableFlag),
    DiscriminatedObjectSchema() => _discriminated(schema, effective, nullableFlag),
    _ => throw UnsupportedError(
        'Schema type ${schema.runtimeType} not supported for JsonSchema conversion.',
      ),
  };
}

JsonSchema _string(JsonSchema json, bool nullableFlag) {
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
    props[entry.key] = _wrapProperty(entry.key, () => _convert(entry.value));
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
    );
  }
  return jsonSchema;
}

T _wrapProperty<T>(String key, T Function() fn) {
  try {
    return fn();
  } catch (e, st) {
    final msg = 'Error converting property "$key": ${e is Error ? e.toString() : e}';
    if (e is UnsupportedError) {
      Error.throwWithStackTrace(UnsupportedError(msg), st);
    } else if (e is ArgumentError) {
      Error.throwWithStackTrace(ArgumentError(msg), st);
    } else if (e is StateError) {
      Error.throwWithStackTrace(StateError(msg), st);
    }
    rethrow;
  }
}
