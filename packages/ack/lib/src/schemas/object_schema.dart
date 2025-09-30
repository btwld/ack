part of 'schema.dart';

typedef MapValue = Map<String, Object?>;

/// Schema for validating maps (`Map<String, Object?>`), often used for objects.
///
/// Note: ObjectSchema does not support default values. Use property schemas with
/// defaults or optional properties instead.
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
    super.constraints,
    super.refinements,
  })  : properties = properties ?? const {},
        super(defaultValue: null);

  @override
  JsonType get acceptedType => JsonType.object;

  /// ObjectSchema uses custom validation logic for properties,
  /// so it overrides parseAndValidate directly.
  @override
  @protected
  SchemaResult<MapValue> parseAndValidate(
    Object? inputValue,
    SchemaContext context,
  ) {
    // Inline null handling - ObjectSchema does not support defaults
    if (inputValue == null) {
      if (isNullable) {
        return SchemaResult.ok(null);
      }
      return failNonNullable(context);
    }

    // Use centralized type checking
    final typeError = checkTypeMatch(inputValue, context);
    if (typeError != null) return typeError;

    // Custom object validation logic
    // Handle both Map<String, Object?> and Map<dynamic, dynamic> from JSON
    final mapValue = inputValue is Map<String, Object?>
        ? inputValue
        : (inputValue as Map).cast<String, Object?>();
    final validatedMap = <String, Object?>{};
    final validationErrors = <SchemaError>[];

    // Optimized single-loop approach: handle both required property validation and input validation
    // First, validate all properties defined in the schema
    for (final entry in properties.entries) {
      final key = entry.key;
      final schema = entry.value;
      final hasValue = mapValue.containsKey(key);

      if (!hasValue) {
        // Property is missing from input
        if (schema is OptionalSchema) {
          // Optional field - check for default value
          // Policy: Use wrapped schema's defaultValue (via OptionalSchema getter proxy)
          if (schema.defaultValue != null) {
            // Optional field with default - validate the default value
            final propertyContext = context.createChild(
              name: key,
              schema: schema,
              value: schema.defaultValue,
              pathSegment: key,
            );
            final result =
                schema.parseAndValidate(schema.defaultValue, propertyContext);
            result.match(
              onOk: (validatedValue) {
                if (validatedValue != null) {
                  validatedMap[key] = validatedValue;
                }
              },
              onFail: validationErrors.add,
            );
          }
          // Else: optional field without default - omit from output map (do nothing)
        } else {
          // Required field missing - error
          final ce = ObjectRequiredPropertiesConstraint(missingPropertyKey: key)
              .validate(mapValue);
          if (ce != null) {
            validationErrors.add(SchemaConstraintsError(
              constraints: [ce],
              context: context.createChild(
                name: key,
                schema: schema,
                value: null,
                pathSegment: key,
              ),
            ));
          }
        }
      } else {
        // Property exists in input, validate the actual value
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

    // Handle additional properties (those not in schema)
    final knownKeys = properties.keys.toSet();
    for (final key in mapValue.keys) {
      if (!knownKeys.contains(key)) {
        // Property not defined in schema
        if (additionalProperties) {
          validatedMap[key] = mapValue[key]; // Keep the original value
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
      return SchemaResult.fail(SchemaNestedError(
        errors: validationErrors,
        context: context,
      ));
    }

    // Use centralized constraints and refinements check
    return applyConstraintsAndRefinements(validatedMap, context);
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
    // defaultValue is ignored - ObjectSchema does not support defaults
    return ObjectSchema(
      properties ?? this.properties,
      additionalProperties: allowAdditionalProperties ?? additionalProperties,
      isNullable: isNullable ?? this.isNullable,
      description: description ?? this.description,
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
      if (entry.value is! OptionalSchema) {
        requiredFields.add(entry.key);
      }
    }

    final schema = {
      'type': isNullable ? ['object', 'null'] : 'object',
      'properties': propsJsonSchema,
      if (requiredFields.isNotEmpty) 'required': requiredFields,
      'additionalProperties': additionalProperties,
      if (description != null) 'description': description,
    };

    return mergeConstraintSchemas(schema);
  }

  @override
  Map<String, Object?> toMap() {
    return {
      'type': acceptedType.typeName,
      'isNullable': isNullable,
      'description': description,
      // defaultValue omitted - ObjectSchema does not support defaults
      'constraints': constraints.map((c) => c.toMap()).toList(),
      'properties': properties.length,
      'additionalProperties': additionalProperties,
    };
  }
}
