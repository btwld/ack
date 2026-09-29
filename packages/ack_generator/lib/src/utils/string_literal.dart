/// Returns [value] as a single-quoted Dart string literal.
///
/// Escapes backslashes, quotes, and `$`, and writes control characters and
/// Unicode line separators as `\uXXXX`, so generated source stays valid and
/// keeps the original string value.
String dartStringLiteral(String value) {
  final escaped = value
      .replaceAll(r'\', r'\\')
      .replaceAll("'", r"\'")
      .replaceAll(r'$', r'\$')
      .replaceAllMapped(RegExp(r'[\x00-\x1f  ]'), (match) {
        final hex = match[0]!.codeUnitAt(0).toRadixString(16).padLeft(4, '0');
        return '\\u$hex';
      });
  return "'$escaped'";
}
