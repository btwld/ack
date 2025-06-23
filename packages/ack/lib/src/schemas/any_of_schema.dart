part of 'schema.dart';

/// Schema for validating against a list of schemas.
/// The input is valid if it is valid against any of the schemas in the list.
@immutable
final class AnyOfSchema extends AckSchema<Object> {
  final List<AckSchema> schemas;

  const AnyOfSchema(
    this.schemas, {
    super.isNullable,
    super.description,
    super.defaultValue,
    super.constraints,
  }) : super(schemaType: SchemaType.unknown);

  @override
  AnyOfSchema copyWithInternal({
    required bool? isNullable,
    required String? description,
    required Object? defaultValue,
    required List<Validator<Object>>? constraints,
    List<AckSchema>? schemas,
  }) {
    return AnyOfSchema(
      schemas ?? this.schemas,
      isNullable: isNullable ?? this.isNullable,
      description: description ?? this.description,
      defaultValue:
          defaultValue == ackRawDefaultValue ? this.defaultValue : defaultValue,
      constraints: constraints ?? this.constraints,
    );
  }

  @override
  SchemaResult<Object> tryConvertInput(
    Object? inputValue,
    SchemaContext context,
  ) {
    // For `anyOf`, conversion is tricky as we don't know the target type.
    // We pass the raw input to `validateConvertedValue` and let the sub-schemas handle conversion.
    if (inputValue != null) {
      return SchemaResult.ok(inputValue);
    }

    final constraintError =
        InvalidTypeConstraint(expectedType: Object, inputValue: inputValue)
            .validate(inputValue);

    return SchemaResult.fail(SchemaConstraintsError(
      constraints: constraintError != null ? [constraintError] : [],
      context: context,
    ));
  }

  @override
  SchemaResult<Object> validateConvertedValue(
    Object convertedValue,
    SchemaContext context,
  ) {
    final validationErrors = <SchemaError>[];

    for (final schema in schemas) {
      final result = schema.validate(convertedValue);
      if (result.isOk) {
        return SchemaResult.ok(result.getOrThrow()!);
      }
      validationErrors.add(result.getError());
    }

    return SchemaResult.fail(SchemaNestedError(
      errors: validationErrors,
      context: context,
    ));
  }

  @override
  Map<String, Object?> toJsonSchema() {
    return {
      'anyOf': schemas.map((s) => s.toJsonSchema()).toList(),
      if (description != null) 'description': description,
    };
  }
}
