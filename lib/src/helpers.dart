import 'dart:convert';

String prettyJson(dynamic json) {
  var spaces = ' ' * 2;
  var encoder = JsonEncoder.withIndent(spaces);

  return encoder.convert(json);
}

String? findClosestStringMatch(String value, List<String> allowedValues) {
  // Normalize the input value
  final normalizedValue = value.toLowerCase().trim();

  // If there are no allowed values, there's nothing to match against
  if (allowedValues.isEmpty) return null;

  String? bestMatch;
  double bestScore = 0.0;

  for (final allowed in allowedValues) {
    final normalizedAllowed = allowed.toLowerCase().trim();

    // Check for direct containment: treat as a perfect similarity (1.0)
    if (normalizedValue.contains(normalizedAllowed) ||
        normalizedAllowed.contains(normalizedValue)) {
      bestScore = 1.0;
      bestMatch = allowed;
      // Typically, you could break here to return the first perfect match.
      // But continuing lets us find the "last" perfect match in the list.
      // continue; // current approach
      // break;    // an alternative if you want the FIRST perfect match found
      continue;
    }

    // Calculate similarity using the Levenshtein distance
    final distance = levenshtein(normalizedValue, normalizedAllowed);
    final maxLen = normalizedValue.length > normalizedAllowed.length
        ? normalizedValue.length
        : normalizedAllowed.length;

    // Convert distance to a similarity score (1.0 = perfect match)
    final similarity = maxLen == 0 ? 1.0 : 1.0 - (distance / maxLen);

    // Update best score & match if this is better
    if (similarity > bestScore) {
      bestScore = similarity;
      bestMatch = allowed;
    }
  }

  // Return the best match only if it meets the similarity threshold
  return bestMatch;
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
      ].reduce((a, b) => a < b ? a : b);
    }

    // Copy v1 to v0 for the next iteration
    v0 = List.from(v1);
  }

  // The final distance is in v1[t.length]
  return v1[t.length];
}
