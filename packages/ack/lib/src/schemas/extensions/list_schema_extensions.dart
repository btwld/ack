import '../../constraints/comparison_constraint.dart';
import '../../constraints/list_unique_items_constraint.dart';
import '../schema.dart';

/// Adds fluent validation methods to [ListSchema].
extension ListSchemaExtensions<
  ItemBoundary extends Object,
  ItemRuntime extends Object
>
    on ListSchema<ItemBoundary, ItemRuntime> {
  /// Adds a constraint that the list must have at least [n] items.
  ListSchema<ItemBoundary, ItemRuntime> minItems(int n) {
    return withConstraint(ComparisonConstraint.listMinItems<ItemRuntime>(n));
  }

  /// Alias for [minItems].
  ListSchema<ItemBoundary, ItemRuntime> minLength(int n) => minItems(n);

  /// Adds a constraint that the list must have no more than [n] items.
  ListSchema<ItemBoundary, ItemRuntime> maxItems(int n) {
    return withConstraint(ComparisonConstraint.listMaxItems<ItemRuntime>(n));
  }

  /// Alias for [maxItems].
  ListSchema<ItemBoundary, ItemRuntime> maxLength(int n) => maxItems(n);

  /// Adds a constraint that the list must have exactly [n] items.
  ListSchema<ItemBoundary, ItemRuntime> exactLength(int n) {
    return withConstraint(ComparisonConstraint.listExactItems<ItemRuntime>(n));
  }

  /// Alias for [exactLength].
  ListSchema<ItemBoundary, ItemRuntime> length(int n) => exactLength(n);

  /// Adds a constraint that the list must not be empty.
  ListSchema<ItemBoundary, ItemRuntime> nonEmpty() {
    return minItems(1);
  }

  /// Alias for [nonEmpty].
  ListSchema<ItemBoundary, ItemRuntime> notEmpty() => nonEmpty();

  /// Adds a constraint that all items in the list must be unique.
  ListSchema<ItemBoundary, ItemRuntime> unique() {
    return withConstraint(ListUniqueItemsConstraint<ItemRuntime>());
  }
}
