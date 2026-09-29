/// Utilities for reading Ack tags from resolved Dart documentation comments.
library;

/// Reads the text on one `@description` line in a Dart documentation comment.
///
/// Ordinary prose and tags inside fenced code blocks do not become schema
/// descriptions. The tag must start a `///` or `/** */` documentation line.
/// A blank or duplicate tag is ambiguous and causes a [FormatException].
String? parseDescriptionTag(String? docComment) {
  if (docComment == null || docComment.isEmpty) return null;
  final normalized = docComment.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  final rawLines = normalized.split('\n');
  final isLineComment = normalized.trimLeft().startsWith('///');
  final isBlockComment = normalized.trimLeft().startsWith('/**');
  if (!isLineComment && !isBlockComment) return null;

  String cleanLine(String line, int index) {
    var value = line.trimLeft();
    if (isLineComment) {
      if (!value.startsWith('///')) return '';
      value = value.substring(3);
    } else {
      if (index == 0) {
        value = value.substring(3);
      } else if (value.startsWith('*')) {
        value = value.substring(1);
      }
      if (index == rawLines.length - 1 && value.endsWith('*/')) {
        value = value.substring(0, value.length - 2);
      }
    }
    return value.trimLeft();
  }

  String? description;
  String? fence;
  for (var index = 0; index < rawLines.length; index++) {
    final line = cleanLine(rawLines[index], index);
    final fenceMatch = RegExp(r'^(`{3,}|~{3,})').firstMatch(line);
    if (fenceMatch != null) {
      final marker = fenceMatch.group(1)!;
      if (fence == null) {
        fence = marker;
      } else if (marker[0] == fence[0] && marker.length >= fence.length) {
        fence = null;
      }
      continue;
    }
    if (fence != null || !RegExp(r'^@description(?:\s|$)').hasMatch(line)) {
      continue;
    }
    final text = line.substring('@description'.length).trim();
    if (text.isEmpty) {
      throw const FormatException(
        '@description requires text on the same documentation line.',
      );
    }
    if (description != null) {
      throw const FormatException('Duplicate @description tags.');
    }
    description = text;
  }
  return description;
}
