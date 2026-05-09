part of 'schema.dart';

/// Schema for validating boolean values.
///
/// In loose parsing mode (default), accepts boolean values and
/// strings "true"/"false" (case-insensitive).
/// In strict mode, only accepts actual boolean values.
///
/// Example:
/// ```dart
/// final isActiveSchema = Ack.boolean();
/// isActiveSchema.safeParse(true);     // Ok
/// isActiveSchema.safeParse('true');   // Ok (loose mode)
/// ```
@immutable
final class BooleanSchema extends AckSchema<bool>
    with FluentSchema<bool, BooleanSchema> {
  @override
  final bool strictPrimitiveParsing;

  const BooleanSchema({
    this.strictPrimitiveParsing = false,
    super.isNullable,
    super.isOptional,
    super.description,
    super.defaultValue,
    super.constraints,
    super.refinements,
  });

  @override
  SchemaType get schemaType => SchemaType.boolean;

  /// Creates a new BooleanSchema with strict parsing enabled/disabled
  BooleanSchema strictParsing({bool value = true}) =>
      copyWith(strictPrimitiveParsing: value);

  @override
  BooleanSchema copyWith({
    bool? strictPrimitiveParsing,
    bool? isNullable,
    bool? isOptional,
    String? description,
    bool? defaultValue,
    List<Constraint<bool>>? constraints,
    List<Refinement<bool>>? refinements,
  }) {
    return BooleanSchema(
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
  Map<String, Object?> toJsonSchema() => buildJsonSchemaWithNullable(
    typeSchema: {'type': 'boolean'},
    serializedDefault: defaultValue,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! BooleanSchema) return false;
    return baseFieldsEqual(other) &&
        strictPrimitiveParsing == other.strictPrimitiveParsing;
  }

  @override
  int get hashCode => Object.hash(baseFieldsHashCode, strictPrimitiveParsing);
}
