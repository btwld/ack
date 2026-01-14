/// Utilities for parsing Dart documentation comments.
library;

/// Parses a Dart documentation comment into a clean description string.
///
/// Handles:
/// - Single-line doc comments (`/// ...`)
/// - Multi-line doc comments joined with spaces
/// - Block doc comments (`/** ... */`)
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

  // Handle /// style comments (check startsWith to avoid false matches)
  if (docComment.startsWith('///')) {
    final lines = docComment
        .split('\n')
        .map((line) => line.replaceFirst(RegExp(r'^\s*///\s?'), ''))
        .where((line) => line.isNotEmpty)
        .toList();

    if (lines.isEmpty) return null;
    return lines.join(' ').trim();
  }

  // Handle /** */ style comments
  if (docComment.startsWith('/**')) {
    final content = docComment
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
