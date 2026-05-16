import '../schemas/schema.dart';

/// Returns the underlying branch schema by unwrapping any transform or codec
/// layers.
///
/// Discriminated branches may be wrapped in [TransformedSchema] or
/// [CodecSchema] while still being object-backed at their core.
AckSchema unwrapDiscriminatedBranchSchema(AckSchema schema) {
  var current = schema;
  while (true) {
    if (current is TransformedSchema) {
      current = current.schema;
      continue;
    }
    if (current is CodecSchema) {
      current = current.inputSchema as AckSchema;
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
