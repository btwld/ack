import '../constraints/string_literal_constraint.dart';
import '../schemas/schema.dart';

/// Walks wrapper schemas to return the underlying base schema.
///
/// Handles both [CodecSchema] (input boundary) and [DefaultSchema] (parse-time
/// default supplier). Used by branch-is-object-backed checks and JSON Schema
/// emission to inspect a schema's underlying shape regardless of how it was
/// composed.
AckSchema unwrapWrappers(AckSchema schema) {
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

/// True if [schema] supplies a parse-time default anywhere in its wrapper
/// stack (after walking codec layers).
///
/// Distinct from [unwrapWrappers]: that helper unwraps everything for shape
/// inspection, while this one preserves the question "would parse synthesize
/// a default for this schema?". A `CodecSchema(DefaultSchema(...))` qualifies
/// because the codec delegates `decodeBoundary` to its input schema, which
/// supplies the default.
bool providesParseDefault(AckSchema schema) {
  var current = schema;
  while (true) {
    if (current is DefaultSchema) return true;
    if (current is CodecSchema) {
      current = current.inputSchema;
      continue;
    }
    break;
  }

  return false;
}

/// Backwards-compatible alias for [unwrapWrappers].
///
/// The original name implied this was specific to discriminated-union branch
/// resolution, but the same wrapper-traversal policy is needed by JSON Schema
/// default serialization and the missing-optional gate. Prefer [unwrapWrappers]
/// for new call sites.
AckSchema unwrapDiscriminatedBranchSchema(AckSchema schema) =>
    unwrapWrappers(schema);

/// Verifies a discriminated branch's pre-declared discriminator property is
/// compatible with [label].
///
/// The canonical Ack pattern is for branches to declare the discriminator
/// field as `Ack.literal(label)`. Returns `null` when the branch is compatible
/// (literal value matches [label], or the property is absent). Returns an
/// [ArgumentError] to throw when the existing property is incompatible.
ArgumentError? checkDiscriminatorBranchConflict({
  required ObjectSchema baseBranch,
  required String discriminatorKey,
  required String label,
}) {
  final existing = baseBranch.properties[discriminatorKey];
  if (existing == null) return null;

  final unwrapped = unwrapWrappers(existing);
  if (unwrapped is StringSchema) {
    for (final constraint in unwrapped.constraints) {
      if (constraint is StringLiteralConstraint &&
          constraint.expectedValue == label) {
        return null;
      }
    }
  }

  return ArgumentError(
    'Discriminator key "$discriminatorKey" in branch "$label" must be '
    '`Ack.literal("$label")` or omitted; got incompatible schema.',
  );
}
