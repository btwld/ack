part of '../../ack_base.dart';

class MinValueValidator<T extends num> extends ConstraintValidator<T> {
  final min;
  const MinValueValidator(this.min);

  @override
  bool check(num value) => value >= min;

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
  String get name => 'num_min_value';

  @override
  String get description => 'Must be greater than or equal to $min';
}

class MaxValueValidator<T extends num> extends ConstraintValidator<T> {
  final T max;
  const MaxValueValidator(this.max);

  @override
  bool check(num value) => value <= max;

  @override
  ConstraintError onError(num value) {
    return buildError(
      message: 'Value $value exceeds the maximum allowed value of $max. '
          'Please provide a number less than or equal to $max.',
      context: {
        'value': value,
        'max': max,
        'excess': value - max,
        'suggestion': 'Try using a value at least ${value - max} lower',
      },
    );
  }

  @override
  String get name => 'num_max_value';

  @override
  String get description => 'Must be less than or equal to $max';
}

class RangeValidator<T extends num> extends ConstraintValidator<T> {
  final T min;
  final T max;
  const RangeValidator(this.min, this.max);

  @override
  bool check(num value) => value >= min && value <= max;

  @override
  ConstraintError onError(num value) {
    return buildError(
      message: 'Value $value is outside the required range of $min to $max. '
          'Please provide a number between $min and $max (inclusive).',
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
  String get name => 'num_range';

  @override
  String get description => 'Must be between $min and $max (inclusive)';
}
