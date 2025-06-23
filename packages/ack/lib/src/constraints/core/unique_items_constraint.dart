import '../constraint.dart';

/// Validates that all items in a list are unique.
///
/// It handles uniqueness for primitives directly. For complex objects,
/// it relies on the object's `hashCode` and `==` implementation.
class UniqueItemsConstraint<T> extends Constraint<List<T>>
    with Validator<List<T>> {
  UniqueItemsConstraint()
      : super(
          constraintKey: 'list.unique',
          description: 'All items in the list must be unique.',
        );

  @override
  bool isValid(List<T> value) {
    // Using a Set is a classic and efficient way to check for uniqueness.
    return value.toSet().length == value.length;
  }

  @override
  String buildMessage(List<T> value) {
    // Finding the first duplicate to provide a more helpful error message.
    final seen = <T>{};
    for (final item in value) {
      if (!seen.add(item)) {
        return 'List must contain unique items, but found a duplicate value: "$item".';
      }
    }

    return 'List must contain unique items.';
  }
}
