/// JSON Schema Builder converter for ACK validation library.
///
/// Converts ACK validation schemas to json_schema_builder Schema format
/// for JSON Schema Draft 2020-12 validation and documentation.
///
/// ## Usage
///
/// ```dart
/// import 'package:ack/ack.dart';
/// import 'package:ack_json_schema_builder/ack_json_schema_builder.dart';
///
/// final schema = Ack.object({
///   'name': Ack.string().minLength(2),
///   'age': Ack.integer().min(0).optional(),
/// });
///
/// // Convert to json_schema_builder 
/// final jsbSchema = schema.toJsonSchemaBuilder();
/// ```
library;

import 'package:ack/ack.dart';
import 'package:json_schema_builder/json_schema_builder.dart' as jsb;

/// Extension methods for converting ACK schemas to json_schema_builder format.
extension JsonSchemaBuilderExtension on AckSchema {
  /// Converts this ACK schema to json_schema_builder Schema format.
  ///
  /// Returns a json_schema_builder [Schema] instance for JSON Schema Draft 2020-12.
  jsb.Schema toJsonSchemaBuilder() {
    final model = toJsonSchemaModel();
    return _convert(model);
  }
}

// Standalone converter from JsonSchema model to json_schema_builder Schema.
jsb.Schema _convert(JsonSchema schema) {
  final effective = _effective(schema);
  final nullableFlag = schema.nullable ?? effective.nullable;

  switch (effective.type) {
    case JsonSchemaType.string:
      return _convertString(effective, nullableFlag);
    case JsonSchemaType.integer:
      return _convertInteger(effective, nullableFlag);
    case JsonSchemaType.number:
      return _convertNumber(effective, nullableFlag);
    case JsonSchemaType.boolean:
      return _convertBoolean(effective, nullableFlag);
    case JsonSchemaType.array:
      return _convertArray(effective, nullableFlag);
    case JsonSchemaType.object:
      return _convertObject(effective, nullableFlag);
    default:
      // composition handled below
      break;
  }

  if (schema.anyOf != null) {
    return _wrapNullable(
      jsb.Schema.combined(anyOf: schema.anyOf!.map(_convert).toList()),
      nullableFlag,
    );
  }

  if (schema.oneOf != null) {
    return _wrapNullable(
      jsb.Schema.combined(anyOf: schema.oneOf!.map(_convert).toList()),
      nullableFlag,
    );
  }

  // Fallback: typeless -> allow anything
  return jsb.Schema.combined(anyOf: [jsb.Schema.nil(), jsb.Schema.string()]);
}

jsb.Schema _convertString(JsonSchema schema, bool? nullableFlag) {
  final base = jsb.Schema.string(
    enumValues: schema.isEnum ? schema.enum_ : null,
    description: schema.description,
    title: schema.title,
    minLength: schema.minLength,
    maxLength: schema.maxLength,
    pattern: schema.pattern,
    format: schema.format,
  );
  return _wrapNullable(base, nullableFlag);
}

jsb.Schema _convertInteger(JsonSchema schema, bool? nullableFlag) {
  final base = jsb.Schema.integer(
    description: schema.description,
    title: schema.title,
    minimum: schema.minimum?.toInt(),
    maximum: schema.maximum?.toInt(),
  );
  return _wrapNullable(base, nullableFlag);
}

jsb.Schema _convertNumber(JsonSchema schema, bool? nullableFlag) {
  final base = jsb.Schema.number(
    description: schema.description,
    title: schema.title,
    minimum: schema.minimum?.toDouble(),
    maximum: schema.maximum?.toDouble(),
  );
  return _wrapNullable(base, nullableFlag);
}

jsb.Schema _convertBoolean(JsonSchema schema, bool? nullableFlag) {
  final base = jsb.Schema.boolean(
    description: schema.description,
    title: schema.title,
  );
  return _wrapNullable(base, nullableFlag);
}

jsb.Schema _convertArray(JsonSchema schema, bool? nullableFlag) {
  final items = schema.items != null ? _convert(schema.items!) : jsb.Schema.any();
  final base = jsb.Schema.list(
    items: items,
    description: schema.description,
    title: schema.title,
    minItems: schema.minItems,
    maxItems: schema.maxItems,
    uniqueItems: schema.uniqueItems,
  );
  return _wrapNullable(base, nullableFlag);
}

jsb.Schema _convertObject(JsonSchema schema, bool? nullableFlag) {
  final props = <String, jsb.Schema>{};
  for (final entry in schema.properties?.entries ?? const <MapEntry<String, JsonSchema>>[]) {
    props[entry.key] = _wrapProperty(entry.key, () => _convert(entry.value));
  }

  final required = schema.required ?? const [];

  final base = jsb.Schema.object(
    properties: props,
    required: required.isEmpty ? null : required,
    description: schema.description,
    title: schema.title,
    additionalProperties: schema.additionalPropertiesAllowed ?? true,
  );
  return _wrapNullable(base, nullableFlag);
}

jsb.Schema _wrapNullable(jsb.Schema base, bool? isNullable) {
  if (isNullable != true) return base;
  return jsb.Schema.combined(anyOf: [base, jsb.Schema.nil()]);
}

JsonSchema _effective(JsonSchema schema) {
  final anyOf = schema.anyOf;
  if (anyOf == null || anyOf.isEmpty) return schema;
  final nonNull = anyOf.where((b) => b.type != JsonSchemaType.null_).toList();
  if (nonNull.length == 1) {
    return nonNull.first.copyWith(nullable: schema.nullable ?? true);
  }
  return schema;
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
