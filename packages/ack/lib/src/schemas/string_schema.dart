part of 'schema.dart';

@immutable
final class StringSchema extends AckSchema<String>
    with FluentSchema<String, StringSchema> {
  final bool strictPrimitiveParsing;

  const StringSchema({
    super.isNullable,
    super.description,
    super.defaultValue,
    super.constraints,
    this.strictPrimitiveParsing = false,
  }) : super(schemaType: SchemaType.string);

  /// Creates a new [StringSchema] that enforces strict parsing.
  StringSchema strictParsing({bool value = true}) =>
      copyWith(strictPrimitiveParsing: value);

  @override
  SchemaResult<String> tryConvertInput(
    Object? inputValue,
    SchemaContext context,
  ) {
    if (inputValue is String) {
      return SchemaResult.ok(inputValue);
    }

    final constraintError = InvalidTypeConstraint(
      expectedType: String,
      inputValue: inputValue,
    ).validate(inputValue);

    return SchemaResult.fail(SchemaConstraintsError(
      constraints: constraintError != null ? [constraintError] : [],
      context: context,
    ));
  }

  @override
  SchemaResult<String> validateConvertedValue(
    String convertedValue,
    SchemaContext context,
  ) {
    return SchemaResult.ok(convertedValue);
  }

  @override
  StringSchema copyWithInternal({
    required bool? isNullable,
    required String? description,
    required Object? defaultValue,
    required List<Validator<String>>? constraints,
    // StringSchema specific
    bool? strictPrimitiveParsing,
  }) {
    return StringSchema(
      isNullable: isNullable ?? this.isNullable,
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
  StringSchema copyWith({
    bool? isNullable,
    String? description,
    Object? defaultValue,
    List<Validator<String>>? constraints,
    bool? strictPrimitiveParsing,
  }) {
    return copyWithInternal(
      isNullable: isNullable,
      description: description,
      defaultValue: defaultValue,
      constraints: constraints,
      strictPrimitiveParsing: strictPrimitiveParsing,
    );
  }

  @override
  Map<String, Object?> toJsonSchema() {
    final Map<String, Object?> schema = {
      'type': isNullable ? ['string', 'null'] : 'string',
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
