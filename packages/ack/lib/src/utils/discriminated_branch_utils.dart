import '../schemas/schema.dart';

/// Returns the underlying branch schema by unwrapping any codec / default
/// layers.
///
/// Discriminated branches may be wrapped in [CodecSchema] or [DefaultSchema]
/// while still being object-backed at their core. For [CodecSchema], the
/// boundary form (`inputSchema`) is what carries the discriminator field,
/// so we follow that side. (`.transform(...)` returns a one-way
/// `CodecSchema`, so the codec arm covers transforms too.)
AckSchema unwrapDiscriminatedBranchSchema(AckSchema schema) {
  var current = schema;
  while (true) {
    if (current is CodecSchema) {
      current = current.inputSchema;
      continue;
    }
    if (current is DefaultSchema) {
      current = current.inner;
      continue;
    }
    break;
  }

  return current;
}

/// Verifies that an existing discriminator property is exactly pinned to
/// [label].
///
/// Existing discriminator properties are allowed only when their raw JSON Schema
/// is a matching `const` value or a single-value `enum`. Loose schemas like
/// `Ack.string()` are ambiguous and mismatched literals would be silently masked
/// by discriminator injection, so both are rejected.
void assertCompatibleDiscriminatorProperty({
  required String discriminatorKey,
  required String label,
  required Object? rawPropertySchema,
}) {
  if (rawPropertySchema == null) return;
  if (rawDiscriminatorPropertyMatchesLabel(rawPropertySchema, label)) return;

  throw ArgumentError(
    'Discriminator key "$discriminatorKey" conflicts with existing property in branch "$label".',
  );
}

bool rawDiscriminatorPropertyMatchesLabel(
  Object? rawPropertySchema,
  String label,
) {
  if (rawPropertySchema is! Map) return false;

  if (rawPropertySchema.containsKey('const')) {
    return rawPropertySchema['const'] == label;
  }

  final enumValues = rawPropertySchema['enum'];
  return enumValues is List &&
      enumValues.length == 1 &&
      enumValues.single == label;
}
