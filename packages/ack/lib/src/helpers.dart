import 'dart:convert';

String prettyJson(Map<String, dynamic> json) {
  var spaces = ' ' * 2;
  var encoder = JsonEncoder.withIndent(spaces);

  return encoder.convert(json);
}

String? findClosestStringMatch(
  String value,
  List<String> allowedValues, {
  double threshold = 0.6, // Add a threshold parameter with default
}) {
  // Normalize the input value
  final normalizedValue = value.toLowerCase().trim();

  // If there are no allowed values, there's nothing to match against
  if (allowedValues.isEmpty) return null;

  String? bestMatch;
  double bestScore = 0.0;

  for (final allowed in allowedValues) {
    final normalizedAllowed = allowed.toLowerCase().trim();
    double similarity = 0.0;

    // Check for exact match first
    if (normalizedValue == normalizedAllowed) {
      return allowed; // Return immediately for exact matches
    }

    // Check for containment with more nuanced scoring
    if (normalizedValue.contains(normalizedAllowed) ||
        normalizedAllowed.contains(normalizedValue)) {
      // Calculate length ratio for a more nuanced containment score
      final ratio = normalizedValue.length / normalizedAllowed.length;
      if (ratio >= 0.5 && ratio <= 2.0) {
        // Only consider it high similarity if lengths are reasonably close
        similarity = 0.8 + (0.2 * (1.0 - (ratio > 1 ? 1 / ratio : ratio)));
      } else {
        // Otherwise, still give it a boost but not perfect
        similarity = 0.6;
      }
    } else {
      // Calculate similarity using the Levenshtein distance
      final distance = levenshtein(normalizedValue, normalizedAllowed);
      final maxLen = normalizedValue.length > normalizedAllowed.length
          ? normalizedValue.length
          : normalizedAllowed.length;

      // Convert distance to a similarity score (1.0 = perfect match)
      similarity = maxLen == 0 ? 1.0 : 1.0 - (distance / maxLen);
    }

    // Update best score & match if this is better
    if (similarity > bestScore) {
      bestScore = similarity;
      bestMatch = allowed;
    }
  }

  // Only return the match if it meets the threshold
  return bestScore >= threshold ? bestMatch : null;
}

int levenshtein(String s, String t) {
  // If strings are equal, distance is 0
  if (s == t) return 0;

  // If one is empty, distance is length of the other
  if (s.isEmpty) return t.length;
  if (t.isEmpty) return s.length;

  // Create two work vectors of integer distances
  List<int> v0 = List.generate(t.length + 1, (i) => i);
  List<int> v1 = List.filled(t.length + 1, 0);

  for (int i = 0; i < s.length; i++) {
    // The first element of v1 is the distance from s[0..i] to an empty t
    v1[0] = i + 1;

    for (int j = 0; j < t.length; j++) {
      // Cost is 0 if the current characters match, otherwise 1
      final cost = s[i] == t[j] ? 0 : 1;

      // Take the minimum of insertion, deletion, or substitution
      v1[j + 1] = [
        v1[j] + 1, // Insertion
        v0[j + 1] + 1, // Deletion
        v0[j] + cost // Substitution
        ,
      ].reduce((a, b) => a < b ? a : b);
    }

    // Copy v1 to v0 for the next iteration
    v0 = List.of(v1);
  }

  // The final distance is in v1[t.length]
  return v1[t.length];
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
  bool get areUnique => duplicates.isEmpty;

  bool get areNotUnique => !areUnique;

  Iterable<T> get duplicates => _getNonUniqueValues();

  Iterable<T> _getNonUniqueValues() {
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

  bool containsAll(Iterable<T> iterable) => iterable.every(contains);

  Iterable<T> getNonContainedValues(Iterable<T> iterable) =>
      iterable.where((e) => !contains(e));

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

/// Extension to check if an object is considered "truthy"
extension TruthyCheck on Object? {
  bool get isTruthy {
    final value = this;
    if (value == null) return false;

    return switch (value) {
      String v => v.isNotEmpty,
      Iterable v => v.isNotEmpty,
      Map v => v.isNotEmpty,
      bool v => v,
      num v => v != 0,
      Duration v => v != Duration.zero,
      Uri v => v.toString().isNotEmpty,
      RegExp r => r.pattern.isNotEmpty,
      _ => true,
    };
  }
}
