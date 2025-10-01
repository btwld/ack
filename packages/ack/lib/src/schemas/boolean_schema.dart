part of 'schema.dart';

/// Schema for validating boolean (`bool`) values.
@immutable
final class BooleanSchema extends AckSchema<bool>
    with FluentSchema<bool, BooleanSchema> {
  @override
  final bool strictPrimitiveParsing;

  const BooleanSchema({
    this.strictPrimitiveParsing = false,
    super.isNullable,
    super.description,
    super.defaultValue,
    super.constraints,
    super.refinements,
  });

  @override
  SchemaType get acceptedType => SchemaType.boolean;

  /// Creates a new BooleanSchema with strict parsing enabled/disabled
  BooleanSchema strictParsing({bool value = true}) =>
      copyWith(strictPrimitiveParsing: value);

  @override
  BooleanSchema copyWith({
    bool? strictPrimitiveParsing,
    bool? isNullable,
    String? description,
    bool? defaultValue,
    List<Constraint<bool>>? constraints,
    List<Refinement<bool>>? refinements,
  }) {
    return copyWithInternal(
      strictPrimitiveParsing: strictPrimitiveParsing,
      isNullable: isNullable,
      description: description,
      defaultValue: defaultValue,
      constraints: constraints,
      refinements: refinements,
    );
  }

  @override
  BooleanSchema copyWithInternal({
    required bool? isNullable,
    required String? description,
    required bool? defaultValue,
    required List<Constraint<bool>>? constraints,
    required List<Refinement<bool>>? refinements,
    // BooleanSchema specific
    bool? strictPrimitiveParsing,
  }) {
    return BooleanSchema(
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
  Map<String, Object?> toJsonSchema() {
    final schema = {
      'type': isNullable ? ['boolean', 'null'] : 'boolean',
      if (description != null) 'description': description,
      if (defaultValue != null) 'default': defaultValue,
    };

    return mergeConstraintSchemas(schema);
  }
}
