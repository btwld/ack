part of 'schema.dart';

/// Schema type enumeration covering JSON primitives and schema-specific categories.
///
/// Unifies type detection, coercion rules, and schema categorization so validation,
/// JSON Schema export, and error messages share a single source of truth.
///
/// ## Type Categories
///
/// **JSON Primitives**: string, integer, number, boolean, object, array, null_
/// **Schema-Specific**: any, anyOf, enum_, discriminated
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
/// | null_    | null_                           | no coercion                                |
///
/// ### Strict Mode (strict: true)
/// | Target   | Accepts From    | Notes                                     |
/// |----------|-----------------|-------------------------------------------|
/// | number   | number, integer | integer→number per JSON Schema semantics |
/// | *        | exact type only | all other conversions disabled            |
///
/// Example:
/// ```dart
/// SchemaType.integer.canAcceptFrom(SchemaType.string, strict: false); // true
/// SchemaType.integer.parse('42', SchemaType.string, context); // Ok(42)
/// ```
enum SchemaType {
  string('string', supportsCoercion: true),
  integer('integer', supportsCoercion: true),
  number('number', supportsCoercion: true),
  boolean('boolean', supportsCoercion: true),
  object('object'),
  array('array'),
  null_('null'),
  any('any'),
  anyOf('anyOf'),
  enum_('enum'),
  discriminated('discriminated');

  const SchemaType(this.typeName, {this.supportsCoercion = false});

  /// The string representation used in JSON Schema and error messages.
  final String typeName;

  /// Whether this type supports coercion from other types in loose mode.
  final bool supportsCoercion;

  /// Determines if this type can accept/parse values from [sourceType].
  ///
  /// When [strict] is true, only exact type matches are allowed (except number ← integer).
  /// When [strict] is false, primitive types can parse from compatible types.
  bool canAcceptFrom(SchemaType sourceType, {required bool strict}) {
    if (this == sourceType) return true;

    return switch (this) {
      SchemaType.integer =>
        !strict &&
            (sourceType == SchemaType.number ||
                sourceType == SchemaType.string),
      SchemaType.string =>
        !strict &&
            (sourceType == SchemaType.integer ||
                sourceType == SchemaType.number ||
                sourceType == SchemaType.boolean),
      SchemaType.boolean => !strict && sourceType == SchemaType.string,
      SchemaType.number =>
        sourceType == SchemaType.integer ||
            (!strict && sourceType == SchemaType.string),
      _ => false,
    };
  }

  /// Parses [value] from [sourceType] into this type.
  ///
  /// Precondition: [canAcceptFrom] must already have returned true.
  SchemaResult<T> parse<T extends Object>(
    Object value,
    SchemaType sourceType,
    SchemaContext context,
  ) {
    if (this == sourceType) {
      return SchemaResult.ok(value as T);
    }

    return switch ((this, sourceType, value)) {
      // integer conversions
      (SchemaType.integer, SchemaType.number, double d) =>
        _convertDoubleToInt(d, context) as SchemaResult<T>,
      (SchemaType.integer, SchemaType.string, String s) =>
        _parseIntFromString(s, context) as SchemaResult<T>,

      // number conversions
      (SchemaType.number, SchemaType.integer, int i) => SchemaResult.ok(
        i.toDouble() as T,
      ),
      (SchemaType.number, SchemaType.string, String s) =>
        _parseDoubleFromString(s, context) as SchemaResult<T>,

      // boolean conversions
      (SchemaType.boolean, SchemaType.string, String s) =>
        _parseBoolFromString(s, context) as SchemaResult<T>,

      // string conversions (accepts anything)
      (SchemaType.string, _, Object v) => SchemaResult.ok(v.toString() as T),

      // unsupported conversion
      _ => SchemaResult.fail(
        SchemaValidationError(
          message: 'Cannot parse ${sourceType.typeName} to $typeName',
          context: context,
        ),
      ),
    };
  }

  /// Infers the [SchemaType] for [value].
  static SchemaType of(Object? value) => switch (value) {
    null => SchemaType.null_,
    Map() => SchemaType.object,
    List() => SchemaType.array,
    Enum() => SchemaType.enum_,
    String() => SchemaType.string,
    bool() => SchemaType.boolean,
    int() => SchemaType.integer,
    num() => SchemaType.number,
    _ => throw ArgumentError('Unknown schema type for value: $value'),
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
