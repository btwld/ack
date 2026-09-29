/// One reason a JSON Schema document cannot generate Ack models.
final class AckJsonSchemaDiagnostic {
  /// Creates a diagnostic for the node at [pointer].
  const AckJsonSchemaDiagnostic(this.pointer, this.message);

  /// The JSON pointer of the offending node, such as `#/$defs/User/type`.
  final String pointer;

  /// What is unsupported and, where possible, how to fix it.
  final String message;

  @override
  String toString() => '$pointer: $message';
}

/// Thrown when a JSON Schema document cannot generate Ack models.
final class AckJsonSchemaGenerationException implements Exception {
  /// Creates an exception for [documentUri] with every [diagnostics] entry.
  AckJsonSchemaGenerationException(this.documentUri, this.diagnostics)
    : assert(diagnostics.isNotEmpty, 'An exception needs a diagnostic.');

  /// The document that failed.
  final Uri documentUri;

  /// Every problem found, in document order.
  final List<AckJsonSchemaDiagnostic> diagnostics;

  @override
  String toString() => [
    'Cannot generate Ack models from $documentUri:',
    for (final diagnostic in diagnostics) '  $documentUri$diagnostic',
  ].join('\n');
}
