import '../schemas/schema.dart';

/// Returns the underlying branch schema by unwrapping any transform / codec
/// / default layers.
///
/// Discriminated branches may be wrapped in [TransformedSchema], [CodecSchema],
/// or [DefaultSchema] while still being object-backed at their core. For
/// [CodecSchema], the boundary form (`inputSchema`) is what carries the
/// discriminator field, so we follow that side.
AckSchema unwrapDiscriminatedBranchSchema(AckSchema schema) {
  var current = schema;
  while (true) {
    if (current is TransformedSchema) {
      current = current.schema;
      continue;
    }
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
