/// Performs deep equality comparison between two values.
///
/// This function recursively compares:
/// - Primitives (num, String, bool, null) using standard equality
/// - Lists by comparing each element in order
/// - Maps by comparing keys and values
/// - Sets by comparing elements (order-independent)
///
/// Returns `true` if the values are structurally equal, `false` otherwise.
/// Different types are never equal (e.g., List vs Map, int vs double).
bool deepEquals(Object? a, Object? b) {
  // Fast path: identical objects or both null
  if (identical(a, b)) return true;

  // Different types are never equal
  if (a.runtimeType != b.runtimeType) return false;

  // Handle primitives (null, bool, num, String)
  // These use standard equality
  if (a is! Iterable && a is! Map) {
    return a == b;
  }

  // Handle Lists
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!deepEquals(a[i], b[i])) return false;
    }
    return true;
  }

  // Handle Sets (order-independent comparison)
  if (a is Set && b is Set) {
    if (a.length != b.length) return false;
    // For each element in a, check if b contains an equal element
    for (final itemA in a) {
      var found = false;
      for (final itemB in b) {
        if (deepEquals(itemA, itemB)) {
          found = true;
          break;
        }
      }
      if (!found) return false;
    }
    return true;
  }

  // Handle Maps
  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key)) return false;
      if (!deepEquals(a[key], b[key])) return false;
    }
    return true;
  }

  // Handle other Iterables (not List or Set)
  if (a is Iterable && b is Iterable) {
    final iterA = a.iterator;
    final iterB = b.iterator;
    while (iterA.moveNext()) {
      if (!iterB.moveNext()) return false;
      if (!deepEquals(iterA.current, iterB.current)) return false;
    }
    return !iterB.moveNext(); // Ensure b has no more elements
  }

  // Fallback: use standard equality
  return a == b;
}

extension IterableExtensions<T> on Iterable<T> {
  /// Returns duplicate elements in this iterable.
  /// The order of duplicates in the returned iterable is based on their second appearance.
  Iterable<T> get duplicates {
    final seen = <T>{};
    final duplicatesFound = <T>[];
    for (final element in this) {
      if (!seen.add(element)) {
        // .add returns false if element was already present
        duplicatesFound.add(element);
      }
    }

    return duplicatesFound;
  }

  /// Checks if there are any duplicate elements in this iterable.
  bool get hasDuplicates => duplicates.isNotEmpty;

  /// Returns the first element matching [test], or `null` if none found.
  T? firstWhereOrNull(bool Function(T element) test) {
    for (final element in this) {
      if (test(element)) return element;
    }

    return null;
  }
}
