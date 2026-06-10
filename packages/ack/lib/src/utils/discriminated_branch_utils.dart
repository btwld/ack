import '../constraints/pattern_constraint.dart';
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

StringSchema _discriminatorLiteralSchema(String discriminatorValue) {
  return StringSchema(
    constraints: [StringLiteralConstraint(discriminatorValue)],
  );
}

/// Returns whether [propertySchema] accepts [discriminatorValue] as a value of
/// the discriminator field.
///
/// This compatibility check is structural and side-effect-free. It does not
/// parse the discriminator value because parsing can execute user
/// transforms/refinements during branch selection or schema export.
bool discriminatorPropertyAcceptsValue({
  required AnyAckSchema propertySchema,
  required String discriminatorValue,
}) {
  if (propertySchema is! StringSchema) return false;
  if (propertySchema.refinements.isNotEmpty) return false;
  if (propertySchema.constraints.length != 1) return false;

  final constraint = propertySchema.constraints.single;
  if (constraint is StringLiteralConstraint) {
    return constraint.expectedValue == discriminatorValue;
  }

  if (constraint is PatternConstraint &&
      constraint.type == PatternType.enumString) {
    return constraint.allowedValues?.contains(discriminatorValue) ?? false;
  }

  return false;
}

/// Builds the effective object branch for a discriminated-union value.
///
/// The returned object schema always contains [discriminatorKey] first, as an
/// exact string literal matching [discriminatorValue]. The authored schema is
/// never mutated.
ObjectSchema effectiveDiscriminatedObjectBranch({
  required String discriminatorKey,
  required String discriminatorValue,
  required ObjectSchema objectSchema,
}) {
  final existingDiscriminator = objectSchema.properties[discriminatorKey];
  if (existingDiscriminator != null &&
      !discriminatorPropertyAcceptsValue(
        propertySchema: existingDiscriminator,
        discriminatorValue: discriminatorValue,
      )) {
    throw ArgumentError(
      'Discriminator property "$discriminatorKey" does not accept '
      'branch value "$discriminatorValue".',
    );
  }

  // Extend the authored branch with the union-owned discriminator as an exact
  // literal. Keep it first so exported property order stays stable.
  final literal = _discriminatorLiteralSchema(discriminatorValue);
  final properties = <String, AnyAckSchema>{
    discriminatorKey: literal,
    for (final entry in objectSchema.properties.entries)
      if (entry.key != discriminatorKey) entry.key: entry.value,
  };

  return objectSchema.copyWith(properties: properties);
}

/// Builds the effective schema for a discriminated-union branch.
///
/// Supports plain object branches and wrapper-backed branches (codecs,
/// defaults). The effective schema validates/exports with a union-injected
/// literal discriminator while preserving the branch output type.
///
/// Returns a type-erased [AnyAckSchema]; callers in a typed context (such as
/// [DiscriminatedObjectSchema.effectiveBranch]) should cast back to the
/// schema's specific `AckSchema<Boundary, Runtime>` shape.
AnyAckSchema effectiveDiscriminatedBranch({
  required String discriminatorKey,
  required String discriminatorValue,
  required AnyAckSchema branchSchema,
}) {
  if (branchSchema is ObjectSchema) {
    return effectiveDiscriminatedObjectBranch(
      discriminatorKey: discriminatorKey,
      discriminatorValue: discriminatorValue,
      objectSchema: branchSchema,
    );
  }

  if (branchSchema is WrapperSchema) {
    final effectiveInner = effectiveDiscriminatedBranch(
      discriminatorKey: discriminatorKey,
      discriminatorValue: discriminatorValue,
      branchSchema: branchSchema.inner,
    );

    return branchSchema.copyWithInner(effectiveInner);
  }

  throw ArgumentError('Discriminated branches must be object-backed schemas');
}
