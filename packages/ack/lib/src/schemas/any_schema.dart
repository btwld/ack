part of 'schema.dart';

/// Schema that accepts any value without type conversion or validation.
/// Useful for dynamic content or when you need maximum flexibility.
///
/// Defaults are owned by [DefaultSchema] (use `.withDefault(...)`).
@immutable
final class AnySchema extends AckSchema<Object>
    with FluentSchema<Object, AnySchema> {
  const AnySchema({
    super.isNullable,
    super.isOptional,
    super.description,
    super.constraints,
    super.refinements,
  });

  @override
  SchemaType get schemaType => SchemaType.any;

  /// AnySchema accepts any non-null value as-is — no type detection or
  /// coercion. Constraints/refinements are applied by [_parse].
  @override
  @protected
  SchemaResult<Object> decodeBoundary(Object? input, SchemaContext context) {
    return SchemaResult.ok(input!);
  }

  @override
  AnySchema copyWith({
    bool? isNullable,
    bool? isOptional,
    String? description,
    List<Constraint<Object>>? constraints,
    List<Refinement<Object>>? refinements,
  }) {
    return AnySchema(
      isNullable: isNullable ?? this.isNullable,
      isOptional: isOptional ?? this.isOptional,
      description: description ?? this.description,
      constraints: constraints ?? this.constraints,
      refinements: refinements ?? this.refinements,
    );
  }

  @override
  Map<String, Object?> toJsonSchema() {
    final schema = <String, Object?>{
      'anyOf': [
        {'type': 'string'},
        {'type': 'number'},
        {'type': 'integer'},
        {'type': 'boolean'},
        {'type': 'object'},
        {'type': 'array'},
        if (isNullable) {'type': 'null'},
      ],
      if (description != null) 'description': description,
    };

    return mergeConstraintSchemas(schema);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AnySchema) return false;
    return baseFieldsEqual(other);
  }

  @override
  int get hashCode => baseFieldsHashCode;
}
