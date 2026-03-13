import 'package:ack_annotations/ack_annotations.dart';

String applyCaseStyle(CaseStyle style, String input) {
  return switch (style) {
    CaseStyle.none => input,
    CaseStyle.camelCase => _toCamelCase(input),
    CaseStyle.pascalCase => _toPascalCase(input),
    CaseStyle.snakeCase => _joinWords(input, '_'),
    CaseStyle.paramCase => _joinWords(input, '-'),
  };
}

String _toCamelCase(String input) {
  final words = _splitWords(input);
  if (words.isEmpty) return input;

  final tail = words.skip(1).map(_capitalize).join();
  return words.first.toLowerCase() + tail;
}

String _toPascalCase(String input) {
  return _splitWords(input).map(_capitalize).join();
}

String _joinWords(String input, String separator) {
  final words = _splitWords(input);
  if (words.isEmpty) return input;
  return words.map((word) => word.toLowerCase()).join(separator);
}

List<String> _splitWords(String input) {
  if (input.isEmpty) return const [];

  final normalized = input
      .replaceAllMapped(
        RegExp(r'([A-Z]+)([A-Z][a-z])'),
        (match) => '${match.group(1)} ${match.group(2)}',
      )
      .replaceAllMapped(
        RegExp(r'([a-z0-9])([A-Z])'),
        (match) => '${match.group(1)} ${match.group(2)}',
      )
      .replaceAll(RegExp(r'[_\-\s]+'), ' ')
      .trim();

  if (normalized.isEmpty) return const [];

  return normalized
      .split(' ')
      .where((word) => word.isNotEmpty)
      .toList(growable: false);
}

String _capitalize(String input) {
  if (input.isEmpty) return input;
  final lower = input.toLowerCase();
  return lower[0].toUpperCase() + lower.substring(1);
}
