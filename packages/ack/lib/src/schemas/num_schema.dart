part of 'schema.dart';

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
  Map<String, Object?> toJsonSchema() {
    if (isNullable) {
      final baseSchema = {
        'type': 'number',
        if (description != null) 'description': description,
      };
      final mergedSchema = mergeConstraintSchemas(baseSchema);
      return {
        if (defaultValue != null) 'default': defaultValue,
        'anyOf': [
          mergedSchema,
          {'type': 'null'},
        ],
      };
    }

    final schema = {
      'type': 'number',
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
    super.isOptional,
    super.description,
    super.defaultValue,
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
  Map<String, Object?> toJsonSchema() {
    final schema = super.toJsonSchema();
    // Override the type to be 'integer' instead of 'number'
    // Handle both direct type and anyOf nullable pattern
    if (schema.containsKey('anyOf')) {
      final anyOf = schema['anyOf'] as List;
      final firstOption = anyOf[0] as Map<String, Object?>;
      firstOption['type'] = 'integer';
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
    super.isOptional,
    super.description,
    super.defaultValue,
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

  @override
  Map<String, Object?> toJsonSchema() {
    final schema = super.toJsonSchema();
    // Note: 'double' is not a standard JSON Schema format keyword.
    // JSON Schema uses 'number' type for all floating point values.
    // If OpenAPI-specific double precision is needed, use x-openapi-format extension.

    return schema;
  }
}
