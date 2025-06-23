part of 'schema.dart';

typedef MapValue = Map<String, Object?>;

/// Schema for validating maps (`Map<String, Object?>`), often used for objects.
@immutable
final class ObjectSchema extends AckSchema<MapValue> {
  final Map<String, AckSchema<Object?>> properties;
  final List<String> requiredProperties;
  final bool allowAdditionalProperties;

  const ObjectSchema({
    this.properties = const {},
    this.requiredProperties = const [],
    this.allowAdditionalProperties = true,
    String? description,
    MapValue? defaultValue,
    List<Validator<MapValue>> constraints = const [],
  }) : super(
          schemaType: SchemaType.object,
          description: description,
          defaultValue: defaultValue,
          constraints: constraints,
        );

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
      // Should not be reached.
      return SchemaResult.fail(
        SchemaConstraintsError(
          constraints: [NonNullableConstraint().validate(null)],
          context: context,
        ),
      );
    }

    final errors = <SchemaError>[];
    final validatedMap = <String, Object?>{};

    // 1. Check for missing required properties
    for (final key in requiredProperties) {
      if (!convertedMap.containsKey(key) || convertedMap[key] == null) {
        errors.add(
          SchemaConstraintsError(
            constraints: [
              ObjectRequiredPropertiesConstraint(missingPropertyKey: key)
                  .validate(convertedMap)!,
            ],
            context: context,
          ),
        );
      }
    }

    // 2. Validate all properties against their schemas
    for (final key in convertedMap.keys) {
      final propertySchema = properties[key];
      final propertyValue = convertedMap[key];

      if (propertySchema != null) {
        final propertyContext = SchemaContext(
          name: '${context.name}.$key',
          schema: propertySchema,
          value: propertyValue,
        );
        final result =
            propertySchema.parseAndValidate(propertyValue, propertyContext);
        result.match(
          onOk: (validatedValue) {
            validatedMap[key] = validatedValue;
          },
          onFail: errors.add,
        );
      } else if (allowAdditionalProperties) {
        validatedMap[key] = propertyValue; // Keep the original value
      } else {
        // Property not in schema and not allowed
        errors.add(
          SchemaConstraintsError(
            constraints: [
              ObjectNoAdditionalPropertiesConstraint(
                unexpectedPropertyKey: key,
              ).validate(convertedMap)!,
            ],
            context: context,
          ),
        );
      }
    }

    if (errors.isNotEmpty) {
      return SchemaResult.fail(SchemaNestedError(
        errors: errors,
        context: context,
      ));
    }

    return SchemaResult.ok(validatedMap);
  }

  @override
  ObjectSchema copyWith({
    String? description,
    Object? defaultValue,
    List<Validator<MapValue>>? constraints,
    Map<String, AckSchema<Object?>>? properties,
    List<String>? requiredProperties,
    bool? allowAdditionalProperties,
  }) {
    return ObjectSchema(
      properties: properties ?? this.properties,
      requiredProperties: requiredProperties ?? this.requiredProperties,
      allowAdditionalProperties:
          allowAdditionalProperties ?? this.allowAdditionalProperties,
      description: description ?? this.description,
      defaultValue: defaultValue == ackRawDefaultValue
          ? this.defaultValue
          : defaultValue as MapValue?,
      constraints: constraints ?? this.constraints,
    );
  }

  @override
  ObjectSchema withDescription(String? d) => copyWith(description: d);

  @override
  ObjectSchema withDefault(MapValue val) => copyWith(defaultValue: val);

  @override
  ObjectSchema addConstraint(Validator<MapValue> c) =>
      copyWith(constraints: [...constraints, c]);

  @override
  ObjectSchema addConstraints(List<Validator<MapValue>> cs) =>
      copyWith(constraints: [...constraints, ...cs]);

  @override
  Map<String, Object?> toJsonSchema() {
    final Map<String, Map<String, Object?>> schemaProperties = {};
    for (var entry in properties.entries) {
      schemaProperties[entry.key] = entry.value.toJsonSchema();
    }

    Map<String, Object?> schema = {
      'type': 'object',
      if (schemaProperties.isNotEmpty) 'properties': schemaProperties,
      if (requiredProperties.isNotEmpty) 'required': requiredProperties,
      'additionalProperties': allowAdditionalProperties,
      if (description != null) 'description': description,
      if (defaultValue != null) 'default': defaultValue,
    };

    final constraintSchemas = constraints
        .whereType<JsonSchemaSpec<MapValue>>()
        .map((c) => c.toJsonSchema())
        .fold<Map<String, Object?>>(
      {},
      (prev, current) => deepMerge(prev, current),
    );

    return deepMerge(schema, constraintSchemas);
  }
}
