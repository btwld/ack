import 'dart:convert';

String prettyJson(Map<String, dynamic> json) {
  var spaces = ' ' * 2;
  var encoder = JsonEncoder.withIndent(spaces);

  return encoder.convert(json);
}

/// String matching for suggestions with edit distance support.
String? findClosestStringMatch(
  String value,
  List<String> allowedValues, {
  double threshold = 0.6,
}) {
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

  // Fourth pass: edit distance for typos (only for reasonable length strings)
  if (normalizedValue.length >= 3 && normalizedValue.length <= 10) {
    String? bestMatch;
    double bestSimilarity = 0.0;

    for (final allowed in allowedValues) {
      final normalizedAllowed = allowed.toLowerCase().trim();
      if (normalizedAllowed.length <= 10) {
        // Only check reasonable length strings
        final similarity =
            _calculateSimilarity(normalizedValue, normalizedAllowed);
        if (similarity >= threshold && similarity > bestSimilarity) {
          bestSimilarity = similarity;
          bestMatch = allowed;
        }
      }
    }

    return bestMatch;
  }

  return null; // No reasonable suggestion found
}

/// Calculate similarity between two strings using a simple edit distance approach.
double _calculateSimilarity(String a, String b) {
  if (a == b) return 1.0;
  if (a.isEmpty || b.isEmpty) return 0.0;

  final maxLength = a.length > b.length ? a.length : b.length;
  final editDistance = _levenshteinDistance(a, b);

  return 1.0 - (editDistance / maxLength);
}

/// Calculate Levenshtein distance between two strings.
int _levenshteinDistance(String a, String b) {
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;

  final matrix = List.generate(
    a.length + 1,
    (i) => List.filled(b.length + 1, 0),
  );

  // Initialize first row and column
  for (int i = 0; i <= a.length; i++) {
    matrix[i][0] = i;
  }
  for (int j = 0; j <= b.length; j++) {
    matrix[0][j] = j;
  }

  // Fill the matrix
  for (int i = 1; i <= a.length; i++) {
    for (int j = 1; j <= b.length; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      matrix[i][j] = [
        matrix[i - 1][j] + 1, // deletion
        matrix[i][j - 1] + 1, // insertion
        matrix[i - 1][j - 1] + cost, // substitution
      ].reduce((a, b) => a < b ? a : b);
    }
  }

  return matrix[a.length][b.length];
}

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
