import '../../constraints/core/comparison_constraint.dart';
import '../../constraints/core/unique_items_constraint.dart';
import '../schema.dart';

/// Adds fluent validation methods to [ListSchema].
extension ListSchemaExtensions<T extends Object> on ListSchema<T> {
  /// Adds a constraint that the list must have at least [n] items.
  ListSchema<T> minItems(int n) {
    return withConstraint(ComparisonConstraint.listMinItems<T>(n));
  }

  /// Adds a constraint that the list must have no more than [n] items.
  ListSchema<T> maxItems(int n) {
    return withConstraint(ComparisonConstraint.listMaxItems<T>(n));
  }

  /// Adds a constraint that the list must have exactly [n] items.
  ListSchema<T> exactLength(int n) {
    return withConstraint(ComparisonConstraint.listExactItems<T>(n));
  }

  /// Adds a constraint that the list must not be empty.
  /// This is a convenience method for `minLength(1)`.
  ListSchema<T> nonEmpty() {
    return minItems(1);
  }

  /// Adds a constraint that all items in the list must be unique.
  ListSchema<T> unique() {
    return withConstraint(UniqueItemsConstraint<T>());
  }
}
