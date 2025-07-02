import 'dart:math';

/// Finds the closest string match from a list of allowed values.
///
/// Uses a multi-pass approach: exact match, prefix match, contains match (short strings),
/// and finally Levenshtein distance for typo correction.
String? findClosestStringMatch(
  String value,
  List<String> allowedValues, {
  double similarityThreshold = 0.6, // Higher threshold means more similar
}) {
  if (allowedValues.isEmpty) return null;

  final normalizedValue = value.toLowerCase().trim();
  if (normalizedValue.isEmpty) return null;

  // Pass 1: Exact case-insensitive match
  for (final allowed in allowedValues) {
    if (allowed.toLowerCase().trim() == normalizedValue) {
      return allowed; // Return original casing
    }
  }

  // Pass 2: Prefix match (value is prefix of allowed, or allowed is prefix of value)
  for (final allowed in allowedValues) {
    final normalizedAllowed = allowed.toLowerCase().trim();
    if (normalizedAllowed.startsWith(normalizedValue) ||
        normalizedValue.startsWith(normalizedAllowed)) {
      return allowed;
    }
  }

  // Pass 3: Contains match (for very short strings, this can be noisy)
  if (normalizedValue.length <= 5) {
    for (final allowed in allowedValues) {
      final normalizedAllowed = allowed.toLowerCase().trim();
      if (normalizedAllowed.length <=
              8 && // Only suggest for relatively short allowed values too
          (normalizedAllowed.contains(normalizedValue) ||
              normalizedValue.contains(normalizedAllowed))) {
        return allowed;
      }
    }
  }

  // Pass 4: Levenshtein distance based similarity
  // Only apply for reasonable length strings to avoid too many false positives
  if (normalizedValue.length >= 3 && normalizedValue.length <= 20) {
    String? bestMatch;
    double highestSimilarity = 0.0;

    for (final allowed in allowedValues) {
      final normalizedAllowed = allowed.toLowerCase().trim();
      // Compare with reasonably similar length strings
      if ((normalizedAllowed.length - normalizedValue.length).abs() <= 5 ||
          normalizedAllowed.length <= 10) {
        final similarity =
            _calculateStringSimilarity(normalizedValue, normalizedAllowed);
        if (similarity >= similarityThreshold &&
            similarity > highestSimilarity) {
          highestSimilarity = similarity;
          bestMatch = allowed;
        }
      }
    }
    if (bestMatch != null) return bestMatch;
  }

  return null; // No sufficiently close match found
}

double _calculateStringSimilarity(String a, String b) {
  if (a.isEmpty && b.isEmpty) return 1.0;
  if (a.isEmpty || b.isEmpty) return 0.0;

  final maxLength = max(a.length, b.length);
  if (maxLength == 0) return 1.0; // Both empty

  final distance = _levenshteinDistance(a, b);

  return 1.0 - (distance / maxLength);
}

int _levenshteinDistance(String s1, String s2) {
  if (s1 == s2) return 0;
  if (s1.isEmpty) return s2.length;
  if (s2.isEmpty) return s1.length;

  List<int> v0 = List<int>.filled(s2.length + 1, 0, growable: false);
  List<int> v1 = List<int>.filled(s2.length + 1, 0, growable: false);

  for (int i = 0; i <= s2.length; i++) {
    v0[i] = i;
  }

  for (int i = 0; i < s1.length; i++) {
    v1[0] = i + 1;
    for (int j = 0; j < s2.length; j++) {
      int cost = (s1[i] == s2[j]) ? 0 : 1;
      v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
    }
    for (int j = 0; j <= s2.length; j++) {
      v0[j] = v1[j];
    }
  }

  return v1[s2.length];
}