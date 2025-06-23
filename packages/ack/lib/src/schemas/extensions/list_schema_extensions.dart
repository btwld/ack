import '../../constraints/core/comparison_constraint.dart';
import '../schema.dart';

/// Adds fluent validation methods to [ListSchema].
extension ListSchemaExtensions<V extends Object> on ListSchema<V> {
  /// Adds a constraint that the list must have at least [n] items.
  ListSchema<V> minLength(int n) {
    return copyWith(
      constraints: [...constraints, ComparisonConstraint.listMinItems<V>(n)],
    );
  }

  /// Adds a constraint that the list must have no more than [n] items.
  ListSchema<V> maxLength(int n) {
    return copyWith(
      constraints: [...constraints, ComparisonConstraint.listMaxItems<V>(n)],
    );
  }

  /// Adds a constraint that the list must have exactly [n] items.
  ListSchema<V> length(int n) {
    return copyWith(
      constraints: [...constraints, ComparisonConstraint.listExactItems<V>(n)],
    );
  }

  /// Adds a constraint that the list must not be empty.
  /// This is a convenience method for `minLength(1)`.
  ListSchema<V> nonempty() {
    return minLength(1);
  }
}
