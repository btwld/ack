import '../schemas/schema.dart';

/// Returns the underlying branch schema by unwrapping any transform layers.
///
/// Discriminated branches may be wrapped in [TransformedSchema] while still
/// being object-backed at their core.
AckSchema unwrapDiscriminatedBranchSchema(AckSchema schema) {
  var current = schema;
  while (current is TransformedSchema) {
    current = current.schema;
  }

  return current;
}
