part of 'schema.dart';

/// A wrapper schema that makes any non-nullable schema nullable.
///
/// It holds an internal `_schema` and delegates all logic to it, relying on
/// the base `AckSchema` implementation to handle nulls correctly by checking
/// the generic type `T?`.
@immutable
class NullableSchema<T extends Object> extends AckSchema<T?> {
  final AckSchema<T> _schema;

  NullableSchema(this._schema)
      : super(
          schemaType: _schema.schemaType,
          description: _schema.description,
          defaultValue: _schema.defaultValue,
          // The constraints of the inner schema are for `T`, not `T?`.
          // We need to handle this carefully since we can't directly cast
          // List<Validator<T>> to List<Validator<T?>>
          constraints: const [],
        );

  /// Provides access to the underlying non-nullable schema
  AckSchema<T> get innerSchema => _schema;

  /// Creates a new NullableSchema with a modified inner schema
  NullableSchema<T> copyWithInnerSchema(AckSchema<T> newInnerSchema) {
    return NullableSchema(newInnerSchema);
  }

  AckSchema<T?> nullable({bool value = true}) {
    // It's already nullable, so just return this.
    return this;
  }

  @override
  SchemaResult<T?> tryConvertInput(Object? inputValue, SchemaContext context) {
    // A null value is handled by the base parseAndValidate. If we get here,
    // the inputValue is not null, so we delegate to the inner schema.
    final result = _schema.tryConvertInput(inputValue, context);

    // Safe conversion: if inner schema succeeds with T, we can safely return T?
    return result.match(
      onOk: (value) => SchemaResult.ok(value),
      onFail: (error) => SchemaResult.fail(error),
    );
  }

  @override
  SchemaResult<T?> validateConvertedValue(
    T? convertedValue,
    SchemaContext context,
  ) {
    // If the value is null, it's valid for a nullable schema.
    if (convertedValue == null) {
      return SchemaResult.ok(null);
    }

    // If it's not null, delegate validation to the inner schema.
    // Since convertedValue is T? and we checked it's not null, it's safe to cast to T
    final result = _schema.validateConvertedValue(convertedValue, context);

    // Safe conversion: if inner schema succeeds with T, we can safely return T?
    return result.match(
      onOk: (value) => SchemaResult.ok(value),
      onFail: (error) => SchemaResult.fail(error),
    );
  }

  @override
  AckSchema<T?> copyWithInternal({
    String? description,
    Object? defaultValue,
    // ignore: avoid_unused_parameters
    List<Validator<T?>>? constraints,
  }) {
    // When copying, we create a new inner schema with the updated properties
    // and then wrap it in a new NullableSchema.
    // Note: We can't forward T? constraints to the inner T schema,
    // so we ignore the constraints parameter for now.
    final newInner = _schema.copyWith(
      description: description,
      defaultValue: defaultValue == ackRawDefaultValue
          ? _schema.defaultValue
          : defaultValue,
      // Cannot forward constraints as they are typed differently
    );

    return NullableSchema(newInner);
  }

  @override
  Map<String, Object?> toJsonSchema() {
    final originalSchema = _schema.toJsonSchema();
    if (originalSchema['type'] is String) {
      return {
        ...originalSchema,
        'type': [originalSchema['type'], 'null'],
      };
    }

    return originalSchema;
  }
}
