import 'package:analyzer/dart/ast/token.dart' show Keyword;

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
      .replaceAllMapped(RegExp(r'[\x00-\x1f\u2028\u2029]'), (match) {
        final hex = match[0]!.codeUnitAt(0).toRadixString(16).padLeft(4, '0');
        return '\\u$hex';
      });
  return "'$escaped'";
}

/// Qualifies [symbol] with [prefix] when [prefix] is non-null and non-empty.
String qualifySymbol(String? prefix, String symbol) =>
    prefix == null || prefix.isEmpty ? symbol : '$prefix.$symbol';

/// Whether [value] is a Dart keyword, including built-in identifiers and
/// contextual keywords. Type-name guards have stricter rules than members.
bool isDartKeyword(String value) => Keyword.keywords.containsKey(value);

/// Whether [value] is reserved in every Dart identifier context.
///
/// Built-in identifiers and contextual keywords remain valid member names in
/// the synchronous constructors, getters, and methods emitted by the generator.
bool isDartReservedWord(String value) =>
    Keyword.keywords[value]?.isReservedWord ?? false;
