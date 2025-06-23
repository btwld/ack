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
    super.refinements,
    this.strictPrimitiveParsing = false,
  }) : super(schemaType: SchemaType.string);

  @override
  @protected
  SchemaResult<String> _onConvert(Object? inputValue, SchemaContext context) {
    if (inputValue == null) {
      // This can happen if a nullable schema has a non-null default value,
      // and the input is explicitly null. The base `parseAndValidate` allows it.
      return SchemaResult.fail(
        SchemaConstraintsError(
          constraints: [
            InvalidTypeConstraint(expectedType: String, inputValue: null)
                .validate(null)!,
          ],
          context: context,
        ),
      );
    }
    if (inputValue is String) {
      return SchemaResult.ok(inputValue);
    }

    if (!strictPrimitiveParsing) {
      if (inputValue is int || inputValue is double || inputValue is bool) {
        return SchemaResult.ok(inputValue.toString());
      }
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

  /// Creates a new [StringSchema] that enforces strict parsing.
  StringSchema strictParsing({bool value = true}) =>
      copyWith(strictPrimitiveParsing: value);

  @override
  StringSchema copyWithInternal({
    required bool? isNullable,
    required String? description,
    required String? defaultValue,
    required List<Constraint<String>>? constraints,
    required List<Refinement<String>>? refinements,
    // StringSchema specific
    bool? strictPrimitiveParsing,
  }) {
    return StringSchema(
      isNullable: isNullable ?? this.isNullable,
      description: description ?? this.description,
      defaultValue: defaultValue ?? this.defaultValue,
      constraints: constraints ?? this.constraints,
      refinements: refinements ?? this.refinements,
      strictPrimitiveParsing:
          strictPrimitiveParsing ?? this.strictPrimitiveParsing,
    );
  }

  @override
  StringSchema copyWith({
    bool? isNullable,
    String? description,
    String? defaultValue,
    List<Constraint<String>>? constraints,
    List<Refinement<String>>? refinements,
    bool? strictPrimitiveParsing,
  }) {
    return copyWithInternal(
      isNullable: isNullable,
      description: description,
      defaultValue: defaultValue,
      constraints: constraints,
      refinements: refinements,
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
