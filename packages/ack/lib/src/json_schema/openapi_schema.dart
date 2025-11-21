library;

import 'package:meta/meta.dart';

/// Subset of the OpenAPI 3.0 Schema Object we care about for LLM output.
///
/// Note: `anyOf` and `oneOf` are not included here as they are composition
/// keywords, not strict types. A schema using them will effectively have
/// a null `type`.
enum OpenApiSchemaType { string, number, integer, boolean, array, object }

@immutable
class OpenApiDiscriminator {
  const OpenApiDiscriminator({required this.propertyName, this.mapping});

  final String propertyName;
  final Map<String, String>? mapping;

  Map<String, Object?> toJson() => {
    'propertyName': propertyName,
    if (mapping case final m?) 'mapping': m,
  };

  factory OpenApiDiscriminator.fromJson(Map<String, Object?> json) {
    final mapping = json['mapping'];
    return OpenApiDiscriminator(
      propertyName: json['propertyName'] as String,
      // SAFE CASTING: Handle cases where map keys/values might be dynamic
      mapping: mapping is Map
          ? Map<String, String>.fromEntries(
              mapping.entries.map(
                (e) => MapEntry(e.key.toString(), e.value.toString()),
              ),
            )
          : null,
    );
  }
}

/// Typed representation of an OpenAPI-aligned schema with pragmatic extras
/// for LLM outputs.
@immutable
class OpenApiSchema {
  const OpenApiSchema({
    this.type,
    this.format,
    this.title,
    this.description,
    this.nullable,
    this.enumValues,
    this.items,
    this.properties,
    this.required,
    this.propertyOrdering,
    this.anyOf,
    this.oneOf,
    this.minItems,
    this.maxItems,
    this.minProperties,
    this.maxProperties,
    this.minLength,
    this.maxLength,
    this.pattern,
    this.minimum,
    this.maximum,
    this.discriminator,
    this.additionalPropertiesSchema,
    this.additionalPropertiesAllowed,
  }) : assert(
         additionalPropertiesSchema == null ||
             additionalPropertiesAllowed == null,
         'Cannot set both schema and boolean for additionalProperties',
       ),
       assert(
         anyOf == null || oneOf == null,
         'Cannot set both anyOf and oneOf. Choose one composition strategy to avoid ambiguity.',
       );

  /// The data type of the schema.
  ///
  /// If null, no type constraint is applied (effectively "any"), or the type
  /// is implied by composition keywords like [anyOf] or [oneOf].
  final OpenApiSchemaType? type;

  final String? format;
  final String? title;
  final String? description;
  final bool? nullable;

  /// Enumerated values for this schema.
  ///
  /// Note: While OpenAPI 3.0 allows mixed types (strings, ints, bools),
  /// specific downstream consumers (like Firebase/Vertex AI) may ONLY support
  /// strings. You may need to stringify these values in your converter.
  final List<Object?>? enumValues;

  final OpenApiSchema? items;
  final Map<String, OpenApiSchema>? properties;
  final List<String>? required;

  /// A non-standard hint used by some LLMs (e.g., Vertex AI) to control
  /// the order of generated JSON fields in structured output.
  final List<String>? propertyOrdering;

  final List<OpenApiSchema>? anyOf;
  final List<OpenApiSchema>? oneOf;

  // --- Validation Constraints ---

  final int? minItems;
  final int? maxItems;
  final int? minProperties;
  final int? maxProperties;
  final int? minLength;
  final int? maxLength;
  final String? pattern;
  final num? minimum;
  final num? maximum;

  final OpenApiDiscriminator? discriminator;

  /// Schema for `additionalProperties` if it is defined as a Schema Object.
  /// Used for Maps/Dictionaries (e.g., `Map<String, int>`).
  final OpenApiSchema? additionalPropertiesSchema;

  /// Boolean value for `additionalProperties` if it is defined as a boolean.
  /// Used for strict object validation (e.g., `false` forbids unknown keys).
  final bool? additionalPropertiesAllowed;

  /// Helper to check if the schema is valid regarding discriminator rules.
  /// Returns false if a discriminator is defined but the property is missing from `required`.
  bool get isValidDiscriminator {
    if (discriminator == null) {
      return true;
    }
    return required?.contains(discriminator!.propertyName) ?? false;
  }

  Map<String, Object?> toJson() {
    return {
      if (type != null) 'type': type!.name,
      if (format != null) 'format': format,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (nullable != null) 'nullable': nullable,
      if (enumValues != null) 'enum': enumValues,
      if (items != null) 'items': items!.toJson(),
      if (properties != null)
        'properties': {
          for (final e in properties!.entries) e.key: e.value.toJson(),
        },
      if (required != null) 'required': required,
      if (propertyOrdering != null) 'propertyOrdering': propertyOrdering,
      if (anyOf != null) 'anyOf': anyOf!.map((s) => s.toJson()).toList(),
      if (oneOf != null) 'oneOf': oneOf!.map((s) => s.toJson()).toList(),

      // Constraints
      if (minItems != null) 'minItems': minItems,
      if (maxItems != null) 'maxItems': maxItems,
      if (minProperties != null) 'minProperties': minProperties,
      if (maxProperties != null) 'maxProperties': maxProperties,
      if (minLength != null) 'minLength': minLength,
      if (maxLength != null) 'maxLength': maxLength,
      if (pattern != null) 'pattern': pattern,
      if (minimum != null) 'minimum': minimum,
      if (maximum != null) 'maximum': maximum,

      if (discriminator != null) 'discriminator': discriminator!.toJson(),

      // LOGIC: Handle the Union Type for additionalProperties
      if (additionalPropertiesSchema != null)
        'additionalProperties': additionalPropertiesSchema!.toJson()
      else if (additionalPropertiesAllowed != null)
        'additionalProperties': additionalPropertiesAllowed,
    }..removeWhere((_, v) => v == null);
  }

  factory OpenApiSchema.fromJson(Map<String, Object?> json) {
    // 1. Helpers for safe recursive parsing
    OpenApiSchema? parseSchema(Object? raw) {
      if (raw is Map) {
        return OpenApiSchema.fromJson(Map<String, Object?>.from(raw));
      }
      return null;
    }

    List<OpenApiSchema>? parseList(Object? raw) {
      if (raw is List) {
        return raw
            .whereType<Map>()
            .map((m) => OpenApiSchema.fromJson(Map<String, Object?>.from(m)))
            .toList();
      }
      return null;
    }

    // 2. Extract logic
    final rawAddProps = json['additionalProperties'];

    final props = json['properties'];
    final properties = props is Map
        ? props.map((k, v) {
            // Ensure keys are strings and values are safely parsed schemas
            return MapEntry(
              k.toString(),
              OpenApiSchema.fromJson(Map<String, Object?>.from(v as Map)),
            );
          })
        : null;

    final discriminatorRaw = json['discriminator'];

    return OpenApiSchema(
      type: _typeFromString(json['type'] as String?),
      format: json['format'] as String?,
      title: json['title'] as String?,
      description: json['description'] as String?,
      nullable: json['nullable'] as bool?,

      // Safe Casting
      enumValues: (json['enum'] as List?)?.cast<Object?>(),
      required: (json['required'] as List?)?.map((e) => e.toString()).toList(),
      propertyOrdering: (json['propertyOrdering'] as List?)
          ?.map((e) => e.toString())
          .toList(),

      // Recursion
      items: parseSchema(json['items']),
      properties: properties,
      anyOf: parseList(json['anyOf']),
      oneOf: parseList(json['oneOf']),

      // Constraints
      minItems: json['minItems'] as int?,
      maxItems: json['maxItems'] as int?,
      minProperties: json['minProperties'] as int?,
      maxProperties: json['maxProperties'] as int?,
      minLength: json['minLength'] as int?,
      maxLength: json['maxLength'] as int?,
      pattern: json['pattern'] as String?,
      minimum: json['minimum'] as num?,
      maximum: json['maximum'] as num?,

      // Complex Objects
      discriminator: discriminatorRaw is Map
          ? OpenApiDiscriminator.fromJson(
              Map<String, Object?>.from(discriminatorRaw),
            )
          : null,
      additionalPropertiesSchema: parseSchema(rawAddProps),
      additionalPropertiesAllowed: rawAddProps is bool ? rawAddProps : null,
    );
  }
}

OpenApiSchemaType? _typeFromString(String? raw) {
  if (raw == null) return null;
  return switch (raw) {
    'string' => OpenApiSchemaType.string,
    'number' => OpenApiSchemaType.number,
    'integer' => OpenApiSchemaType.integer,
    'boolean' => OpenApiSchemaType.boolean,
    'array' => OpenApiSchemaType.array,
    'object' => OpenApiSchemaType.object,
    _ => null,
  };
}
