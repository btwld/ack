import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

/// Returns the path of the first non-JSON-safe value in [value], or null when
/// the whole structure is JSON-safe. Mirrors ack's `_jsonSafeOrNull`
/// (packages/ack/lib/src/schemas/schema.dart): JSON values are null, a finite
/// num, a bool, or a String; JSON collections are Lists of JSON values or
/// `Map<String, JSON value>`, recursively.
String? jsonSafetyViolation(Object? value, [String path = r'$']) {
  if (value == null || value is bool || value is String) return null;
  if (value is num) {
    return value.isFinite ? null : '$path: non-finite number ($value)';
  }
  if (value is List) {
    for (var i = 0; i < value.length; i++) {
      final violation = jsonSafetyViolation(value[i], '$path[$i]');
      if (violation != null) return violation;
    }
    return null;
  }
  if (value is Map) {
    for (final entry in value.entries) {
      if (entry.key is! String) {
        return '$path: non-string key (${entry.key.runtimeType})';
      }
      final violation = jsonSafetyViolation(entry.value, '$path.${entry.key}');
      if (violation != null) return violation;
    }
    return null;
  }

  return '$path: non-JSON value of type ${value.runtimeType}';
}

/// Asserts [value] is composed solely of JSON values/collections and survives
/// a real `jsonEncode` round-trip.
void expectJsonSafe(Object? value) {
  expect(
    jsonSafetyViolation(value),
    isNull,
    reason: 'Encoded output is not JSON-safe',
  );
  expect(() => jsonEncode(value), returnsNormally);
}
