import '../constraints/string_literal_constraint.dart';
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

/// Returns `true` when [schema] declares a [StringLiteralConstraint] whose
/// [StringLiteralConstraint.expectedValue] matches [label].
///
/// Used to enforce the branch-owned discriminator policy: each branch in a
/// `Ack.discriminated(...)` schema must define the discriminator field with
/// `Ack.literal(label)`. Multiple literal constraints are allowed only when
/// every one of them matches [label].
bool hasMatchingDiscriminatorLiteral(AnyAckSchema schema, String label) {
  final base = unwrapDiscriminatedBranchSchema(schema);
  final literals = base.constraints
      .whereType<StringLiteralConstraint>()
      .toList(growable: false);

  return literals.isNotEmpty &&
      literals.every((constraint) => constraint.expectedValue == label);
}
