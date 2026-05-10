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
/// `Ack.string()` is strict: only `String` values are accepted (no
/// coercion from `int` / `bool` / `num`). For explicit boundary
/// conversion use `Ack.codec(...)` — see
/// `test/migration_recipes_test.dart`.
///
/// See also: [StringSchemaExtensions] for available validation methods.
@immutable
final class StringSchema extends AckSchema<String>
    with FluentSchema<String, StringSchema> {
  const StringSchema({
    super.isNullable,
    super.isOptional,
    super.description,
    super.constraints,
    super.refinements,
  });

  @override
  SchemaType get schemaType => SchemaType.string;

  @override
  StringSchema copyWith({
    bool? isNullable,
    bool? isOptional,
    String? description,
    List<Constraint<String>>? constraints,
    List<Refinement<String>>? refinements,
  }) {
    return StringSchema(
      isNullable: isNullable ?? this.isNullable,
      isOptional: isOptional ?? this.isOptional,
      description: description ?? this.description,
      constraints: constraints ?? this.constraints,
      refinements: refinements ?? this.refinements,
    );
  }

  @override
  Map<String, Object?> toJsonSchema() =>
      buildJsonSchemaWithNullable(typeSchema: {'type': 'string'});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! StringSchema) return false;
    return baseFieldsEqual(other);
  }

  @override
  int get hashCode => baseFieldsHashCode;
}
