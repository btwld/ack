part of 'schema.dart';

/// A wrapper schema that makes any non-nullable schema nullable.
///
/// It holds an internal `_schema` and intercepts the validation process.
/// If the input value is `null`, it returns a successful result with `null`.
/// Otherwise, it delegates the validation to the wrapped schema.
@immutable
class NullableSchema<T extends Object> extends AckSchema<T?> {
  final AckSchema<T> _schema;

  const NullableSchema(this._schema)
      : super(
          schemaType: _schema.schemaType,
          // All other properties are delegated to the inner schema
        );

  @override
  SchemaResult<T?> tryConvertInput(Object? inputValue, SchemaContext context) {
    if (inputValue == null) {
      return SchemaResult.ok(null);
    }

    // Delegate to the wrapped schema for conversion and validation
    return _schema.tryConvertInput(inputValue, context);
  }

  @override
  SchemaResult<T?> validateConvertedValue(
    T? convertedValue,
    SchemaContext context,
  ) {
    if (convertedValue == null) {
      return SchemaResult.ok(null);
    }

    // Delegate to the wrapped schema for validation
    return _schema.validateConvertedValue(convertedValue, context);
  }

  @override
  AckSchema<T?> copyWith({
    String? description,
    Object defaultValue = ackRawDefaultValue,
    List<Validator<T?>>? constraints,
  }) {
    // When we copy a nullable schema, we are essentially creating a new
    // nullable schema that wraps a modified version of the original schema.
    final newDefault = defaultValue == ackRawDefaultValue
        ? _schema.defaultValue
        : defaultValue as T?;

    // Create a new inner schema with the updated properties that are
    // applicable to it.
    final newInnerSchema = _schema.copyWith(
      description: description ?? _schema.description,
      defaultValue: newDefault,
      // We can't directly pass constraints of T? to a schema for T.
      // This is a limitation we must handle or document. For now, we assume
      // constraints are applied before making it nullable.
    );

    return NullableSchema(newInnerSchema as AckSchema<T>);
  }

  // --- Fluent API ---
  // The fluent API methods must return a new NullableSchema wrapping a
  // modified inner schema.

  @override
  AckSchema<T?> withDescription(String? newDescription) {
    return NullableSchema(_schema.withDescription(newDescription));
  }

  @override
  AckSchema<T?> withDefault(T? newDefaultValue) {
    // The default value is handled by the wrapper.
    return copyWith(defaultValue: newDefaultValue);
  }

  @override
  AckSchema<T?> addConstraint(Validator<T?> constraint) {
    // This is complex. A Validator<T?> cannot be applied to an AckSchema<T>.
    // For now, we'll throw an exception to make this limitation clear.
    // A better solution might involve creating a new type of constraint.
    throw UnimplementedError(
      'Cannot add a nullable constraint to a schema after making it nullable. Add constraints before calling .nullable()',
    );
  }

  @override
  AckSchema<T?> addConstraints(List<Validator<T?>> newConstraints) {
    throw UnimplementedError(
      'Cannot add nullable constraints to a schema after making it nullable. Add constraints before calling .nullable()',
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
