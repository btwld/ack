import '../utils/string_literal.dart';

/// Names that conflict with generated APIs or their unqualified type references.
const ackSchemaFirstReservedMembers = {
  r'$ack',
  // Generated JSON signatures use the unqualified dynamic type.
  'dynamic',
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
      isDartReservedWord(key)) {
    return 'cannot be represented as a Dart field name.';
  }
  if (key == 'dynamic') {
    return 'shadows the dynamic type used by generated JSON methods.';
  }
  if (ackSchemaFirstReservedMembers.contains(key)) {
    return 'conflicts with generated/Object member "$key".';
  }
  if (capturesExtras && key == 'additionalProperties') {
    return 'conflicts with the generated additional-properties member.';
  }
  return null;
}
