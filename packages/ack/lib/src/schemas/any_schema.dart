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
    // Use centralized null handling
    final nullResult = handleNullInput(inputValue, context);
    if (nullResult != null) return nullResult;

    // After null check, inputValue is guaranteed non-null
    // Accept any non-null value as-is, then use centralized constraints and refinements check
    return applyConstraintsAndRefinements(inputValue!, context);
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
  Map<String, Object?> toJsonSchema() => buildJsonSchemaWithNullable(
        // Empty typeSchema means "accepts any value" per JSON Schema standard
        typeSchema: {},
        serializedDefault: defaultValue,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AnySchema) return false;
    return baseFieldsEqual(other);
  }

  @override
  int get hashCode => baseFieldsHashCode;
}
