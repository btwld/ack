import '../schemas/schema.dart';

/// Returns the underlying branch schema by unwrapping any transform / codec
/// layers.
///
/// Discriminated branches may be wrapped in [TransformedSchema] or
/// [CodecSchema] while still being object-backed at their core. For
/// [CodecSchema], the boundary form (`inputSchema`) is what carries the
/// discriminator field, so we follow that side.
///
/// TODO(M12): also unwrap `DefaultSchema` once it lands.
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
    break;
  }

  return current;
}
