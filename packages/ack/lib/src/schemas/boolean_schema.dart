part of 'schema.dart';

/// Schema for validating boolean (`bool`) values.
@immutable
final class BooleanSchema extends AckSchema<bool>
    with FluentSchema<bool, BooleanSchema> {
  final bool strictPrimitiveParsing;

  const BooleanSchema({
    this.strictPrimitiveParsing = false,
    super.isNullable,
    super.description,
    super.defaultValue,
    super.constraints,
  }) : super(schemaType: SchemaType.boolean);

  /// Creates a new BooleanSchema with strict parsing enabled/disabled
  BooleanSchema strictParsing({bool value = true}) =>
      copyWith(strictPrimitiveParsing: value);

  @override
  BooleanSchema copyWith({
    bool? strictPrimitiveParsing,
    bool? isNullable,
    String? description,
    Object? defaultValue,
    List<Validator<bool>>? constraints,
  }) {
    return copyWithInternal(
      strictPrimitiveParsing: strictPrimitiveParsing,
      isNullable: isNullable,
      description: description,
      defaultValue: defaultValue,
      constraints: constraints,
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
        InvalidTypeConstraint(expectedType: bool, inputValue: inputValue)
            .validate(inputValue);

    return SchemaResult.fail(
      SchemaConstraintsError(
        constraints: constraintError != null ? [constraintError] : [],
        context: context,
      ),
    );
  }

  @override
  SchemaResult<bool> validateConvertedValue(
    bool convertedValue,
    SchemaContext context,
  ) {
    return SchemaResult.ok(convertedValue);
  }

  @override
  BooleanSchema copyWithInternal({
    required bool? isNullable,
    required String? description,
    required Object? defaultValue,
    required List<Validator<bool>>? constraints,
    // BooleanSchema specific
    bool? strictPrimitiveParsing,
  }) {
    return BooleanSchema(
      isNullable: isNullable ?? this.isNullable,
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
  Map<String, Object?> toJsonSchema() {
    final Map<String, Object?> schema = {
      'type': isNullable ? ['boolean', 'null'] : 'boolean',
      if (description != null) 'description': description,
      if (defaultValue != null) 'default': defaultValue,
    };

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
