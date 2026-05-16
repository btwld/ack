part of 'schema.dart';

/// Schema for validating `JsonMap` shaped values.
///
/// `ObjectSchema` has identical boundary and runtime types
/// (`AckSchema<JsonMap, JsonMap>`). Use [ObjectSchemaModelExtension.model] to
/// map an object shape to a typed Dart model.
@immutable
final class ObjectSchema extends AckSchema<JsonMap, JsonMap>
    with FluentSchema<JsonMap, JsonMap, ObjectSchema> {
  final Map<String, AckSchema> properties;
  final bool additionalProperties;

  ObjectSchema(
    Map<String, AckSchema>? properties, {
    this.additionalProperties = false,
    super.isNullable,
    super.isOptional,
    super.description,
    super.constraints,
    super.refinements,
  }) : properties = properties ?? const {};

  @override
  SchemaType get schemaType => SchemaType.object;

  @override
  @protected
  SchemaResult<JsonMap> parseAndValidate(
    Object? inputValue,
    SchemaContext context,
  ) {
    final nullResult = handleNullInput(inputValue, context);
    if (nullResult != null) return nullResult;

    if (inputValue is! Map) {
      return SchemaResult.fail(
        TypeMismatchError(
          expectedType: schemaType,
          actualType: AckSchema.getSchemaType(inputValue),
          context: context,
        ),
      );
    }

    final mapValue = inputValue is JsonMap
        ? inputValue
        : inputValue.cast<String, Object?>();
    final validatedMap = <String, Object?>{};
    final validationErrors = <SchemaError>[];

    for (final entry in properties.entries) {
      final key = entry.key;
      final schema = entry.value;
      final hasValue = mapValue.containsKey(key);

      if (!hasValue) {
        if (schema.isOptional) {
          // Optional + DefaultSchema injection: invoke schema with null so it
          // can supply its default.
          if (schema is DefaultSchema) {
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
              onFail: validationErrors.add,
            );
          }
        } else {
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

    final unmodifiableMap = Map<String, Object?>.unmodifiable(validatedMap);
    return applyConstraintsAndRefinements(unmodifiableMap, context);
  }

  @override
  @protected
  SchemaResult<JsonMap> encodeRuntime(
    JsonMap value,
    SchemaContext context,
  ) {
    final encodedMap = <String, Object?>{};
    final errors = <SchemaError>[];
    final knownKeys = properties.keys.toSet();

    for (final entry in properties.entries) {
      final key = entry.key;
      final schema = entry.value;
      final hasValue = value.containsKey(key);

      if (!hasValue) {
        if (!schema.isOptional) {
          errors.add(
            SchemaEncodeError.missingRequiredProperty(
              propertyKey: key,
              context: context.createChild(
                name: key,
                schema: schema,
                value: null,
                pathSegment: key,
                operation: SchemaOperation.encode,
              ),
            ),
          );
        }
        continue;
      }

      final propertyValue = value[key];
      final propertyContext = context.createChild(
        name: key,
        schema: schema,
        value: propertyValue,
        pathSegment: key,
        operation: SchemaOperation.encode,
      );

      if (propertyValue == null) {
        if (schema.isNullable) {
          encodedMap[key] = null;
        } else if (!schema.isOptional) {
          errors.add(
            SchemaEncodeError.nonNullable(context: propertyContext),
          );
        }
        continue;
      }

      final encoded = schema.safeEncode(propertyValue);
      if (encoded.isFail) {
        errors.add(encoded.getError());
        continue;
      }
      encodedMap[key] = encoded.getOrNull();
    }

    for (final key in value.keys) {
      if (knownKeys.contains(key)) continue;
      if (additionalProperties) {
        encodedMap[key] = value[key];
      } else {
        errors.add(
          SchemaEncodeError.unexpectedProperty(
            propertyKey: key,
            context: context.createChild(
              name: key,
              schema: this,
              value: value[key],
              pathSegment: key,
              operation: SchemaOperation.encode,
            ),
          ),
        );
      }
    }

    if (errors.isNotEmpty) {
      return SchemaResult.fail(
        SchemaNestedError(errors: errors, context: context),
      );
    }

    return SchemaResult.ok(Map<String, Object?>.unmodifiable(encodedMap));
  }

  @override
  ObjectSchema copyWith({
    Map<String, AckSchema>? properties,
    bool? additionalProperties,
    bool? isNullable,
    bool? isOptional,
    String? description,
    List<Constraint<JsonMap>>? constraints,
    List<Refinement<JsonMap>>? refinements,
  }) {
    return ObjectSchema(
      properties ?? this.properties,
      additionalProperties: additionalProperties ?? this.additionalProperties,
      isNullable: isNullable ?? this.isNullable,
      isOptional: isOptional ?? this.isOptional,
      description: description ?? this.description,
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
      if (!entry.value.isOptional) {
        requiredFields.add(entry.key);
      }
    }

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
    );
  }

  @override
  Map<String, Object?> toMap() {
    return {
      'type': schemaType.typeName,
      'isNullable': isNullable,
      'description': description,
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
