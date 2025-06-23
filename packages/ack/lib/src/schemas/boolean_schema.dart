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

  /// Creates a new BooleanSchema with strict parsing enabled/disabled
  BooleanSchema strictParsing({bool value = true}) =>
      copyWithBooleanProperties(strictPrimitiveParsing: value);

  /// Creates a new BooleanSchema with modified boolean-specific properties
  BooleanSchema copyWithBooleanProperties({
    bool? strictPrimitiveParsing,
    String? description,
    Object? defaultValue,
    List<Validator<bool>>? constraints,
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
  SchemaResult<bool> tryConvertInput(
    Object? inputValue,
    SchemaContext context,
  ) {
    if (inputValue is bool) return SchemaResult.ok(inputValue);

    if (strictPrimitiveParsing) {
      final constraintError =
          InvalidTypeConstraint(expectedType: bool).validate(inputValue);

      return SchemaResult.fail(SchemaConstraintsError(
        constraints: constraintError != null ? [constraintError] : [],
        context: context,
      ));
    }

    if (inputValue is String) {
      if (inputValue.toLowerCase() == 'true') return SchemaResult.ok(true);
      if (inputValue.toLowerCase() == 'false') return SchemaResult.ok(false);
    }

    final constraintError =
        InvalidTypeConstraint(expectedType: bool).validate(inputValue);

    return SchemaResult.fail(SchemaConstraintsError(
      constraints: constraintError != null ? [constraintError] : [],
      context: context,
    ));
  }

  @override
  SchemaResult<bool> validateConvertedValue(
    bool? convertedValue,
    SchemaContext context,
  ) {
    if (convertedValue == null) {
      final constraintError =
          InvalidTypeConstraint(expectedType: bool, inputValue: null)
              .validate(null);

      return SchemaResult.fail(
        SchemaConstraintsError(
          constraints: constraintError != null ? [constraintError] : [],
          context: context,
        ),
      );
    }

    return SchemaResult.ok(convertedValue);
  }

  @override
  BooleanSchema copyWithInternal({
    String? description,
    Object? defaultValue,
    List<Validator<bool>>? constraints,
  }) {
    return BooleanSchema(
      description: description ?? this.description,
      defaultValue: defaultValue == ackRawDefaultValue
          ? this.defaultValue
          : defaultValue as bool?,
      constraints: constraints ?? this.constraints,
      strictPrimitiveParsing: strictPrimitiveParsing,
    );
  }

  @override
  Map<String, Object?> toJsonSchema() {
    Map<String, Object?> schema = {
      'type': 'boolean',
      if (description != null) 'description': description,
      if (defaultValue != null) 'default': defaultValue,
    };

    // Check constraints that implement JsonSchemaSpec
    final constraintSchemas = <Map<String, Object?>>[];
    for (final constraint in constraints) {
      if (constraint is JsonSchemaSpec) {
        constraintSchemas.add((constraint as JsonSchemaSpec).toJsonSchema());
      }
    }

    return constraintSchemas.fold(
      schema,
      (prev, current) => deepMerge(prev, current),
    );
  }
}
