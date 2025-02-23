part of '../ack_base.dart';

typedef DoubleSchema = Schema<double>;
typedef IntSchema = Schema<int>;

extension NumberSchemaExt<S extends Schema<num>> on S {
  S minValue(num min) => constraint(MinValueValidator(min));

  S maxValue(num max) => constraint(MaxValueValidator(max));

  S range(num min, num max) => constraint(RangeValidator(min, max));
}

class MinValueValidator extends ConstraintsValidator<num> {
  final num min;
  const MinValueValidator(this.min)
      : super(
          type: 'num_min_value',
          description: 'Must be greater than or equal to $min',
        );

  @override
  ConstraintsValidationError? validate(num value) {
    return value >= min
        ? null
        : ConstraintsValidationError(
            type: 'num_min_value',
            message:
                'Value $value is less than the minimum required value of $min. '
                'Please provide a number greater than or equal to $min.',
            context: {
              'value': value,
              'min': min,
              'difference': min - value,
              'suggestion': 'Try using a value at least ${min - value} higher',
            },
          );
  }
}

class MaxValueValidator extends ConstraintsValidator<num> {
  final num max;
  const MaxValueValidator(this.max)
      : super(
          type: 'num_max_value',
          description: 'Must be less than or equal to $max',
        );

  @override
  ConstraintsValidationError? validate(num value) {
    return value <= max
        ? null
        : ConstraintsValidationError(
            type: 'num_max_value',
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
}

class RangeValidator extends ConstraintsValidator<num> {
  final num min;
  final num max;
  const RangeValidator(this.min, this.max)
      : super(
          type: 'num_range',
          description: 'Must be between $min and $max (inclusive)',
        );

  @override
  ConstraintsValidationError? validate(num value) {
    return value >= min && value <= max
        ? null
        : ConstraintsValidationError(
            type: 'num_range',
            message:
                'Value $value is outside the required range of $min to $max. '
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
}
