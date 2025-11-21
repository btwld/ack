/// Firebase AI (Gemini) schema converter for ACK validation library.
///
/// Converts ACK validation schemas to Firebase AI Schema format for structured
/// output generation with Gemini models.
library;

import 'package:ack/ack.dart';
import 'package:firebase_ai/firebase_ai.dart' as firebase_ai;

/// Extension methods for converting ACK schemas to Firebase AI format.
extension FirebaseAiSchemaExtension on AckSchema {
  /// Converts this ACK schema to Firebase AI (Gemini) Schema format.
  firebase_ai.Schema toFirebaseAiSchema() {
    final model = toJsonSchemaModel();
    return _convert(model);
  }
}

// JsonSchema (canonical) -> Firebase AI Schema
firebase_ai.Schema _convert(JsonSchema schema) {
  switch (schema.type) {
    case JsonSchemaType.string:
      return _string(schema);
    case JsonSchemaType.integer:
      return _integer(schema);
    case JsonSchemaType.number:
      return _number(schema);
    case JsonSchemaType.boolean:
      return _boolean(schema);
    case JsonSchemaType.array:
      return _array(schema);
    case JsonSchemaType.object:
      return _object(schema);
    default:
      break;
  }

  if (schema.anyOf != null) {
    final branches = schema.anyOf!.map(_convert).toList();
    return _wrapNullable(
      firebase_ai.Schema(firebase_ai.SchemaType.anyOf, anyOf: branches),
      schema.nullable,
    );
  }

  if (schema.oneOf != null) {
    final branches = schema.oneOf!.map(_convert).toList();
    // Firebase has only anyOf, reuse it
    return _wrapNullable(
      firebase_ai.Schema(firebase_ai.SchemaType.anyOf, anyOf: branches),
      schema.nullable,
    );
  }

  // typeless fallback
  return firebase_ai.Schema(firebase_ai.SchemaType.anyOf, anyOf: []);
}

firebase_ai.Schema _string(JsonSchema schema) {
  final values = schema.isEnum ? schema.enum_ ?? [] : null;
  final base = values != null
      ? firebase_ai.Schema.enumString(
          enumValues: values,
          description: schema.description,
          title: schema.title,
        )
      : firebase_ai.Schema.string(
          description: schema.description,
          title: schema.title,
          format: schema.format,
        );
  return _wrapNullable(base, schema.nullable);
}

firebase_ai.Schema _integer(JsonSchema schema) {
  final base = firebase_ai.Schema.integer(
    description: schema.description,
    title: schema.title,
    minimum: schema.minimum?.toInt(),
    maximum: schema.maximum?.toInt(),
    format: schema.format,
  );
  return _wrapNullable(base, schema.nullable);
}

firebase_ai.Schema _number(JsonSchema schema) {
  final base = firebase_ai.Schema.number(
    description: schema.description,
    title: schema.title,
    minimum: schema.minimum?.toDouble(),
    maximum: schema.maximum?.toDouble(),
    format: schema.format,
  );
  return _wrapNullable(base, schema.nullable);
}

firebase_ai.Schema _boolean(JsonSchema schema) {
  final base = firebase_ai.Schema.boolean(
    description: schema.description,
    title: schema.title,
  );
  return _wrapNullable(base, schema.nullable);
}

firebase_ai.Schema _array(JsonSchema schema) {
  final items = schema.items != null
      ? _convert(schema.items!)
      : firebase_ai.Schema.anyOf(schemas: []);
  final base = firebase_ai.Schema.array(
    items: items,
    description: schema.description,
    title: schema.title,
    minItems: schema.minItems,
    maxItems: schema.maxItems,
  );
  return _wrapNullable(base, schema.nullable);
}

firebase_ai.Schema _object(JsonSchema schema) {
  final properties = <String, firebase_ai.Schema>{};
  for (final entry in schema.properties?.entries ?? const <MapEntry<String, JsonSchema>>[]) {
    properties[entry.key] = _convert(entry.value);
  }

  final optional = <String>[];
  final required = schema.required ?? const [];
  for (final entry in schema.properties?.entries ?? const <MapEntry<String, JsonSchema>>[]) {
    if (!required.contains(entry.key)) {
      optional.add(entry.key);
    }
  }

  final base = firebase_ai.Schema.object(
    properties: properties,
    optionalProperties: optional.isEmpty ? null : optional,
    propertyOrdering: schema.propertyOrdering,
    description: schema.description,
    title: schema.title,
  );
  return _wrapNullable(base, schema.nullable);
}

firebase_ai.Schema _wrapNullable(firebase_ai.Schema base, bool? nullable) {
  if (nullable == true) {
    base.nullable = true;
  }
  return base;
}
