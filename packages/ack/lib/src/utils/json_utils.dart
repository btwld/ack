import 'dart:convert';

String prettyJson(Object? json) {
  try {
    const encoder = JsonEncoder.withIndent('  ');

    return encoder.convert(json);
  } on JsonUnsupportedObjectError {
    // Non-encodable object - fall back to toString representation
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
