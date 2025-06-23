part of 'schema.dart';

// --- IntegerSchema ---
@immutable
final class IntegerSchema extends AckSchema<int> {
  final bool strictPrimitiveParsing;

  const IntegerSchema({
    this.strictPrimitiveParsing = false,
    super.isNullable,
    super.description,
    super.defaultValue,
    super.constraints,
  }) : super(schemaType: SchemaType.integer);

  @override
  IntegerSchema copyWith({
    bool? strictPrimitiveParsing,
    bool? isNullable,
    String? description,
    Object? defaultValue,
    List<Validator<int>>? constraints,
  }) {
    return copyWithInternal(
      strictPrimitiveParsing: strictPrimitiveParsing,
      isNullable: isNullable,
      description: description,
      defaultValue: defaultValue,
      constraints: constraints,
    );
  }

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
    if (inputValue is double && !strictPrimitiveParsing) {
      if (inputValue == inputValue.truncateToDouble()) {
        return SchemaResult.ok(inputValue.toInt());
      }
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
  SchemaResult<int> validateConvertedValue(
    int convertedValue,
    SchemaContext context,
  ) {
    return SchemaResult.ok(convertedValue);
  }

  @override
  IntegerSchema copyWithInternal({
    required bool? isNullable,
    required String? description,
    required Object? defaultValue,
    required List<Validator<int>>? constraints,
    // IntegerSchema specific
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
    final Map<String, Object?> schema = {
      'type': isNullable ? ['integer', 'null'] : 'integer',
      if (description != null) 'description': description,
      if (defaultValue != null) 'default': defaultValue,
    };

    final constraintSchemas = <Map<String, Object?>>[];
    for (final constraint in constraints) {
      if (constraint is JsonSchemaSpec) {
        constraintSchemas.add((constraint as JsonSchemaSpec).toJsonSchema());
      }
    }

    return constraintSchemas.fold(
      schema,
      (prev, current) => deepMerge(prev, current),
    );
  }
}

// --- DoubleSchema ---
@immutable
final class DoubleSchema extends AckSchema<double> {
  final bool strictPrimitiveParsing;

  const DoubleSchema({
    this.strictPrimitiveParsing = false,
    super.isNullable,
    super.description,
    super.defaultValue,
    super.constraints,
  }) : super(schemaType: SchemaType.double);

  @override
  DoubleSchema copyWith({
    bool? strictPrimitiveParsing,
    bool? isNullable,
    String? description,
    Object? defaultValue,
    List<Validator<double>>? constraints,
  }) {
    return copyWithInternal(
      strictPrimitiveParsing: strictPrimitiveParsing,
      isNullable: isNullable,
      description: description,
      defaultValue: defaultValue,
      constraints: constraints,
    );
  }

  @override
  SchemaResult<double> tryConvertInput(
    Object? inputValue,
    SchemaContext context,
  ) {
    if (inputValue is double) return SchemaResult.ok(inputValue);
    if (inputValue is int) return SchemaResult.ok(inputValue.toDouble());
    if (strictPrimitiveParsing) {
      final constraintError =
          InvalidTypeConstraint(expectedType: double, inputValue: inputValue)
              .validate(inputValue);

      return SchemaResult.fail(SchemaConstraintsError(
        constraints: constraintError != null ? [constraintError] : [],
        context: context,
      ));
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
  SchemaResult<double> validateConvertedValue(
    double convertedValue,
    SchemaContext context,
  ) {
    return SchemaResult.ok(convertedValue);
  }

  @override
  DoubleSchema copyWithInternal({
    required bool? isNullable,
    required String? description,
    required Object? defaultValue,
    required List<Validator<double>>? constraints,
    // DoubleSchema specific
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
    final Map<String, Object?> schema = {
      'type': isNullable ? ['number', 'null'] : 'number',
      'format': 'double',
      if (description != null) 'description': description,
      if (defaultValue != null) 'default': defaultValue,
    };

    final constraintSchemas = <Map<String, Object?>>[];
    for (final constraint in constraints) {
      if (constraint is JsonSchemaSpec) {
        constraintSchemas.add((constraint as JsonSchemaSpec).toJsonSchema());
      }
    }

    return constraintSchemas.fold(
      schema,
      (prev, current) => deepMerge(prev, current),
    );
  }
}
