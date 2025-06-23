part of 'schema.dart';

@immutable
sealed class NumSchema<T extends num> extends AckSchema<T>
    with FluentSchema<T, NumSchema<T>> {
  final bool strictPrimitiveParsing;

  const NumSchema({
    this.strictPrimitiveParsing = false,
    required super.schemaType,
    super.isNullable,
    super.description,
    super.defaultValue,
    super.constraints,
  });

  @override
  NumSchema<T> copyWith({
    bool? strictPrimitiveParsing,
    bool? isNullable,
    String? description,
    Object? defaultValue,
    List<Validator<T>>? constraints,
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
  SchemaResult<T> tryConvertInput(Object? inputValue, SchemaContext context) {
    if (inputValue is T) return SchemaResult.ok(inputValue);
    if (strictPrimitiveParsing) {
      final constraintError =
          InvalidTypeConstraint(expectedType: T, inputValue: inputValue)
              .validate(inputValue);

      return SchemaResult.fail(SchemaConstraintsError(
        constraints: constraintError != null ? [constraintError] : [],
        context: context,
      ));
    }

    if (inputValue is String) {
      final parsed = T.parse(inputValue);
      if (parsed != null) return SchemaResult.ok(parsed);
    }
    if (inputValue is double && !strictPrimitiveParsing) {
      if (inputValue == inputValue.truncateToDouble()) {
        return SchemaResult.ok(inputValue.toInt());
      }
    }
    final constraintError =
        InvalidTypeConstraint(expectedType: T, inputValue: inputValue)
            .validate(inputValue);

    return SchemaResult.fail(
      SchemaConstraintsError(
        constraints: constraintError != null ? [constraintError] : [],
        context: context,
      ),
    );
  }

  @override
  SchemaResult<T> validateConvertedValue(
    T convertedValue,
    SchemaContext context,
  ) {
    return SchemaResult.ok(convertedValue);
  }

  @override
  NumSchema<T> copyWithInternal({
    required bool? isNullable,
    required String? description,
    required Object? defaultValue,
    required List<Validator<T>>? constraints,
    // NumSchema specific
    bool? strictPrimitiveParsing,
  }) {
    return NumSchema(
      isNullable: isNullable ?? this.isNullable,
      description: description ?? this.description,
      defaultValue: defaultValue == ackRawDefaultValue
          ? this.defaultValue
          : defaultValue as T?,
      constraints: constraints ?? this.constraints,
      strictPrimitiveParsing:
          strictPrimitiveParsing ?? this.strictPrimitiveParsing,
      schemaType: schemaType,
    );
  }

  @override
  Map<String, Object?> toJsonSchema() {
    final Map<String, Object?> schema = {
      'type': isNullable ? ['number', 'null'] : 'number',
      'format': schemaType.format,
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

// --- IntegerSchema ---
@immutable
final class IntegerSchema extends NumSchema<int> {
  const IntegerSchema({
    super.strictPrimitiveParsing,
    super.isNullable,
    super.description,
    super.defaultValue,
    super.constraints,
  }) : super(schemaType: SchemaType.integer);
}

// --- DoubleSchema ---
@immutable
final class DoubleSchema extends NumSchema<double> {
  const DoubleSchema({
    super.strictPrimitiveParsing,
    super.isNullable,
    super.description,
    super.defaultValue,
    super.constraints,
  }) : super(schemaType: SchemaType.double);
}
