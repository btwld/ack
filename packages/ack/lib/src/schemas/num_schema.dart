part of 'schema.dart';

/// Base schema for numeric types (integer and double).
///
/// Provides common numeric validation constraints. Use [IntegerSchema]
/// or [DoubleSchema] for type-specific validation.
@immutable
sealed class NumSchema<T extends num> extends AckSchema<T> {
  @override
  final bool strictPrimitiveParsing;

  const NumSchema({
    this.strictPrimitiveParsing = false,
    super.isNullable,
    super.isOptional,
    super.description,
    super.defaultValue,
    super.constraints,
    super.refinements,
  });

  @override
  Map<String, Object?> toJsonSchema() => buildJsonSchemaWithNullable(
    typeSchema: {'type': 'number'},
    serializedDefault: defaultValue,
  );
}

// --- IntegerSchema ---

/// Schema for validating integer values.
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
    super.strictPrimitiveParsing,
    super.isNullable,
    super.isOptional,
    super.description,
    super.defaultValue,
    super.constraints,
    super.refinements,
  });

  @override
  SchemaType get schemaType => SchemaType.integer;

  /// Creates a new [IntegerSchema] that enforces strict parsing.
  IntegerSchema strictParsing({bool value = true}) =>
      copyWith(strictPrimitiveParsing: value);

  @override
  IntegerSchema copyWith({
    bool? isNullable,
    bool? isOptional,
    String? description,
    int? defaultValue,
    List<Constraint<int>>? constraints,
    List<Refinement<int>>? refinements,
    bool? strictPrimitiveParsing,
  }) {
    return IntegerSchema(
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
    typeSchema: {'type': 'integer'},
    serializedDefault: defaultValue,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! IntegerSchema) return false;
    return baseFieldsEqual(other) &&
        strictPrimitiveParsing == other.strictPrimitiveParsing;
  }

  @override
  int get hashCode => Object.hash(baseFieldsHashCode, strictPrimitiveParsing);
}

// --- DoubleSchema ---

/// Schema for validating double/floating-point values.
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
    super.strictPrimitiveParsing,
    super.isNullable,
    super.isOptional,
    super.description,
    super.defaultValue,
    super.constraints,
    super.refinements,
  });

  @override
  SchemaType get schemaType => SchemaType.number;

  /// Creates a new [DoubleSchema] that enforces strict parsing.
  DoubleSchema strictParsing({bool value = true}) =>
      copyWith(strictPrimitiveParsing: value);

  @override
  DoubleSchema copyWith({
    bool? isNullable,
    bool? isOptional,
    String? description,
    double? defaultValue,
    List<Constraint<double>>? constraints,
    List<Refinement<double>>? refinements,
    bool? strictPrimitiveParsing,
  }) {
    return DoubleSchema(
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

  // Note: DoubleSchema inherits toJsonSchema() from NumSchema.
  // JSON Schema uses 'number' type for all floating point values.

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DoubleSchema) return false;
    return baseFieldsEqual(other) &&
        strictPrimitiveParsing == other.strictPrimitiveParsing;
  }

  @override
  int get hashCode => Object.hash(baseFieldsHashCode, strictPrimitiveParsing);
}
