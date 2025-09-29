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
  SchemaResult<String> _performTypeConversion(
      Object inputValue, SchemaContext context) {
    // First try basic type validation
    final typeResult = validateExpectedType(inputValue, context);
    if (typeResult.isOk) {
      return SchemaResult.ok(inputValue as String);
    }

    // If basic type validation fails, try type coercion (if allowed)
    if (!strictPrimitiveParsing) {
      if (inputValue is int || inputValue is double || inputValue is bool) {
        return SchemaResult.ok(inputValue.toString());
      }
    }

    // Return the original type error
    return SchemaResult.fail(typeResult.getError());
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
    final schema = {
      'type': isNullable ? ['string', 'null'] : 'string',
      if (description != null) 'description': description,
      if (defaultValue != null) 'default': defaultValue,
    };

    return mergeConstraintSchemas(schema);
  }
}
