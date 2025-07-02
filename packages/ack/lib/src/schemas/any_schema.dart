part of 'schema.dart';

/// Schema that accepts any value without type conversion or validation.
/// Useful for dynamic content or when you need maximum flexibility.
@immutable
final class AnySchema extends AckSchema<Object>
    with FluentSchema<Object, AnySchema> {
  const AnySchema({
    super.isNullable,
    super.description,
    super.defaultValue,
    super.constraints,
    super.refinements,
  }) : super(schemaType: SchemaType.unknown);

  @override
  @protected
  SchemaResult<Object> _onConvert(Object? inputValue, SchemaContext context) {
    // Accept any non-null value as-is
    if (inputValue != null) {
      return SchemaResult.ok(inputValue);
    }

    // Handle null case - use default validation logic
    final constraintError = NonNullableConstraint().validate(null);

    return SchemaResult.fail(SchemaConstraintsError(
      constraints: constraintError != null ? [constraintError] : [],
      context: context,
    ));
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
    return {
      // No type restriction in JSON Schema
      if (description != null) 'description': description,
      if (defaultValue != null) 'default': defaultValue,
    };
  }
}
