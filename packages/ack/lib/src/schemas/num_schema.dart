part of 'schema.dart';

/// Base schema for numeric types (integer and double).
///
/// Provides common numeric validation constraints. Use [IntegerSchema]
/// or [DoubleSchema] for type-specific validation.
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

// --- IntegerSchema ---

/// Schema for validating integer values.
///
/// Strict: only `int` values are accepted (no implicit conversion from
/// `String`, `double`, etc.). For explicit boundary conversion use
/// `Ack.codec(...)` — see `test/migration_recipes_test.dart`.
///
/// Supports validation for whole numbers with constraints like min/max,
/// positive/negative, and multipleOf.
///
/// Example:
/// ```dart
/// final ageSchema = Ack.integer().min(0).max(150);
/// ```
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

// --- DoubleSchema ---

/// Schema for validating double/floating-point values.
///
/// Strict: only `double` values are accepted (no implicit conversion
/// from `int` or `String`). For explicit boundary conversion use
/// `Ack.codec(...)` — see `test/migration_recipes_test.dart`.
///
/// Supports validation for decimal numbers with constraints like min/max,
/// finite checks, and precision requirements.
///
/// Example:
/// ```dart
/// final priceSchema = Ack.double().min(0.0).finite();
/// ```
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

  // Note: DoubleSchema inherits toJsonSchema() from NumSchema.
  // JSON Schema uses 'number' type for all floating point values.

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DoubleSchema) return false;
    return baseFieldsEqual(other);
  }

  @override
  int get hashCode => baseFieldsHashCode;
}
