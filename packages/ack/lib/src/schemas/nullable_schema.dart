part of 'schema.dart';

/// A wrapper schema that makes any non-nullable schema nullable.
///
/// It holds an internal `_schema` and delegates all logic to it, relying on
/// the base `AckSchema` implementation to handle nulls correctly by checking
/// the generic type `T?`.
@immutable
class NullableSchema<T extends Object> extends AckSchema<T?> {
  final AckSchema<dynamic> _schema;

  NullableSchema(this._schema)
      : super(
          schemaType: _schema.schemaType,
          description: _schema.description,
          defaultValue: _schema.defaultValue,
          // The constraints of the inner schema are for `T`, not `T?`.
          // We cast them here. This assumes constraints are added before
          // nullability is applied, which is enforced by the API.
          constraints: _schema.constraints.cast(),
        );

  @override
  SchemaResult<T?> tryConvertInput(Object? inputValue, SchemaContext context) {
    // A null value is handled by the base parseAndValidate. If we get here,
    // the inputValue is not null, so we delegate to the inner schema.
    return _schema.tryConvertInput(inputValue, context) as SchemaResult<T?>;
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
    return _schema.validateConvertedValue(convertedValue, context)
        as SchemaResult<T?>;
  }

  @override
  AckSchema<T?> copyWith({
    String? description,
    Object? defaultValue,
    List<Validator<T?>>? constraints,
  }) {
    // When copying, we create a new inner schema with the updated properties
    // and then wrap it in a new NullableSchema.
    final newInner = _schema.copyWith(
      description: description,
      defaultValue: defaultValue,
      // Pass null for constraints as we cannot forward Validator<T?> to Validator<T>
    );

    return NullableSchema(newInner);
  }

  // --- Fluent API Delegation ---

  @override
  AckSchema<T?> withDescription(String? newDescription) {
    return NullableSchema(_schema.withDescription(newDescription));
  }

  @override
  AckSchema<T?> withDefault(T? newDefaultValue) {
    // This is the key. The default value is applied to a *new* copy of the
    // inner schema, which is then wrapped.
    return NullableSchema(_schema.copyWith(defaultValue: newDefaultValue));
  }

  @override
  AckSchema<T?> addConstraint(Validator<T?> constraint) {
    throw UnimplementedError(
      'Cannot add constraints after making a schema nullable. Add constraints before calling .nullable()',
    );
  }

  @override
  AckSchema<T?> addConstraints(List<Validator<T?>> newConstraints) {
    throw UnimplementedError(
      'Cannot add constraints after making a schema nullable. Add constraints before calling .nullable()',
    );
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

  @override
  AckSchema<T?> nullable({bool value = true}) {
    // It's already nullable, so just return this.
    return this;
  }
}
