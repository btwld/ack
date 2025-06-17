import '../schemas/schema.dart';
import 'constraint.dart';
import 'core/comparison_constraint.dart';

/// Extension methods for [NumSchema] to provide additional validation capabilities.
extension NumSchemaExtensions<T extends num> on NumSchema<T> {
  NumSchema<T> _add(Validator<T> validator) => withConstraints([validator]);

  /// {@macro min_num_validator}
  NumSchema<T> min(T min) => _add(ComparisonConstraint.numberMin(min));

  /// {@macro max_num_validator}
  NumSchema<T> max(T max) => _add(ComparisonConstraint.numberMax(max));

  /// {@macro range_num_validator}
  NumSchema<T> range(T min, T max) => _add(ComparisonConstraint.numberRange(min, max));

  /// {@macro multiple_of_num_validator}
  NumSchema<T> multipleOf(T multiple) =>
      _add(ComparisonConstraint.numberMultipleOf(multiple));

  /// Validates that a number is positive (greater than 0).
  ///
  /// Example:
  /// ```dart
  /// final priceSchema = Ack.double.positive();
  /// ```
  NumSchema<T> positive() {
    return constrain(ComparisonConstraint.numberExclusiveMin(0 as T));
  }

  /// Validates that a number is negative (less than 0).
  ///
  /// Example:
  /// ```dart
  /// final temperatureSchema = Ack.double.negative();
  /// ```
  NumSchema<T> negative() {
    return constrain(ComparisonConstraint.numberExclusiveMax(0 as T));
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

