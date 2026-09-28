/// Member names every schema-first model generates, so a field cannot use
/// them.
const ackSchemaFirstReservedMembers = {
  r'$ack',
  'parse',
  'safeParse',
  'fromJson',
  'toJson',
  'safeToJson',
  'copyWith',
  '_fromAckRuntime',
  '_toAckRuntime',
  'hashCode',
  'noSuchMethod',
  'toString',
  'runtimeType',
};

/// Dart reserved words, which cannot be field names.
const ackDartReservedWords = {
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

/// Why [key] cannot be a schema-first field name, or `null` when it can.
///
/// [capturesExtras] is whether the model stores unknown properties in its
/// generated `additionalProperties` field.
String? ackSchemaFirstFieldNameProblem(
  String key, {
  required bool capturesExtras,
}) {
  if (key.startsWith('_')) {
    return "cannot start with '_' (private Dart member).";
  }
  if (!RegExp(r'^[A-Za-z$][A-Za-z0-9_$]*$').hasMatch(key) ||
      ackDartReservedWords.contains(key)) {
    return 'cannot be represented as a Dart field name.';
  }
  if (ackSchemaFirstReservedMembers.contains(key)) {
    return 'conflicts with generated/Object member "$key".';
  }
  if (capturesExtras && key == 'additionalProperties') {
    return 'conflicts with the generated additional-properties member.';
  }
  return null;
}
