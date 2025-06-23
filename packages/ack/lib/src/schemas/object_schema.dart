part of 'schema.dart';

typedef MapValue = Map<String, Object?>;

/// Schema for validating map-like objects (`Map<String, Object?>`).
///
/// Defines expected properties, their schemas, required keys, and whether
/// additional (undefined) properties are allowed.
@immutable
final class ObjectSchema extends AckSchema<MapValue> {
  final Map<String, AckSchema<dynamic>> properties; // dynamic for item schemas
  final List<String> requiredProperties;
  final bool allowAdditionalProperties;

  const ObjectSchema({
    this.properties = const {},
    this.requiredProperties = const [],
    this.allowAdditionalProperties = false,
    super.isNullable,
    super.description,
    super.defaultValue,
    super.constraints, // e.g., minProperties, maxProperties, custom object-level validation
  }) : super(schemaType: SchemaType.object);

  ObjectSchema extendWith({
    Map<String, AckSchema<dynamic>>? additionalProps,
    List<String>? newRequired,
    bool? newAllowAdditional,
  }) {
    final mergedProperties = {...properties, ...(additionalProps ?? {})};

    final mergedRequired =
        {...requiredProperties, ...(newRequired ?? [])}.toSet().toList();
    for (final reqKey in newRequired ?? <String>[]) {
      if (!mergedProperties.containsKey(reqKey)) {
        throw ArgumentError(
          'Cannot mark "$reqKey" as required: it is not defined in the properties.',
        );
      }
    }

    return copyWith(
      properties: mergedProperties,
      requiredProperties: mergedRequired,
      allowAdditionalProperties:
          newAllowAdditional ?? allowAdditionalProperties,
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
        return SchemaResult.fail(SchemaConstraintsError(
          constraints: [
            InvalidTypeConstraint(expectedType: MapValue).validate(inputValue)!,
          ],
          context: context,
        ));
      }
    }

    return SchemaResult.fail(SchemaConstraintsError(
      constraints: [
        InvalidTypeConstraint(expectedType: MapValue).validate(inputValue)!,
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
      return SchemaResult.fail(
        SchemaConstraintsError(
          constraints: [NonNullableConstraint().validate(convertedMap)!],
          context: context,
        ),
      );
    }
    final validatedMap = <String, Object?>{};
    final validationErrors = <SchemaError>[];

    // 1. Check for missing required properties
    for (final reqKey in requiredProperties) {
      if (!convertedMap.containsKey(reqKey)) {
        validationErrors.add(SchemaConstraintsError(
          constraints: [
            ObjectRequiredPropertiesConstraint(missingPropertyKey: reqKey)
                .validate(convertedMap)!,
          ],
          context: SchemaContext(
            name: '${context.name}.$reqKey',
            schema: this,
            value: convertedMap,
          ),
        ));
      }
    }

    // 2. Validate defined properties against their schemas
    properties.forEach((propKey, propSchema) {
      final propValue = convertedMap[propKey];
      final propContext = SchemaContext(
        name: '${context.name}.$propKey',
        schema: propSchema,
        value: propValue,
      );

      final propResult = propSchema.parseAndValidate(propValue, propContext);

      if (propResult.isOk) {
        if (convertedMap.containsKey(propKey) ||
            propSchema.defaultValue != null) {
          validatedMap[propKey] = propResult.getOrNull();
        }
      } else {
        validationErrors.add(propResult.getError());
      }
    });

    // 3. Handle additional properties found in the input map
    convertedMap.forEach((keyInInput, valueInInput) {
      if (!properties.containsKey(keyInInput)) {
        if (!allowAdditionalProperties) {
          validationErrors.add(SchemaConstraintsError(
            constraints: [
              ObjectNoAdditionalPropertiesConstraint(
                unexpectedPropertyKey: keyInInput,
              ).validate(convertedMap)!,
            ],
            context: SchemaContext(
              name: '${context.name}.$keyInInput',
              schema: this,
              value: valueInInput,
            ),
          ));
        } else {
          validatedMap[keyInInput] = valueInInput;
        }
      }
    });

    if (validationErrors.isNotEmpty) {
      return SchemaResult.fail(
        SchemaNestedError(errors: validationErrors, context: context),
      );
    }

    return SchemaResult.ok(validatedMap);
  }

  
  @protected
  ObjectSchema copyWithInternal({
    required bool? isNullable,
    required String? description,
    required Object? defaultValue,
    required List<Validator<MapValue>>? constraints,
    // ObjectSchema specific
    Map<String, AckSchema<dynamic>>? properties,
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
  ObjectSchema copyWith({
    bool? isNullable,
    String? description,
    Object? defaultValue = ackRawDefaultValue,
    List<Validator<MapValue>>? constraints,
    Map<String, AckSchema<dynamic>>? properties,
    List<String>? requiredProperties,
    bool? allowAdditionalProperties,
  }) {
    return copyWithInternal(
      isNullable: isNullable,
      description: description,
      defaultValue: defaultValue,
      constraints: constraints,
      properties: properties,
      requiredProperties: requiredProperties,
      allowAdditionalProperties: allowAdditionalProperties,
    );
  }

  @override
  Map<String, Object?> toJsonSchema() {
    final Map<String, Object?> propsJsonSchema = {};
    properties.forEach((key, schema) {
      propsJsonSchema[key] = schema.toJsonSchema();
    });

    Map<String, Object?> schema = {
      'type': isNullable ? ['object', 'null'] : 'object',
      'properties': propsJsonSchema,
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

  @override
  ObjectSchema withDefault(Object? val) {
    return copyWith(defaultValue: val);
  }

  @override
  ObjectSchema addConstraint(Validator<MapValue> constraint) {
    return copyWith(constraints: [...constraints, constraint]);
  }

  @override
  ObjectSchema addConstraints(List<Validator<MapValue>> newConstraints) {
    return copyWith(constraints: [...constraints, ...newConstraints]);
  }

  @override
  ObjectSchema nullable({bool value = true}) {
    return copyWith(isNullable: value);
  }

  @override
  ObjectSchema withDescription(String? newDescription) {
    return copyWith(description: newDescription);
  }
}
