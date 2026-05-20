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
  SchemaResult<bool> parseWithContext(Object? value, SchemaContext context) =>
      validateRuntimeWithContext(value, context);

  @override
  @protected
  SchemaResult<bool> validateRuntimeWithContext(
    Object? value,
    SchemaContext context,
  ) {
    final nullResult = handleNullInput(value, context);
    if (nullResult != null) return nullResult;

    if (value is! bool) {
      return SchemaResult.fail(
        _buildTypeMismatch(
          expectedType: schemaType,
          actualValue: value,
          context: context,
        ),
      );
    }

    return applyConstraintsAndRefinements(value, context);
  }

  @override
  @protected
  SchemaResult<bool> encodeWithContext(bool value, SchemaContext context) =>
      encodeAsBoundary(value, context);

  @override
  BooleanSchema copyWith({
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
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! BooleanSchema) return false;
    return baseFieldsEqual(other);
  }

  @override
  int get hashCode => baseFieldsHashCode;
}
