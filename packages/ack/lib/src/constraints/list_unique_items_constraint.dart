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
    final seen = <T>[];
    final dups = <T>[];

    for (final item in value) {
      var isDuplicate = false;
      for (final seenItem in seen) {
        if (deepEquals(item, seenItem)) {
          isDuplicate = true;
          if (!dups.any((d) => deepEquals(d, item))) {
            dups.add(item);
          }
          break;
        }
      }
      if (!isDuplicate) {
        seen.add(item);
      }
    }

    if (dups.isEmpty) return 'List must contain unique items.';
    final joined = dups.map((e) => '"$e"').join(', ');
    return 'List items must be unique. Duplicates found: $joined.';
  }

  @override
  Map<String, Object?> toJsonSchema() => {'uniqueItems': true};
}
