part of 'schema.dart';

@immutable
final class StringSchema extends AckSchema<String> {
  final bool strictPrimitiveParsing;

  const StringSchema({
    String? description,
    String? defaultValue,
    List<Validator<String>> constraints = const [],
    this.strictPrimitiveParsing = false,
  }) : super(
          schemaType: SchemaType.string,
          description: description,
          defaultValue: defaultValue,
          constraints: constraints,
        );

  /// Creates a new StringSchema with strict parsing enabled/disabled
  StringSchema strictParsing({bool value = true}) =>
      copyWithStringProperties(strictPrimitiveParsing: value);

  /// Creates a new StringSchema with modified string-specific properties
  StringSchema copyWithStringProperties({
    bool? strictPrimitiveParsing,
    String? description,
    Object? defaultValue,
    List<Validator<String>>? constraints,
  }) {
    return StringSchema(
      description: description ?? this.description,
      defaultValue: defaultValue == ackRawDefaultValue
          ? this.defaultValue
          : defaultValue as String?,
      constraints: constraints ?? this.constraints,
      strictPrimitiveParsing:
          strictPrimitiveParsing ?? this.strictPrimitiveParsing,
    );
  }

  @override
  SchemaResult<String> tryConvertInput(
    Object? inputValue,
    SchemaContext context,
  ) {
    if (inputValue is String) return SchemaResult.ok(inputValue);
    if (strictPrimitiveParsing) {
      final constraintError =
          InvalidTypeConstraint(expectedType: String, inputValue: inputValue)
              .validate(inputValue);

      return SchemaResult.fail(SchemaConstraintsError(
        constraints: constraintError != null ? [constraintError] : [],
        context: context,
      ));
    }

    // For non-strict parsing, convert other primitives to string.
    if (inputValue != null && inputValue is! Map && inputValue is! List) {
      return SchemaResult.ok(inputValue.toString());
    }

    // Fail if input is null, a map, or a list.
    final constraintError =
        InvalidTypeConstraint(expectedType: String, inputValue: inputValue)
            .validate(inputValue);

    return SchemaResult.fail(SchemaConstraintsError(
      constraints: constraintError != null ? [constraintError] : [],
      context: context,
    ));
  }

  @override
  SchemaResult<String> validateConvertedValue(
    String? convertedValue,
    SchemaContext context,
  ) {
    // This method is called after tryConvertInput, which for a non-nullable
    // schema should never produce a null value. This is a safeguard.
    if (convertedValue == null) {
      final constraintError =
          InvalidTypeConstraint(expectedType: String, inputValue: null)
              .validate(null);

      return SchemaResult.fail(SchemaConstraintsError(
        constraints: constraintError != null ? [constraintError] : [],
        context: context,
      ));
    }

    return SchemaResult.ok(convertedValue);
  }

  @override
  StringSchema copyWithInternal({
    String? description,
    Object? defaultValue,
    List<Validator<String>>? constraints,
  }) {
    return StringSchema(
      description: description ?? this.description,
      defaultValue: defaultValue == ackRawDefaultValue
          ? this.defaultValue
          : defaultValue as String?,
      constraints: constraints ?? this.constraints,
      strictPrimitiveParsing: strictPrimitiveParsing,
    );
  }

  @override
  Map<String, Object?> toJsonSchema() {
    Map<String, Object?> schema = {
      'type': 'string',
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
