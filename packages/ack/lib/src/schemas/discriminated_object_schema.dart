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
        return SchemaResult.fail(SchemaConstraintsError(
          constraints: [
            InvalidTypeConstraint(expectedType: MapValue).validate(inputValue),
          ],
          context: context,
        ));
      }
    }

    return SchemaResult.fail(SchemaConstraintsError(
      constraints: [
        InvalidTypeConstraint(expectedType: MapValue).validate(inputValue),
      ],
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
      return SchemaResult.fail(
        SchemaConstraintsError(
          constraints: [NonNullableConstraint().validate(null)],
          context: context,
        ),
      );
    }

    final Object? discValueRaw = convertedMap[discriminatorKey];

    if (discValueRaw == null) {
      return SchemaResult.fail(SchemaConstraintsError(
        constraints: [
          ObjectRequiredPropertiesConstraint(
            missingPropertyKey: discriminatorKey,
          ).validate(convertedMap)!,
        ],
        context: context,
      ));
    }

    if (discValueRaw is! String) {
      return SchemaResult.fail(SchemaConstraintsError(
        constraints: [
          InvalidTypeConstraint(expectedType: String).validate(discValueRaw),
        ],
        context: context,
      ));
    }

    final String discValue = discValueRaw;
    final ObjectSchema? selectedSubSchema = subSchemas[discValue];

    if (selectedSubSchema == null) {
      // Using a generic PatternConstraint as a placeholder for a more specific
      // 'enum' or 'oneOf' style constraint for the discriminator value.
      return SchemaResult.fail(SchemaConstraintsError(
        constraints: [
          PatternConstraint<String>(
            (v) => subSchemas.containsKey(v),
            'a valid discriminator value',
          ).validate(discValue)!,
        ],
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
  DiscriminatedObjectSchema copyWith({
    String? description,
    Object? defaultValue,
    List<Validator<MapValue>>? constraints,
    String? discriminatorKey,
    Map<String, ObjectSchema>? subSchemas,
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
  Map<String, Object?> toJsonSchema() {
    final List<Map<String, Object?>> oneOfClauses = [];
    subSchemas.forEach((discriminatorValue, objectSchema) {
      final subSchemaJson = objectSchema.toJsonSchema();
      // Ensure the discriminator property is correctly constrained in the sub-schema JSON
      subSchemaJson['properties'] = {
        ...(subSchemaJson['properties'] as Map? ?? {}),
        discriminatorKey: {'const': discriminatorValue},
      };
      subSchemaJson['required'] = {
        ...((subSchemaJson['required'] as List?)?.cast<String>() ?? []),
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

  @override
  DiscriminatedObjectSchema withDefault(MapValue val) {
    return copyWith(defaultValue: val);
  }

  @override
  DiscriminatedObjectSchema addConstraint(Validator<MapValue> constraint) {
    return copyWith(constraints: [...constraints, constraint]);
  }

  @override
  DiscriminatedObjectSchema addConstraints(
    List<Validator<MapValue>> newConstraints,
  ) {
    return copyWith(constraints: [...constraints, ...newConstraints]);
  }

  @override
  DiscriminatedObjectSchema withDescription(String? newDescription) {
    return copyWith(description: newDescription);
  }
}
