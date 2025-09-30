part of 'schema.dart';

/// Schema for validating against a list of schemas.
/// The input is valid if it is valid against any of the schemas in the list.
@immutable
final class AnyOfSchema extends AckSchema<Object>
    with FluentSchema<Object, AnyOfSchema> {
  final List<AckSchema> schemas;

  const AnyOfSchema(
    this.schemas, {
    super.isNullable,
    super.description,
    super.defaultValue,
    super.constraints,
    super.refinements,
  }) : super(schemaType: SchemaType.unknown);

  @override
  JsonType get acceptedType => JsonType.string; // Arbitrary, not used

  /// AnyOfSchema tries multiple schemas, so it overrides parseAndValidate directly.
  @override
  @protected
  SchemaResult<Object> parseAndValidate(
    Object? inputValue,
    SchemaContext context,
  ) {
    // Use centralized null handling
    if (inputValue == null) return handleNullInput(context);

    // Try each schema until one succeeds
    final validationErrors = <SchemaError>[];

    for (var i = 0; i < schemas.length; i++) {
      final schema = schemas[i];
      // Keep branch name for debug but DON'T pollute the JSON Pointer path
      // User errors should point to their field path, not #/field/anyOf:0
      // Empty pathSegment means "inherit parent's path"
      final childContext = context.createChild(
        name: 'anyOf:$i',
        schema: schema,
        value: inputValue,
        pathSegment: '', // Inherit parent path, don't add segment
      );
      final result = schema.parseAndValidate(inputValue, childContext);
      if (result.isOk) {
        final validatedValue = result.getOrThrow()!;

        // Use centralized constraints and refinements check
        return applyConstraintsAndRefinements(validatedValue, context);
      }
      validationErrors.add(result.getError());
    }

    return SchemaResult.fail(SchemaNestedError(
      errors: validationErrors,
      context: context,
    ));
  }

  @override
  AnyOfSchema copyWithInternal({
    required bool? isNullable,
    required String? description,
    required Object? defaultValue,
    required List<Constraint<Object>>? constraints,
    required List<Refinement<Object>>? refinements,
    List<AckSchema>? schemas,
  }) {
    return AnyOfSchema(
      schemas ?? this.schemas,
      isNullable: isNullable ?? this.isNullable,
      description: description ?? this.description,
      defaultValue: defaultValue ?? this.defaultValue,
      constraints: constraints ?? this.constraints,
      refinements: refinements ?? this.refinements,
    );
  }

  @override
  Map<String, Object?> toJsonSchema() {
    final anyOfClauses = schemas.map((s) => s.toJsonSchema()).toList();

    // Add null as an option if nullable
    if (isNullable) {
      anyOfClauses.insert(0, {'type': 'null'});
    }

    final schema = {
      'anyOf': anyOfClauses,
      if (description != null) 'description': description,
    };

    return mergeConstraintSchemas(schema);
  }
}
