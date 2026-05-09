part of 'schema.dart';

/// Schema that accepts any value without type conversion or validation.
/// Useful for dynamic content or when you need maximum flexibility.
///
/// Unlike composite schemas (List, Object, AnyOf, Discriminated), AnySchema
/// supports default values and will emit them in JSON Schema output.
@immutable
final class AnySchema extends AckSchema<Object>
    with FluentSchema<Object, AnySchema> {
  const AnySchema({
    super.isNullable,
    super.isOptional,
    super.description,
    super.defaultValue,
    super.constraints,
    super.refinements,
  });

  @override
  SchemaType get schemaType => SchemaType.any;

  /// AnySchema accepts all values, so it overrides parseAndValidate directly.
  @override
  @protected
  SchemaResult<Object> parseAndValidate(
    Object? inputValue,
    SchemaContext context,
  ) {
    // Stage-2 shim: route through the new dispatcher so `decodeBoundary`
    // handles boundary semantics. Removed in M5.5 stage 5.
    return _parse(inputValue, context);
  }

  /// AnySchema accepts any non-null value as-is — no type detection or
  /// coercion. Constraints/refinements are applied by [_parse].
  @override
  @protected
  SchemaResult<Object> decodeBoundary(
    Object? input,
    SchemaContext context,
  ) {
    return SchemaResult.ok(input!);
  }

  @override
  AnySchema copyWith({
    bool? isNullable,
    bool? isOptional,
    String? description,
    Object? defaultValue,
    List<Constraint<Object>>? constraints,
    List<Refinement<Object>>? refinements,
  }) {
    return AnySchema(
      isNullable: isNullable ?? this.isNullable,
      isOptional: isOptional ?? this.isOptional,
      description: description ?? this.description,
      defaultValue: defaultValue ?? this.defaultValue,
      constraints: constraints ?? this.constraints,
      refinements: refinements ?? this.refinements,
    );
  }

  @override
  Map<String, Object?> toJsonSchema() => buildJsonSchemaWithNullable(
    // Empty typeSchema means "accepts any value" per JSON Schema standard
    typeSchema: {},
    serializedDefault: defaultValue,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AnySchema) return false;
    return baseFieldsEqual(other);
  }

  @override
  int get hashCode => baseFieldsHashCode;
}
