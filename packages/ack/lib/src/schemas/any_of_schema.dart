part of 'schema.dart';

/// Schema for validating against a list of schemas (union).
///
/// Keeps broad typing in the first redesign (`Object`/`Object`) because
/// Dart does not have first-class union types.
///
/// Nullable semantics are symmetric: an `AnyOfSchema` allows null on both
/// parse and encode if [isNullable] is true OR any branch is itself nullable.
@immutable
final class AnyOfSchema extends AckSchema<Object, Object>
    with FluentSchema<Object, Object, AnyOfSchema> {
  final List<AnyAckSchema> schemas;

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

  bool get _anyBranchNullable => schemas.any((s) => s.isNullable);

  @override
  bool get acceptsParseNull => super.acceptsParseNull || _anyBranchNullable;

  @override
  bool get acceptsEncodeNull => super.acceptsEncodeNull || _anyBranchNullable;

  @override
  @protected
  SchemaResult<Object> parseWithContext(Object? value, SchemaContext context) =>
      _tryBranches(value, context, parse: true);

  @override
  @protected
  SchemaResult<Object> validateRuntimeWithContext(
    Object? value,
    SchemaContext context,
  ) => _tryBranches(value, context, parse: false);

  SchemaResult<Object> _tryBranches(
    Object? value,
    SchemaContext context, {
    required bool parse,
  }) {
    final nullResult = handleNullInput(value, context);
    if (nullResult != null) return nullResult;

    final errors = <SchemaError>[];
    for (final (index, schema) in schemas.indexed) {
      final childContext = context.createChild(
        name: 'anyOf:$index',
        schema: schema,
        value: value,
        pathSegment: '',
      );
      final result = parse
          ? schema.parseWithContext(value, childContext)
          : schema.validateRuntimeWithContext(value, childContext);
      if (result.isOk) {
        final v = result.getOrNull();
        if (v == null) return SchemaResult.ok(null);
        return applyConstraintsAndRefinements(v, context);
      }
      errors.add(result.getError());
    }
    return SchemaResult.fail(
      SchemaNestedError(errors: errors, context: context),
    );
  }

  @override
  @protected
  SchemaResult<Object> encodeWithContext(Object value, SchemaContext context) {
    final errors = <SchemaError>[];
    for (final (index, schema) in schemas.indexed) {
      final childContext = context.createChild(
        name: 'anyOf:$index',
        schema: schema,
        value: value,
        pathSegment: '',
        operation: SchemaOperation.encode,
      );
      try {
        // Validate against the branch's runtime first; only attempt encode
        // when the value plausibly fits this branch.
        final branchValidation = schema.validateRuntimeWithContext(
          value,
          childContext,
        );
        if (branchValidation.isFail) {
          errors.add(branchValidation.getError());
          continue;
        }
        final encoded = schema.encodeWithContext(value, childContext);
        if (encoded.isOk) {
          final boundary = encoded.getOrNull();
          if (boundary != null) {
            return SchemaResult.ok(boundary);
          }
        } else {
          errors.add(encoded.getError());
        }
      } catch (e, st) {
        errors.add(
          SchemaEncodeError.encoderThrew(
            message: 'AnyOf branch $index threw: $e',
            context: childContext,
            cause: e,
            stackTrace: st,
          ),
        );
      }
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
    return wrapCompositeWithNullable({
      'anyOf': schemas.map((s) => s.toJsonSchema()).toList(),
      if (!isNullable && description != null) 'description': description,
    });
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
    const listEq = ListEquality<AnyAckSchema>();
    return baseFieldsEqual(other) && listEq.equals(schemas, other.schemas);
  }

  @override
  int get hashCode {
    const listEq = ListEquality<AnyAckSchema>();
    return Object.hash(baseFieldsHashCode, listEq.hash(schemas));
  }
}
