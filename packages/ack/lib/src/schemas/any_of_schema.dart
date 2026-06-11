part of 'schema.dart';

/// Schema for validating against a list of schemas (union).
///
/// Uses broad `Object`/`Object` typing because Dart does not have first-class
/// union types.
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

  SchemaResult<Object> _tryBranches(
    Object? value,
    SchemaContext context, {
    required bool parse,
  }) {
    // On parse we let branches see null first so a member's DefaultSchema or
    // nullable branch can resolve before the union-level null gate rejects.
    // Runtime validation keeps the union-level null gate intact.
    if (!parse) {
      final nullResult = handleNullInput(value, context);
      if (nullResult != null) return nullResult;
    }

    final errors = <SchemaError>[];
    for (final (index, schema) in schemas.indexed) {
      final childContext = context.createChild(
        name: 'anyOf:$index',
        schema: schema,
        value: value,
        pathSegment: const SchemaPathSegment.passThrough(),
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

    if (parse && value == null) {
      if (acceptsNull) return SchemaResult.ok(null);

      return failNonNullable(context);
    }

    return SchemaResult.fail(
      SchemaNestedError(errors: errors, context: context),
    );
  }

  bool get _anyBranchNullable => schemas.any((s) => s.isNullable);

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

  @override
  @protected
  SchemaResult<Object> encodeWithContext(Object value, SchemaContext context) {
    final validated = validateRuntimeWithContext(value, context);
    if (validated.isFail) {
      return SchemaResult.fail(validated.getError());
    }
    final runtime = validated.getOrNull();
    if (runtime == null) return SchemaResult.ok(null);

    final errors = <SchemaError>[];
    for (final (index, schema) in schemas.indexed) {
      final childContext = context.createChild(
        name: 'anyOf:$index',
        schema: schema,
        value: runtime,
        pathSegment: const SchemaPathSegment.passThrough(),
        operation: SchemaOperation.encode,
      );
      try {
        // Validate against the branch's runtime first; only attempt encode
        // when the value plausibly fits this branch.
        final branchValidation = schema.validateRuntimeWithContext(
          runtime,
          childContext,
        );
        if (branchValidation.isFail) {
          errors.add(branchValidation.getError());
          continue;
        }
        final encoded = schema.encodeWithContext(runtime, childContext);
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
  SchemaType get schemaType => SchemaType.anyOf;

  @override
  bool get acceptsNull => super.acceptsNull || _anyBranchNullable;

  @override
  int get hashCode {
    const listEq = ListEquality<AnyAckSchema>();

    return Object.hash(baseFieldsHashCode, listEq.hash(schemas));
  }
}
