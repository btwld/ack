part of 'schema.dart';

/// Schema for validating a discriminated union of objects.
///
/// Based on a `discriminatorKey` (e.g., 'type'), it uses one of the provided
/// `subSchemas` to validate the object.
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
  }) : super(schemaType: SchemaType.discriminatedObject);

  @override
  @protected
  SchemaResult<MapValue> _onConvert(
    Object? inputValue,
    SchemaContext context,
  ) {
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
        context: context,
      ));
    }

    if (discValueRaw is! String) {
      final constraintError =
          InvalidTypeConstraint(expectedType: String).validate(discValueRaw);

      return SchemaResult.fail(SchemaConstraintsError(
        constraints: constraintError != null ? [constraintError] : [],
        context: context,
      ));
    }

    final discValue = discValueRaw;
    final AckSchema? selectedSubSchema = schemas[discValue];

    if (selectedSubSchema == null) {
      // Using a generic PatternConstraint as a placeholder for a more specific
      // 'enum' or 'oneOf' style constraint for the discriminator value.
      final constraintError = PatternConstraint<String>(
        (v) => schemas.containsKey(v),
        'a valid discriminator value',
      ).validate(discValue);

      return SchemaResult.fail(SchemaConstraintsError(
        constraints: constraintError != null ? [constraintError] : [],
        context: context,
      ));
    }

    final subSchemaContext = SchemaContext(
      name: '${context.name}(when $discriminatorKey="$discValue")',
      schema: selectedSubSchema,
      value: inputValue,
    );

    final result = selectedSubSchema.validate(
      inputValue,
      debugName: subSchemaContext.name,
    );

    // Convert the result to MapValue type for compatibility
    return result.match(
      onOk: (value) => SchemaResult.ok(value as MapValue),
      onFail: (error) => SchemaResult.fail(error),
    );
  }

  @override
  DiscriminatedObjectSchema copyWith({
    String? discriminatorKey,
    Map<String, AckSchema>? subSchemas,
    bool? isNullable,
    String? description,
    MapValue? defaultValue,
    List<Constraint<MapValue>>? constraints,
    List<Refinement<MapValue>>? refinements,
  }) {
    return copyWithInternal(
      discriminatorKey: discriminatorKey,
      subSchemas: subSchemas,
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
    Map<String, AckSchema>? subSchemas,
  }) {
    return DiscriminatedObjectSchema(
      discriminatorKey: discriminatorKey ?? this.discriminatorKey,
      schemas: subSchemas ?? schemas,
      isNullable: isNullable ?? this.isNullable,
      description: description ?? this.description,
      defaultValue: defaultValue ?? this.defaultValue,
      constraints: constraints ?? this.constraints,
      refinements: refinements ?? this.refinements,
    );
  }

  @override
  Map<String, Object?> toJsonSchema() {
    final List<Map<String, Object?>> oneOfClauses = [];
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

    Map<String, Object?> schema = {
      'oneOf': oneOfClauses,
      if (description != null) 'description': description,
    };

    if (isNullable) {
      return {
        'oneOf': [
          {'type': 'null'},
          schema,
        ],
        if (description != null) 'description': description,
      };
    }

    return schema;
  }
}
