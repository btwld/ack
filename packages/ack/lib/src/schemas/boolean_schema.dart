part of 'schema.dart';

/// Schema for validating boolean values.
@immutable
final class BooleanSchema extends AckSchema<bool, bool>
    with FluentSchema<bool, bool, BooleanSchema> {
  const BooleanSchema({
    super.isNullable,
    super.isOptional,
    super.description,
    super.constraints,
    super.refinements,
  });

  @override
  SchemaType get schemaType => SchemaType.boolean;

  @override
  @protected
  SchemaResult<bool> parseAndValidate(
    Object? inputValue,
    SchemaContext context,
  ) {
    final nullResult = handleNullInput(inputValue, context);
    if (nullResult != null) return nullResult;

    if (inputValue is! bool) {
      return SchemaResult.fail(
        TypeMismatchError(
          expectedType: schemaType,
          actualType: AckSchema.getSchemaType(inputValue),
          context: context,
        ),
      );
    }

    return applyConstraintsAndRefinements(inputValue, context);
  }

  @override
  @protected
  SchemaResult<bool> encodeRuntime(bool value, SchemaContext context) {
    return SchemaResult.ok(value);
  }

  @override
  BooleanSchema copyWithBase({
    bool? isNullable,
    bool? isOptional,
    String? description,
    List<Constraint<bool>>? constraints,
    List<Refinement<bool>>? refinements,
  }) {
    return BooleanSchema(
      isNullable: isNullable ?? this.isNullable,
      isOptional: isOptional ?? this.isOptional,
      description: description ?? this.description,
      constraints: constraints ?? this.constraints,
      refinements: refinements ?? this.refinements,
    );
  }

  @override
  Map<String, Object?> toJsonSchema() =>
      buildJsonSchemaWithNullable(typeSchema: {'type': 'boolean'});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! BooleanSchema) return false;
    return baseFieldsEqual(other);
  }

  @override
  int get hashCode => baseFieldsHashCode;
}
