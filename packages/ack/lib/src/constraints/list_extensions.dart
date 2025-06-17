import '../schemas/schema.dart';
import 'validators.dart';
import 'core/comparison_constraint.dart';

/// Extension methods for [ListSchema] to provide additional validation capabilities.
extension ListSchemaExtensions<T extends Object> on ListSchema<T> {
  /// {@macro unique_items_list_validator}
  ///
  /// Example:
  /// ```dart
  /// final schema = Ack.list(Ack.string).uniqueItems();
  /// ```
  ListSchema<T> uniqueItems() {
    return withConstraints([ListUniqueItemsConstraint()]);
  }

  /// {@macro min_items_list_validator}
  ///
  /// Example:
  /// ```dart
  /// final schema = Ack.list(Ack.string).minItems(2);
  /// ```
  ListSchema<T> minItems(int min) =>
      withConstraints([ComparisonConstraint.listMinItems<T>(min)]);

  /// {@macro max_items_list_validator}
  ///
  /// Example:
  /// ```dart
  /// final schema = Ack.list(Ack.string).maxItems(3);
  /// ```
  ListSchema<T> maxItems(int max) =>
      withConstraints([ComparisonConstraint.listMaxItems<T>(max)]);

  /// Validates that a list has exactly the specified number of items.
  ///
  /// Example:
  /// ```dart
  /// final coordinatesSchema = Ack.list(Ack.double).exactItems(2);
  /// ```
  ListSchema<T> exactItems(int count) {
    return minItems(count).maxItems(count);
  }

  /// Validates that a list is not empty.
  ///
  /// Example:
  /// ```dart
  /// final tagsSchema = Ack.list(Ack.string).notEmpty();
  /// ```
  ListSchema<T> notEmpty() {
    return minItems(1);
  }
}
