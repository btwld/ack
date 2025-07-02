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