part of 'schema.dart';

typedef MapValue = Map<String, Object?>;

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
    super.description,
    super.defaultValue,
    super.constraints,
    super.refinements,
  })  : properties = properties ?? const {},
        super(schemaType: SchemaType.object);

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

    final validatedMap = <String, Object?>{};
    final validationErrors = <SchemaError>[];

    // 1. Check for missing required properties (all non-optional properties are required)
    for (final entry in properties.entries) {
      final key = entry.key;
      final schema = entry.value;

      // Skip optional fields if they're missing
      if (!inputValue.containsKey(key) && schema.isOptional) {
        continue;
      }

      // Non-optional fields must be present
      if (!inputValue.containsKey(key) && !schema.isOptional) {
        final constraintError =
            ObjectRequiredPropertiesConstraint(missingPropertyKey: key)
                .validate(inputValue);
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

    // 2. Validate all properties against their schemas
    for (final key in inputValue.keys) {
      final propertySchema = properties[key];
      final propertyValue = inputValue[key];

      if (propertySchema != null) {
        final propertyContext = SchemaContext(
          name: '${context.name}.$key',
          schema: propertySchema,
          value: propertyValue,
        );
        final result =
            (propertySchema).parseAndValidate(propertyValue, propertyContext);
        result.match(
          onOk: (validatedValue) {
            validatedMap[key] = validatedValue;
          },
          onFail: validationErrors.add,
        );
      } else if (additionalProperties) {
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
  ObjectSchema copyWith({
    Map<String, AckSchema>? properties,
    bool? allowAdditionalProperties,
    bool? isNullable,
    String? description,
    MapValue? defaultValue,
    List<Constraint<MapValue>>? constraints,
    List<Refinement<MapValue>>? refinements,
  }) {
    return copyWithInternal(
      properties: properties,
      allowAdditionalProperties: allowAdditionalProperties,
      isNullable: isNullable,
      description: description,
      defaultValue: defaultValue,
      constraints: constraints,
      refinements: refinements,
    );
  }

  @override
  ObjectSchema copyWithInternal({
    required bool? isNullable,
    required String? description,
    required MapValue? defaultValue,
    required List<Constraint<MapValue>>? constraints,
    required List<Refinement<MapValue>>? refinements,
    // ObjectSchema specific
    Map<String, AckSchema>? properties,
    bool? allowAdditionalProperties,
  }) {
    return ObjectSchema(
      properties ?? this.properties,
      additionalProperties: allowAdditionalProperties ?? additionalProperties,
      isNullable: isNullable ?? this.isNullable,
      description: description ?? this.description,
      defaultValue: defaultValue ?? this.defaultValue,
      constraints: constraints ?? this.constraints,
      refinements: refinements ?? this.refinements,
    );
  }

  @override
  Map<String, Object?> toJsonSchema() {
    final Map<String, Object?> propsJsonSchema = {};
    final List<String> requiredFields = [];

    for (final entry in properties.entries) {
      propsJsonSchema[entry.key] = entry.value.toJsonSchema();
      // All non-optional fields are required
      if (!entry.value.isOptional) {
        requiredFields.add(entry.key);
      }
    }

    return {
      'type': isNullable ? ['object', 'null'] : 'object',
      'properties': propsJsonSchema,
      if (requiredFields.isNotEmpty) 'required': requiredFields,
      'additionalProperties': additionalProperties,
      if (description != null) 'description': description,
    };
  }
}
