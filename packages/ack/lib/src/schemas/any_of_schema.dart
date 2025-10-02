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
/// Note: AnyOfSchema does not support default values. Use defaults on the
/// individual member schemas instead.
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
  }) : super(defaultValue: null);

  @override
  SchemaType get schemaType => SchemaType.anyOf;

  /// AnyOfSchema tries multiple schemas, so it overrides parseAndValidate directly.
  ///
  /// Key behaviors:
  /// 1. Tries ALL member schemas with the input value (including null)
  /// 2. Returns success on first matching schema
  /// 3. If no schema matches and input is null, checks AnyOfSchema's own nullable
  /// 4. Collects all errors for comprehensive debugging
  @override
  @protected
  SchemaResult<Object> parseAndValidate(
    Object? inputValue,
    SchemaContext context,
  ) {
    // STEP 1: Try all member schemas first (including with null input!)
    // This allows patterns like: Ack.anyOf([Ack.string().nullable(), Ack.integer()])
    // where the nullable member schema should accept null.
    final errors = <SchemaError>[];

    for (final (index, schema) in schemas.indexed) {
      // Keep branch name for debug but DON'T pollute the JSON Pointer path
      // User errors should point to their field path, not #/field/anyOf:0
      // Empty pathSegment means "inherit parent's path"
      final childContext = context.createChild(
        name: 'anyOf:$index',
        schema: schema,
        value: inputValue,
        pathSegment: '', // Inherit parent path, don't add segment
      );

      final result = schema.parseAndValidate(inputValue, childContext);

      // Early return on first success for better performance
      if (result.isOk) {
        final validatedValue = result.getOrNull();

        // If member schema returned null (because it's nullable), return directly
        // We don't apply AnyOfSchema's own constraints to null values
        if (validatedValue == null) {
          return SchemaResult.ok(null);
        }

        // Apply AnyOfSchema's own constraints and refinements to non-null values
        return applyConstraintsAndRefinements(validatedValue, context);
      }

      // Collect error for comprehensive error reporting
      errors.add(result.getError());
    }

    // STEP 2: No member schema accepted the value
    // If input is null, check AnyOfSchema's own nullable settings
    if (inputValue == null) {
      if (isNullable) {
        return SchemaResult.ok(null);
      }
    }

    // STEP 3: Nothing worked - return comprehensive errors
    return SchemaResult.fail(SchemaNestedError(
      errors: errors,
      context: context,
    ));
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
    // defaultValue is ignored - AnyOfSchema does not support defaults
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
      // defaultValue omitted - AnyOfSchema does not support defaults
      'constraints': constraints.map((c) => c.toMap()).toList(),
      'schemas': schemas.length,
    };
  }
}
