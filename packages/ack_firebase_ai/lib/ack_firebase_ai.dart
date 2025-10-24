/// Firebase AI (Gemini) schema converter for ACK validation library.
///
/// Converts ACK validation schemas to Firebase AI Schema format for use with
/// Gemini structured output generation.
///
/// ## Usage
///
/// ```dart
/// import 'package:ack/ack.dart';
/// import 'package:ack_firebase_ai/ack_firebase_ai.dart';
/// import 'package:firebase_ai/firebase_ai.dart';
///
/// final schema = Ack.object({
///   'name': Ack.string().minLength(2),
///   'age': Ack.integer().min(0).optional(),
/// });
///
/// // Convert to Firebase AI format
/// final geminiSchema = schema.toFirebaseAiSchema();
///
/// // Use with Firebase AI SDK
/// final model = FirebaseAI.instance.generativeModel(
///   model: 'gemini-1.5-pro',
///   generationConfig: GenerationConfig(
///     responseMimeType: 'application/json',
///     responseSchema: geminiSchema,
///   ),
/// );
/// ```
///
/// ## Limitations
///
/// Some ACK features cannot be converted to Firebase AI format:
/// - Custom refinements (`.refine()`) - validate after AI response
/// - Regex patterns (`.matches()`) - use enum or validate after
/// - Default values - Firebase AI doesn't use them
/// - Transformed schemas (`.transform()`) - converts underlying schema with metadata overrides applied
/// - String length constraints - metadata not yet exposed by Firebase AI Schema
library;

import 'package:ack/ack.dart';
import 'package:firebase_ai/firebase_ai.dart' as firebase_ai;

// ============================================================================
// Public Extension API
// ============================================================================

/// Extension methods for converting ACK schemas to Firebase AI format.
extension FirebaseAiSchemaExtension on AckSchema {
  /// Converts this ACK schema to Firebase AI (Gemini) Schema format.
  ///
  /// Returns a Firebase AI [Schema] instance for structured output generation.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final schema = Ack.object({
  ///   'name': Ack.string().minLength(2),
  ///   'age': Ack.integer().min(0).optional(),
  /// });
  ///
  /// final geminiSchema = schema.toFirebaseAiSchema();
  /// ```
  ///
  /// ## Firebase AI Schema Format
  ///
  /// The returned [Schema] follows Firebase AI's schema format (a subset of
  /// OpenAPI 3.0). Key fields include:
  /// - `type`: The schema type (string, integer, number, boolean, object, array)
  /// - `properties`: For object types, map of property names to child schemas
  /// - `optionalProperties`: Keys that are optional (everything else is required)
  /// - `items`: For array types, the schema for array items
  /// - `enumValues`: For enum types, array of allowed values
  /// - `nullable`: Whether the value can be null
  /// - `description`: Human-readable description
  firebase_ai.Schema toFirebaseAiSchema() {
    return _convert(this);
  }
}

// ============================================================================
// Converter Implementation
// ============================================================================

typedef _JsonMap = Map<String, Object?>;

firebase_ai.Schema _convert(AckSchema schema) {
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
      'Schema type ${schema.runtimeType} is not supported for Firebase AI conversion.',
    ),
  };
}

firebase_ai.Schema _convertString(
  StringSchema schema,
  JsonSchema jsonSchema,
) {
  if (jsonSchema.isEnum) {
    return firebase_ai.Schema.enumString(
      enumValues: jsonSchema.enum_!,
      description: jsonSchema.description,
      title: jsonSchema.title,
      nullable: schema.isNullable ? true : null,
    );
  }

  return firebase_ai.Schema.string(
    description: jsonSchema.description,
    title: jsonSchema.title,
    nullable: schema.isNullable ? true : null,
    format: jsonSchema.format,
  );
}

firebase_ai.Schema _convertInteger(
  IntegerSchema schema,
  JsonSchema jsonSchema,
) {
  return firebase_ai.Schema.integer(
    description: jsonSchema.description,
    title: jsonSchema.title,
    nullable: schema.isNullable ? true : null,
    minimum: jsonSchema.minimum?.toInt(),
    maximum: jsonSchema.maximum?.toInt(),
    format: jsonSchema.format,
  );
}

firebase_ai.Schema _convertDouble(
  DoubleSchema schema,
  JsonSchema jsonSchema,
) {
  return firebase_ai.Schema.number(
    description: jsonSchema.description,
    title: jsonSchema.title,
    nullable: schema.isNullable ? true : null,
    minimum: jsonSchema.minimum?.toDouble(),
    maximum: jsonSchema.maximum?.toDouble(),
    format: jsonSchema.format,
  );
}

firebase_ai.Schema _convertBoolean(
  BooleanSchema schema,
  JsonSchema jsonSchema,
) {
  return firebase_ai.Schema.boolean(
    description: jsonSchema.description,
    title: jsonSchema.title,
    nullable: schema.isNullable ? true : null,
  );
}

firebase_ai.Schema _convertObject(
  ObjectSchema schema,
  JsonSchema jsonSchema,
) {
  final propertyOrdering = schema.properties.keys.toList(growable: false);

  final properties = <String, firebase_ai.Schema>{
    for (final entry in schema.properties.entries)
      entry.key: _convert(entry.value),
  };

  final optionalProperties = [
    for (final entry in schema.properties.entries)
      if (entry.value.isOptional) entry.key,
  ];

  return firebase_ai.Schema.object(
    properties: properties,
    optionalProperties: optionalProperties.isEmpty ? null : optionalProperties,
    propertyOrdering: propertyOrdering.isEmpty ? null : propertyOrdering,
    description: jsonSchema.description,
    title: jsonSchema.title,
    nullable: schema.isNullable ? true : null,
  );
}

firebase_ai.Schema _convertArray(
  ListSchema schema,
  JsonSchema jsonSchema,
) {
  final items = _convert(schema.itemSchema);

  return firebase_ai.Schema.array(
    items: items,
    description: jsonSchema.description,
    title: jsonSchema.title,
    nullable: schema.isNullable ? true : null,
    minItems: jsonSchema.minItems,
    maxItems: jsonSchema.maxItems,
  );
}

firebase_ai.Schema _convertEnum(
  EnumSchema schema,
  JsonSchema jsonSchema,
) {
  final enumValues = [
    for (final value in schema.values) value.name,
  ];

  return firebase_ai.Schema.enumString(
    enumValues: enumValues,
    description: jsonSchema.description,
    title: jsonSchema.title,
    nullable: schema.isNullable ? true : null,
  );
}

firebase_ai.Schema _convertAnyOf(
  AnyOfSchema schema,
) {
  final schemas = [
    for (final childSchema in schema.schemas)
      _convert(childSchema),
  ];

  return firebase_ai.Schema(
    firebase_ai.SchemaType.anyOf,
    description: schema.description,
    nullable: schema.isNullable ? true : null,
    anyOf: schemas,
  );
}

firebase_ai.Schema _convertAny(
  AnySchema schema,
  JsonSchema jsonSchema,
) {
  final description = jsonSchema.description ?? schema.description;
  final primitives = _primitiveAnyBranches(description);

  final arrayItems = firebase_ai.Schema(
    firebase_ai.SchemaType.anyOf,
    anyOf: primitives,
  );

  return firebase_ai.Schema(
    firebase_ai.SchemaType.anyOf,
    description: description,
    nullable: schema.isNullable ? true : null,
    anyOf: [
      ...primitives,
      firebase_ai.Schema.array(items: arrayItems, description: description),
    ],
  );
}

firebase_ai.Schema _convertDiscriminated(
  DiscriminatedObjectSchema schema,
) {
  if (schema.schemas.isEmpty) {
    return firebase_ai.Schema.object(
      properties: const {},
      description: schema.description,
      nullable: schema.isNullable ? true : null,
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

    return _convertObject(
      normalized,
      normalizedJsonSchema,
    );
  });

  return firebase_ai.Schema(
    firebase_ai.SchemaType.anyOf,
    description: schema.description,
    nullable: schema.isNullable ? true : null,
    anyOf: branches,
  );
}

List<firebase_ai.Schema> _primitiveAnyBranches(String? description) {
  return [
    firebase_ai.Schema.string(description: description),
    firebase_ai.Schema.number(description: description),
    firebase_ai.Schema.integer(description: description),
    firebase_ai.Schema.boolean(description: description),
    firebase_ai.Schema.object(
      properties: const {},
      description: description,
    ),
  ];
}

void _applyOverrides({
  required firebase_ai.Schema target,
  required _JsonMap source,
  required bool forceNullable,
}) {
  final jsonSchema = JsonSchema.fromJson(source);

  if (jsonSchema.description != null) {
    target.description = jsonSchema.description;
  }

  if (jsonSchema.title != null) {
    target.title = jsonSchema.title;
  }

  if (forceNullable && target.nullable != true) {
    target.nullable = true;
  }
}
