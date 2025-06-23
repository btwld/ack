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

  /// Creates a new IntegerSchema with modified integer-specific properties
  IntegerSchema copyWithIntegerProperties({
    bool? strictPrimitiveParsing,
    String? description,
    Object? defaultValue,
    List<Validator<int>>? constraints,
  }) {
    return IntegerSchema(
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
    if (inputValue is double) {
      if (inputValue.truncate() == inputValue) {
        return SchemaResult.ok(inputValue.toInt());
      }
    }

    final constraintError =
        InvalidTypeConstraint(expectedType: int, inputValue: inputValue)
            .validate(inputValue);

    return SchemaResult.fail(SchemaConstraintsError(
      constraints: constraintError != null ? [constraintError] : [],
      context: context,
    ));
  }

  @override
  SchemaResult<int> validateConvertedValue(
    int? convertedValue,
    SchemaContext context,
  ) {
    if (convertedValue == null) {
      final constraintError =
          InvalidTypeConstraint(expectedType: int, inputValue: null)
              .validate(null);

      return SchemaResult.fail(SchemaConstraintsError(
        constraints: constraintError != null ? [constraintError] : [],
        context: context,
      ));
    }

    return SchemaResult.ok(convertedValue);
  }

  @override
  IntegerSchema copyWithInternal({
    String? description,
    Object? defaultValue,
    List<Validator<int>>? constraints,
  }) {
    return IntegerSchema(
      description: description ?? this.description,
      defaultValue: defaultValue == ackRawDefaultValue
          ? this.defaultValue
          : defaultValue as int?,
      constraints: constraints ?? this.constraints,
      strictPrimitiveParsing: strictPrimitiveParsing,
    );
  }

  @override
  Map<String, Object?> toJsonSchema() {
    Map<String, Object?> schema = {
      'type': 'integer',
      if (description != null) 'description': description,
      if (defaultValue != null) 'default': defaultValue,
    };

    // Check constraints that implement JsonSchemaSpec
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

  /// Creates a new DoubleSchema with modified double-specific properties
  DoubleSchema copyWithDoubleProperties({
    bool? strictPrimitiveParsing,
    String? description,
    Object? defaultValue,
    List<Validator<double>>? constraints,
  }) {
    return DoubleSchema(
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
      final parsed = double.tryParse(inputValue);
      if (parsed != null) return SchemaResult.ok(parsed);
    }

    final constraintError =
        InvalidTypeConstraint(expectedType: double, inputValue: inputValue)
            .validate(inputValue);

    return SchemaResult.fail(SchemaConstraintsError(
      constraints: constraintError != null ? [constraintError] : [],
      context: context,
    ));
  }

  @override
  SchemaResult<double> validateConvertedValue(
    double? convertedValue,
    SchemaContext context,
  ) {
    if (convertedValue == null) {
      final constraintError =
          InvalidTypeConstraint(expectedType: double, inputValue: null)
              .validate(null);

      return SchemaResult.fail(SchemaConstraintsError(
        constraints: constraintError != null ? [constraintError] : [],
        context: context,
      ));
    }

    return SchemaResult.ok(convertedValue);
  }

  @override
  DoubleSchema copyWithInternal({
    String? description,
    Object? defaultValue,
    List<Validator<double>>? constraints,
  }) {
    return DoubleSchema(
      description: description ?? this.description,
      defaultValue: defaultValue == ackRawDefaultValue
          ? this.defaultValue
          : defaultValue as double?,
      constraints: constraints ?? this.constraints,
      strictPrimitiveParsing: strictPrimitiveParsing,
    );
  }

  @override
  Map<String, Object?> toJsonSchema() {
    Map<String, Object?> schema = {
      'type': 'number',
      if (description != null) 'description': description,
      if (defaultValue != null) 'default': defaultValue,
    };

    // Check constraints that implement JsonSchemaSpec
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
