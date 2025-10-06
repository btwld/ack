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

  @override
  @protected
  SchemaResult<Object> parseAndValidate(
    Object? inputValue,
    SchemaContext context,
  ) {
    // Handle defaults with cloning
    if (inputValue == null && defaultValue != null) {
      final clonedDefault = cloneDefault(defaultValue!) as Object;
      return parseAndValidate(clonedDefault, context);
    }

    // Try all member schemas (including with null input for nullable members)
    final errors = <SchemaError>[];

    for (final (index, schema) in schemas.indexed) {
      // Branch name for debugging; inherit parent path (no segment pollution)
      final childContext = context.createChild(
        name: 'anyOf:$index',
        schema: schema,
        value: inputValue,
        pathSegment: '', // Inherit parent path
      );

      final result = schema.parseAndValidate(inputValue, childContext);

      if (result.isOk) {
        final validatedValue = result.getOrNull();

        // Nullable member returned null - pass through
        if (validatedValue == null) {
          return SchemaResult.ok(null);
        }

        // Apply AnyOfSchema's own constraints to non-null values
        return applyConstraintsAndRefinements(validatedValue, context);
      }

      errors.add(result.getError());
    }

    // No member schema matched; check AnyOfSchema's own nullable flag
    if (inputValue == null && isNullable) {
      return SchemaResult.ok(null);
    }

    // Return all errors for debugging
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
          baseSchema,
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
}
