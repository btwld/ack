part of 'schema.dart';

/// JSON type enumeration following JSON Schema Draft 2020-12.
///
/// Centralizes type detection, coercion rules, and parsing helpers so the
/// individual schema classes can stay focused on validation concerns.
///
/// ## Type Conversion Matrix
///
/// ### Loose Mode (strict: false) - Default
/// | Target   | Accepts From                    | Notes                                      |
/// |----------|----------------------------------|---------------------------------------------|
/// | integer  | integer, number, string         | number→integer: lossless only (42.0→42)    |
/// | number   | number, integer, string         | integer→number: always allowed (42→42.0)   |
/// | boolean  | boolean, string                 | string: "true"/"false" (case-insensitive)  |
/// | string   | string, integer, number, boolean| via .toString()                            |
/// | object   | object                          | no coercion                                |
/// | array    | array                           | no coercion                                |
/// | nil      | nil                             | no coercion                                |
///
/// ### Strict Mode (strict: true)
/// | Target   | Accepts From    | Notes                                     |
/// |----------|-----------------|-------------------------------------------|
/// | number   | number, integer | integer→number per JSON Schema semantics |
/// | *        | exact type only | all other conversions disabled            |
///
/// Example:
/// ```dart
/// JsonType.integer.canAcceptFrom(JsonType.string, strict: false); // true
/// JsonType.integer.parse('42', JsonType.string, context); // Ok(42)
/// ```
enum JsonType {
  string('string'),
  integer('integer'),
  number('number'),
  boolean('boolean'),
  object('object'),
  array('array'),
  nil('null');

  const JsonType(this.typeName);

  /// The string representation used in JSON Schema.
  final String typeName;

  /// Determines if this type can accept/parse values from [sourceType].
  ///
  /// When [strict] is true, only exact type matches are allowed (except number ← integer).
  /// When [strict] is false, primitive types can parse from compatible types.
  bool canAcceptFrom(JsonType sourceType, {required bool strict}) {
    if (this == sourceType) return true;

    return switch (this) {
      JsonType.integer => !strict &&
          (sourceType == JsonType.number || sourceType == JsonType.string),
      JsonType.string => !strict &&
          (sourceType == JsonType.integer ||
              sourceType == JsonType.number ||
              sourceType == JsonType.boolean),
      JsonType.boolean => !strict && sourceType == JsonType.string,
      JsonType.number => sourceType == JsonType.integer ||
          (!strict && sourceType == JsonType.string),
      _ => false,
    };
  }

  /// Parses [value] from [sourceType] into this type.
  ///
  /// Precondition: [canAcceptFrom] must already have returned true.
  SchemaResult<T> parse<T extends Object>(
    Object value,
    JsonType sourceType,
    SchemaContext context,
  ) {
    if (this == sourceType) {
      return SchemaResult.ok(value as T);
    }

    return switch ((this, sourceType, value)) {
      // integer conversions
      (JsonType.integer, JsonType.number, double d) =>
        _convertDoubleToInt(d, context) as SchemaResult<T>,
      (JsonType.integer, JsonType.string, String s) =>
        _parseIntFromString(s, context) as SchemaResult<T>,

      // number conversions
      (JsonType.number, JsonType.integer, int i) =>
        SchemaResult.ok(i.toDouble() as T),
      (JsonType.number, JsonType.string, String s) =>
        _parseDoubleFromString(s, context) as SchemaResult<T>,

      // boolean conversions
      (JsonType.boolean, JsonType.string, String s) =>
        _parseBoolFromString(s, context) as SchemaResult<T>,

      // string conversions (accepts anything)
      (JsonType.string, _, Object v) => SchemaResult.ok(v.toString() as T),

      // unsupported conversion
      _ => SchemaResult.fail(
          SchemaValidationError(
            message: 'Cannot parse ${sourceType.typeName} to $typeName',
            context: context,
          ),
        ),
    };
  }

  /// Infers the [JsonType] for [value].
  static JsonType of(Object? value) => switch (value) {
        null => JsonType.nil,
        Map() => JsonType.object,
        List() => JsonType.array,
        Enum() => JsonType.string,
        String() => JsonType.string,
        bool() => JsonType.boolean,
        int() => JsonType.integer,
        num() => JsonType.number,
        _ => throw ArgumentError('Unknown JSON type for value: $value'),
      };

  static SchemaResult<int> _convertDoubleToInt(
    double value,
    SchemaContext context,
  ) {
    if (value.isFinite && value == value.truncate()) {
      return SchemaResult.ok(value.toInt());
    }
    return SchemaResult.fail(
      SchemaValidationError(
        message: 'Cannot convert $value to integer without losing precision.',
        context: context,
      ),
    );
  }

  static SchemaResult<int> _parseIntFromString(
    String value,
    SchemaContext context,
  ) {
    final parsed = int.tryParse(value);
    if (parsed != null) return SchemaResult.ok(parsed);
    return SchemaResult.fail(
      SchemaValidationError(
        message: 'Cannot convert "$value" to integer.',
        context: context,
      ),
    );
  }

  static SchemaResult<double> _parseDoubleFromString(
    String value,
    SchemaContext context,
  ) {
    final parsed = double.tryParse(value);
    if (parsed != null) return SchemaResult.ok(parsed);
    return SchemaResult.fail(
      SchemaValidationError(
        message: 'Cannot convert "$value" to number.',
        context: context,
      ),
    );
  }

  static SchemaResult<bool> _parseBoolFromString(
    String value,
    SchemaContext context,
  ) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true') return SchemaResult.ok(true);
    if (normalized == 'false') return SchemaResult.ok(false);
    return SchemaResult.fail(
      SchemaValidationError(
        message: 'Cannot convert "$value" to boolean.',
        context: context,
      ),
    );
  }
}
