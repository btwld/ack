import '../../constraints/core/comparison_constraint.dart';
import '../../constraints/core/finite_constraint.dart';
import '../../constraints/core/safe_constraint.dart';
import '../schema.dart';

/// Adds fluent validation methods to [IntegerSchema].
extension IntegerSchemaExtensions on IntegerSchema {
  /// Adds a constraint that the integer must be greater than [n].
  IntegerSchema greaterThan(int n) {
    return addConstraint(ComparisonConstraint.numberExclusiveMin<int>(n));
  }

  /// Adds a constraint that the integer must be greater than or equal to [n].
  IntegerSchema min(int n) {
    return addConstraint(ComparisonConstraint.numberMin<int>(n));
  }

  /// Adds a constraint that the integer must be less than [n].
  IntegerSchema lessThan(int n) {
    return addConstraint(ComparisonConstraint.numberExclusiveMax<int>(n));
  }

  /// Adds a constraint that the integer must be less than or equal to [n].
  IntegerSchema max(int n) {
    return addConstraint(ComparisonConstraint.numberMax<int>(n));
  }

  /// Adds a constraint that the integer must be positive (> 0).
  IntegerSchema positive() {
    return addConstraint(ComparisonConstraint.numberPositive<int>());
  }

  /// Adds a constraint that the integer must be negative (< 0).
  IntegerSchema negative() {
    return addConstraint(ComparisonConstraint.numberNegative<int>());
  }

  /// Adds a constraint that the integer must be a multiple of [n].
  IntegerSchema multipleOf(int n) {
    return addConstraint(ComparisonConstraint.numberMultipleOf<int>(n));
  }

  /// Adds a constraint that the integer must be a "safe" integer
  /// for use in environments like JavaScript.
  IntegerSchema safe() {
    return addConstraint(IsSafeIntegerConstraint());
  }
}

/// Adds fluent validation methods to [DoubleSchema].
extension DoubleSchemaExtensions on DoubleSchema {
  /// Adds a constraint that the double must be greater than [n].
  DoubleSchema greaterThan(double n) {
    return addConstraint(ComparisonConstraint.numberExclusiveMin<double>(n));
  }

  /// Adds a constraint that the double must be greater than or equal to [n].
  DoubleSchema min(double n) {
    return addConstraint(ComparisonConstraint.numberMin<double>(n));
  }

  /// Adds a constraint that the double must be less than [n].
  DoubleSchema lessThan(double n) {
    return addConstraint(ComparisonConstraint.numberExclusiveMax<double>(n));
  }

  /// Adds a constraint that the double must be less than or equal to [n].
  DoubleSchema max(double n) {
    return addConstraint(ComparisonConstraint.numberMax<double>(n));
  }

  /// Adds a constraint that the double must be positive (> 0).
  DoubleSchema positive() {
    return addConstraint(ComparisonConstraint.numberPositive<double>());
  }

  /// Adds a constraint that the double must be negative (< 0).
  DoubleSchema negative() {
    return addConstraint(ComparisonConstraint.numberNegative<double>());
  }

  /// Adds a constraint that the double must be a multiple of [n].
  DoubleSchema multipleOf(double n) {
    return addConstraint(ComparisonConstraint.numberMultipleOf<double>(n));
  }

  /// Adds a constraint that the double must be a finite number.
  DoubleSchema finite() {
    return addConstraint(IsFiniteConstraint());
  }
}
