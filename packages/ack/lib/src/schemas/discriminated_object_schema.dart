part of 'schema.dart';

/// Schema for validating a discriminated union of objects.
///
/// Based on a `discriminatorKey` (e.g., 'type'), it uses one of the provided
/// `schemas` to validate the object.
@immutable
final class DiscriminatedObjectSchema extends AckSchema<MapValue>
    with FluentSchema<MapValue, DiscriminatedObjectSchema> {
  final String discriminatorKey;
  final Map<String, AckSchema> schemas;

  const DiscriminatedObjectSchema({
    required this.discriminatorKey,
    required this.schemas,
    super.isNullable,
    super.description,
    super.defaultValue,
    super.constraints,
    super.refinements,
  });

  @override
  JsonType get acceptedType => JsonType.object;

  /// DiscriminatedObjectSchema uses custom polymorphic validation logic,
  /// so it overrides parseAndValidate directly.
  ///
  /// Key behaviors:
  /// 1. For non-null input: validates discriminator and routes to appropriate schema
  /// 2. For null input with default: recursively validates default through discriminator logic
  /// 3. For null input without default but nullable: returns null
  @override
  @protected
  SchemaResult<MapValue> parseAndValidate(
    Object? inputValue,
    SchemaContext context,
  ) {
    // Use centralized null handling
    if (inputValue == null) return handleNullInput(context);

    // Use centralized type checking
    final typeError = checkTypeMatch(inputValue, context);
    if (typeError != null) return typeError;

    // Custom discriminated object validation logic
    if (inputValue is! MapValue) {
      final constraintError =
          InvalidTypeConstraint(expectedType: MapValue).validate(inputValue);

      return SchemaResult.fail(SchemaConstraintsError(
        constraints: constraintError != null ? [constraintError] : [],
        context: context,
      ));
    }

    final Object? discValueRaw = inputValue[discriminatorKey];

    if (discValueRaw == null) {
      final constraintError = ObjectRequiredPropertiesConstraint(
        missingPropertyKey: discriminatorKey,
      ).validate(inputValue);

      return SchemaResult.fail(SchemaConstraintsError(
        constraints: constraintError != null ? [constraintError] : [],
        context: context.createChild(
          name: discriminatorKey,
          schema: const StringSchema(),
          value: null,
          pathSegment: discriminatorKey,
        ),
      ));
    }

    if (discValueRaw is! String) {
      final constraintError =
          InvalidTypeConstraint(expectedType: String).validate(discValueRaw);

      return SchemaResult.fail(SchemaConstraintsError(
        constraints: constraintError != null ? [constraintError] : [],
        context: context.createChild(
          name: discriminatorKey,
          schema: const StringSchema(),
          value: discValueRaw,
          pathSegment: discriminatorKey,
        ),
      ));
    }

    final AckSchema? selectedSubSchema = schemas[discValueRaw];

    if (selectedSubSchema == null) {
      final allowed = schemas.keys.toList(growable: false);
      final enumError = StringEnumConstraint(allowed).validate(discValueRaw);

      // Error context for discriminator key, but inherit parent path
      return SchemaResult.fail(SchemaConstraintsError(
        constraints: enumError != null ? [enumError] : [],
        context: context.createChild(
          name: discriminatorKey,
          schema: const StringSchema(),
          value: discValueRaw,
          pathSegment: discriminatorKey, // Point directly to the failing field
        ),
      ));
    }

    // Validate the selected branch, but keep path at object level
    // Branch name is for debug only; errors point to the object, not a sub-path
    final subSchemaContext = context.createChild(
      name: 'when $discriminatorKey="$discValueRaw"',
      schema: selectedSubSchema,
      value: inputValue,
      pathSegment: '', // Inherit parent path
    );

    final result = selectedSubSchema.parseAndValidate(
      inputValue,
      subSchemaContext,
    );

    if (result.isFail) {
      return result.match(
        onOk: (_) => throw StateError('Unreachable'),
        onFail: (error) => SchemaResult.fail(error),
      );
    }

    final validatedValue = result.getOrThrow() as MapValue;

    // Use centralized constraints and refinements check
    return applyConstraintsAndRefinements(validatedValue, context);
  }

  @override
  DiscriminatedObjectSchema copyWith({
    String? discriminatorKey,
    Map<String, AckSchema>? schemas,
    bool? isNullable,
    String? description,
    MapValue? defaultValue,
    List<Constraint<MapValue>>? constraints,
    List<Refinement<MapValue>>? refinements,
  }) {
    return copyWithInternal(
      discriminatorKey: discriminatorKey,
      schemas: schemas,
      isNullable: isNullable,
      description: description,
      defaultValue: defaultValue,
      constraints: constraints,
      refinements: refinements,
    );
  }

  @override
  DiscriminatedObjectSchema copyWithInternal({
    required bool? isNullable,
    required String? description,
    required MapValue? defaultValue,
    required List<Constraint<MapValue>>? constraints,
    required List<Refinement<MapValue>>? refinements,
    // DiscriminatedObjectSchema specific
    String? discriminatorKey,
    Map<String, AckSchema>? schemas,
  }) {
    if (defaultValue != null) {
      throw StateError('Default not supported for DiscriminatedObjectSchema');
    }
    return DiscriminatedObjectSchema(
      discriminatorKey: discriminatorKey ?? this.discriminatorKey,
      schemas: schemas ?? this.schemas,
      isNullable: isNullable ?? this.isNullable,
      description: description ?? this.description,
      // ignore defaultValue by design
      constraints: constraints ?? this.constraints,
      refinements: refinements ?? this.refinements,
    );
  }

  @override
  Map<String, Object?> toJsonSchema() {
    final oneOfClauses = <Map<String, Object?>>[];
    schemas.forEach((discriminatorValue, objectSchema) {
      final subSchemaJson = objectSchema.toJsonSchema();
      // Ensure the discriminator property is correctly constrained in the sub-schema JSON
      subSchemaJson['properties'] = {
        ...?(subSchemaJson['properties'] as Map?),
        discriminatorKey: {'const': discriminatorValue},
      };
      subSchemaJson['required'] = {
        ...?(subSchemaJson['required'] as List?)?.cast<String>(),
        discriminatorKey,
      }.toList();
      oneOfClauses.add(subSchemaJson);
    });

    // Add null as an option if nullable
    if (isNullable) {
      oneOfClauses.insert(0, {'type': 'null'});
    }

    final schema = {
      'oneOf': oneOfClauses,
      if (description != null) 'description': description,
    };

    return mergeConstraintSchemas(schema);
  }
}
