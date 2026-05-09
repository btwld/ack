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
    super.defaultValue,
    super.constraints,
    super.refinements,
  });

  @override
  SchemaType get schemaType => SchemaType.anyOf;

  /// Custom null/default handling. AnyOf has special null semantics:
  ///   1. If a default exists, apply it (consistent with other schemas).
  ///   2. Otherwise return `null` to let [decodeBoundary] try member schemas
  ///      against `null` — a nullable branch can accept null before this
  ///      schema's own [isNullable] flag is consulted.
  @override
  @protected
  SchemaResult<Object>? handleParseNull(
    Object? input,
    SchemaContext context,
  ) {
    if (input == null && defaultValue != null) {
      final clonedDefault = cloneDefault(defaultValue!);
      return _parse(clonedDefault, context);
    }
    // Returning null routes the dispatcher into decodeBoundary even for a
    // null input; required to give nullable members a chance.
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

  @override
  AnyOfSchema copyWith({
    bool? isNullable,
    bool? isOptional,
    String? description,
    Object? defaultValue,
    List<Constraint<Object>>? constraints,
    List<Refinement<Object>>? refinements,
  }) {
    return AnyOfSchema(
      schemas, // schemas are immutable once created
      isNullable: isNullable ?? this.isNullable,
      isOptional: isOptional ?? this.isOptional,
      description: description ?? this.description,
      defaultValue: defaultValue ?? this.defaultValue,
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
      if (!isNullable && defaultValue != null) 'default': defaultValue,
    };

    // Wrap in another anyOf with null if nullable (match Zod's format)
    if (isNullable) {
      return {
        if (description != null) 'description': description,
        if (defaultValue != null) 'default': defaultValue,
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
      'defaultValue': defaultValue,
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
