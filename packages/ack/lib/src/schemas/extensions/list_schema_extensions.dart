import '../../constraints/core/comparison_constraint.dart';
import '../../constraints/core/unique_items_constraint.dart';
import '../schema.dart';

/// Adds fluent validation methods to [ListSchema].
extension ListSchemaExtensions<T extends Object> on ListSchema<T> {
  /// Adds a constraint that the list must have at least [n] items.
  ListSchema<T> minItems(int n) {
    return withConstraint(ComparisonConstraint.listMinItems<T>(n));
  }

  /// Alias for [minItems] to mirror documentation naming.
  ListSchema<T> minLength(int n) => minItems(n);

  /// Adds a constraint that the list must have no more than [n] items.
  ListSchema<T> maxItems(int n) {
    return withConstraint(ComparisonConstraint.listMaxItems<T>(n));
  }

  /// Alias for [maxItems] to mirror documentation naming.
  ListSchema<T> maxLength(int n) => maxItems(n);

  /// Adds a constraint that the list must have exactly [n] items.
  ListSchema<T> exactLength(int n) {
    return withConstraint(ComparisonConstraint.listExactItems<T>(n));
  }

  /// Alias for [exactLength] to mirror documentation naming.
  ListSchema<T> length(int n) => exactLength(n);

  /// Adds a constraint that the list must not be empty.
  /// This is a convenience method for `minItems(1)`.
  ListSchema<T> nonEmpty() {
    return minItems(1);
  }

  /// Alias for [nonEmpty] to mirror documentation naming.
  ListSchema<T> notEmpty() => nonEmpty();

  /// Adds a constraint that all items in the list must be unique.
  ListSchema<T> unique() {
    return withConstraint(UniqueItemsConstraint<T>());
  }
}
