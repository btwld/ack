import 'dart:convert';

String prettyJson(Object? json) {
  try {
    const encoder = JsonEncoder.withIndent('  ');

    return encoder.convert(json);
  } catch (e) {
    return json?.toString() ?? 'null';
  }
}

/// Escapes a single RFC 6901 JSON Pointer reference token.
String escapeJsonPointerToken(String token) =>
    token.replaceAll('~', '~0').replaceAll('/', '~1');
