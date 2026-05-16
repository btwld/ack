part of 'schema.dart';

/// Schema for validating string values.
///
/// `StringSchema` is a primitive schema where boundary and runtime types both
/// equal `String`.
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
  SchemaResult<String> parseAndValidate(
    Object? inputValue,
    SchemaContext context,
  ) {
    final nullResult = handleNullInput(inputValue, context);
    if (nullResult != null) return nullResult;

    if (inputValue is! String) {
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
  SchemaResult<String> encodeRuntime(String value, SchemaContext context) {
    return SchemaResult.ok(value);
  }

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
