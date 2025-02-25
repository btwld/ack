part of '../../ack.dart';

extension IntSchemaValidatorExt on IntegerSchema {
  /// {@macro max_num_validator}
  IntegerSchema maxValue(int max, {bool? exclusive}) =>
      withConstraints([MaxNumValidator<int>(max, exclusive: exclusive)]);

  /// {@macro min_num_validator}
  IntegerSchema minValue(int min, {bool? exclusive}) =>
      withConstraints([MinNumValidator<int>(min, exclusive: exclusive)]);

  /// {@macro range_num_validator}
  IntegerSchema range(int min, int max, {bool? exclusive}) =>
      withConstraints([RangeNumValidator<int>(min, max, exclusive: exclusive)]);

  /// {@macro multiple_of_num_validator}
  IntegerSchema multipleOf(int multiple) =>
      withConstraints([MultipleOfNumValidator<int>(multiple)]);
}

extension DoubleSchemaValidatorExt on DoubleSchema {
  /// {@macro max_num_validator}
  DoubleSchema maxValue(double max, {bool? exclusive}) =>
      withConstraints([MaxNumValidator<double>(max, exclusive: exclusive)]);

  /// {@macro min_num_validator}
  DoubleSchema minValue(double min, {bool? exclusive}) =>
      withConstraints([MinNumValidator<double>(min, exclusive: exclusive)]);

  /// {@macro range_num_validator}
  DoubleSchema range(double min, double max, {bool? exclusive}) =>
      withConstraints(
        [RangeNumValidator<double>(min, max, exclusive: exclusive)],
      );

  /// {@macro multiple_of_num_validator}
  DoubleSchema multipleOf(double multiple) =>
      withConstraints([MultipleOfNumValidator<double>(multiple)]);
}

/// {@template min_num_validator}
/// Validates that the input number is greater than or equal to a minimum value.
///
/// The [min] parameter specifies the minimum allowed value.
/// The [exclusive] parameter determines whether the minimum value itself is allowed:
/// - If false (default), values greater than or equal to min are valid
/// - If true, only values strictly greater than min are valid
/// {@endtemplate}
class MinNumValidator<T extends num> extends OpenApiConstraintValidator<T> {
  final T min;
  final bool exclusive;
  const MinNumValidator(this.min, {bool? exclusive})
      : exclusive = exclusive ?? false;

  @override
  bool isValid(num value) => exclusive ? value > min : value >= min;

  @override
  ConstraintError onError(num value) {
    return buildError(
      message: 'Value $value is less than the minimum required value of $min. '
          'Please provide a number greater than or equal to $min.',
      context: {
        'value': value,
        'min': min,
        'difference': min - value,
        'suggestion': 'Try using a value at least ${min - value} higher',
      },
    );
  }

  @override
  Map<String, Object?> toSchema() => {
        'minimum': min,
        if (exclusive) 'exclusiveMinimum': exclusive,
      };

  @override
  String get name => 'num_min_value';

  @override
  String get description => 'Must be greater than or equal to $min';
}

// Multiple of
class MultipleOfNumValidator<T extends num>
    extends OpenApiConstraintValidator<T> {
  final T multiple;
  const MultipleOfNumValidator(this.multiple);

  @override
  bool isValid(num value) => value % multiple == 0;

  @override
  ConstraintError onError(num value) {
    return buildError(
      message: 'Value $value is not a multiple of $multiple',
      context: {
        'value': value,
        'multiple': multiple,
        'quotient': value / multiple,
        'remainder': value % multiple,
      },
    );
  }

  @override
  Map<String, Object?> toSchema() => {'multipleOf': multiple};

  @override
  String get name => 'num_multiple_of';

  @override
  String get description => 'Must be a multiple of $multiple';
}

/// {@template max_num_validator}
/// Validates that the input number is less than a maximum value.
///
/// The [max] parameter specifies the maximum allowed value.
/// The [exclusive] parameter determines whether the maximum value itself is allowed:
/// - If true (default), only values strictly less than max are valid
/// - If false, values less than or equal to max are valid
/// {@endtemplate}
class MaxNumValidator<T extends num> extends OpenApiConstraintValidator<T> {
  final T max;
  final bool exclusive;
  const MaxNumValidator(this.max, {bool? exclusive})
      : exclusive = exclusive ?? false;

  @override
  bool isValid(num value) => exclusive ? value < max : value <= max;

  @override
  ConstraintError onError(num value) {
    final message = exclusive
        ? 'Value $value must be strictly less than $max'
        : 'Value $value exceeds the maximum allowed value of $max';

    return buildError(
      message: message,
      context: {
        'value': value,
        'max': max,
        'exclusive': exclusive,
        'excess': value - max,
        'suggestion':
            'Try using a value at least ${value - max + (exclusive ? 1 : 0)} lower',
      },
    );
  }

  @override
  Map<String, Object?> toSchema() => {
        'maximum': max,
        if (exclusive) 'exclusiveMaximum': exclusive,
      };

  @override
  String get name => 'num_max_value';

  @override
  String get description => 'Must be less than or equal to $max';
}

/// {@template range_num_validator}
/// Validates that the input number is between a minimum and maximum value.
///
/// The [min] parameter specifies the minimum allowed value.
/// The [max] parameter specifies the maximum allowed value.
/// The [exclusive] parameter determines whether the minimum and maximum values themselves are allowed:
/// - If true (default), only values strictly between min and max are valid
/// - If false, values between min and max (inclusive) are valid
/// {@endtemplate}
class RangeNumValidator<T extends num> extends OpenApiConstraintValidator<T> {
  final T min;
  final T max;
  final bool exclusive;
  const RangeNumValidator(this.min, this.max, {bool? exclusive})
      : exclusive = exclusive ?? false;

  @override
  bool isValid(num value) =>
      exclusive ? value > min && value < max : value >= min && value <= max;

  @override
  ConstraintError onError(num value) {
    final message = exclusive
        ? 'Value $value must be strictly between $min and $max'
        : 'Value $value exceeds the maximum allowed value of $max';

    return buildError(
      message: message,
      context: {
        'value': value,
        'min': min,
        'max': max,
        'distance_from_min': value < min ? min - value : null,
        'distance_from_max': value > max ? value - max : null,
        'suggestion': value < min
            ? 'Try increasing the value by at least ${min - value}'
            : 'Try decreasing the value by at least ${value - max}',
      },
    );
  }

  @override
  Map<String, Object?> toSchema() => {
        'minimum': min,
        'maximum': max,
        if (exclusive) 'exclusiveMinimum': exclusive,
        if (exclusive) 'exclusiveMaximum': exclusive,
      };

  @override
  String get name => 'num_range';

  @override
  String get description => 'Must be between $min and $max (inclusive)';
}
