import '../utils/collection_utils.dart';
import 'constraint.dart';

/// Validates that all items in a list are unique.
///
/// Uses JSON instance equality to properly detect duplicates in collections
/// and nested structures. In particular, numerically equal JSON numbers such
/// as `1` and `1.0` are duplicates.
class ListUniqueItemsConstraint<T> extends Constraint<List<T>>
    with Validator<List<T>>, JsonSchemaSpec<List<T>> {
  const ListUniqueItemsConstraint()
    : super(
        constraintKey: 'list.unique',
        description: 'All items in the list must be unique.',
      );

  @override
  bool isValid(List<T> value) => hasUniqueJsonItems(value);

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

/// Returns whether all items in [value] are unique under JSON instance equality.
bool hasUniqueJsonItems(List<Object?> value) {
  if (value.length <= 1) return true;

  final seenByHash = <int, List<Object?>>{};
  for (final item in value) {
    final hash = _jsonInstanceHashCode(item);
    final bucket = seenByHash.putIfAbsent(hash, () => <Object?>[]);
    if (bucket.any((seen) => _jsonInstanceEquals(seen, item))) {
      return false;
    }
    bucket.add(item);
  }

  return true;
}

/// Finds duplicate items in [value] using JSON instance equality.
///
/// Returns a list of unique values that appear more than once (in order of
/// first occurrence), or `null` if no duplicates exist.
///
/// **Note**: This function assumes acyclic inputs (e.g., JSON-derived data).
/// Cyclic structures will cause stack overflow.
List<T>? _findDuplicates<T>(List<T> value) {
  if (value.isEmpty) return null;

  final groupsByHash = <int, List<_DuplicateGroup<T>>>{};
  final groupsInOrder = <_DuplicateGroup<T>>[];

  for (final item in value) {
    final hash = _jsonInstanceHashCode(item);
    final bucket = groupsByHash.putIfAbsent(hash, () => <_DuplicateGroup<T>>[]);
    var matched = false;
    for (final group in bucket) {
      if (_jsonInstanceEquals(group.value, item)) {
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

bool _jsonInstanceEquals(Object? left, Object? right) {
  if (identical(left, right)) return true;

  if (left is num || right is num) {
    return left is num && right is num && left == right;
  }

  if (left is List || right is List) {
    if (left is! List || right is! List || left.length != right.length) {
      return false;
    }
    for (var index = 0; index < left.length; index++) {
      if (!_jsonInstanceEquals(left[index], right[index])) return false;
    }
    return true;
  }

  if (left is Map || right is Map) {
    if (left is! Map || right is! Map || left.length != right.length) {
      return false;
    }
    final unmatched = right.entries.toList();
    for (final leftEntry in left.entries) {
      var matchIndex = -1;
      for (var index = 0; index < unmatched.length; index++) {
        final rightEntry = unmatched[index];
        if (_jsonObjectKeyEquals(leftEntry.key, rightEntry.key) &&
            _jsonInstanceEquals(leftEntry.value, rightEntry.value)) {
          matchIndex = index;
          break;
        }
      }
      if (matchIndex == -1) return false;
      unmatched.removeAt(matchIndex);
    }
    return true;
  }

  return deepEquals(left, right);
}

bool _jsonObjectKeyEquals(Object? left, Object? right) {
  if (left is String || right is String) {
    return left is String && right is String && left == right;
  }
  return deepEquals(left, right);
}

int _jsonInstanceHashCode(Object? value) {
  if (value == null) return Object.hash('ack:json:null', null);
  if (value is num) return Object.hash('ack:json:number', value);
  if (value is String) return Object.hash('ack:json:string', value);
  if (value is bool) return Object.hash('ack:json:boolean', value);

  if (value is List) {
    var hash = Object.hash('ack:json:list', value.length);
    for (final item in value) {
      hash = Object.hash(hash, _jsonInstanceHashCode(item));
    }
    return hash;
  }

  if (value is Map) {
    var combined = 0;
    for (final entry in value.entries) {
      final keyHash = entry.key is String
          ? Object.hash('ack:json:string', entry.key)
          : deepHashCode(entry.key);
      final entryHash = Object.hash(
        keyHash,
        _jsonInstanceHashCode(entry.value),
      );
      combined ^= entryHash ^ (entryHash >>> 16);
    }
    return Object.hash('ack:json:object', value.length, combined);
  }

  return deepHashCode(value);
}

class _DuplicateGroup<T> {
  final T value;

  int count = 1;
  _DuplicateGroup(this.value);
}
