import '../../constraints/core/comparison_constraint.dart';
import '../../constraints/core/finite_constraint.dart';
import '../../constraints/core/safe_constraint.dart';
import '../schema.dart';

/// Adds fluent validation methods to any schema whose type is a [num].
/// This includes [IntegerSchema] and [DoubleSchema].
extension NumSchemaExtensions<T extends num> on AckSchema<T> {
  /// Adds a constraint that the number must be greater than [n].
  AckSchema<T> greaterThan(T n) {
    return copyWith(
      constraints: [
        ...constraints,
        ComparisonConstraint.numberExclusiveMin<T>(n),
      ],
    );
  }

  /// Adds a constraint that the number must be greater than or equal to [n].
  AckSchema<T> min(T n) {
    return copyWith(
      constraints: [...constraints, ComparisonConstraint.numberMin<T>(n)],
    );
  }

  /// Adds a constraint that the number must be less than [n].
  AckSchema<T> lessThan(T n) {
    return copyWith(
      constraints: [
        ...constraints,
        ComparisonConstraint.numberExclusiveMax<T>(n),
      ],
    );
  }

  /// Adds a constraint that the number must be less than or equal to [n].
  AckSchema<T> max(T n) {
    return copyWith(
      constraints: [...constraints, ComparisonConstraint.numberMax<T>(n)],
    );
  }

  /// Adds a constraint that the number must be positive (> 0).
  AckSchema<T> positive() {
    return copyWith(
      constraints: [...constraints, ComparisonConstraint.numberPositive<T>()],
    );
  }

  /// Adds a constraint that the number must be negative (< 0).
  AckSchema<T> negative() {
    return copyWith(
      constraints: [...constraints, ComparisonConstraint.numberNegative<T>()],
    );
  }

  /// Adds a constraint that the number must be a multiple of [n].
  AckSchema<T> multipleOf(T n) {
    return copyWith(
      constraints: [
        ...constraints,
        ComparisonConstraint.numberMultipleOf<T>(n),
      ],
    );
  }
}

/// Adds fluent validation methods to [DoubleSchema].
extension DoubleSchemaExtensions on DoubleSchema {
  /// Adds a constraint that the double must be a finite number.
  DoubleSchema finite() {
    return copyWith(constraints: [...constraints, IsFiniteConstraint()]);
  }
}

/// Adds fluent validation methods to [IntegerSchema].
extension IntegerSchemaExtensions on IntegerSchema {
  /// Adds a constraint that the integer must be a "safe" integer
  /// for use in environments like JavaScript.
  IntegerSchema safe() {
    return copyWith(
      constraints: [...constraints, IsSafeIntegerConstraint()],
    );
  }
}
