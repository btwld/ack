part of 'schema.dart';

@immutable
sealed class NumSchema<T extends num> extends AckSchema<T> {
  final bool strictPrimitiveParsing;

  const NumSchema({
    required super.schemaType,
    this.strictPrimitiveParsing = false,
    super.isNullable,
    super.description,
    super.defaultValue,
    super.constraints,
    super.refinements,
  });

  @override
  Map<String, Object?> toJsonSchema() {
    final Map<String, Object?> schema = {
      'type': 'number',
      if (description != null) 'description': description,
      if (defaultValue != null) 'default': defaultValue,
    };

    final constraintSchemas = <Map<String, Object?>>[];
    for (final constraint in constraints) {
      if (constraint is JsonSchemaSpec) {
        constraintSchemas.add((constraint as JsonSchemaSpec).toJsonSchema());
      }
    }

    final mergedSchema = constraintSchemas.fold(
      schema,
      (prev, current) => deepMerge(prev, current),
    );

    if (isNullable) {
      return {
        'oneOf': [
          {'type': 'null'},
          mergedSchema,
        ],
      };
    }

    return mergedSchema;
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
  }) : super(schemaType: SchemaType.integer);

  @override
  @protected
  SchemaResult<int> _onConvert(Object? inputValue, SchemaContext context) {
    if (inputValue is int) return SchemaResult.ok(inputValue);
    if (strictPrimitiveParsing) {
      final constraintError =
          InvalidTypeConstraint(expectedType: int, inputValue: inputValue)
              .validate(inputValue);

      return SchemaResult.fail(SchemaConstraintsError(
        constraints: constraintError != null ? [constraintError] : [],
        context: context,
      ));
    }

    if (inputValue is String) {
      final parsed = int.tryParse(inputValue);
      if (parsed != null) return SchemaResult.ok(parsed);
    }
    if (inputValue is double && inputValue == inputValue.roundToDouble()) {
      return SchemaResult.ok(inputValue.toInt());
    }

    final constraintError =
        InvalidTypeConstraint(expectedType: int, inputValue: inputValue)
            .validate(inputValue);

    return SchemaResult.fail(
      SchemaConstraintsError(
        constraints: constraintError != null ? [constraintError] : [],
        context: context,
      ),
    );
  }

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
    schema['type'] = 'integer';
    if (isNullable) {
      (schema['oneOf'] as List).last['type'] = 'integer';
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
  }) : super(schemaType: SchemaType.double);

  @override
  @protected
  SchemaResult<double> _onConvert(Object? inputValue, SchemaContext context) {
    if (inputValue is double) return SchemaResult.ok(inputValue);
    if (inputValue is int && !strictPrimitiveParsing) {
      return SchemaResult.ok(inputValue.toDouble());
    }
    if (inputValue is String) {
      final val = double.tryParse(inputValue);
      if (val != null) return SchemaResult.ok(val);
    }

    final constraintError =
        InvalidTypeConstraint(expectedType: double, inputValue: inputValue)
            .validate(inputValue);

    return SchemaResult.fail(
      SchemaConstraintsError(
        constraints: constraintError != null ? [constraintError] : [],
        context: context,
      ),
    );
  }

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
    schema['format'] = 'double';
    if (isNullable) {
      (schema['oneOf'] as List).last['format'] = 'double';
    }

    return schema;
  }
}
