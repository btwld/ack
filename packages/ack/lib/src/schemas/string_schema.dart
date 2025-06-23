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

  StringSchema strictParsing({bool value = true}) =>
      copyWith(strictPrimitiveParsing: value);

  @override
  SchemaResult<String> tryConvertInput(
    Object? inputValue,
    SchemaContext context,
  ) {
    if (inputValue is String) return SchemaResult.ok(inputValue);
    if (strictPrimitiveParsing) {
      return SchemaResult.fail(SchemaConstraintsError(
        constraints: [
          InvalidTypeConstraint(expectedType: String, inputValue: inputValue)
              .validate(inputValue)!,
        ],
        context: context,
      ));
    }

    // For non-strict parsing, convert other primitives to string.
    if (inputValue != null && inputValue is! Map && inputValue is! List) {
      return SchemaResult.ok(inputValue.toString());
    }

    // Fail if input is null, a map, or a list.
    return SchemaResult.fail(SchemaConstraintsError(
      constraints: [
        InvalidTypeConstraint(expectedType: String, inputValue: inputValue)
            .validate(inputValue)!,
      ],
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
      return SchemaResult.fail(SchemaConstraintsError(
        constraints: [
          InvalidTypeConstraint(expectedType: String, inputValue: null)
              .validate(null)!,
        ],
        context: context,
      ));
    }

    return SchemaResult.ok(convertedValue);
  }

  @override
  StringSchema copyWith({
    String? description,
    Object? defaultValue,
    List<Validator<String>>? constraints,
    bool? strictPrimitiveParsing,
  }) {
    final newDefaultValue = defaultValue == ackRawDefaultValue
        ? this.defaultValue
        : defaultValue as String?;

    return StringSchema(
      description: description ?? this.description,
      defaultValue: newDefaultValue,
      constraints: constraints ?? this.constraints,
      strictPrimitiveParsing:
          strictPrimitiveParsing ?? this.strictPrimitiveParsing,
    );
  }

  @override
  StringSchema withDescription(String? d) => copyWith(description: d);
  @override
  StringSchema withDefault(String val) {
    return copyWith(defaultValue: val);
  }

  @override
  StringSchema addConstraint(Validator<String> c) =>
      copyWith(constraints: [...constraints, c]);

  @override
  StringSchema addConstraints(List<Validator<String>> cs) =>
      copyWith(constraints: [...constraints, ...cs]);

  @override
  Map<String, Object?> toJsonSchema() {
    Map<String, Object?> schema = {
      'type': 'string',
      if (description != null) 'description': description,
      if (defaultValue != null) 'default': defaultValue,
    };
    final constraintSchemas = constraints
        .whereType<JsonSchemaSpec<String>>()
        .map((c) => c.toJsonSchema())
        .fold<Map<String, Object?>>(
      {},
      (prev, current) => deepMerge(prev, current),
    );

    return deepMerge(schema, constraintSchemas);
  }
}
