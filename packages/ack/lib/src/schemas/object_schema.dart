part of 'schema.dart';

typedef MapValue = Map<String, Object?>;

/// Schema for validating maps (`Map<String, Object?>`), often used for objects.
@immutable
final class ObjectSchema extends AckSchema<MapValue> {
  final Map<String, AckSchema> properties;
  final List<String> requiredProperties;
  final bool allowAdditionalProperties;

  const ObjectSchema({
    this.properties = const {},
    this.requiredProperties = const [],
    this.allowAdditionalProperties = false,
    super.isNullable,
    super.description,
    super.defaultValue,
    super.constraints,
  }) : super(schemaType: SchemaType.object);

  @override
  ObjectSchema copyWith({
    Map<String, AckSchema>? properties,
    List<String>? requiredProperties,
    bool? allowAdditionalProperties,
    bool? isNullable,
    String? description,
    Object? defaultValue,
    List<Validator<MapValue>>? constraints,
  }) {
    return copyWithInternal(
      properties: properties,
      requiredProperties: requiredProperties,
      allowAdditionalProperties: allowAdditionalProperties,
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
    MapValue convertedValue,
    SchemaContext context,
  ) {
    final validatedMap = <String, Object?>{};
    final validationErrors = <SchemaError>[];

    // 1. Check for missing required properties
    for (final key in requiredProperties) {
      if (!convertedValue.containsKey(key)) {
        // Property is completely missing
        final constraintError =
            ObjectRequiredPropertiesConstraint(missingPropertyKey: key)
                .validate(convertedValue);
        if (constraintError != null) {
          validationErrors.add(
            SchemaConstraintsError(
              constraints: [constraintError],
              context: context,
            ),
          );
        }
      } else if (convertedValue[key] == null) {
        // Property exists but is null - check if the property's schema allows null
        final propertySchema = properties[key];
        if (propertySchema != null && !propertySchema.isNullable) {
          final constraintError =
              ObjectRequiredPropertiesConstraint(missingPropertyKey: key)
                  .validate(convertedValue);
          if (constraintError != null) {
            validationErrors.add(
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
    for (final key in convertedValue.keys) {
      final propertySchema = properties[key];
      final propertyValue = convertedValue[key];

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
          onFail: validationErrors.add,
        );
      } else if (allowAdditionalProperties) {
        validatedMap[key] = propertyValue; // Keep the original value
      } else {
        // Property not in schema and not allowed
        validationErrors.add(
          SchemaConstraintsError(
            constraints: [
              ConstraintError(
                constraint: ObjectNoAdditionalPropertiesConstraint(
                  unexpectedPropertyKey: key,
                ),
                message: 'Property "$key" is not allowed.',
              ),
            ],
            context: context,
          ),
        );
      }
    }

    if (validationErrors.isNotEmpty) {
      return SchemaResult.fail(SchemaNestedError(
        errors: validationErrors,
        context: context,
      ));
    }

    return SchemaResult.ok(validatedMap);
  }

  @override
  ObjectSchema copyWithInternal({
    required bool? isNullable,
    required String? description,
    required Object? defaultValue,
    required List<Validator<MapValue>>? constraints,
    // ObjectSchema specific
    Map<String, AckSchema>? properties,
    List<String>? requiredProperties,
    bool? allowAdditionalProperties,
  }) {
    return ObjectSchema(
      properties: properties ?? this.properties,
      requiredProperties: requiredProperties ?? this.requiredProperties,
      allowAdditionalProperties:
          allowAdditionalProperties ?? this.allowAdditionalProperties,
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
    final Map<String, Object?> propsJsonSchema = {};
    for (final entry in properties.entries) {
      propsJsonSchema[entry.key] = entry.value.toJsonSchema();
    }

    return {
      'type': isNullable ? ['object', 'null'] : 'object',
      'properties': propsJsonSchema,
      if (requiredProperties.isNotEmpty) 'required': requiredProperties,
      'additionalProperties': allowAdditionalProperties,
      if (description != null) 'description': description,
    };
  }
}
