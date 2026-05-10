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
