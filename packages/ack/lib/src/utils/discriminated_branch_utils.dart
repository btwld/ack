import '../schemas/schema.dart';

/// Returns the underlying branch schema by unwrapping any codec layers.
///
/// Discriminated branches may be wrapped in a [CodecSchema] (for example a
/// `.transform(fn)` over an object schema) while still being object-backed
/// at their core.
AckSchema unwrapDiscriminatedBranchSchema(AckSchema schema) {
  var current = schema;
  while (current is CodecSchema) {
    current = current.inputSchema;
  }

  return current;
}
