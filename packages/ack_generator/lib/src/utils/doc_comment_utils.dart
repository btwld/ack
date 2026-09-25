/// Utilities for parsing Dart documentation comments.
library;

/// Parses a Dart documentation comment into a clean description string.
///
/// Supports `///` and `/** ... */` doc comments, including multi-line variants,
/// and returns cleaned text as a single string.
///
/// Returns `null` if the comment is empty or cannot be parsed.
///
/// Example:
/// ```dart
/// final description = parseDocComment('/// User name field');
/// // Returns: 'User name field'
/// ```
String? parseDocComment(String? docComment) {
  if (docComment == null || docComment.isEmpty) {
    return null;
  }
  final normalized = docComment.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

  // Handle /// style comments (check startsWith to avoid false matches)
  if (normalized.startsWith('///')) {
    final lines = normalized
        .split('\n')
        .map((line) => line.replaceFirst(RegExp(r'^\s*///\s?'), ''))
        .where((line) => line.isNotEmpty)
        .toList();

    if (lines.isEmpty) return null;
    return lines.join(' ').trim();
  }

  // Handle /** */ style comments
  if (normalized.startsWith('/**')) {
    final content = normalized
        .replaceFirst(RegExp(r'^/\*\*\s*'), '')
        .replaceFirst(RegExp(r'\s*\*/$'), '')
        .split('\n')
        .map((line) => line.replaceFirst(RegExp(r'^\s*\*\s?'), ''))
        .where((line) => line.isNotEmpty)
        .join(' ')
        .trim();

    return content.isEmpty ? null : content;
  }

  return null;
}
