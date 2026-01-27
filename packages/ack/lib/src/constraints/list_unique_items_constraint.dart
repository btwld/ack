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
    return _findDuplicates(value) == null;
  }

  @override
  String buildMessage(List<T> value) {
    final uniqueDuplicates = _findDuplicates(value);
    if (uniqueDuplicates == null || uniqueDuplicates.isEmpty) {
      return 'List must contain unique items.';
    }

    final joined = uniqueDuplicates.map((e) => '"$e"').join(', ');
    return 'List items must be unique. Duplicates found: $joined.';
  }

  @override
  Map<String, Object?> toJsonSchema() => {'uniqueItems': true};

  // No additional fields - base class equality is sufficient.
  // Explicitly not overriding == and hashCode as ListUniqueItemsConstraint
  // has no type-specific fields beyond constraintKey and description.
}

List<T>? _findDuplicates<T>(List<T> value) {
  if (value.isEmpty) return null;

  // Always use hash-based deep equality for consistency with deepEquals.
  // The primitive path was removed because it used == (which treats 1 == 1.0
  // as true) while deepEquals treats different runtimeTypes as not equal.
  final groupsByHash = <int, List<_DuplicateGroup<T>>>{};
  final groupsInOrder = <_DuplicateGroup<T>>[];

  for (final item in value) {
    final hash = _deepHashCode(item);
    final bucket = groupsByHash.putIfAbsent(hash, () => <_DuplicateGroup<T>>[]);
    var matched = false;
    for (final group in bucket) {
      if (deepEquals(group.value, item)) {
        group.count++;
        matched = true;
        break;
      }
    }
    if (!matched) {
      final group = _DuplicateGroup<T>(item);
      bucket.add(group);
      groupsInOrder.add(group);
    }
  }

  final duplicates = <T>[];
  for (final group in groupsInOrder) {
    if (group.count > 1) {
      duplicates.add(group.value);
    }
  }

  return duplicates.isEmpty ? null : duplicates;
}

int _deepHashCode(Object? value) {
  if (value == null) return Object.hash(null, null);

  if (value is! Iterable && value is! Map) {
    return Object.hash(value.runtimeType, value);
  }

  if (value is List) {
    var hash = Object.hash(value.runtimeType, value.length);
    for (final item in value) {
      hash = Object.hash(hash, _deepHashCode(item));
    }
    return hash;
  }

  if (value is Set) {
    var sum = 0;
    for (final item in value) {
      sum += _deepHashCode(item);
    }
    return Object.hash(value.runtimeType, value.length, sum);
  }

  if (value is Map) {
    var sum = 0;
    for (final entry in value.entries) {
      // Use deep hashing for both keys and values to align with deepEquals
      final keyHash = _deepHashCode(entry.key);
      final valueHash = _deepHashCode(entry.value);
      sum += Object.hash(keyHash, valueHash);
    }
    return Object.hash(value.runtimeType, value.length, sum);
  }

  if (value is Iterable) {
    var hash = Object.hash(value.runtimeType, 0);
    for (final item in value) {
      hash = Object.hash(hash, _deepHashCode(item));
    }
    return hash;
  }

  return Object.hash(value.runtimeType, value.hashCode);
}

class _DuplicateGroup<T> {
  _DuplicateGroup(this.value);

  final T value;
  int count = 1;
}
