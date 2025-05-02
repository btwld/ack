import '../schemas/schema.dart';
import 'constraint.dart';
import 'validators.dart';

/// Extension methods for [NumSchema] to provide additional validation capabilities.
extension NumSchemaExtensions<T extends num> on NumSchema<T> {
  NumSchema<T> _add(Validator<T> validator) => withConstraints([validator]);

  /// {@macro min_num_validator}
  NumSchema<T> min(T min) => _add(NumberMinConstraint(min));

  /// {@macro max_num_validator}
  NumSchema<T> max(T max) => _add(NumberMaxConstraint(max));

  /// {@macro range_num_validator}
  NumSchema<T> range(T min, T max) => _add(NumberRangeConstraint(min, max));

  /// {@macro multiple_of_num_validator}
  NumSchema<T> multipleOf(T multiple) =>
      _add(NumberMultipleOfConstraint(multiple));

  /// Validates that a number is positive (greater than 0).
  ///
  /// Example:
  /// ```dart
  /// final priceSchema = Ack.double.positive();
  /// ```
  NumSchema<T> positive() {
    return constrain(NumberExclusiveMinConstraint(0 as T));
  }

  /// Validates that a number is negative (less than 0).
  ///
  /// Example:
  /// ```dart
  /// final temperatureSchema = Ack.double.negative();
  /// ```
  NumSchema<T> negative() {
    return constrain(NumberExclusiveMaxConstraint(0 as T));
  }

  /// Validates that a number is within a range (inclusive by default).
  ///
  /// Example:
  /// ```dart
  /// final percentageSchema = Ack.double.between(0, 100);
  /// ```
  NumSchema<T> between(T min, T max) {
    return this.min(min).max(max);
  }
}

/// Constraint for validating that a number is strictly greater than a minimum value.
class NumberExclusiveMinConstraint<T extends num> extends Constraint<T>
    with Validator<T>, OpenApiSpec<T> {
  final T min;

  const NumberExclusiveMinConstraint(this.min)
      : super(
          constraintKey: 'number_exclusive_min',
          description: 'Must be greater than $min',
        );

  @override
  bool isValid(T value) => value > min;

  @override
  String buildMessage(T value) => 'Must be greater than $min';

  @override
  Map<String, Object?> toOpenApiSpec() =>
      {'minimum': min, 'exclusiveMinimum': true};
}

/// Constraint for validating that a number is strictly less than a maximum value.
class NumberExclusiveMaxConstraint<T extends num> extends Constraint<T>
    with Validator<T>, OpenApiSpec<T> {
  final T max;

  const NumberExclusiveMaxConstraint(this.max)
      : super(
          constraintKey: 'number_exclusive_max',
          description: 'Must be less than $max',
        );

  @override
  bool isValid(T value) => value < max;

  @override
  String buildMessage(T value) => 'Must be less than $max';

  @override
  Map<String, Object?> toOpenApiSpec() =>
      {'maximum': max, 'exclusiveMaximum': true};
}
