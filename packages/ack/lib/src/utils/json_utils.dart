import 'dart:convert';

String prettyJson(Object? json) {
  try {
    const encoder = JsonEncoder.withIndent('  ');

    return encoder.convert(json);
  } catch (e) {
    return json?.toString() ?? 'null';
  }
}

/// Merges two maps recursively.
/// If keys conflict:
/// - If both values are maps, they are recursively merged.
/// - Otherwise, the value from [map2] overwrites the value from [map1].
Map<String, Object?> deepMerge(
  Map<String, Object?> map1,
  Map<String, Object?> map2,
) {
  final result = Map<String, Object?>.from(map1);
  for (final key in map2.keys) {
    final value1 = result[key];
    final value2 = map2[key];
    if (value1 is Map<String, Object?> && value2 is Map<String, Object?>) {
      result[key] = deepMerge(value1, value2);
    } else {
      result[key] = value2;
    }
  }

  return result;
}

/// Basic heuristic to check if a string looks like it could be JSON.
/// This is not a validator, just a quick check.
bool looksLikeJson(String value) {
  if (value.isEmpty) return false;
  final trimmed = value.trim();

  return (trimmed.startsWith('{') && trimmed.endsWith('}')) ||
      (trimmed.startsWith('[') && trimmed.endsWith(']')) ||
      (trimmed == 'null') ||
      (trimmed == 'true' || trimmed == 'false') ||
      (double.tryParse(trimmed) != null &&
          !trimmed.contains(RegExp(r'[a-zA-Z]'))) || // Number
      (trimmed.startsWith('"') && trimmed.endsWith('"')); // String literal
}