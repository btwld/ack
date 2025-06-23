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

  /// Helper method to check if a schema accepts null values
  bool _schemaAcceptsNull(AckSchema<Object?> schema) {
    // Check if it's a NullableSchema wrapper
    if (schema is NullableSchema) return true;

    // For non-NullableSchema instances, we can test if they accept null
    // by attempting validation. This is not the most efficient approach,
    // but it's correct and works with the current architecture.
    try {
      final result = schema.validate(null, debugName: 'null_check');

      return result.isOk;
    } catch (_) {
      return false;
    }
  }

  /// Creates a new ObjectSchema with modified properties, required fields, or additional properties setting
  ObjectSchema copyWithObjectProperties({
    Map<String, AckSchema<Object?>>? properties,
    List<String>? requiredProperties,
    bool? allowAdditionalProperties,
    String? description,
    Object? defaultValue,
    List<Validator<MapValue>>? constraints,
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
      // Should not be reached.
      final constraintError = NonNullableConstraint().validate(null);

      return SchemaResult.fail(
        SchemaConstraintsError(
          constraints: constraintError != null ? [constraintError] : [],
          context: context,
        ),
      );
    }

    final errors = <SchemaError>[];
    final validatedMap = <String, Object?>{};

    // 1. Check for missing required properties
    for (final key in requiredProperties) {
      if (!convertedMap.containsKey(key)) {
        // Property is completely missing
        final constraintError =
            ObjectRequiredPropertiesConstraint(missingPropertyKey: key)
                .validate(convertedMap);
        if (constraintError != null) {
          errors.add(
            SchemaConstraintsError(
              constraints: [constraintError],
              context: context,
            ),
          );
        }
      } else if (convertedMap[key] == null) {
        // Property exists but is null - check if the property's schema allows null
        final propertySchema = properties[key];
        if (propertySchema != null && !_schemaAcceptsNull(propertySchema)) {
          final constraintError =
              ObjectRequiredPropertiesConstraint(missingPropertyKey: key)
                  .validate(convertedMap);
          if (constraintError != null) {
            errors.add(
              SchemaConstraintsError(
                constraints: [constraintError],
                context: context,
              ),
            );
          }
        }
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
        final constraintError = ObjectNoAdditionalPropertiesConstraint(
          unexpectedPropertyKey: key,
        ).validate(convertedMap);
        if (constraintError != null) {
          errors.add(
            SchemaConstraintsError(
              constraints: [constraintError],
              context: context,
            ),
          );
        }
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
  ObjectSchema copyWithInternal({
    String? description,
    Object? defaultValue,
    List<Validator<MapValue>>? constraints,
  }) {
    return ObjectSchema(
      properties: properties,
      requiredProperties: requiredProperties,
      allowAdditionalProperties: allowAdditionalProperties,
      description: description ?? this.description,
      defaultValue: defaultValue == ackRawDefaultValue
          ? this.defaultValue
          : defaultValue as MapValue?,
      constraints: constraints ?? this.constraints,
    );
  }

  @override
  Map<String, Object?> toJsonSchema() {
    final Map<String, Map<String, Object?>> schemaProperties = {};
    for (final entry in properties.entries) {
      schemaProperties[entry.key] = entry.value.toJsonSchema();
    }

    final Map<String, Object?> schema = {
      'type': 'object',
      if (schemaProperties.isNotEmpty) 'properties': schemaProperties,
      if (requiredProperties.isNotEmpty) 'required': requiredProperties,
      'additionalProperties': allowAdditionalProperties,
      if (description != null) 'description': description,
      if (defaultValue != null) 'default': defaultValue,
    };

    final constraintSchemas = <Map<String, Object?>>[];
    for (final constraint in constraints) {
      if (constraint is JsonSchemaSpec) {
        constraintSchemas.add((constraint as JsonSchemaSpec).toJsonSchema());
      }
    }

    return constraintSchemas.fold(
      schema,
      (prev, current) => deepMerge(prev, current),
    );
  }
}
