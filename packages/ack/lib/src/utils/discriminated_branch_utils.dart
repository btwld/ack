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
  bool synthesizeOnEncode = false,
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

  final properties = <String, AnyAckSchema>{
    discriminatorKey: _discriminatorLiteralSchema(discriminatorValue),
    for (final entry in objectSchema.properties.entries)
      if (entry.key != discriminatorKey) entry.key: entry.value,
  };

  return objectSchema.copyWith(
    properties: properties,
    encodeOnlyDefaults: synthesizeOnEncode
        ? {
            ...objectSchema.encodeOnlyDefaults,
            discriminatorKey: discriminatorValue,
          }
        : null,
  );
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
  bool underCodec = false,
}) {
  if (branchSchema is ObjectSchema) {
    return effectiveDiscriminatedObjectBranch(
      discriminatorKey: discriminatorKey,
      discriminatorValue: discriminatorValue,
      objectSchema: branchSchema,
      synthesizeOnEncode: underCodec,
    );
  }

  if (branchSchema is WrapperSchema) {
    // Synthesize only for the branch-root object when a CodecSchema appears
    // above it on the wrapper spine. This recursion follows `.inner` only, so
    // nested property objects are unaffected.
    final effectiveInner = effectiveDiscriminatedBranch(
      discriminatorKey: discriminatorKey,
      discriminatorValue: discriminatorValue,
      branchSchema: branchSchema.inner,
      underCodec: underCodec || branchSchema is CodecSchema,
    );
    return branchSchema.copyWithInner(effectiveInner);
  }

  throw ArgumentError('Discriminated branches must be object-backed schemas');
}
