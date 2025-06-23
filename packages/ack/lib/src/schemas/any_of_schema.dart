part of 'schema.dart';

/// Schema for validating against a list of schemas.
/// The input is valid if it is valid against any of the schemas in the list.
@immutable
final class AnyOfSchema extends AckSchema<Object>
    with FluentSchema<Object, AnyOfSchema> {
  final List<AckSchema> schemas;

  const AnyOfSchema(
    this.schemas, {
    super.isNullable,
    super.description,
    super.defaultValue,
    super.constraints,
    super.refinements,
  }) : super(schemaType: SchemaType.unknown);

  @override
  @protected
  SchemaResult<Object> _onConvert(Object? inputValue, SchemaContext context) {
    if (inputValue == null) {
      final constraintError =
          InvalidTypeConstraint(expectedType: Object, inputValue: null)
              .validate(null);

      return SchemaResult.fail(SchemaConstraintsError(
        constraints: constraintError != null ? [constraintError] : [],
        context: context,
      ));
    }

    final validationErrors = <SchemaError>[];

    for (final schema in schemas) {
      final result = schema.validate(inputValue);
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
  AnyOfSchema copyWithInternal({
    required bool? isNullable,
    required String? description,
    required Object? defaultValue,
    required List<Validator<Object>>? constraints,
    required List<Refinement<Object>>? refinements,
    List<AckSchema>? schemas,
  }) {
    return AnyOfSchema(
      schemas ?? this.schemas,
      isNullable: isNullable ?? this.isNullable,
      description: description ?? this.description,
      defaultValue:
          defaultValue == ackRawDefaultValue ? this.defaultValue : defaultValue,
      constraints: constraints ?? this.constraints,
      refinements: refinements ?? this.refinements,
    );
  }

  @override
  Map<String, Object?> toJsonSchema() {
    return {
      'anyOf': schemas.map((s) => s.toJsonSchema()).toList(),
      if (description != null) 'description': description,
    };
  }
}
