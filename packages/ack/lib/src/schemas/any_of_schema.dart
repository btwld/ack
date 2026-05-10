part of 'schema.dart';

/// Schema for validating against a list of schemas.
///
/// The input is valid if it matches ANY of the provided schemas.
/// This is useful for union types where a value can be one of several different types.
///
/// Example:
/// ```dart
/// final schema = Ack.anyOf([
///   Ack.string(),
///   Ack.integer(),
///   Ack.boolean(),
/// ]);
///
/// schema.safeParse('hello');  // Ok
/// schema.safeParse(42);        // Ok
/// schema.safeParse(true);      // Ok
/// schema.safeParse([]);        // Fail - not matching any schema
/// ```
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

  /// AnyOf has special null semantics: returning `null` from
  /// `handleParseNull` routes the dispatcher into [decodeBoundary] even for
  /// a null input, so a nullable branch member can accept null before this
  /// schema's own [isNullable] flag is consulted. Defaults are owned by
  /// [DefaultSchema] (use `.withDefault(...)`).
  @override
  @protected
  SchemaResult<Object>? handleParseNull(
    Object? input,
    SchemaContext context,
  ) {
    return null;
  }

  /// Tries every member schema in order. The first branch whose parse
  /// succeeds wins. A successful parse returning a null value (nullable
  /// branch matched null) short-circuits to `Ok(null)`. If all branches
  /// fail, this schema's own `isNullable` flag is consulted for null input.
  /// Constraints/refinements are applied by [_parse] for non-null branch
  /// values.
  @override
  @protected
  SchemaResult<Object> decodeBoundary(
    Object? input,
    SchemaContext context,
  ) {
    final errors = <SchemaError>[];

    for (final (index, schema) in schemas.indexed) {
      final childContext = context.createChild(
        name: 'anyOf:$index',
        schema: schema,
        value: input,
        pathSegment: '', // Inherit parent path
      );

      final result = schema._parse(input, childContext);

      if (result.isOk) {
        final validatedValue = result.getOrNull();
        if (validatedValue == null) {
          // Nullable branch matched null. Dispatcher will short-circuit
          // constraint application.
          return SchemaResult.ok(null);
        }
        return SchemaResult.ok(validatedValue);
      }

      errors.add(result.getError());
    }

    // No member schema matched; check this schema's own nullable flag.
    if (input == null && isNullable) {
      return SchemaResult.ok(null);
    }

    return SchemaResult.fail(
      SchemaNestedError(errors: errors, context: context),
    );
  }

  /// Validates a runtime value against the union: tries each member's
  /// `_validateRuntime` in declaration order; the first branch whose runtime
  /// validation succeeds wins. AnyOf-level constraints/refinements are
  /// applied here (exactly once) so [encodeBoundary] does not re-apply them.
  @override
  @protected
  SchemaResult<Object> _validateRuntime(
    Object? value,
    SchemaContext context,
  ) {
    final errors = <SchemaError>[];

    for (final (index, schema) in schemas.indexed) {
      final childContext = context.createChild(
        name: 'anyOf:$index',
        schema: schema,
        value: value,
        pathSegment: '', // Inherit parent path
      );

      final result = schema._validateRuntime(value, childContext);
      if (result.isOk) {
        final validated = result.getOrNull();
        if (validated == null) {
          return SchemaResult.ok(null);
        }
        return applyConstraintsAndRefinements(validated, context);
      }
      errors.add(result.getError());
    }

    if (value == null && isNullable) {
      return SchemaResult.ok(null);
    }

    return SchemaResult.fail(
      SchemaNestedError(errors: errors, context: context),
    );
  }

  /// Encodes a runtime value through the first branch whose **full** encode
  /// pipeline succeeds end-to-end (`_validateRuntime` + `encodeBoundary`),
  /// per A5. A branch that validates but fails encoding does NOT short-
  /// circuit — encoding falls through to the next branch.
  ///
  /// AnyOf-level constraints/refinements are NOT re-applied here; they
  /// already ran in [_validateRuntime] before this method was invoked.
  @override
  @protected
  SchemaResult<Object> encodeBoundary(
    Object value,
    SchemaContext context,
  ) {
    final errors = <SchemaError>[];

    for (final (index, schema) in schemas.indexed) {
      final childContext = context.createChild(
        name: 'anyOf:$index',
        schema: schema,
        value: value,
        pathSegment: '', // Inherit parent path
      );

      final validated = schema._validateRuntime(value, childContext);
      if (validated.isFail) {
        errors.add(validated.getError());
        continue;
      }

      final branchValue = validated.getOrNull();
      if (branchValue == null) {
        // Nullable branch accepted null at runtime → null in boundary form.
        return SchemaResult.ok(null);
      }

      final encoded = schema.encodeBoundary(branchValue, childContext);
      if (encoded.isOk) {
        return encoded;
      }
      errors.add(encoded.getError());
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
      schemas, // schemas are immutable once created
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

    // Wrap in another anyOf with null if nullable (match Zod's format)
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
