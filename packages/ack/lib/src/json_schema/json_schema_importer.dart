part of '../schemas/schema.dart';

/// A limitation or error found while importing a JSON Schema document.
@immutable
final class JsonSchemaImportDiagnostic {
  const JsonSchemaImportDiagnostic({
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

/// A strict import encountered a limitation, or the input cannot be imported.
final class JsonSchemaImportException implements Exception {
  JsonSchemaImportException(Iterable<JsonSchemaImportDiagnostic> diagnostics)
    : diagnostics = List.unmodifiable(diagnostics);

  final List<JsonSchemaImportDiagnostic> diagnostics;

  @override
  String toString() => 'JSON Schema import failed:\n${diagnostics.join('\n')}';
}

/// The imported validator and an immutable report of omitted semantics.
@immutable
final class JsonSchemaImportResult {
  JsonSchemaImportResult._(
    this.schema,
    Iterable<JsonSchemaImportDiagnostic> issues,
  ) : diagnostics = List.unmodifiable(issues);

  final AckSchema<Object, Object> schema;
  final List<JsonSchemaImportDiagnostic> diagnostics;

  /// Whether every assertion reachable from the imported schema is supported.
  bool get isExact => diagnostics.isEmpty;
}

/// Imports a decoded draft 2020-12 JSON Schema (a map or boolean).
///
/// [documents] supplies referenced documents keyed by retrieval URI. Relative
/// registry keys resolve against [baseUri]. No files or URLs are fetched.
/// `$id`, `$anchor`, and JSON Pointer references are resolved within the bundle.
/// An absent `$schema` selects draft 2020-12 semantics.
///
/// By default any unsupported keyword throws [JsonSchemaImportException]. With
/// [allowUnsupported], unsupported assertions are omitted and reported. The
/// resulting schema may accept more values, but never intentionally fewer.
/// Invalid supported keywords, missing references, unsupported dialects, and
/// reference cycles that do not descend into an instance always throw.
JsonSchemaImportResult importJsonSchema(
  Object document, {
  Uri? baseUri,
  Map<Uri, Object> documents = const {},
  bool allowUnsupported = false,
}) {
  final compiler = _JsonSchemaCompiler();
  final base = baseUri ?? Uri.parse('ack-import:///root.json');
  final root = compiler.addDocument(document, base);
  for (final entry in documents.entries) {
    compiler.addDocument(entry.value, base.resolveUri(entry.key));
  }
  compiler.compile(root);
  if (!allowUnsupported && compiler.diagnostics.isNotEmpty) {
    throw JsonSchemaImportException(compiler.diagnostics);
  }
  return JsonSchemaImportResult._(
    ImportedJsonSchema._(root),
    compiler.diagnostics,
  );
}
