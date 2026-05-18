import '../schemas/schema.dart';

/// Returns the underlying branch schema by unwrapping wrapper layers.
///
/// Discriminated branches may be wrapped while still being object-backed at
/// their core.
AnyAckSchema unwrapDiscriminatedBranchSchema(AnyAckSchema schema) {
  AnyAckSchema current = schema;
  while (current is WrapperSchema) {
    current = current.inner;
  }

  return current;
}
