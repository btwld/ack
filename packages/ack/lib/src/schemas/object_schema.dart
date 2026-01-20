part of 'schema.dart';

/// Schema for validating maps (`Map<String, Object?>`), often used for objects.
@immutable
final class ObjectSchema extends AckSchema<MapValue>
    with FluentSchema<MapValue, ObjectSchema> {
  final Map<String, AckSchema> properties;
  final bool additionalProperties;

  const ObjectSchema(
    Map<String, AckSchema>? properties, {
    this.additionalProperties = false,
    super.isNullable,
    super.isOptional,
    super.description,
    super.defaultValue,
    super.constraints,
    super.refinements,
  }) : properties = properties ?? const {};

  @override
  SchemaType get schemaType => SchemaType.object;

  @override
  @protected
  SchemaResult<MapValue> parseAndValidate(
    Object? inputValue,
    SchemaContext context,
  ) {
    // Use centralized null handling (delegates to processClonedDefault for defaults)
    final nullResult = handleNullInput(inputValue, context);
    if (nullResult != null) return nullResult;

    // Type guard
    if (inputValue is! Map) {
      final actualType = AckSchema.getSchemaType(inputValue);
      return SchemaResult.fail(
        TypeMismatchError(
          expectedType: schemaType,
          actualType: actualType,
          context: context,
        ),
      );
    }

    // Handle both Map<String, Object?> and Map<dynamic, dynamic> from JSON
    final mapValue = inputValue is Map<String, Object?>
        ? inputValue
        : inputValue.cast<String, Object?>();
    final validatedMap = <String, Object?>{};
    final validationErrors = <SchemaError>[];

    // Validate defined properties and handle additional properties
    _validateDefinedProperties(mapValue, context, validatedMap, validationErrors);
    _handleAdditionalProperties(mapValue, context, validatedMap, validationErrors);

    if (validationErrors.isNotEmpty) {
      return SchemaResult.fail(
        SchemaNestedError(errors: validationErrors, context: context),
      );
    }

    return applyConstraintsAndRefinements(validatedMap, context);
  }

  /// Validates all properties defined in the schema.
  void _validateDefinedProperties(
    Map<String, Object?> mapValue,
    SchemaContext context,
    Map<String, Object?> validatedMap,
    List<SchemaError> errors,
  ) {
    for (final entry in properties.entries) {
      final key = entry.key;
      final schema = entry.value;

      if (mapValue.containsKey(key)) {
        _validateExistingProperty(key, schema, mapValue[key], context, validatedMap, errors);
      } else {
        _handleMissingProperty(key, schema, mapValue, context, validatedMap, errors);
      }
    }
  }

  /// Validates a property that exists in the input map.
  void _validateExistingProperty(
    String key,
    AckSchema schema,
    Object? propertyValue,
    SchemaContext context,
    Map<String, Object?> validatedMap,
    List<SchemaError> errors,
  ) {
    final propertyContext = context.createChild(
      name: key,
      schema: schema,
      value: propertyValue,
      pathSegment: key,
    );
    final result = schema.parseAndValidate(propertyValue, propertyContext);
    result.match(
      onOk: (validatedValue) {
        validatedMap[key] = validatedValue;
      },
      onFail: errors.add,
    );
  }

  /// Handles a property that is missing from the input map.
  void _handleMissingProperty(
    String key,
    AckSchema schema,
    Map<String, Object?> mapValue,
    SchemaContext context,
    Map<String, Object?> validatedMap,
    List<SchemaError> errors,
  ) {
    if (schema.isOptional) {
      // Optional field with default - pass null to let child schema's handleNullInput
      // clone the default and validate it (prevents mutation of shared defaults)
      if (schema.defaultValue != null) {
        final propertyContext = context.createChild(
          name: key,
          schema: schema,
          value: null,
          pathSegment: key,
        );
        final result = schema.parseAndValidate(null, propertyContext);
        result.match(
          onOk: (validatedValue) {
            if (validatedValue != null) {
              validatedMap[key] = validatedValue;
            }
          },
          onFail: errors.add,
        );
      }
      // Optional field without default - omit from output
    } else {
      // Required field missing
      final ce = ObjectRequiredPropertiesConstraint(
        missingPropertyKey: key,
      ).validate(mapValue);
      if (ce != null) {
        errors.add(
          SchemaConstraintsError(
            constraints: [ce],
            context: context.createChild(
              name: key,
              schema: schema,
              value: null,
              pathSegment: key,
            ),
          ),
        );
      }
    }
  }

  /// Handles properties in the input that are not defined in the schema.
  void _handleAdditionalProperties(
    Map<String, Object?> mapValue,
    SchemaContext context,
    Map<String, Object?> validatedMap,
    List<SchemaError> errors,
  ) {
    final knownKeys = properties.keys.toSet();
    for (final key in mapValue.keys) {
      if (!knownKeys.contains(key)) {
        if (additionalProperties) {
          validatedMap[key] = mapValue[key];
        } else {
          errors.add(
            SchemaConstraintsError(
              constraints: [
                ConstraintError(
                  constraint: ObjectNoAdditionalPropertiesConstraint(
                    unexpectedPropertyKey: key,
                  ),
                  message: 'Property "$key" is not allowed.',
                ),
              ],
              context: context.createChild(
                name: key,
                schema: this,
                value: mapValue[key],
                pathSegment: key,
              ),
            ),
          );
        }
      }
    }
  }

  @override
  ObjectSchema copyWith({
    Map<String, AckSchema>? properties,
    bool? additionalProperties,
    bool? isNullable,
    bool? isOptional,
    String? description,
    MapValue? defaultValue,
    List<Constraint<MapValue>>? constraints,
    List<Refinement<MapValue>>? refinements,
  }) {
    return ObjectSchema(
      properties ?? this.properties,
      additionalProperties: additionalProperties ?? this.additionalProperties,
      isNullable: isNullable ?? this.isNullable,
      isOptional: isOptional ?? this.isOptional,
      description: description ?? this.description,
      defaultValue: defaultValue ?? this.defaultValue,
      constraints: constraints ?? this.constraints,
      refinements: refinements ?? this.refinements,
    );
  }

  @override
  Map<String, Object?> toJsonSchema() {
    final propsJsonSchema = <String, Object?>{};
    final requiredFields = <String>[];

    for (final entry in properties.entries) {
      propsJsonSchema[entry.key] = entry.value.toJsonSchema();
      // All non-optional fields are required
      if (!entry.value.isOptional) {
        requiredFields.add(entry.key);
      }
    }

    // Zod uses {} (empty schema) for true, false for false
    final additionalPropertiesValue = additionalProperties
        ? <String, Object?>{}
        : false;

    return buildJsonSchemaWithNullable(
      typeSchema: {
        'type': 'object',
        'properties': propsJsonSchema,
        if (requiredFields.isNotEmpty) 'required': requiredFields,
        'additionalProperties': additionalPropertiesValue,
      },
      serializedDefault: defaultValue,
    );
  }

  @override
  Map<String, Object?> toMap() {
    return {
      'type': schemaType.typeName,
      'isNullable': isNullable,
      'description': description,
      'defaultValue': defaultValue,
      'constraints': constraints.map((c) => c.toMap()).toList(),
      'properties': properties.length,
      'additionalProperties': additionalProperties,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ObjectSchema) return false;
    const mapEq = MapEquality<String, AckSchema>();
    return baseFieldsEqual(other) &&
        additionalProperties == other.additionalProperties &&
        mapEq.equals(properties, other.properties);
  }

  @override
  int get hashCode {
    const mapEq = MapEquality<String, AckSchema>();
    return Object.hash(
      baseFieldsHashCode,
      additionalProperties,
      mapEq.hash(properties),
    );
  }
}
