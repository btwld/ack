part of 'schema.dart';

/// JSON type enumeration following JSON Schema Draft 2020-12.
///
/// Centralizes type detection, coercion rules, and parsing helpers so the
/// individual schema classes can stay focused on validation concerns.
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

    return switch (this) {
      JsonType.integer =>
        _parseInteger(value, sourceType, context) as SchemaResult<T>,
      JsonType.string => SchemaResult.ok(value.toString() as T),
      JsonType.boolean =>
        _parseBoolean(value, sourceType, context) as SchemaResult<T>,
      JsonType.number =>
        _parseNumber(value, sourceType, context) as SchemaResult<T>,
      _ => SchemaResult.fail(
          SchemaValidationError(
            message: 'Cannot parse ${sourceType.typeName} to $typeName',
            context: context,
          ),
        ),
    };
  }

  /// Infers the [JsonType] for [value].
  static JsonType of(Object? value) {
    if (value == null) return JsonType.nil;
    if (value is Map) return JsonType.object;
    if (value is List) return JsonType.array;
    if (value is Enum) return JsonType.string;
    if (value is String) return JsonType.string;
    if (value is bool) return JsonType.boolean;
    if (value is int) return JsonType.integer;
    if (value is num) return JsonType.number;
    throw ArgumentError('Unknown JSON type for value: $value');
  }

  SchemaResult<int> _parseInteger(
    Object value,
    JsonType sourceType,
    SchemaContext context,
  ) {
    return switch (sourceType) {
      JsonType.integer => SchemaResult.ok(value as int),
      JsonType.number => _convertDoubleToInt(value as double, context),
      JsonType.string => _parseIntFromString(value as String, context),
      _ => SchemaResult.fail(
          SchemaValidationError(
            message: 'Cannot convert ${sourceType.typeName} to integer',
            context: context,
          ),
        ),
    };
  }

  SchemaResult<double> _parseNumber(
    Object value,
    JsonType sourceType,
    SchemaContext context,
  ) {
    return switch (sourceType) {
      JsonType.number => SchemaResult.ok(value as double),
      JsonType.integer => SchemaResult.ok((value as int).toDouble()),
      JsonType.string => _parseDoubleFromString(value as String, context),
      _ => SchemaResult.fail(
          SchemaValidationError(
            message: 'Cannot convert ${sourceType.typeName} to number',
            context: context,
          ),
        ),
    };
  }

  SchemaResult<bool> _parseBoolean(
    Object value,
    JsonType sourceType,
    SchemaContext context,
  ) {
    return switch (sourceType) {
      JsonType.boolean => SchemaResult.ok(value as bool),
      JsonType.string => _parseBoolFromString(value as String, context),
      _ => SchemaResult.fail(
          SchemaValidationError(
            message: 'Cannot convert ${sourceType.typeName} to boolean',
            context: context,
          ),
        ),
    };
  }

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
