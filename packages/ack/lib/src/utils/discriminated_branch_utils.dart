import '../constraints/string_literal_constraint.dart';
import '../schemas/schema.dart';

StringSchema _discriminatorLiteralSchema(String discriminatorValue) {
  return StringSchema(
    constraints: [StringLiteralConstraint(discriminatorValue)],
  );
}

/// Returns whether [propertySchema] accepts [discriminatorValue].
bool discriminatorPropertyAcceptsValue({
  required AckSchema propertySchema,
  required String discriminatorValue,
}) {
  return propertySchema.safeParse(discriminatorValue).isOk;
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

  final properties = <String, AckSchema>{
    discriminatorKey: _discriminatorLiteralSchema(discriminatorValue),
    for (final entry in objectSchema.properties.entries)
      if (entry.key != discriminatorKey) entry.key: entry.value,
  };

  return objectSchema.copyWith(properties: properties);
}

/// Builds the effective schema for a discriminated-union branch.
///
/// Supports plain object branches and direct object-backed transforms. The
/// effective schema validates/exports as if the branch owned a literal
/// discriminator, while preserving the branch output type.
AckSchema<T> effectiveDiscriminatedBranch<T extends Object>({
  required String discriminatorKey,
  required String discriminatorValue,
  required AckSchema<T> branchSchema,
}) {
  return _effectiveDiscriminatedBranch(
        discriminatorKey: discriminatorKey,
        discriminatorValue: discriminatorValue,
        branchSchema: branchSchema,
      )
      as AckSchema<T>;
}

AckSchema _effectiveDiscriminatedBranch({
  required String discriminatorKey,
  required String discriminatorValue,
  required AckSchema branchSchema,
}) {
  if (branchSchema is ObjectSchema) {
    return effectiveDiscriminatedObjectBranch(
      discriminatorKey: discriminatorKey,
      discriminatorValue: discriminatorValue,
      objectSchema: branchSchema,
    );
  }

  if (branchSchema is TransformedSchema<Object, Object>) {
    final effectiveInputSchema = _effectiveDiscriminatedBranch(
      discriminatorKey: discriminatorKey,
      discriminatorValue: discriminatorValue,
      branchSchema: branchSchema.schema,
    );
    return branchSchema.copyWithSchema(effectiveInputSchema);
  }

  throw ArgumentError('Discriminated branches must be object-backed schemas');
}
