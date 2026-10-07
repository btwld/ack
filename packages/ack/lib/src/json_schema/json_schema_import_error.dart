part of '../schemas/schema.dart';

/// A limitation or error found while importing a JSON Schema document.
@immutable
final class JsonSchemaImportDiagnostic {
  const JsonSchemaImportDiagnostic._({
    required this.code,
    required this.documentUri,
    required this.pointer,
    required this.keyword,
    required this.message,
  });

  /// Machine-readable reason, for example `unsupported_keyword`.
  final String code;
  final Uri documentUri;

  /// JSON Pointer URI fragment identifying the source keyword.
  final String pointer;
  final String keyword;
  final String message;

  @override
  String toString() => '$documentUri$pointer: $message ($code)';
}

/// A value failed a keyword of a schema imported by `Ack.fromJsonSchema`.
///
/// [documentUri] and [pointer] locate the failing keyword after `$ref`
/// resolution, as they do on [JsonSchemaImportDiagnostic]. [path] is the
/// instance location.
@immutable
final class JsonSchemaValidationError extends SchemaValidationError {
  JsonSchemaValidationError._({
    required super.message,
    required super.context,
    required this.keyword,
    required this.documentUri,
    required this.pointer,
  });

  /// The failing keyword, or empty when the failing subschema is `false`.
  final String keyword;
  final Uri documentUri;

  /// JSON Pointer URI fragment identifying the failing keyword.
  final String pointer;

  @override
  Map<String, Object?> toMap() => {
    ...super.toMap(),
    'keyword': keyword,
    'documentUri': '$documentUri',
    'pointer': pointer,
  };
}

/// A strict import encountered a limitation, or the input cannot be imported.
final class JsonSchemaImportException implements Exception {
  JsonSchemaImportException._(Iterable<JsonSchemaImportDiagnostic> diagnostics)
    : diagnostics = List.unmodifiable(diagnostics);

  final List<JsonSchemaImportDiagnostic> diagnostics;

  @override
  String toString() => 'JSON Schema import failed:\n${diagnostics.join('\n')}';
}
