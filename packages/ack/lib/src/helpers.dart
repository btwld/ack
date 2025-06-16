import 'dart:convert';

String prettyJson(Map<String, dynamic> json) {
  var spaces = ' ' * 2;
  var encoder = JsonEncoder.withIndent(spaces);

  return encoder.convert(json);
}

/// Simple string matching for suggestions - prioritizes prefix matches and short values.
String? findClosestStringMatch(
  String value,
  List<String> allowedValues, {
  double threshold =
      0.6, // Kept for compatibility but not used in simplified logic
}) {
  // Note: threshold parameter kept for API compatibility but not used in simplified logic
  if (allowedValues.isEmpty) return null;

  final normalizedValue = value.toLowerCase().trim();

  // First pass: exact matches
  for (final allowed in allowedValues) {
    if (allowed.toLowerCase().trim() == normalizedValue) {
      return allowed;
    }
  }

  // Second pass: prefix matches (most useful for suggestions)
  for (final allowed in allowedValues) {
    final normalizedAllowed = allowed.toLowerCase().trim();
    if (normalizedAllowed.startsWith(normalizedValue) ||
        normalizedValue.startsWith(normalizedAllowed)) {
      return allowed;
    }
  }

  // Third pass: contains matches for shorter strings only
  for (final allowed in allowedValues) {
    final normalizedAllowed = allowed.toLowerCase().trim();
    if (normalizedAllowed.length <= 8 && // Only suggest short values
        (normalizedAllowed.contains(normalizedValue) ||
            normalizedValue.contains(normalizedAllowed))) {
      return allowed;
    }
  }

  return null; // No reasonable suggestion found
}

// Removed complex Levenshtein distance algorithm - no longer needed
// String matching now uses simpler prefix/contains logic

/// Merges two maps recursively.
///
/// If both maps have a value for the same key, the value from the second map
/// will replace the value from the first map.
///
/// If both values are maps, the function will recursively merge them.
///
Map<String, Object?> deepMerge(
  Map<String, Object?> map1,
  Map<String, Object?> map2,
) {
  final result = Map<String, Object?>.from(map1);
  map2.forEach((key, value) {
    final existing = result[key];
    if (existing is Map<String, Object?> && value is Map<String, Object?>) {
      result[key] = deepMerge(existing, value);
    } else {
      result[key] = value;
    }
  });

  return result;
}

extension IterableExt<T> on Iterable<T> {
  /// Returns duplicate elements in this iterable.
  Iterable<T> get duplicates {
    final duplicates = <T>[];
    final seen = <T>{};
    for (final element in this) {
      if (seen.contains(element)) {
        duplicates.add(element);
      } else {
        seen.add(element);
      }
    }

    return duplicates;
  }

  /// Returns true if this iterable has duplicate elements.
  bool get areNotUnique => duplicates.isNotEmpty;

  /// Returns true if all elements in [iterable] are contained in this.
  bool containsAll(Iterable<T> iterable) => iterable.every(contains);

  /// Returns elements from [iterable] that are not contained in this.
  Iterable<T> getNonContainedValues(Iterable<T> iterable) =>
      iterable.where((e) => !contains(e));

  /// Returns the first element that satisfies [test], or null if none found.
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }

    return null;
  }
}

/// Checks if a string is a valid json format
/// check if starts with the charcters that are supported
/// as valid json
///
bool looksLikeJson(String value) {
  if (value.isEmpty) return false;
  final trimmedValue = value.trim();

  // Check if starts with { and ends with } or starts with [ and ends with ]
  return (trimmedValue.startsWith('{') && trimmedValue.endsWith('}')) ||
      (trimmedValue.startsWith('[') && trimmedValue.endsWith(']'));
}
