part of 'schema.dart';

/// Schema for validating a discriminated union of objects.
///
/// Based on a `discriminatorKey` (e.g., 'type'), it uses one of the provided
/// `subSchemas` to validate the object.
@immutable
final class DiscriminatedObjectSchema extends AckSchema<MapValue> {
  final String discriminatorKey;
  final Map<String, ObjectSchema> subSchemas;

  DiscriminatedObjectSchema({
    required this.discriminatorKey,
    required this.subSchemas,
    String? description,
    MapValue? defaultValue,
    List<Validator<MapValue>> constraints = const [],
  }) : super(
          schemaType: SchemaType.discriminatedObject,
          description: description,
          defaultValue: defaultValue,
          constraints: constraints,
        ) {
    // Constructor validation
    subSchemas.forEach((discriminatorValue, schema) {
      if (!schema.properties.containsKey(discriminatorKey)) {
        throw ArgumentError(
          'Sub-schema for discriminator value "$discriminatorValue" must define the discriminator property "$discriminatorKey".',
        );
      }
      final discriminatorPropSchema = schema.properties[discriminatorKey]!;
      if (discriminatorPropSchema is! StringSchema) {
        throw ArgumentError(
          'Discriminator property "$discriminatorKey" in sub-schema for "$discriminatorValue" must be a StringSchema.',
        );
      }
    });
  }

  /// Creates a new DiscriminatedObjectSchema with modified discriminated-object-specific properties
  DiscriminatedObjectSchema copyWithDiscriminatedObjectProperties({
    String? discriminatorKey,
    Map<String, ObjectSchema>? subSchemas,
    String? description,
    Object? defaultValue,
    List<Validator<MapValue>>? constraints,
  }) {
    return DiscriminatedObjectSchema(
      discriminatorKey: discriminatorKey ?? this.discriminatorKey,
      subSchemas: subSchemas ?? this.subSchemas,
      description: description ?? this.description,
      defaultValue: defaultValue == ackRawDefaultValue
          ? this.defaultValue
          : defaultValue as MapValue?,
      constraints: constraints ?? this.constraints,
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

    return selectedSubSchema.parseAndValidate(convertedMap, subSchemaContext);
  }

  @override
  DiscriminatedObjectSchema copyWithInternal({
    String? description,
    Object? defaultValue,
    List<Validator<MapValue>>? constraints,
  }) {
    return DiscriminatedObjectSchema(
      discriminatorKey: discriminatorKey,
      subSchemas: subSchemas,
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

    return schema;
  }
}
