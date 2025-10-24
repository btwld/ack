/// JSON Schema type values as defined in JSON Schema Draft-7.
///
/// Represents the core type system of JSON Schema.
/// See: https://json-schema.org/draft-07/json-schema-core.html#rfc.section.4.2.1
enum JsonSchemaType {
  /// String type.
  string,

  /// Number type (includes integers and floating-point numbers).
  number,

  /// Integer type (whole numbers).
  integer,

  /// Boolean type (true/false).
  boolean,

  /// Array type (ordered list of values).
  array,

  /// Object type (key-value pairs).
  object,

  /// Null type (represents absence of value).
  ///
  /// Note: 'null' is a reserved keyword in Dart, so we use 'null_'.
  null_;

  /// Converts this type to its JSON Schema string representation.
  ///
  /// Example:
  /// ```dart
  /// JsonSchemaType.string.toJson() // 'string'
  /// JsonSchemaType.null_.toJson()  // 'null'
  /// ```
  String toJson() {
    return switch (this) {
      JsonSchemaType.null_ => 'null',
      _ => name,
    };
  }

  /// Parses a JSON Schema type string to a [JsonSchemaType] enum value.
  ///
  /// Returns `null` if the string doesn't match any known type.
  ///
  /// Example:
  /// ```dart
  /// JsonSchemaType.parse('string')  // JsonSchemaType.string
  /// JsonSchemaType.parse('null')    // JsonSchemaType.null_
  /// JsonSchemaType.parse('invalid') // null
  /// ```
  static JsonSchemaType? parse(String? value) {
    return switch (value?.toLowerCase()) {
      null => null,
      'string' => JsonSchemaType.string,
      'number' => JsonSchemaType.number,
      'integer' => JsonSchemaType.integer,
      'boolean' => JsonSchemaType.boolean,
      'array' => JsonSchemaType.array,
      'object' => JsonSchemaType.object,
      'null' => JsonSchemaType.null_,
      _ => null,
    };
  }
}
