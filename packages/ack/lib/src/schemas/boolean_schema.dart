part of 'schema.dart';

/// Schema for validating boolean (`bool`) values.
@immutable
final class BooleanSchema extends AckSchema<bool> {
  final bool strictPrimitiveParsing;

  const BooleanSchema({
    String? description,
    bool? defaultValue,
    List<Validator<bool>> constraints = const [],
    this.strictPrimitiveParsing = false,
  }) : super(
          schemaType: SchemaType.boolean,
          description: description,
          defaultValue: defaultValue,
          constraints: constraints,
        );

  BooleanSchema strictParsing({bool value = true}) =>
      copyWith(strictPrimitiveParsing: value);

  @override
  SchemaResult<bool> tryConvertInput(
    Object? inputValue,
    SchemaContext context,
  ) {
    if (inputValue is bool) return SchemaResult.ok(inputValue);

    if (strictPrimitiveParsing) {
      return SchemaResult.fail(SchemaConstraintsError(
        constraints: [
          InvalidTypeConstraint(expectedType: bool).validate(inputValue)!,
        ],
        context: context,
      ));
    }

    if (inputValue is String) {
      if (inputValue.toLowerCase() == 'true') return SchemaResult.ok(true);
      if (inputValue.toLowerCase() == 'false') return SchemaResult.ok(false);
    }

    return SchemaResult.fail(SchemaConstraintsError(
      constraints: [
        InvalidTypeConstraint(expectedType: bool).validate(inputValue)!,
      ],
      context: context,
    ));
  }

  @override
  SchemaResult<bool> validateConvertedValue(
    bool? convertedValue,
    SchemaContext context,
  ) {
    if (convertedValue == null) {
      return SchemaResult.fail(
        SchemaConstraintsError(
          constraints: [
            InvalidTypeConstraint(expectedType: bool, inputValue: null)
                .validate(null)!,
          ],
          context: context,
        ),
      );
    }

    return SchemaResult.ok(convertedValue);
  }

  @override
  BooleanSchema copyWith({
    String? description,
    Object? defaultValue,
    List<Validator<bool>>? constraints,
    bool? strictPrimitiveParsing,
  }) {
    return BooleanSchema(
      description: description ?? this.description,
      defaultValue: defaultValue == ackRawDefaultValue
          ? this.defaultValue
          : defaultValue as bool?,
      constraints: constraints ?? this.constraints,
      strictPrimitiveParsing:
          strictPrimitiveParsing ?? this.strictPrimitiveParsing,
    );
  }

  @override
  BooleanSchema withDefault(bool val) {
    return copyWith(defaultValue: val);
  }

  @override
  Map<String, Object?> toJsonSchema() {
    Map<String, Object?> schema = {
      'type': 'boolean',
      if (description != null) 'description': description,
      if (defaultValue != null) 'default': defaultValue,
    };
    final constraintSchemas = constraints
        .whereType<JsonSchemaSpec<bool>>()
        .map((c) => c.toJsonSchema())
        .fold<Map<String, Object?>>(
      {},
      (prev, current) => deepMerge(prev, current),
    );

    return deepMerge(schema, constraintSchemas);
  }

  @override
  BooleanSchema addConstraint(Validator<bool> constraint) {
    return copyWith(constraints: [...constraints, constraint]);
  }

  @override
  BooleanSchema addConstraints(List<Validator<bool>> newConstraints) {
    return copyWith(constraints: [...constraints, ...newConstraints]);
  }

  @override
  BooleanSchema withDescription(String? newDescription) {
    return copyWith(description: newDescription);
  }
}
