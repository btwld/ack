part of 'schema.dart';

@immutable
sealed class NumSchema<T extends num> extends AckSchema<T> {
  @override
  final bool strictPrimitiveParsing;

  const NumSchema({
    this.strictPrimitiveParsing = false,
    super.isNullable,
    super.description,
    super.defaultValue,
    super.constraints,
    super.refinements,
  });

  @override
  Map<String, Object?> toJsonSchema() {
    final schema = {
      'type': isNullable ? ['number', 'null'] : 'number',
      if (description != null) 'description': description,
      if (defaultValue != null) 'default': defaultValue,
    };

    return mergeConstraintSchemas(schema);
  }
}

// --- IntegerSchema ---
@immutable
final class IntegerSchema extends NumSchema<int>
    with FluentSchema<int, IntegerSchema> {
  const IntegerSchema({
    super.strictPrimitiveParsing,
    super.isNullable,
    super.description,
    super.defaultValue,
    super.constraints,
    super.refinements,
  });

  @override
  SchemaType get acceptedType => SchemaType.integer;

  @override
  IntegerSchema copyWith({
    bool? isNullable,
    String? description,
    int? defaultValue,
    List<Constraint<int>>? constraints,
    List<Refinement<int>>? refinements,
    bool? strictPrimitiveParsing,
  }) {
    return copyWithInternal(
      isNullable: isNullable,
      description: description,
      defaultValue: defaultValue,
      constraints: constraints,
      refinements: refinements,
      strictPrimitiveParsing: strictPrimitiveParsing,
    );
  }

  @override
  IntegerSchema copyWithInternal({
    required bool? isNullable,
    required String? description,
    required int? defaultValue,
    required List<Constraint<int>>? constraints,
    required List<Refinement<int>>? refinements,
    // NumSchema specific
    bool? strictPrimitiveParsing,
  }) {
    return IntegerSchema(
      isNullable: isNullable ?? this.isNullable,
      description: description ?? this.description,
      defaultValue: defaultValue ?? this.defaultValue,
      constraints: constraints ?? this.constraints,
      refinements: refinements ?? this.refinements,
      strictPrimitiveParsing:
          strictPrimitiveParsing ?? this.strictPrimitiveParsing,
    );
  }

  @override
  Map<String, Object?> toJsonSchema() {
    final schema = super.toJsonSchema();
    // Override the type to be 'integer' instead of 'number'
    if (isNullable) {
      schema['type'] = ['integer', 'null'];
    } else {
      schema['type'] = 'integer';
    }

    return schema;
  }
}

// --- DoubleSchema ---
@immutable
final class DoubleSchema extends NumSchema<double>
    with FluentSchema<double, DoubleSchema> {
  const DoubleSchema({
    super.strictPrimitiveParsing,
    super.isNullable,
    super.description,
    super.defaultValue,
    super.constraints,
    super.refinements,
  });

  @override
  SchemaType get acceptedType => SchemaType.number;

  @override
  DoubleSchema copyWith({
    bool? isNullable,
    String? description,
    double? defaultValue,
    List<Constraint<double>>? constraints,
    List<Refinement<double>>? refinements,
    bool? strictPrimitiveParsing,
  }) {
    return copyWithInternal(
      isNullable: isNullable,
      description: description,
      defaultValue: defaultValue,
      constraints: constraints,
      refinements: refinements,
      strictPrimitiveParsing: strictPrimitiveParsing,
    );
  }

  @override
  DoubleSchema copyWithInternal({
    required bool? isNullable,
    required String? description,
    required double? defaultValue,
    required List<Constraint<double>>? constraints,
    required List<Refinement<double>>? refinements,
    // NumSchema specific
    bool? strictPrimitiveParsing,
  }) {
    return DoubleSchema(
      isNullable: isNullable ?? this.isNullable,
      description: description ?? this.description,
      defaultValue: defaultValue ?? this.defaultValue,
      constraints: constraints ?? this.constraints,
      refinements: refinements ?? this.refinements,
      strictPrimitiveParsing:
          strictPrimitiveParsing ?? this.strictPrimitiveParsing,
    );
  }

  @override
  Map<String, Object?> toJsonSchema() {
    final schema = super.toJsonSchema();
    // Note: 'double' is not a standard JSON Schema format keyword.
    // JSON Schema uses 'number' type for all floating point values.
    // If OpenAPI-specific double precision is needed, use x-openapi-format extension.

    return schema;
  }
}
