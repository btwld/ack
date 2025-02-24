part of '../ack_base.dart';

final class DoubleSchema extends Schema<double> {
  const DoubleSchema({super.nullable, super.constraints});

  @override
  double? _tryParse(Object value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);

    return null;
  }

  @override
  DoubleSchema copyWith({
    bool? nullable,
    List<ConstraintsValidator<double>>? constraints,
  }) {
    return DoubleSchema(
      nullable: nullable ?? _nullable,
      constraints: constraints ?? _constraints,
    );
  }
}

final class IntSchema extends Schema<int> {
  const IntSchema({super.nullable, super.constraints});

  @override
  int? _tryParse(Object value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);

    return null;
  }

  @override
  IntSchema copyWith({
    bool? nullable,
    List<ConstraintsValidator<int>>? constraints,
  }) {
    return IntSchema(
      nullable: nullable ?? _nullable,
      constraints: constraints ?? _constraints,
    );
  }
}

extension DoubleSchemaExt on DoubleSchema {
  DoubleSchema maxValue(num max) =>
      copyWith(constraints: [MaxValueValidator(max)]);

  DoubleSchema range(num min, num max) =>
      copyWith(constraints: [RangeValidator(min, max)]);
}

extension IntSchemaExt on IntSchema {
  IntSchema maxValue(num max) =>
      copyWith(constraints: [MaxValueValidator(max)]);

  IntSchema range(num min, num max) =>
      copyWith(constraints: [RangeValidator(min, max)]);
}

class MinValueValidator<T extends num> extends ConstraintsValidator<T> {
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
            type: type,
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

class MaxValueValidator<T extends num> extends ConstraintsValidator<T> {
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
            type: type,
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

class RangeValidator<T extends num> extends ConstraintsValidator<T> {
  final num min;
  final num max;
  const RangeValidator(
    this.min,
    this.max,
  ) : super(
          type: 'num_range',
          description: 'Must be between $min and $max (inclusive)',
        );

  @override
  ConstraintsValidationError? validate(num value) {
    return value >= min && value <= max
        ? null
        : ConstraintsValidationError(
            type: type,
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
