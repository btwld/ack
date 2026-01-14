part of 'schema.dart';

/// Schema for validating string values.
///
/// Provides fluent methods for common string validations like length constraints,
/// format checks (email, URL, UUID), and pattern matching.
///
/// Example:
/// ```dart
/// final emailSchema = Ack.string().email().minLength(5);
/// final result = emailSchema.safeParse('user@example.com'); // Ok
/// ```
///
/// See also: [StringSchemaExtensions] for available validation methods.
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
  StringSchema copyWith({
    bool? isNullable,
    bool? isOptional,
    String? description,
    String? defaultValue,
    List<Constraint<String>>? constraints,
    List<Refinement<String>>? refinements,
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
  Map<String, Object?> toJsonSchema() => buildJsonSchemaWithNullable(
        typeSchema: {'type': 'string'},
        serializedDefault: defaultValue,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! StringSchema) return false;
    return baseFieldsEqual(other) &&
        strictPrimitiveParsing == other.strictPrimitiveParsing;
  }

  @override
  int get hashCode => Object.hash(baseFieldsHashCode, strictPrimitiveParsing);
}
