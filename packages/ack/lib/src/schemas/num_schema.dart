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
  });

  @override
  SchemaResult<T> validateConvertedValue(
    T convertedValue,
    SchemaContext context,
  ) {
    return SchemaResult.ok(convertedValue);
  }

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
  }) : super(schemaType: SchemaType.integer);

  @override
  SchemaResult<int> tryConvertInput(Object? inputValue, SchemaContext context) {
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
    Object? defaultValue,
    List<Validator<int>>? constraints,
    bool? strictPrimitiveParsing,
  }) {
    return copyWithInternal(
      isNullable: isNullable,
      description: description,
      defaultValue: defaultValue,
      constraints: constraints,
      strictPrimitiveParsing: strictPrimitiveParsing,
    );
  }

  @override
  IntegerSchema copyWithInternal({
    required bool? isNullable,
    required String? description,
    required Object? defaultValue,
    required List<Validator<int>>? constraints,
    // NumSchema specific
    bool? strictPrimitiveParsing,
  }) {
    return IntegerSchema(
      isNullable: isNullable ?? this.isNullable,
      description: description ?? this.description,
      defaultValue: defaultValue == ackRawDefaultValue
          ? this.defaultValue
          : defaultValue as int?,
      constraints: constraints ?? this.constraints,
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
  }) : super(schemaType: SchemaType.double);

  @override
  SchemaResult<double> tryConvertInput(
    Object? inputValue,
    SchemaContext context,
  ) {
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
    Object? defaultValue,
    List<Validator<double>>? constraints,
    bool? strictPrimitiveParsing,
  }) {
    return copyWithInternal(
      isNullable: isNullable,
      description: description,
      defaultValue: defaultValue,
      constraints: constraints,
      strictPrimitiveParsing: strictPrimitiveParsing,
    );
  }

  @override
  DoubleSchema copyWithInternal({
    required bool? isNullable,
    required String? description,
    required Object? defaultValue,
    required List<Validator<double>>? constraints,
    // NumSchema specific
    bool? strictPrimitiveParsing,
  }) {
    return DoubleSchema(
      isNullable: isNullable ?? this.isNullable,
      description: description ?? this.description,
      defaultValue: defaultValue == ackRawDefaultValue
          ? this.defaultValue
          : defaultValue as double?,
      constraints: constraints ?? this.constraints,
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
