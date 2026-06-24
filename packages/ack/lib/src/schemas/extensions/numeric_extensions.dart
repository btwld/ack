import '../../constraints/comparison_constraint.dart';
import '../../constraints/number_finite_constraint.dart';
import '../../constraints/number_safe_integer_constraint.dart';
import '../schema.dart';

/// Adds fluent validation methods to [IntegerSchema].
extension IntegerSchemaExtensions on IntegerSchema {
  /// Adds a constraint that the integer must be greater than [n].
  IntegerSchema greaterThan(int n) {
    return withConstraint(ComparisonConstraint.numberExclusiveMin<int>(n));
  }

  /// Adds a constraint that the integer must be greater than or equal to [n].
  IntegerSchema min(int n) {
    return withConstraint(ComparisonConstraint.numberMin<int>(n));
  }

  /// Adds a constraint that the integer must be less than [n].
  IntegerSchema lessThan(int n) {
    return withConstraint(ComparisonConstraint.numberExclusiveMax<int>(n));
  }

  /// Adds a constraint that the integer must be less than or equal to [n].
  IntegerSchema max(int n) {
    return withConstraint(ComparisonConstraint.numberMax<int>(n));
  }

  /// Adds a constraint that the integer must be positive (> 0).
  IntegerSchema positive() {
    return withConstraint(ComparisonConstraint.numberPositive<int>());
  }

  /// Adds a constraint that the integer must be negative (< 0).
  IntegerSchema negative() {
    return withConstraint(ComparisonConstraint.numberNegative<int>());
  }

  /// Adds a constraint that the integer must be a multiple of [n].
  IntegerSchema multipleOf(int n) {
    return withConstraint(ComparisonConstraint.numberMultipleOf<int>(n));
  }

  /// Adds a constraint that the integer must be a "safe" integer
  /// for use in environments like JavaScript.
  IntegerSchema safe() {
    return withConstraint(NumberSafeIntegerConstraint());
  }
}

/// Adds fluent validation methods to [DoubleSchema].
extension DoubleSchemaExtensions on DoubleSchema {
  /// Adds a constraint that the double must be greater than [n].
  DoubleSchema greaterThan(double n) {
    return withConstraint(ComparisonConstraint.numberExclusiveMin<double>(n));
  }

  /// Adds a constraint that the double must be greater than or equal to [n].
  DoubleSchema min(double n) {
    return withConstraint(ComparisonConstraint.numberMin<double>(n));
  }

  /// Adds a constraint that the double must be less than [n].
  DoubleSchema lessThan(double n) {
    return withConstraint(ComparisonConstraint.numberExclusiveMax<double>(n));
  }

  /// Adds a constraint that the double must be less than or equal to [n].
  DoubleSchema max(double n) {
    return withConstraint(ComparisonConstraint.numberMax<double>(n));
  }

  /// Adds a constraint that the double must be positive (> 0).
  DoubleSchema positive() {
    return withConstraint(ComparisonConstraint.numberPositive<double>());
  }

  /// Adds a constraint that the double must be negative (< 0).
  DoubleSchema negative() {
    return withConstraint(ComparisonConstraint.numberNegative<double>());
  }

  /// Adds a constraint that the double must be a multiple of [n].
  DoubleSchema multipleOf(double n) {
    return withConstraint(ComparisonConstraint.numberMultipleOf<double>(n));
  }

  /// Adds a constraint that the double must be a finite number.
  DoubleSchema finite() {
    return withConstraint(NumberFiniteConstraint<double>());
  }
}

/// Adds fluent validation methods to [NumberSchema].
extension NumberSchemaExtensions on NumberSchema {
  /// Adds a constraint that the number must be greater than [n].
  NumberSchema greaterThan(num n) {
    return withConstraint(ComparisonConstraint.numberExclusiveMin<num>(n));
  }

  /// Adds a constraint that the number must be greater than or equal to [n].
  NumberSchema min(num n) {
    return withConstraint(ComparisonConstraint.numberMin<num>(n));
  }

  /// Adds a constraint that the number must be less than [n].
  NumberSchema lessThan(num n) {
    return withConstraint(ComparisonConstraint.numberExclusiveMax<num>(n));
  }

  /// Adds a constraint that the number must be less than or equal to [n].
  NumberSchema max(num n) {
    return withConstraint(ComparisonConstraint.numberMax<num>(n));
  }

  /// Adds a constraint that the number must be positive (> 0).
  NumberSchema positive() {
    return withConstraint(ComparisonConstraint.numberPositive<num>());
  }

  /// Adds a constraint that the number must be negative (< 0).
  NumberSchema negative() {
    return withConstraint(ComparisonConstraint.numberNegative<num>());
  }

  /// Adds a constraint that the number must be a multiple of [n].
  NumberSchema multipleOf(num n) {
    return withConstraint(ComparisonConstraint.numberMultipleOf<num>(n));
  }

  /// Adds a constraint that the number must be finite.
  ///
  /// Numbers are finite by default; this method is kept for API symmetry with
  /// [DoubleSchemaExtensions.finite].
  NumberSchema finite() {
    return withConstraint(NumberFiniteConstraint<num>());
  }
}
