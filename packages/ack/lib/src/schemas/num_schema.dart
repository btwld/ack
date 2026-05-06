part of 'schema.dart';

/// Base schema for numeric types (integer and double).
@immutable
sealed class NumSchema<T extends num> extends AckSchema<T> {
  const NumSchema({
    super.isNullable,
    super.isOptional,
    super.description,
    super.constraints,
    super.refinements,
  });

  @override
  Map<String, Object?> toJsonSchema() =>
      buildJsonSchemaWithNullable(typeSchema: {'type': 'number'});
}

/// Schema for validating integer values.
@immutable
final class IntegerSchema extends NumSchema<int>
    with FluentSchema<int, IntegerSchema> {
  const IntegerSchema({
    super.isNullable,
    super.isOptional,
    super.description,
    super.constraints,
    super.refinements,
  });

  @override
  SchemaType get schemaType => SchemaType.integer;

  @override
  IntegerSchema copyWith({
    bool? isNullable,
    bool? isOptional,
    String? description,
    List<Constraint<int>>? constraints,
    List<Refinement<int>>? refinements,
  }) {
    return IntegerSchema(
      isNullable: isNullable ?? this.isNullable,
      isOptional: isOptional ?? this.isOptional,
      description: description ?? this.description,
      constraints: constraints ?? this.constraints,
      refinements: refinements ?? this.refinements,
    );
  }

  @override
  Map<String, Object?> toJsonSchema() =>
      buildJsonSchemaWithNullable(typeSchema: {'type': 'integer'});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! IntegerSchema) return false;
    return baseFieldsEqual(other);
  }

  @override
  int get hashCode => baseFieldsHashCode;
}

/// Schema for validating double/floating-point values.
@immutable
final class DoubleSchema extends NumSchema<double>
    with FluentSchema<double, DoubleSchema> {
  const DoubleSchema({
    super.isNullable,
    super.isOptional,
    super.description,
    super.constraints,
    super.refinements,
  });

  @override
  SchemaType get schemaType => SchemaType.number;

  @override
  DoubleSchema copyWith({
    bool? isNullable,
    bool? isOptional,
    String? description,
    List<Constraint<double>>? constraints,
    List<Refinement<double>>? refinements,
  }) {
    return DoubleSchema(
      isNullable: isNullable ?? this.isNullable,
      isOptional: isOptional ?? this.isOptional,
      description: description ?? this.description,
      constraints: constraints ?? this.constraints,
      refinements: refinements ?? this.refinements,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DoubleSchema) return false;
    return baseFieldsEqual(other);
  }

  @override
  int get hashCode => baseFieldsHashCode;
}
