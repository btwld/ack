part of 'schema.dart';

/// Schema for validating a discriminated union of objects.
///
/// Based on a `discriminatorKey` (e.g., 'type'), it uses one of the provided
/// `subSchemas` to validate the object.
@immutable
final class DiscriminatedObjectSchema extends AckSchema<MapValue> {
  final String discriminatorKey;
  final Map<String, ObjectSchema> subSchemas;

  const DiscriminatedObjectSchema({
    required this.discriminatorKey,
    required this.subSchemas,
    super.isNullable,
    super.description,
    super.defaultValue,
    super.constraints,
  }) : super(schemaType: SchemaType.discriminatedObject);

  @override
  DiscriminatedObjectSchema copyWith({
    String? discriminatorKey,
    Map<String, ObjectSchema>? subSchemas,
    bool? isNullable,
    String? description,
    Object? defaultValue,
    List<Validator<MapValue>>? constraints,
  }) {
    return copyWithInternal(
      discriminatorKey: discriminatorKey,
      subSchemas: subSchemas,
      isNullable: isNullable,
      description: description,
      defaultValue: defaultValue,
      constraints: constraints,
    );
  }

  @override
  SchemaResult<MapValue> tryConvertInput(
    Object? inputValue,
    SchemaContext context,
  ) {
    if (inputValue is Map) {
      try {
        final mapValue = Map<String, Object?>.from(inputValue);

        return SchemaResult.ok(mapValue);
      } catch (e) {
        final constraintError =
            InvalidTypeConstraint(expectedType: MapValue).validate(inputValue);

        return SchemaResult.fail(SchemaConstraintsError(
          constraints: constraintError != null ? [constraintError] : [],
          context: context,
        ));
      }
    }

    final constraintError =
        InvalidTypeConstraint(expectedType: MapValue).validate(inputValue);

    return SchemaResult.fail(SchemaConstraintsError(
      constraints: constraintError != null ? [constraintError] : [],
      context: context,
    ));
  }

  @override
  SchemaResult<MapValue> validateConvertedValue(
    MapValue? convertedMap,
    SchemaContext context,
  ) {
    if (convertedMap == null) {
      // Should not be reached
      final constraintError = NonNullableConstraint().validate(null);

      return SchemaResult.fail(
        SchemaConstraintsError(
          constraints: constraintError != null ? [constraintError] : [],
          context: context,
        ),
      );
    }

    final Object? discValueRaw = convertedMap[discriminatorKey];

    if (discValueRaw == null) {
      final constraintError = ObjectRequiredPropertiesConstraint(
        missingPropertyKey: discriminatorKey,
      ).validate(convertedMap);

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

    final String discValue = discValueRaw;
    final ObjectSchema? selectedSubSchema = subSchemas[discValue];

    if (selectedSubSchema == null) {
      // Using a generic PatternConstraint as a placeholder for a more specific
      // 'enum' or 'oneOf' style constraint for the discriminator value.
      final constraintError = PatternConstraint<String>(
        (v) => subSchemas.containsKey(v),
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
      value: convertedMap,
    );

    return selectedSubSchema.validate(
      convertedMap,
      debugName: subSchemaContext.name,
    );
  }

  @override
  DiscriminatedObjectSchema copyWithInternal({
    required bool? isNullable,
    required String? description,
    required Object? defaultValue,
    required List<Validator<MapValue>>? constraints,
    // DiscriminatedObjectSchema specific
    String? discriminatorKey,
    Map<String, ObjectSchema>? subSchemas,
  }) {
    return DiscriminatedObjectSchema(
      discriminatorKey: discriminatorKey ?? this.discriminatorKey,
      subSchemas: subSchemas ?? this.subSchemas,
      isNullable: isNullable ?? this.isNullable,
      description: description ?? this.description,
      defaultValue: defaultValue == ackRawDefaultValue
          ? this.defaultValue
          : defaultValue as MapValue?,
      constraints: constraints ?? this.constraints,
    );
  }

  @override
  Map<String, Object?> toJsonSchema() {
    final List<Map<String, Object?>> oneOfClauses = [];
    subSchemas.forEach((discriminatorValue, objectSchema) {
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
