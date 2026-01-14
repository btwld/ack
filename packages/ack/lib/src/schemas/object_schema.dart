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
    // Null handling with default cloning to prevent mutation
    if (inputValue == null) {
      if (defaultValue != null) {
        final clonedDefault = cloneDefault(defaultValue!) as MapValue;
        // Recursively validate the cloned default
        return parseAndValidate(clonedDefault, context);
      }
      if (isNullable) {
        return SchemaResult.ok(null);
      }
      return failNonNullable(context);
    }

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

    // Validate all properties defined in the schema
    for (final entry in properties.entries) {
      final key = entry.key;
      final schema = entry.value;
      final hasValue = mapValue.containsKey(key);

      if (!hasValue) {
        // Property missing from input
        if (schema.isOptional) {
          // Optional field with default - validate it
          if (schema.defaultValue != null) {
            final propertyContext = context.createChild(
              name: key,
              schema: schema,
              value: schema.defaultValue,
              pathSegment: key,
            );
            final result = schema.parseAndValidate(
              schema.defaultValue,
              propertyContext,
            );
            result.match(
              onOk: (validatedValue) {
                if (validatedValue != null) {
                  validatedMap[key] = validatedValue;
                }
              },
              onFail: validationErrors.add,
            );
          }
          // Optional field without default - omit from output
        } else {
          // Required field missing
          final ce = ObjectRequiredPropertiesConstraint(
            missingPropertyKey: key,
          ).validate(mapValue);
          if (ce != null) {
            validationErrors.add(
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
      } else {
        // Property exists - validate it
        final propertyValue = mapValue[key];
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
          onFail: validationErrors.add,
        );
      }
    }

    // Handle additional properties
    final knownKeys = properties.keys.toSet();
    for (final key in mapValue.keys) {
      if (!knownKeys.contains(key)) {
        if (additionalProperties) {
          validatedMap[key] = mapValue[key];
        } else {
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

    if (validationErrors.isNotEmpty) {
      return SchemaResult.fail(
        SchemaNestedError(errors: validationErrors, context: context),
      );
    }

    return applyConstraintsAndRefinements(validatedMap, context);
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
    final additionalPropertiesValue = additionalProperties ? <String, Object?>{} : false;

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
