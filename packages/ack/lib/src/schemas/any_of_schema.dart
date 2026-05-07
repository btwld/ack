part of 'schema.dart';

/// Schema for validating against a list of schemas.
@immutable
final class AnyOfSchema extends AckSchema<Object>
    with FluentSchema<Object, AnyOfSchema> {
  final List<AckSchema> schemas;

  const AnyOfSchema(
    this.schemas, {
    super.isNullable,
    super.isOptional,
    super.description,
    super.constraints,
    super.refinements,
  });

  @override
  SchemaType get schemaType => SchemaType.anyOf;

  @override
  @protected
  SchemaResult<Object> _validateRuntime(Object? value, SchemaContext context) =>
      _runBranches(
        value,
        context,
        (schema, v, ctx) => schema._validateRuntime(v, ctx),
      );

  @override
  @protected
  SchemaResult<Object> decodeBoundary(Object? input, SchemaContext context) =>
      _runBranches(
        input,
        context,
        (schema, v, ctx) => schema.decodeBoundary(v, ctx),
      );

  SchemaResult<Object> _runBranches(
    Object? value,
    SchemaContext context,
    SchemaResult<Object> Function(
      AckSchema schema,
      Object? v,
      SchemaContext ctx,
    )
    handle,
  ) {
    final errors = <SchemaError>[];

    for (final (index, schema) in schemas.indexed) {
      final childContext = context.createChild(
        name: 'anyOf:$index',
        schema: schema,
        value: value,
        pathSegment: '',
      );

      final result = handle(schema, value, childContext);

      if (result.isOk) {
        final validated = result.getOrNull();
        if (validated == null) return SchemaResult.ok(null);
        return applyConstraintsAndRefinements(validated, context);
      }

      errors.add(result.getError());
    }

    if (value == null && isNullable) return SchemaResult.ok(null);

    return SchemaResult.fail(
      SchemaNestedError(errors: errors, context: context),
    );
  }

  @override
  @protected
  SchemaResult<Object> encodeBoundary(Object value, SchemaContext context) {
    final errors = <SchemaError>[];

    for (final (index, schema) in schemas.indexed) {
      final childContext = context.createChild(
        name: 'anyOf:$index',
        schema: schema,
        value: value,
        pathSegment: '',
      );

      final result = _encodeWithSchema(schema, value, childContext);
      if (result.isOk) return result;

      errors.add(result.getError());
    }

    return SchemaResult.fail(
      SchemaNestedError(errors: errors, context: context),
    );
  }

  @override
  AnyOfSchema copyWith({
    bool? isNullable,
    bool? isOptional,
    String? description,
    List<Constraint<Object>>? constraints,
    List<Refinement<Object>>? refinements,
  }) {
    return AnyOfSchema(
      schemas,
      isNullable: isNullable ?? this.isNullable,
      isOptional: isOptional ?? this.isOptional,
      description: description ?? this.description,
      constraints: constraints ?? this.constraints,
      refinements: refinements ?? this.refinements,
    );
  }

  @override
  Map<String, Object?> toJsonSchema() {
    final anyOfClauses = schemas.map((s) => s.toJsonSchema()).toList();

    final baseSchema = {
      'anyOf': anyOfClauses,
      if (!isNullable && description != null) 'description': description,
    };

    if (isNullable) {
      return {
        if (description != null) 'description': description,
        'anyOf': [
          mergeConstraintSchemas(baseSchema),
          {'type': 'null'},
        ],
      };
    }

    return mergeConstraintSchemas(baseSchema);
  }

  @override
  Map<String, Object?> toMap() {
    return {
      'type': schemaType.typeName,
      'isNullable': isNullable,
      'description': description,
      'constraints': constraints.map((c) => c.toMap()).toList(),
      'schemas': schemas.length,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AnyOfSchema) return false;
    const listEq = ListEquality<AckSchema>();
    return baseFieldsEqual(other) && listEq.equals(schemas, other.schemas);
  }

  @override
  int get hashCode {
    const listEq = ListEquality<AckSchema>();
    return Object.hash(baseFieldsHashCode, listEq.hash(schemas));
  }
}
