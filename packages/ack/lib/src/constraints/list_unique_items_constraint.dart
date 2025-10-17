import '../utils/collection_utils.dart';
import 'constraint.dart';

/// Validates that all items in a list are unique.
///
/// Uses deep equality comparison to properly detect duplicates in
/// collections (Lists, Maps, Sets) and nested structures.
class ListUniqueItemsConstraint<T> extends Constraint<List<T>>
    with Validator<List<T>>, JsonSchemaSpec<List<T>> {
  const ListUniqueItemsConstraint()
    : super(
        constraintKey: 'list.unique',
        description: 'All items in the list must be unique.',
      );

  @override
  bool isValid(List<T> value) {
    // For primitive types, use Set for efficiency
    if (value.isEmpty) return true;
    final first = value.first;
    final isPrimitive = first is num || first is String || first is bool;

    if (isPrimitive) {
      return value.toSet().length == value.length;
    }

    // For complex types, use deep equality
    for (var i = 0; i < value.length; i++) {
      for (var j = i + 1; j < value.length; j++) {
        if (deepEquals(value[i], value[j])) {
          return false;
        }
      }
    }
    return true;
  }

  @override
  String buildMessage(List<T> value) {
    // Collect unique values that have duplicates
    final uniqueDuplicates = <T>[];

    // Use same double-loop structure as isValid
    for (var i = 0; i < value.length; i++) {
      // Check if value[i] appears later in the list
      var hasDuplicate = false;
      for (var j = i + 1; j < value.length; j++) {
        if (deepEquals(value[i], value[j])) {
          hasDuplicate = true;
          break; // Found one duplicate, that's enough
        }
      }

      // If it has a duplicate and not already tracked, add it
      if (hasDuplicate) {
        var alreadyAdded = false;
        for (final dup in uniqueDuplicates) {
          if (deepEquals(value[i], dup)) {
            alreadyAdded = true;
            break;
          }
        }
        if (!alreadyAdded) {
          uniqueDuplicates.add(value[i]);
        }
      }
    }

    if (uniqueDuplicates.isEmpty) {
      return 'List must contain unique items.';
    }

    final joined = uniqueDuplicates.map((e) => '"$e"').join(', ');
    return 'List items must be unique. Duplicates found: $joined.';
  }

  @override
  Map<String, Object?> toJsonSchema() => {'uniqueItems': true};
}
