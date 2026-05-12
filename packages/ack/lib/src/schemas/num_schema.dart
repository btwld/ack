part of 'schema.dart';

/// Base schema for numeric types.
///
/// Provides common numeric validation constraints. Use [IntegerSchema]
/// or [DoubleSchema] for strict per-type validation, or [NumberSchema]
/// (`Ack.number()`) for non-strict `num` validation that accepts both
/// `int` and `double` runtime values.
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

// --- NumberSchema ---

/// Schema for validating any numeric value — accepts both `int` and `double`
/// runtime values.
///
/// Unlike the strict [IntegerSchema] and [DoubleSchema], `NumberSchema`
/// mirrors JSON Schema's `"type": "number"` semantics: any Dart `num` is
/// accepted at the boundary without conversion. Use this when a field is
/// allowed to be either an integer or a floating-point value; reach for
/// [IntegerSchema] or [DoubleSchema] when only one is valid.
///
/// Example:
/// ```dart
/// final temperatureSchema = Ack.number().min(-273.15);
/// temperatureSchema.parse(20);    // ok — int accepted
/// temperatureSchema.parse(20.5);  // ok — double accepted
/// temperatureSchema.parse('20');  // fail — strings still need Ack.codec(...)
/// ```
@immutable
final class NumberSchema extends NumSchema<num>
    with FluentSchema<num, NumberSchema> {
  const NumberSchema({
    super.isNullable,
    super.isOptional,
    super.description,
    super.constraints,
    super.refinements,
  });

  @override
  SchemaType get schemaType => SchemaType.number;

  /// Accepts any non-null `num` (both `int` and `double`). The base
  /// `decodeBoundary` would dispatch through `SchemaType.canAcceptFrom`,
  /// which is exact-match and would reject `int` for `SchemaType.number`;
  /// `NumberSchema` is the deliberate non-strict numeric primitive, so we
  /// check `is num` directly here.
  @override
  @protected
  SchemaResult<num> decodeBoundary(Object? input, SchemaContext context) {
    final nonNullInput = input!;
    if (nonNullInput is num) return SchemaResult.ok(nonNullInput);

    SchemaType actualType;
    try {
      actualType = AckSchema.getSchemaType(nonNullInput);
    } catch (_) {
      return SchemaResult.fail(
        SchemaValidationError(
          message: 'Unsupported input type: ${nonNullInput.runtimeType}',
          context: context,
        ),
      );
    }
    return SchemaResult.fail(
      TypeMismatchError(
        expectedType: schemaType,
        actualType: actualType,
        context: context,
      ),
    );
  }

  @override
  NumberSchema copyWith({
    bool? isNullable,
    bool? isOptional,
    String? description,
    List<Constraint<num>>? constraints,
    List<Refinement<num>>? refinements,
  }) {
    return NumberSchema(
      isNullable: isNullable ?? this.isNullable,
      isOptional: isOptional ?? this.isOptional,
      description: description ?? this.description,
      constraints: constraints ?? this.constraints,
      refinements: refinements ?? this.refinements,
    );
  }

  // NumberSchema inherits toJsonSchema() from NumSchema → {'type': 'number'},
  // matching JSON Schema's union-of-int-and-float semantics.

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NumberSchema) return false;
    return baseFieldsEqual(other);
  }

  @override
  int get hashCode => baseFieldsHashCode;
}
