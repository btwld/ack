part of 'schema.dart';

// --- IntegerSchema ---
@immutable
final class IntegerSchema extends AckSchema<int> {
  final bool strictPrimitiveParsing;

  const IntegerSchema({
    String? description,
    int? defaultValue,
    List<Validator<int>> constraints = const [],
    this.strictPrimitiveParsing = false,
  }) : super(
          schemaType: SchemaType.integer,
          description: description,
          defaultValue: defaultValue,
          constraints: constraints,
        );

  @override
  SchemaResult<int> tryConvertInput(Object? inputValue, SchemaContext context) {
    if (inputValue is int) return SchemaResult.ok(inputValue);
    if (strictPrimitiveParsing) {
      return SchemaResult.fail(SchemaConstraintsError(
        constraints: [
          InvalidTypeConstraint(expectedType: int, inputValue: inputValue)
              .validate(inputValue)!,
        ],
        context: context,
      ));
    }

    if (inputValue is String) {
      final parsed = int.tryParse(inputValue);
      if (parsed != null) return SchemaResult.ok(parsed);
    }
    if (inputValue is double) {
      if (inputValue.truncate() == inputValue) {
        return SchemaResult.ok(inputValue.toInt());
      }
    }

    return SchemaResult.fail(SchemaConstraintsError(
      constraints: [
        InvalidTypeConstraint(expectedType: int, inputValue: inputValue)
            .validate(inputValue)!,
      ],
      context: context,
    ));
  }

  @override
  SchemaResult<int> validateConvertedValue(
    int? convertedValue,
    SchemaContext context,
  ) {
    if (convertedValue == null) {
      return SchemaResult.fail(SchemaConstraintsError(
        constraints: [
          InvalidTypeConstraint(expectedType: int, inputValue: null)
              .validate(null)!,
        ],
        context: context,
      ));
    }

    return SchemaResult.ok(convertedValue);
  }

  @override
  IntegerSchema copyWith({
    String? description,
    Object? defaultValue,
    List<Validator<int>>? constraints,
    bool? strictPrimitiveParsing,
  }) {
    final newDefaultValue = defaultValue == ackRawDefaultValue
        ? this.defaultValue
        : defaultValue as int?;

    return IntegerSchema(
      description: description ?? this.description,
      defaultValue: newDefaultValue,
      constraints: constraints ?? this.constraints,
      strictPrimitiveParsing:
          strictPrimitiveParsing ?? this.strictPrimitiveParsing,
    );
  }

  @override
  IntegerSchema withDescription(String? d) => copyWith(description: d);

  @override
  IntegerSchema withDefault(int val) => copyWith(defaultValue: val);

  @override
  IntegerSchema addConstraint(Validator<int> c) =>
      copyWith(constraints: [...constraints, c]);

  @override
  IntegerSchema addConstraints(List<Validator<int>> cs) =>
      copyWith(constraints: [...constraints, ...cs]);

  @override
  Map<String, Object?> toJsonSchema() {
    Map<String, Object?> schema = {
      'type': 'integer',
      if (description != null) 'description': description,
      if (defaultValue != null) 'default': defaultValue,
    };
    final constraintSchemas = constraints
        .whereType<JsonSchemaSpec<int>>()
        .map((c) => c.toJsonSchema())
        .fold<Map<String, Object?>>(
      {},
      (prev, current) => deepMerge(prev, current),
    );

    return deepMerge(schema, constraintSchemas);
  }
}

// --- DoubleSchema ---
@immutable
final class DoubleSchema extends AckSchema<double> {
  final bool strictPrimitiveParsing;

  const DoubleSchema({
    String? description,
    double? defaultValue,
    List<Validator<double>> constraints = const [],
    this.strictPrimitiveParsing = false,
  }) : super(
          schemaType: SchemaType.double,
          description: description,
          defaultValue: defaultValue,
          constraints: constraints,
        );

  @override
  SchemaResult<double> tryConvertInput(
    Object? inputValue,
    SchemaContext context,
  ) {
    if (inputValue is double) return SchemaResult.ok(inputValue);
    if (inputValue is int) return SchemaResult.ok(inputValue.toDouble());
    if (strictPrimitiveParsing) {
      return SchemaResult.fail(SchemaConstraintsError(
        constraints: [
          InvalidTypeConstraint(expectedType: double, inputValue: inputValue)
              .validate(inputValue)!,
        ],
        context: context,
      ));
    }
    if (inputValue is String) {
      final parsed = double.tryParse(inputValue);
      if (parsed != null) return SchemaResult.ok(parsed);
    }

    return SchemaResult.fail(SchemaConstraintsError(
      constraints: [
        InvalidTypeConstraint(expectedType: double, inputValue: inputValue)
            .validate(inputValue)!,
      ],
      context: context,
    ));
  }

  @override
  SchemaResult<double> validateConvertedValue(
    double? convertedValue,
    SchemaContext context,
  ) {
    if (convertedValue == null) {
      return SchemaResult.fail(SchemaConstraintsError(
        constraints: [
          InvalidTypeConstraint(expectedType: double, inputValue: null)
              .validate(null)!,
        ],
        context: context,
      ));
    }

    return SchemaResult.ok(convertedValue);
  }

  @override
  DoubleSchema copyWith({
    String? description,
    Object? defaultValue,
    List<Validator<double>>? constraints,
    bool? strictPrimitiveParsing,
  }) {
    final newDefaultValue = defaultValue == ackRawDefaultValue
        ? this.defaultValue
        : defaultValue as double?;

    return DoubleSchema(
      description: description ?? this.description,
      defaultValue: newDefaultValue,
      constraints: constraints ?? this.constraints,
      strictPrimitiveParsing:
          strictPrimitiveParsing ?? this.strictPrimitiveParsing,
    );
  }

  @override
  DoubleSchema withDescription(String? d) => copyWith(description: d);

  @override
  DoubleSchema withDefault(double val) => copyWith(defaultValue: val);

  @override
  DoubleSchema addConstraint(Validator<double> c) =>
      copyWith(constraints: [...constraints, c]);

  @override
  DoubleSchema addConstraints(List<Validator<double>> cs) =>
      copyWith(constraints: [...constraints, ...cs]);

  @override
  Map<String, Object?> toJsonSchema() {
    Map<String, Object?> schema = {
      'type': 'number',
      if (description != null) 'description': description,
      if (defaultValue != null) 'default': defaultValue,
    };
    final constraintSchemas = constraints
        .whereType<JsonSchemaSpec<double>>()
        .map((c) => c.toJsonSchema())
        .fold<Map<String, Object?>>(
      {},
      (prev, current) => deepMerge(prev, current),
    );

    return deepMerge(schema, constraintSchemas);
  }
}
