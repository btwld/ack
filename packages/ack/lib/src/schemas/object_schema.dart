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
  SchemaResult<JsonMap> parseWithContext(
    Object? value,
    SchemaContext context,
  ) {
    final nullResult = handleNullInput(value, context);
    if (nullResult != null) return nullResult;

    final mapValue = coerceJsonMap(value);
    if (mapValue == null) {
      return SchemaResult.fail(
        TypeMismatchError(
          expectedType: schemaType,
          actualType: AckSchema.getSchemaType(value),
          context: context,
        ),
      );
    }

    final validatedMap = <String, Object?>{};
    final errors = <SchemaError>[];

    for (final entry in properties.entries) {
      final key = entry.key;
      final schema = entry.value;
      final hasValue = mapValue.containsKey(key);

      if (!hasValue) {
        if (schema is DefaultSchema) {
          // Default-wrapped schemas resolve their default on parse(null).
          final childCtx = context.createChild(
            name: key,
            schema: schema,
            value: null,
            pathSegment: key,
          );
          schema.parseWithContext(null, childCtx).match(
                onOk: (v) {
                  if (v != null) validatedMap[key] = v;
                },
                onFail: errors.add,
              );
        } else if (!schema.isOptional) {
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
        continue;
      }

      final propertyValue = mapValue[key];
      final propertyCtx = context.createChild(
        name: key,
        schema: schema,
        value: propertyValue,
        pathSegment: key,
      );
      schema.parseWithContext(propertyValue, propertyCtx).match(
            onOk: (v) {
              validatedMap[key] = v;
            },
            onFail: errors.add,
          );
    }

    final knownKeys = properties.keys.toSet();
    for (final key in mapValue.keys) {
      if (knownKeys.contains(key)) continue;
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

    if (errors.isNotEmpty) {
      return SchemaResult.fail(
        SchemaNestedError(errors: errors, context: context),
      );
    }

    return applyConstraintsAndRefinements(
      Map<String, Object?>.unmodifiable(validatedMap),
      context,
    );
  }

  @override
  @protected
  SchemaResult<JsonMap> validateRuntimeWithContext(
    Object? value,
    SchemaContext context,
  ) {
    final nullResult = handleNullInput(value, context);
    if (nullResult != null) return nullResult;

    final mapValue = coerceJsonMap(value);
    if (mapValue == null) {
      return SchemaResult.fail(
        TypeMismatchError(
          expectedType: schemaType,
          actualType: AckSchema.getSchemaType(value),
          context: context,
        ),
      );
    }

    final errors = <SchemaError>[];
    final isEncode = context.operation == SchemaOperation.encode;

    for (final entry in properties.entries) {
      final key = entry.key;
      final schema = entry.value;
      final hasValue = mapValue.containsKey(key);

      if (!hasValue) {
        if (schema.isOptional) continue;
        final propertyCtx = context.createChild(
          name: key,
          schema: schema,
          value: null,
          pathSegment: key,
        );
        if (isEncode) {
          errors.add(
            SchemaEncodeError.missingRequiredProperty(
              propertyKey: key,
              context: propertyCtx,
            ),
          );
        } else {
          final ce = ObjectRequiredPropertiesConstraint(
            missingPropertyKey: key,
          ).validate(mapValue);
          if (ce != null) {
            errors.add(
              SchemaConstraintsError(
                constraints: [ce],
                context: propertyCtx,
              ),
            );
          }
        }
        continue;
      }

      final propertyValue = mapValue[key];
      final propertyCtx = context.createChild(
        name: key,
        schema: schema,
        value: propertyValue,
        pathSegment: key,
      );

      if (propertyValue == null) {
        if (schema.isNullable || schema.isOptional) continue;
        if (isEncode) {
          errors.add(SchemaEncodeError.nonNullable(context: propertyCtx));
        } else {
          final ce = NonNullableConstraint().validate(null);
          if (ce != null) {
            errors.add(
              SchemaConstraintsError(
                constraints: [ce],
                context: propertyCtx,
              ),
            );
          }
        }
        continue;
      }

      final r = schema.validateRuntimeWithContext(propertyValue, propertyCtx);
      if (r.isFail) errors.add(r.getError());
    }

    final knownKeys = properties.keys.toSet();
    for (final key in mapValue.keys) {
      if (knownKeys.contains(key)) continue;
      if (additionalProperties) continue;
      final extraCtx = context.createChild(
        name: key,
        schema: this,
        value: mapValue[key],
        pathSegment: key,
      );
      if (isEncode) {
        errors.add(
          SchemaEncodeError.unexpectedProperty(
            propertyKey: key,
            context: extraCtx,
          ),
        );
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
            context: extraCtx,
          ),
        );
      }
    }

    if (errors.isNotEmpty) {
      return SchemaResult.fail(
        SchemaNestedError(errors: errors, context: context),
      );
    }

    return applyConstraintsAndRefinements(mapValue, context);
  }

  @override
  @protected
  SchemaResult<JsonMap> encodeWithContext(
    JsonMap value,
    SchemaContext context,
  ) {
    final validated = validateRuntimeWithContext(value, context);
    if (validated.isFail) return SchemaResult.fail(validated.getError());

    final encoded = <String, Object?>{};
    final errors = <SchemaError>[];
    final knownKeys = properties.keys.toSet();

    for (final entry in properties.entries) {
      final key = entry.key;
      final schema = entry.value;
      if (!value.containsKey(key)) continue;
      final propertyValue = value[key];
      if (propertyValue == null) {
        if (schema.isNullable) encoded[key] = null;
        continue;
      }
      final propertyCtx = context.createChild(
        name: key,
        schema: schema,
        value: propertyValue,
        pathSegment: key,
        operation: SchemaOperation.encode,
      );
      try {
        final r = schema.encodeWithContext(propertyValue, propertyCtx);
        if (r.isFail) {
          errors.add(r.getError());
        } else {
          encoded[key] = r.getOrNull();
        }
      } catch (e, st) {
        errors.add(
          SchemaEncodeError.encoderThrew(
            message: 'Property "$key" encoder threw: $e',
            context: propertyCtx,
            cause: e,
            stackTrace: st,
          ),
        );
      }
    }

    if (additionalProperties) {
      for (final key in value.keys) {
        if (!knownKeys.contains(key)) {
          encoded[key] = value[key];
        }
      }
    }

    if (errors.isNotEmpty) {
      return SchemaResult.fail(
        SchemaNestedError(errors: errors, context: context),
      );
    }

    return SchemaResult.ok(Map<String, Object?>.unmodifiable(encoded));
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
