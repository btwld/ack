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
}

// --- IntegerSchema ---

/// Schema for validating integer values.
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
  SchemaType get schemaType => SchemaType.integer;

  @override
  @protected
  SchemaResult<int> parseAndValidate(
    Object? inputValue,
    SchemaContext context,
  ) {
    final nullResult = handleNullInput(inputValue, context);
    if (nullResult != null) return nullResult;

    if (inputValue is! int) {
      return SchemaResult.fail(
        TypeMismatchError(
          expectedType: schemaType,
          actualType: AckSchema.getSchemaType(inputValue),
          context: context,
        ),
      );
    }
    return applyConstraintsAndRefinements(inputValue, context);
  }

  @override
  @protected
  SchemaResult<int> encodeRuntime(int value, SchemaContext context) {
    return SchemaResult.ok(value);
  }

  @override
  IntegerSchema copyWithBase({
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

/// Schema for validating double values.
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
  SchemaType get schemaType => SchemaType.number;

  @override
  @protected
  SchemaResult<double> parseAndValidate(
    Object? inputValue,
    SchemaContext context,
  ) {
    final nullResult = handleNullInput(inputValue, context);
    if (nullResult != null) return nullResult;

    // Per JSON Schema, an integer is a valid number — widen to double.
    if (inputValue is int) {
      return applyConstraintsAndRefinements(inputValue.toDouble(), context);
    }
    if (inputValue is! double) {
      return SchemaResult.fail(
        TypeMismatchError(
          expectedType: schemaType,
          actualType: AckSchema.getSchemaType(inputValue),
          context: context,
        ),
      );
    }
    return applyConstraintsAndRefinements(inputValue, context);
  }

  @override
  @protected
  SchemaResult<double> encodeRuntime(double value, SchemaContext context) {
    return SchemaResult.ok(value);
  }

  @override
  DoubleSchema copyWithBase({
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
  Map<String, Object?> toJsonSchema() =>
      buildJsonSchemaWithNullable(typeSchema: {'type': 'number'});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DoubleSchema) return false;
    return baseFieldsEqual(other);
  }

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
  SchemaType get schemaType => SchemaType.number;

  @override
  @protected
  SchemaResult<num> parseAndValidate(
    Object? inputValue,
    SchemaContext context,
  ) {
    final nullResult = handleNullInput(inputValue, context);
    if (nullResult != null) return nullResult;
    if (inputValue is! num) {
      return SchemaResult.fail(
        TypeMismatchError(
          expectedType: schemaType,
          actualType: AckSchema.getSchemaType(inputValue),
          context: context,
        ),
      );
    }
    return applyConstraintsAndRefinements(inputValue, context);
  }

  @override
  @protected
  SchemaResult<num> encodeRuntime(num value, SchemaContext context) {
    return SchemaResult.ok(value);
  }

  @override
  NumberSchema copyWithBase({
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
  Map<String, Object?> toJsonSchema() =>
      buildJsonSchemaWithNullable(typeSchema: {'type': 'number'});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NumberSchema) return false;
    return baseFieldsEqual(other);
  }

  @override
  int get hashCode => baseFieldsHashCode;
}
