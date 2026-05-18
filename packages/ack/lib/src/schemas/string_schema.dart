part of 'schema.dart';

/// Schema for validating string values.
@immutable
final class StringSchema extends AckSchema<String, String>
    with FluentSchema<String, String, StringSchema> {
  const StringSchema({
    super.isNullable,
    super.isOptional,
    super.description,
    super.constraints,
    super.refinements,
  });

  @override
  SchemaType get schemaType => SchemaType.string;

  @override
  @protected
  SchemaResult<String> parseWithContext(Object? value, SchemaContext context) =>
      validateRuntimeWithContext(value, context);

  @override
  @protected
  SchemaResult<String> validateRuntimeWithContext(
    Object? value,
    SchemaContext context,
  ) {
    final nullResult = handleNullInput(value, context);
    if (nullResult != null) return nullResult;

    if (value is! String) {
      return SchemaResult.fail(
        TypeMismatchError(
          expectedType: schemaType,
          actualType: AckSchema.getSchemaType(value),
          context: context,
        ),
      );
    }

    return applyConstraintsAndRefinements(value, context);
  }

  @override
  @protected
  SchemaResult<String> encodeWithContext(String value, SchemaContext context) =>
      encodeAsBoundary(value, context);

  @override
  StringSchema copyWith({
    bool? isNullable,
    bool? isOptional,
    String? description,
    List<Constraint<String>>? constraints,
    List<Refinement<String>>? refinements,
  }) {
    return StringSchema(
      isNullable: isNullable ?? this.isNullable,
      isOptional: isOptional ?? this.isOptional,
      description: description ?? this.description,
      constraints: constraints ?? this.constraints,
      refinements: refinements ?? this.refinements,
    );
  }

  @override
  Map<String, Object?> toJsonSchema() =>
      buildJsonSchemaWithNullable(typeSchema: {'type': 'string'});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! StringSchema) return false;
    return baseFieldsEqual(other);
  }

  @override
  int get hashCode => baseFieldsHashCode;
}
