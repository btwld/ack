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
  }) : super(schemaType: SchemaType.integer);

  @override
  @protected
  SchemaResult<int> _performTypeConversion(Object inputValue, SchemaContext context) {
    // First try basic type validation
    final typeResult = validateExpectedType(inputValue, context);
    if (typeResult.isOk) {
      return SchemaResult.ok(inputValue as int);
    }

    // If strict parsing is enabled, don't attempt conversion
    if (strictPrimitiveParsing) {
      return SchemaResult.fail(typeResult.getError());
    }

    // Try conversions from other types
    if (inputValue is String) {
      final parsed = int.tryParse(inputValue);
      if (parsed != null) return SchemaResult.ok(parsed);
    }
    if (inputValue is double && inputValue == inputValue.roundToDouble()) {
      return SchemaResult.ok(inputValue.toInt());
    }

    // Return the original type error
    return SchemaResult.fail(typeResult.getError());
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
  }) : super(schemaType: SchemaType.double);

  @override
  @protected
  SchemaResult<double> _performTypeConversion(Object inputValue, SchemaContext context) {
    // First try basic type validation
    final typeResult = validateExpectedType(inputValue, context);
    if (typeResult.isOk) {
      return SchemaResult.ok(inputValue as double);
    }

    // If strict parsing is enabled, don't attempt conversion
    if (strictPrimitiveParsing) {
      return SchemaResult.fail(typeResult.getError());
    }

    // Try conversions from other types
    if (inputValue is int) {
      return SchemaResult.ok(inputValue.toDouble());
    }
    if (inputValue is String) {
      final val = double.tryParse(inputValue);
      if (val != null) return SchemaResult.ok(val);
    }

    // Return the original type error
    return SchemaResult.fail(typeResult.getError());
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
    // Add format annotation for double precision
    schema['format'] = 'double';

    return schema;
  }
}
