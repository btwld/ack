extension IterableExtensions<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }

    return null;
  }
}

String? findClosestStringMatch(String value, List<String> allowedValues) {
  final lowerValue = value.toLowerCase();

  return allowedValues.firstWhereOrNull(
    (v) {
      final lowerV = v.toLowerCase();
      return lowerValue.contains(lowerV) || lowerV.contains(lowerValue);
    },
  );
}
