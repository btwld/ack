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
        return applyConstraintsAndRefinements(defaultValue!, context);
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
  AnySchema copyWithInternal({
    required bool? isNullable,
    required String? description,
    required Object? defaultValue,
    required List<Constraint<Object>>? constraints,
    required List<Refinement<Object>>? refinements,
  }) {
    return AnySchema(
      isNullable: isNullable ?? this.isNullable,
      description: description ?? this.description,
      defaultValue: defaultValue ?? this.defaultValue,
      constraints: constraints ?? this.constraints,
      refinements: refinements ?? this.refinements,
    );
  }

  @override
  Map<String, Object?> toJsonSchema() {
    // AnySchema accepts anything, including null if nullable
    final schema = isNullable
        ? {
            // No type restriction means it accepts any type including null
            if (description != null) 'description': description,
            if (defaultValue != null) 'default': defaultValue,
          }
        : {
            // Accepts any type except null - use explicit type array for better compatibility
            'type': ['boolean', 'number', 'integer', 'string', 'object', 'array'],
            if (description != null) 'description': description,
            if (defaultValue != null) 'default': defaultValue,
          };

    // Merge constraints into the JSON Schema
    return mergeConstraintSchemas(schema);
  }
}
