part of 'schema.dart';

/// Base schema for numeric types (integer, double, num).
@immutable
sealed class NumSchema<T extends num> extends AckSchema<T, T> {
  const NumSchema({
    super.isNullable,
    super.isOptional,
    super.description,
    super.constraints,
    super.refinements,
  });

  @override
  @protected
  SchemaResult<T> applyConstraintsAndRefinements(
    T value,
    SchemaContext context, {
    Iterable<Constraint<T>>? constraints,
    Iterable<Refinement<T>>? refinements,
  }) {
    if (value is double && !value.isFinite) {
      final constraint = NumberFiniteConstraint<T>();
      final error = constraint.validate(value);

      return SchemaResult.fail(
        SchemaConstraintsError(
          constraints: error != null ? [error] : const [],
          context: context,
        ),
      );
    }

    return super.applyConstraintsAndRefinements(
      value,
      context,
      constraints: constraints,
      refinements: refinements,
    );
  }
}

// --- IntegerSchema ---

/// Schema for validating JSON integer values.
///
/// JSON Schema defines an integer as any number with a zero fractional part.
/// Integral [double] inputs are therefore normalized to [int] when conversion
/// is lossless. Add `.safe()` when integers must remain exact on JavaScript.
@immutable
final class IntegerSchema extends NumSchema<int>
    with FluentSchema<int, int, IntegerSchema> {
  const IntegerSchema({
    super.isNullable,
    super.isOptional,
    super.description,
    super.constraints,
    super.refinements,
  });

  @override
  @protected
  SchemaResult<int> validateRuntimeWithContext(
    Object? value,
    SchemaContext context,
  ) {
    final nullResult = handleNullInput(value, context);
    if (nullResult != null) return nullResult;

    if (value is! num || !value.isFinite || value.remainder(1) != 0) {
      return SchemaResult.fail(
        _buildTypeMismatch(
          expectedType: schemaType,
          actualValue: value,
          context: context,
        ),
      );
    }

    // JavaScript preserves the sign bit on negative zero even when Dart treats
    // the value as an `int`. Normalize it explicitly before constraints and
    // refinements observe the value.
    if (value == 0) return applyConstraintsAndRefinements(0, context);
    if (value is int) return applyConstraintsAndRefinements(value, context);

    final normalized = value.toInt();
    // Native double-to-int conversion saturates outside the platform int
    // range. Compare mathematical integer values through BigInt because num
    // equality itself rounds at boundaries such as 2^63.
    if (BigInt.from(normalized) != BigInt.from(value)) {
      return SchemaResult.fail(
        SchemaValidationError(
          message: 'Number cannot be represented as a Dart int without loss.',
          context: context,
        ),
      );
    }

    return applyConstraintsAndRefinements(normalized, context);
  }

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
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! IntegerSchema) return false;

    return baseFieldsEqual(other);
  }

  @override
  SchemaType get schemaType => SchemaType.integer;

  @override
  int get hashCode => baseFieldsHashCode;
}

// --- DoubleSchema ---

/// Schema for validating JSON number values as Dart [double]s.
///
/// JSON Schema's `number` type includes integers. Exactly representable numeric
/// inputs are normalized to [double]; lossy integer conversions are rejected.
@immutable
final class DoubleSchema extends NumSchema<double>
    with FluentSchema<double, double, DoubleSchema> {
  const DoubleSchema({
    super.isNullable,
    super.isOptional,
    super.description,
    super.constraints,
    super.refinements,
  });

  @override
  @protected
  SchemaResult<double> validateRuntimeWithContext(
    Object? value,
    SchemaContext context,
  ) {
    final nullResult = handleNullInput(value, context);
    if (nullResult != null) return nullResult;

    if (value is! num) {
      return SchemaResult.fail(
        _buildTypeMismatch(
          expectedType: schemaType,
          actualValue: value,
          context: context,
        ),
      );
    }

    final normalized = value.toDouble();
    if (normalized.isFinite &&
        value is int &&
        BigInt.from(normalized) != BigInt.from(value)) {
      return SchemaResult.fail(
        SchemaValidationError(
          message:
              'Integer cannot be represented as a Dart double without loss.',
          context: context,
        ),
      );
    }

    return applyConstraintsAndRefinements(normalized, context);
  }

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
  SchemaType get schemaType => SchemaType.number;

  @override
  int get hashCode => baseFieldsHashCode;
}

// --- NumberSchema (num boundary/runtime) ---

/// Schema for validating any [num] value.
@immutable
final class NumberSchema extends NumSchema<num>
    with FluentSchema<num, num, NumberSchema> {
  const NumberSchema({
    super.isNullable,
    super.isOptional,
    super.description,
    super.constraints,
    super.refinements,
  });

  @override
  @protected
  SchemaResult<num> validateRuntimeWithContext(
    Object? value,
    SchemaContext context,
  ) {
    final nullResult = handleNullInput(value, context);
    if (nullResult != null) return nullResult;
    if (value is! num) {
      return SchemaResult.fail(
        _buildTypeMismatch(
          expectedType: schemaType,
          actualValue: value,
          context: context,
        ),
      );
    }

    return applyConstraintsAndRefinements(value, context);
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NumberSchema) return false;

    return baseFieldsEqual(other);
  }

  @override
  SchemaType get schemaType => SchemaType.number;

  @override
  int get hashCode => baseFieldsHashCode;
}
