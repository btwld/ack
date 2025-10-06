part of 'schema.dart';

/// Schema that accepts any value without type conversion or validation.
/// Useful for dynamic content or when you need maximum flexibility.
///
/// Unlike composite schemas (List, Object, AnyOf, Discriminated), AnySchema
/// supports default values and will emit them in JSON Schema output.
@immutable
final class AnySchema extends AckSchema<Object>
    with FluentSchema<Object, AnySchema> {
  const AnySchema({
    super.isNullable,
    super.isOptional,
    super.description,
    super.defaultValue,
    super.constraints,
    super.refinements,
  });

  @override
  SchemaType get schemaType => SchemaType.any;

  /// AnySchema accepts all values, so it overrides parseAndValidate directly.
  @override
  @protected
  SchemaResult<Object> parseAndValidate(
    Object? inputValue,
    SchemaContext context,
  ) {
    // Inline null handling for scalar schema
    if (inputValue == null) {
      if (defaultValue != null) {
        // Clone the default to prevent mutation
        final clonedDefault = cloneDefault(defaultValue!) as Object;
        return applyConstraintsAndRefinements(clonedDefault, context);
      }
      if (isNullable) {
        return SchemaResult.ok(null);
      }
      return failNonNullable(context);
    }

    // Accept any non-null value as-is, then use centralized constraints and refinements check
    return applyConstraintsAndRefinements(inputValue, context);
  }

  @override
  AnySchema copyWith({
    bool? isNullable,
    bool? isOptional,
    String? description,
    Object? defaultValue,
    List<Constraint<Object>>? constraints,
    List<Refinement<Object>>? refinements,
  }) {
    return AnySchema(
      isNullable: isNullable ?? this.isNullable,
      isOptional: isOptional ?? this.isOptional,
      description: description ?? this.description,
      defaultValue: defaultValue ?? this.defaultValue,
      constraints: constraints ?? this.constraints,
      refinements: refinements ?? this.refinements,
    );
  }

  @override
  Map<String, Object?> toJsonSchema() {
    // AnySchema accepts anything - use empty schema per JSON Schema standard
    if (isNullable) {
      // Nullable any: anyOf with empty schema and null
      final baseSchema = {
        if (description != null) 'description': description,
        // Don't include default in baseSchema - it goes at anyOf level
      };
      final mergedSchema = mergeConstraintSchemas(baseSchema);
      return {
        if (defaultValue != null) 'default': defaultValue,
        'anyOf': [
          mergedSchema,
          {'type': 'null'},
        ],
      };
    }

    // Non-nullable any: empty schema {} means "accepts any value" (but not null)
    // Metadata fields like description and default are allowed in empty schemas
    final schema = {
      if (description != null) 'description': description,
      if (defaultValue != null) 'default': defaultValue,
    };

    // Merge constraints into the JSON Schema
    return mergeConstraintSchemas(schema);
  }
}
