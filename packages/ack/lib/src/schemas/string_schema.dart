part of 'schema.dart';

@immutable
final class StringSchema extends AckSchema<String>
    with FluentSchema<String, StringSchema> {
  @override
  final bool strictPrimitiveParsing;

  const StringSchema({
    super.isNullable,
    super.isOptional,
    super.description,
    super.defaultValue,
    super.constraints,
    super.refinements,
    this.strictPrimitiveParsing = false,
  });

  @override
  SchemaType get schemaType => SchemaType.string;

  /// Creates a new [StringSchema] that enforces strict parsing.
  StringSchema strictParsing({bool value = true}) =>
      copyWith(strictPrimitiveParsing: value);

  @override
  StringSchema copyWithInternal({
    required bool? isNullable,
    required bool? isOptional,
    required String? description,
    required String? defaultValue,
    required List<Constraint<String>>? constraints,
    required List<Refinement<String>>? refinements,
    // StringSchema specific
    bool? strictPrimitiveParsing,
  }) {
    return StringSchema(
      isNullable: isNullable ?? this.isNullable,
      isOptional: isOptional ?? this.isOptional,
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
    bool? isOptional,
    String? description,
    String? defaultValue,
    List<Constraint<String>>? constraints,
    List<Refinement<String>>? refinements,
    bool? strictPrimitiveParsing,
  }) {
    return copyWithInternal(
      isNullable: isNullable,
      isOptional: isOptional,
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
