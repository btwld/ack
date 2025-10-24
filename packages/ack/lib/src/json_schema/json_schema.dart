import 'package:meta/meta.dart';

import 'json_schema_type.dart';
import 'well_known_format.dart';

typedef JsonMap = Map<String, Object?>;

/// Typed representation of a JSON Schema Draft-7 document.
///
/// This implementation covers the most commonly used JSON Schema features
/// with strong typing and pattern matching support. It is designed to work
/// seamlessly with ACK-generated schemas and provides good coverage of
/// Draft-7 features.
///
/// ## Supported Features
///
/// - ✅ All primitive types (string, number, integer, boolean, null, array, object)
/// - ✅ Union types (`{"type": ["string", "null"]}`)
/// - ✅ Typeless schemas with constraining keywords (enum without type)
/// - ✅ All string constraints (minLength, maxLength, pattern, format)
/// - ✅ All numeric constraints (minimum, maximum, multipleOf, exclusive bounds)
/// - ✅ Array constraints (minItems, maxItems, uniqueItems, items schema)
/// - ✅ Object constraints (properties, required, additionalProperties as boolean)
/// - ✅ Composition keywords (anyOf, allOf, oneOf)
/// - ✅ Metadata (title, description)
/// - ✅ Well-known formats with enum support
///
/// ## Known Limitations
///
/// The following Draft-07 features are not yet supported:
///
/// - ❌ **Non-string enum values**: `enum_` is modeled as `List<String>`, so
///   numeric/boolean/object enums are stringified and cannot round-trip.
///   Example: `{"enum": [1, 2, true]}` becomes `["1", "2", "true"]`
///
/// - ❌ **Schema-valued `additionalProperties`**: Only boolean values are
///   supported. Schema objects are ignored during parsing.
///   Example: `{"additionalProperties": {"type": "string"}}` → `null`
///
/// - ❌ **Tuple validation**: `items` only supports single schema (list validation).
///   Tuple form with array of schemas is not supported.
///   Example: `{"items": [{"type": "string"}, {"type": "number"}]}` → fails
///
/// These limitations don't affect ACK-generated schemas. If you need full
/// Draft-07 support for these features, they can be added in future updates.
///
/// ## Example Usage
///
/// ```dart
/// // Parse from JSON
/// final schema = JsonSchema.fromJson({
///   'type': ['string', 'null'],  // Union type
///   'minLength': 5,
///   'format': 'email'
/// });
///
/// // Type-safe access
/// print(schema.acceptsNull);        // true
/// print(schema.singleType);         // null (multiple types)
/// print(schema.minLength);          // 5
/// print(schema.wellKnownFormat);    // WellKnownFormat.email
///
/// // Serialize back to JSON
/// final json = schema.toJson();
/// // {'type': ['string', 'null'], 'minLength': 5, 'format': 'email'}
/// ```
///
/// ## Typeless Schemas
///
/// Schemas with constraining keywords don't require a `type` field:
///
/// ```dart
/// // Enum without type (valid Draft-07)
/// final colorSchema = JsonSchema.fromJson({
///   'enum': ['red', 'green', 'blue']
/// });
///
/// // Properties without type (valid Draft-07)
/// final userSchema = JsonSchema.fromJson({
///   'properties': {
///     'name': {'type': 'string'}
///   },
///   'required': ['name']
/// });
/// ```
///
/// See: https://json-schema.org/draft-07/json-schema-core.html
@immutable
class JsonSchema {
  // ==========================================================================
  // Core Fields
  // ==========================================================================

  /// The type(s) of this schema.
  ///
  /// Can be a single type or multiple types (union type).
  /// Optional for composition schemas (anyOf/allOf/oneOf) or empty schemas.
  ///
  /// Examples:
  /// - `[JsonSchemaType.string]` → `{"type": "string"}`
  /// - `[JsonSchemaType.string, JsonSchemaType.null_]` → `{"type": ["string", "null"]}`
  /// - `null` → no type constraint (composition/empty schema)
  final List<JsonSchemaType>? type;

  /// The format of the data (semantic hint).
  ///
  /// For string types: email, uri, uuid, date, date-time, etc.
  /// For numeric types: int32, int64, float, double.
  ///
  /// See [WellKnownFormat] for standard format values.
  final String? format;

  /// A human-readable title for the schema.
  ///
  /// Used for documentation and UI generation.
  final String? title;

  /// A description of the schema's purpose.
  ///
  /// Can be used for documentation, error messages, or UI hints.
  final String? description;

  // ==========================================================================
  // String Constraints
  // ==========================================================================

  /// Minimum length for string values.
  ///
  /// Only applicable when `type` is `string`.
  final int? minLength;

  /// Maximum length for string values.
  ///
  /// Only applicable when `type` is `string`.
  final int? maxLength;

  /// Regular expression pattern for string values.
  ///
  /// Only applicable when `type` is `string`.
  /// Pattern follows ECMA 262 regular expression dialect.
  final String? pattern;

  /// Enumerated string values.
  ///
  /// When present, the value must be one of these strings.
  /// Only applicable when `type` is `string`.
  final List<String>? enum_;

  // ==========================================================================
  // Numeric Constraints
  // ==========================================================================

  /// Minimum value for numeric types (inclusive).
  ///
  /// Only applicable when `type` is `number` or `integer`.
  final num? minimum;

  /// Maximum value for numeric types (inclusive).
  ///
  /// Only applicable when `type` is `number` or `integer`.
  final num? maximum;

  /// Minimum value for numeric types (exclusive).
  ///
  /// Only applicable when `type` is `number` or `integer`.
  final num? exclusiveMinimum;

  /// Maximum value for numeric types (exclusive).
  ///
  /// Only applicable when `type` is `number` or `integer`.
  final num? exclusiveMaximum;

  /// The value must be a multiple of this number.
  ///
  /// Only applicable when `type` is `number` or `integer`.
  final num? multipleOf;

  // ==========================================================================
  // Array Constraints
  // ==========================================================================

  /// Schema for array items.
  ///
  /// Only applicable when `type` is `array`.
  /// All items in the array must conform to this schema.
  final JsonSchema? items;

  /// Minimum number of items in an array.
  ///
  /// Only applicable when `type` is `array`.
  final int? minItems;

  /// Maximum number of items in an array.
  ///
  /// Only applicable when `type` is `array`.
  final int? maxItems;

  /// Whether all items in an array must be unique.
  ///
  /// Only applicable when `type` is `array`.
  final bool? uniqueItems;

  // ==========================================================================
  // Object Constraints
  // ==========================================================================

  /// Schema definitions for object properties.
  ///
  /// Only applicable when `type` is `object`.
  /// Maps property names to their schemas.
  final Map<String, JsonSchema>? properties;

  /// List of required property names.
  ///
  /// Only applicable when `type` is `object`.
  /// Properties in this list must be present in valid objects.
  final List<String>? required;

  /// Whether additional properties are allowed in objects.
  ///
  /// Only applicable when `type` is `object`.
  /// - `true`: Additional properties allowed
  /// - `false`: Additional properties forbidden
  /// - `null`: Not specified (typically allows additional properties)
  final bool? additionalProperties;

  // ==========================================================================
  // Composition Keywords
  // ==========================================================================

  /// The value must validate against ANY of these schemas.
  ///
  /// Used for union types or alternatives.
  final List<JsonSchema>? anyOf;

  /// The value must validate against ALL of these schemas.
  ///
  /// Used for combining multiple constraints.
  final List<JsonSchema>? allOf;

  /// The value must validate against EXACTLY ONE of these schemas.
  ///
  /// Used for mutually exclusive alternatives.
  final List<JsonSchema>? oneOf;

  // ==========================================================================
  // Constructor
  // ==========================================================================

  /// Creates a new JSON Schema with the specified constraints.
  ///
  /// The [type] field is optional for composition schemas or empty schemas.
  /// All other fields are optional and should only be used when applicable
  /// to the schema type.
  const JsonSchema({
    this.type,
    this.format,
    this.title,
    this.description,
    this.minLength,
    this.maxLength,
    this.pattern,
    this.enum_,
    this.minimum,
    this.maximum,
    this.exclusiveMinimum,
    this.exclusiveMaximum,
    this.multipleOf,
    this.items,
    this.minItems,
    this.maxItems,
    this.uniqueItems,
    this.properties,
    this.required,
    this.additionalProperties,
    this.anyOf,
    this.allOf,
    this.oneOf,
  });

  // ==========================================================================
  // Convenience Getters
  // ==========================================================================

  /// Returns the well-known format if [format] is recognized.
  ///
  /// Returns `null` if the format is custom/unknown.
  ///
  /// Example:
  /// ```dart
  /// final schema = JsonSchema.fromJson({'type': 'string', 'format': 'email'});
  /// print(schema.wellKnownFormat); // WellKnownFormat.email
  /// ```
  WellKnownFormat? get wellKnownFormat => WellKnownFormat.parse(format);

  /// Returns `true` if this is an enum schema (has enumerated values).
  ///
  /// Example:
  /// ```dart
  /// final schema = JsonSchema.fromJson({
  ///   'type': 'string',
  ///   'enum': ['red', 'green', 'blue'],
  /// });
  /// print(schema.isEnum); // true
  /// ```
  bool get isEnum => enum_ != null && enum_!.isNotEmpty;

  /// Returns `true` if the format is custom (not a well-known format).
  ///
  /// Example:
  /// ```dart
  /// final schema = JsonSchema.fromJson({
  ///   'type': 'string',
  ///   'format': 'my-custom-format',
  /// });
  /// print(schema.isCustomFormat); // true
  /// ```
  bool get isCustomFormat => format != null && wellKnownFormat == null;

  /// Returns the single type if there's only one type, null otherwise.
  ///
  /// Useful for backward compatibility when checking a single type.
  ///
  /// Example:
  /// ```dart
  /// final stringSchema = JsonSchema.fromJson({'type': 'string'});
  /// print(stringSchema.singleType); // JsonSchemaType.string
  ///
  /// final unionSchema = JsonSchema.fromJson({'type': ['string', 'null']});
  /// print(unionSchema.singleType); // null (multiple types)
  /// ```
  JsonSchemaType? get singleType {
    return type?.length == 1 ? type!.first : null;
  }

  /// Returns `true` if this schema accepts values of the specified type.
  ///
  /// Example:
  /// ```dart
  /// final schema = JsonSchema.fromJson({'type': ['string', 'null']});
  /// print(schema.acceptsType(JsonSchemaType.string)); // true
  /// print(schema.acceptsType(JsonSchemaType.null_)); // true
  /// print(schema.acceptsType(JsonSchemaType.number)); // false
  /// ```
  bool acceptsType(JsonSchemaType checkType) {
    return type?.contains(checkType) ?? false;
  }

  /// Returns `true` if this schema accepts null values.
  ///
  /// Convenient shorthand for checking if null is in the union of types.
  ///
  /// Example:
  /// ```dart
  /// final nullable = JsonSchema.fromJson({'type': ['string', 'null']});
  /// print(nullable.acceptsNull); // true
  ///
  /// final notNullable = JsonSchema.fromJson({'type': 'string'});
  /// print(notNullable.acceptsNull); // false
  /// ```
  bool get acceptsNull {
    return acceptsType(JsonSchemaType.null_);
  }

  // ==========================================================================
  // Parsing (fromJson)
  // ==========================================================================

  /// Parses a JSON Schema from a JSON map.
  ///
  /// Throws [ArgumentError] if the schema is malformed (e.g., missing type).
  ///
  /// Example:
  /// ```dart
  /// final schema = JsonSchema.fromJson({
  ///   'type': 'object',
  ///   'properties': {
  ///     'name': {'type': 'string'},
  ///   },
  /// });
  /// ```
  factory JsonSchema.fromJson(JsonMap json) {
    return _JsonSchemaParser().parse(json);
  }

  // ==========================================================================
  // Serialization (toJson)
  // ==========================================================================

  /// Converts this schema to a JSON map.
  ///
  /// Omits null fields to produce clean, minimal JSON.
  ///
  /// Example:
  /// ```dart
  /// final schema = JsonSchema.string(minLength: 5);
  /// final json = schema.toJson();
  /// // {'type': 'string', 'minLength': 5}
  /// ```
  JsonMap toJson() {
    return {
      if (type != null)
        'type': type!.length == 1
            ? type!.first.toJson()
            : type!.map((t) => t.toJson()).toList(),
      if (format != null) 'format': format,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (minLength != null) 'minLength': minLength,
      if (maxLength != null) 'maxLength': maxLength,
      if (pattern != null) 'pattern': pattern,
      if (enum_ != null) 'enum': enum_,
      if (minimum != null) 'minimum': minimum,
      if (maximum != null) 'maximum': maximum,
      if (exclusiveMinimum != null) 'exclusiveMinimum': exclusiveMinimum,
      if (exclusiveMaximum != null) 'exclusiveMaximum': exclusiveMaximum,
      if (multipleOf != null) 'multipleOf': multipleOf,
      if (items != null) 'items': items!.toJson(),
      if (minItems != null) 'minItems': minItems,
      if (maxItems != null) 'maxItems': maxItems,
      if (uniqueItems != null) 'uniqueItems': uniqueItems,
      if (properties != null)
        'properties': {
          for (final entry in properties!.entries)
            entry.key: entry.value.toJson(),
        },
      if (required != null) 'required': required,
      if (additionalProperties != null)
        'additionalProperties': additionalProperties,
      if (anyOf != null) 'anyOf': anyOf!.map((s) => s.toJson()).toList(),
      if (allOf != null) 'allOf': allOf!.map((s) => s.toJson()).toList(),
      if (oneOf != null) 'oneOf': oneOf!.map((s) => s.toJson()).toList(),
    };
  }

  // ==========================================================================
  // Factory Constructors (Convenience)
  // ==========================================================================

  /// Creates a string schema.
  factory JsonSchema.string({
    String? format,
    String? title,
    String? description,
    int? minLength,
    int? maxLength,
    String? pattern,
    List<String>? enum_,
  }) {
    return JsonSchema(
      type: [JsonSchemaType.string],
      format: format,
      title: title,
      description: description,
      minLength: minLength,
      maxLength: maxLength,
      pattern: pattern,
      enum_: enum_,
    );
  }

  /// Creates an integer schema.
  factory JsonSchema.integer({
    String? format,
    String? title,
    String? description,
    num? minimum,
    num? maximum,
    num? exclusiveMinimum,
    num? exclusiveMaximum,
    num? multipleOf,
  }) {
    return JsonSchema(
      type: [JsonSchemaType.integer],
      format: format,
      title: title,
      description: description,
      minimum: minimum,
      maximum: maximum,
      exclusiveMinimum: exclusiveMinimum,
      exclusiveMaximum: exclusiveMaximum,
      multipleOf: multipleOf,
    );
  }

  /// Creates a number schema (floating-point).
  factory JsonSchema.number({
    String? format,
    String? title,
    String? description,
    num? minimum,
    num? maximum,
    num? exclusiveMinimum,
    num? exclusiveMaximum,
    num? multipleOf,
  }) {
    return JsonSchema(
      type: [JsonSchemaType.number],
      format: format,
      title: title,
      description: description,
      minimum: minimum,
      maximum: maximum,
      exclusiveMinimum: exclusiveMinimum,
      exclusiveMaximum: exclusiveMaximum,
      multipleOf: multipleOf,
    );
  }

  /// Creates a boolean schema.
  factory JsonSchema.boolean({
    String? title,
    String? description,
  }) {
    return JsonSchema(
      type: [JsonSchemaType.boolean],
      title: title,
      description: description,
    );
  }

  /// Creates an array schema.
  factory JsonSchema.array({
    required JsonSchema items,
    String? title,
    String? description,
    int? minItems,
    int? maxItems,
    bool? uniqueItems,
  }) {
    return JsonSchema(
      type: [JsonSchemaType.array],
      title: title,
      description: description,
      items: items,
      minItems: minItems,
      maxItems: maxItems,
      uniqueItems: uniqueItems,
    );
  }

  /// Creates an object schema.
  factory JsonSchema.object({
    required Map<String, JsonSchema> properties,
    List<String>? required,
    String? title,
    String? description,
    bool? additionalProperties,
  }) {
    return JsonSchema(
      type: [JsonSchemaType.object],
      title: title,
      description: description,
      properties: properties,
      required: required,
      additionalProperties: additionalProperties,
    );
  }
}

// ============================================================================
// Parser Implementation
// ============================================================================

/// Internal parser for JSON Schema documents.
class _JsonSchemaParser {
  JsonSchema parse(JsonMap json) {
    // Type is required, unless this schema has other defining characteristics:
    // - Composition keywords (anyOf/allOf/oneOf)
    // - Empty schema (accepts anything)
    // - Constraining keywords (enum, properties, items, etc.)
    final typeValue = json['type'];
    final hasComposition = json.containsKey('anyOf') ||
        json.containsKey('allOf') ||
        json.containsKey('oneOf');

    // An empty schema {} or a schema with only metadata fields is valid
    final isEmptySchema = json.isEmpty ||
        json.keys.every((k) => k == 'description' || k == 'title' || k == 'default');

    // Schemas with constraining keywords don't require type
    final hasConstrainingKeywords = json.containsKey('enum') ||
        json.containsKey('const') ||
        json.containsKey('properties') ||
        json.containsKey('required') ||
        json.containsKey('additionalProperties') ||
        json.containsKey('items') ||
        json.containsKey('minItems') ||
        json.containsKey('maxItems') ||
        json.containsKey('uniqueItems') ||
        json.containsKey('minLength') ||
        json.containsKey('maxLength') ||
        json.containsKey('pattern') ||
        json.containsKey('minimum') ||
        json.containsKey('maximum') ||
        json.containsKey('exclusiveMinimum') ||
        json.containsKey('exclusiveMaximum') ||
        json.containsKey('multipleOf');

    if (typeValue == null && !hasComposition && !isEmptySchema && !hasConstrainingKeywords) {
      throw ArgumentError('JSON Schema is missing required "type" field');
    }

    // Parse type if present (can be string or array of strings)
    List<JsonSchemaType>? type;
    if (typeValue != null) {
      if (typeValue is String) {
        // Single type: "string"
        final parsed = JsonSchemaType.parse(typeValue);
        if (parsed == null) {
          throw ArgumentError('Unknown JSON Schema type: "$typeValue"');
        }
        type = [parsed];
      } else if (typeValue is List) {
        // Array of types: ["string", "null"]
        final parsed = <JsonSchemaType>[];
        for (final item in typeValue) {
          final parsedType = JsonSchemaType.parse(item.toString());
          if (parsedType != null) {
            parsed.add(parsedType);
          }
        }
        if (parsed.isEmpty) {
          throw ArgumentError('Invalid JSON Schema type array: $typeValue');
        }
        type = parsed;
      } else {
        throw ArgumentError('Invalid JSON Schema type: "$typeValue" (must be string or array)');
      }
    } else {
      // No type field - valid for composition schemas or empty schemas
      type = null;
    }

    return JsonSchema(
      type: type,
      format: json['format'] as String?,
      title: json['title'] as String?,
      description: json['description'] as String?,
      minLength: _asInt(json['minLength']),
      maxLength: _asInt(json['maxLength']),
      pattern: json['pattern'] as String?,
      enum_: _stringList(json['enum']),
      minimum: _asNum(json['minimum']),
      maximum: _asNum(json['maximum']),
      exclusiveMinimum: _asNum(json['exclusiveMinimum']),
      exclusiveMaximum: _asNum(json['exclusiveMaximum']),
      multipleOf: _asNum(json['multipleOf']),
      items: _parseSchema(json['items']),
      minItems: _asInt(json['minItems']),
      maxItems: _asInt(json['maxItems']),
      uniqueItems: json['uniqueItems'] as bool?,
      properties: _parseProperties(json['properties']),
      required: _stringList(json['required']),
      additionalProperties: json['additionalProperties'] is bool
          ? json['additionalProperties'] as bool
          : json['additionalProperties'] is Map &&
                  (json['additionalProperties'] as Map).isEmpty
              ? true
              : null,
      anyOf: _parseSchemaList(json['anyOf']),
      allOf: _parseSchemaList(json['allOf']),
      oneOf: _parseSchemaList(json['oneOf']),
    );
  }

  int? _asInt(Object? value) {
    return switch (value) {
      null => null,
      int i => i,
      num n => n.toInt(),
      _ => throw ArgumentError('Expected int, got ${value.runtimeType}: $value'),
    };
  }

  num? _asNum(Object? value) {
    return switch (value) {
      null => null,
      num n => n,
      _ => throw ArgumentError('Expected num, got ${value.runtimeType}: $value'),
    };
  }

  List<String>? _stringList(Object? value) {
    return switch (value) {
      null => null,
      List<dynamic> list => list.map((e) => e.toString()).toList(),
      _ => throw ArgumentError('Expected List, got ${value.runtimeType}: $value'),
    };
  }

  JsonSchema? _parseSchema(Object? value) {
    return switch (value) {
      null => null,
      Map<dynamic, dynamic> map => parse(map.cast<String, Object?>()),
      _ => throw ArgumentError(
          'Expected schema Map, got ${value.runtimeType}: $value',
        ),
    };
  }

  Map<String, JsonSchema>? _parseProperties(Object? value) {
    return switch (value) {
      null => null,
      Map<dynamic, dynamic> map => {
          for (final entry in map.entries)
            entry.key.toString(): parse((entry.value as Map).cast<String, Object?>()),
        },
      _ => throw ArgumentError(
          'Expected properties Map, got ${value.runtimeType}: $value',
        ),
    };
  }

  List<JsonSchema>? _parseSchemaList(Object? value) {
    return switch (value) {
      null => null,
      List<dynamic> list => list
          .map((item) => parse((item as Map).cast<String, Object?>()))
          .toList(),
      _ => throw ArgumentError(
          'Expected schema List, got ${value.runtimeType}: $value',
        ),
    };
  }
}
