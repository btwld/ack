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

/// Whether [value] is a reserved word, built-in identifier, or contextual
/// keyword that cannot be used as an unqualified Dart member or type name.
bool isDartKeyword(String value) => _dartKeywords.contains(value);

const _dartKeywords = {
  'abstract',
  'as',
  'assert',
  'async',
  'await',
  'base',
  'break',
  'case',
  'catch',
  'class',
  'const',
  'continue',
  'covariant',
  'default',
  'deferred',
  'do',
  'dynamic',
  'else',
  'enum',
  'export',
  'extends',
  'extension',
  'external',
  'factory',
  'false',
  'final',
  'finally',
  'for',
  'get',
  'hide',
  'if',
  'implements',
  'import',
  'in',
  'interface',
  'is',
  'late',
  'library',
  'mixin',
  'new',
  'null',
  'of',
  'on',
  'operator',
  'part',
  'required',
  'rethrow',
  'return',
  'sealed',
  'set',
  'show',
  'static',
  'super',
  'switch',
  'sync',
  'this',
  'throw',
  'true',
  'try',
  'typedef',
  'var',
  'void',
  'when',
  'while',
  'with',
  'yield',
};
