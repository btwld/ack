part of 'schema.dart';

/// Schema that accepts any non-null value.
@immutable
final class AnySchema extends AckSchema<Object, Object>
    with FluentSchema<Object, Object, AnySchema> {
  const AnySchema({
    super.isNullable,
    super.isOptional,
    super.description,
    super.constraints,
    super.refinements,
  });

  @override
  SchemaType get schemaType => SchemaType.any;

  @override
  @protected
  SchemaResult<Object> parseWithContext(
    Object? value,
    SchemaContext context,
  ) => validateRuntimeWithContext(value, context);

  @override
  @protected
  SchemaResult<Object> validateRuntimeWithContext(
    Object? value,
    SchemaContext context,
  ) {
    final nullResult = handleNullInput(value, context);
    if (nullResult != null) return nullResult;
    return applyConstraintsAndRefinements(value!, context);
  }

  @override
  @protected
  SchemaResult<Object> encodeWithContext(
    Object value,
    SchemaContext context,
  ) {
    final validated = validateRuntimeWithContext(value, context);
    if (validated.isFail) return SchemaResult.fail(validated.getError());
    return SchemaResult.ok(value);
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
    // `Ack.any()` accepts any non-null Dart value at runtime, so the
    // emitted JSON Schema must NOT accept null unless the schema is
    // explicitly marked nullable. Raw `{}` would accept null, so we
    // enumerate the non-null JSON types explicitly.
    final nonNullBranches = <Map<String, Object?>>[
      {'type': 'string'},
      {'type': 'number'},
      {'type': 'integer'},
      {'type': 'boolean'},
      {'type': 'object'},
      {'type': 'array'},
    ];

    if (isNullable) {
      return {
        if (description != null) 'description': description,
        'anyOf': [
          ...nonNullBranches,
          {'type': 'null'},
        ],
      };
    }

    final base = {
      'anyOf': nonNullBranches,
      if (description != null) 'description': description,
    };
    return mergeConstraintSchemas(base);
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
