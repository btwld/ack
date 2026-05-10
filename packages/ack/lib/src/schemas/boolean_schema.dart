part of 'schema.dart';

/// Schema for validating boolean values.
///
/// Strict: only `bool` values are accepted — no `"true"`/`"false"`
/// string coercion (including the historical case-insensitive /
/// whitespace-padded handling). For explicit boundary conversion use
/// `Ack.codec(...)` — see `test/migration_recipes_test.dart` for the
/// canonical `string ↔ bool` recipe.
///
/// Example:
/// ```dart
/// final isActiveSchema = Ack.boolean();
/// isActiveSchema.safeParse(true);    // Ok
/// isActiveSchema.safeParse('true');  // Fail — use a codec instead
/// ```
@immutable
final class BooleanSchema extends AckSchema<bool>
    with FluentSchema<bool, BooleanSchema> {
  const BooleanSchema({
    super.isNullable,
    super.isOptional,
    super.description,
    super.constraints,
    super.refinements,
  });

  @override
  SchemaType get schemaType => SchemaType.boolean;

  @override
  BooleanSchema copyWith({
    bool? isNullable,
    bool? isOptional,
    String? description,
    List<Constraint<bool>>? constraints,
    List<Refinement<bool>>? refinements,
  }) {
    return BooleanSchema(
      isNullable: isNullable ?? this.isNullable,
      isOptional: isOptional ?? this.isOptional,
      description: description ?? this.description,
      constraints: constraints ?? this.constraints,
      refinements: refinements ?? this.refinements,
    );
  }

  @override
  Map<String, Object?> toJsonSchema() =>
      buildJsonSchemaWithNullable(typeSchema: {'type': 'boolean'});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! BooleanSchema) return false;
    return baseFieldsEqual(other);
  }

  @override
  int get hashCode => baseFieldsHashCode;
}
