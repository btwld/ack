part of 'schema.dart';

/// Schema for validating boolean values.
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
