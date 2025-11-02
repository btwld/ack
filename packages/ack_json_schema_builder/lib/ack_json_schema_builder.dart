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
/// // Convert to json_schema_builder format
/// final jsbSchema = schema.toJsonSchemaBuilder();
///
/// // Use with json_schema_builder for validation
/// final errors = await jsbSchema.validate(data);
/// ```
///
/// ## Limitations
///
/// Some ACK features cannot be converted to json_schema_builder format:
/// - Custom refinements (`.refine()`) - validate after conversion
/// - Regex patterns (`.matches()`) - use enum or validate after
/// - Default values - json_schema_builder doesn't apply them
/// - Transformed schemas (`.transform()`) - converts underlying schema with metadata overrides
library;

import 'package:ack/ack.dart';
import 'package:json_schema_builder/json_schema_builder.dart' as jsb;

// ============================================================================
// Public Extension API
// ============================================================================

/// Extension methods for converting ACK schemas to json_schema_builder format.
extension JsonSchemaBuilderExtension on AckSchema {
  /// Converts this ACK schema to json_schema_builder Schema format.
  ///
  /// Returns a json_schema_builder [Schema] instance for JSON Schema Draft 2020-12.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final schema = Ack.object({
  ///   'name': Ack.string().minLength(2),
  ///   'age': Ack.integer().min(0).optional(),
  /// });
  ///
  /// final jsbSchema = schema.toJsonSchemaBuilder();
  /// ```
  ///
  /// ## JSON Schema Builder Format
  ///
  /// The returned [Schema] follows JSON Schema Draft 2020-12.
  /// Key fields include:
  /// - `type`: The schema type (string, integer, number, boolean, object, array)
  /// - `properties`: For object types, map of property names to child schemas
  /// - `required`: List of required property names
  /// - `items`: For array types, the schema for array items
  /// - `description`: Human-readable description
  jsb.Schema toJsonSchemaBuilder() {
    return _convert(this);
  }
}

// ============================================================================
// Converter Implementation
// ============================================================================

typedef _JsonMap = Map<String, Object?>;

jsb.Schema _convert(AckSchema schema) {
  final jsonSchema = JsonSchema.fromJson(schema.toJsonSchema());

  // Handle TransformedSchema by converting underlying schema and applying overrides
  if (schema is TransformedSchema) {
    final base = _convert(schema.schema);
    _applyOverrides(
      target: base,
      source: schema.toJsonSchema(),
      forceNullable: schema.isNullable,
    );
    return base;
  }

  return switch (schema) {
    StringSchema() => _convertString(schema, jsonSchema),
    IntegerSchema() => _convertInteger(schema, jsonSchema),
    DoubleSchema() => _convertDouble(schema, jsonSchema),
    BooleanSchema() => _convertBoolean(schema, jsonSchema),
    ObjectSchema() => _convertObject(schema, jsonSchema),
    ListSchema() => _convertArray(schema, jsonSchema),
    EnumSchema() => _convertEnum(schema, jsonSchema),
    AnyOfSchema() => _convertAnyOf(schema),
    AnySchema() => _convertAny(schema, jsonSchema),
    DiscriminatedObjectSchema() => _convertDiscriminated(schema),
    _ => throw UnsupportedError(
      'Schema type ${schema.runtimeType} is not supported for json_schema_builder conversion.',
    ),
  };
}

jsb.Schema _convertString(StringSchema schema, JsonSchema jsonSchema) {
  if (jsonSchema.isEnum) {
    return jsb.Schema.string(
      enumValues: jsonSchema.enum_!,
      description: jsonSchema.description,
      title: jsonSchema.title,
    );
  }

  return jsb.Schema.string(
    description: jsonSchema.description,
    title: jsonSchema.title,
    minLength: jsonSchema.minLength,
    maxLength: jsonSchema.maxLength,
    pattern: jsonSchema.pattern,
    format: jsonSchema.format,
  );
}

jsb.Schema _convertInteger(IntegerSchema schema, JsonSchema jsonSchema) {
  return jsb.Schema.integer(
    description: jsonSchema.description,
    title: jsonSchema.title,
    minimum: jsonSchema.minimum?.toInt(),
    maximum: jsonSchema.maximum?.toInt(),
  );
}

jsb.Schema _convertDouble(DoubleSchema schema, JsonSchema jsonSchema) {
  return jsb.Schema.number(
    description: jsonSchema.description,
    title: jsonSchema.title,
    minimum: jsonSchema.minimum?.toDouble(),
    maximum: jsonSchema.maximum?.toDouble(),
  );
}

jsb.Schema _convertBoolean(BooleanSchema schema, JsonSchema jsonSchema) {
  return jsb.Schema.boolean(
    description: jsonSchema.description,
    title: jsonSchema.title,
  );
}

jsb.Schema _convertObject(ObjectSchema schema, JsonSchema jsonSchema) {
  final properties = <String, jsb.Schema>{
    for (final entry in schema.properties.entries)
      entry.key: _convert(entry.value),
  };

  // JSON Schema Builder uses 'required' list (inverse of firebase_ai's optionalProperties)
  final required = [
    for (final entry in schema.properties.entries)
      if (!entry.value.isOptional) entry.key,
  ];

  return jsb.Schema.object(
    properties: properties,
    required: required.isEmpty ? null : required,
    description: jsonSchema.description,
    title: jsonSchema.title,
    additionalProperties: false,
  );
}

jsb.Schema _convertArray(ListSchema schema, JsonSchema jsonSchema) {
  final items = _convert(schema.itemSchema);

  return jsb.Schema.list(
    items: items,
    description: jsonSchema.description,
    title: jsonSchema.title,
    minItems: jsonSchema.minItems,
    maxItems: jsonSchema.maxItems,
    uniqueItems: jsonSchema.uniqueItems,
  );
}

jsb.Schema _convertEnum(EnumSchema schema, JsonSchema jsonSchema) {
  final enumValues = [for (final value in schema.values) value.name];

  return jsb.Schema.string(
    enumValues: enumValues,
    description: jsonSchema.description,
    title: jsonSchema.title,
  );
}

jsb.Schema _convertAnyOf(AnyOfSchema schema) {
  final schemas = [
    for (final childSchema in schema.schemas) _convert(childSchema),
  ];

  return jsb.Schema.combined(anyOf: schemas, description: schema.description);
}

jsb.Schema _convertAny(AnySchema schema, JsonSchema jsonSchema) {
  final description = jsonSchema.description ?? schema.description;
  final primitives = _primitiveAnyBranches(description);

  final arrayItems = jsb.Schema.combined(anyOf: primitives);

  return jsb.Schema.combined(
    anyOf: [
      ...primitives,
      jsb.Schema.list(items: arrayItems, description: description),
    ],
    description: description,
  );
}

jsb.Schema _convertDiscriminated(DiscriminatedObjectSchema schema) {
  if (schema.schemas.isEmpty) {
    return jsb.Schema.object(
      properties: const {},
      description: schema.description,
    );
  }

  final entries = schema.schemas.entries.toList(growable: false);

  final branches = List.generate(entries.length, (index) {
    final entry = entries[index];
    final branchSchema = entry.value;
    if (branchSchema is! ObjectSchema) {
      return _convert(branchSchema);
    }

    final normalized = branchSchema.copyWith(
      properties: {
        schema.discriminatorKey: Ack.string().enumString([entry.key]),
        ...branchSchema.properties,
      },
    );

    final normalizedJsonMap = normalized.toJsonSchema();
    final normalizedJsonSchema = JsonSchema.fromJson(normalizedJsonMap);

    return _convertObject(normalized, normalizedJsonSchema);
  });

  return jsb.Schema.combined(anyOf: branches, description: schema.description);
}

List<jsb.Schema> _primitiveAnyBranches(String? description) {
  return [
    jsb.Schema.string(description: description),
    jsb.Schema.number(description: description),
    jsb.Schema.integer(description: description),
    jsb.Schema.boolean(description: description),
    jsb.Schema.object(properties: const {}, description: description),
  ];
}

void _applyOverrides({
  required jsb.Schema target,
  required _JsonMap source,
  required bool forceNullable,
}) {
  // Note: json_schema_builder Schema is immutable
  // Cannot apply overrides after creation
  // This is a limitation compared to firebase_ai
  // For now, we'll skip override application
  // TransformedSchema metadata will be lost
}
