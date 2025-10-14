import 'constraint.dart';

/// Validates that all items in a list are unique.
///
/// It handles uniqueness for primitives directly. For complex objects,
/// it relies on the object's `hashCode` and `==` implementation.
class ListUniqueItemsConstraint<T> extends Constraint<List<T>>
    with Validator<List<T>>, JsonSchemaSpec<List<T>> {
  const ListUniqueItemsConstraint()
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
    final seen = <T>{};
    final dups = <T>{};
    for (final item in value) {
      if (!seen.add(item)) {
        dups.add(item);
      }
    }
    if (dups.isEmpty) return 'List must contain unique items.';
    final joined = dups.map((e) => '"$e"').join(', ');
    return 'List items must be unique. Duplicates found: $joined.';
  }

  @override
  Map<String, Object?> toJsonSchema() => {'uniqueItems': true};
}
