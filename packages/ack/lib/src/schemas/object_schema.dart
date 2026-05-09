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

  /// Decodes a non-null boundary value into `MapValue`. Each property is
  /// decoded recursively through its schema's `_parse(...)` so child
  /// constraints still apply. The schema's own constraints are applied by
  /// [_parse] after this returns.
  @override
  @protected
  SchemaResult<MapValue> decodeBoundary(
    Object? input,
    SchemaContext context,
  ) {
    if (input is! Map) {
      final actualType = AckSchema.getSchemaType(input);
      return SchemaResult.fail(
        TypeMismatchError(
          expectedType: schemaType,
          actualType: actualType,
          context: context,
        ),
      );
    }

    // Handle both Map<String, Object?> and Map<dynamic, dynamic> from JSON
    final mapValue = input is Map<String, Object?>
        ? input
        : input.cast<String, Object?>();
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
          // Optional field with default - pass null to trigger the child schema's
          // null/default handling.
          if (schema.defaultValue != null) {
            final propertyContext = context.createChild(
              name: key,
              schema: schema,
              value: null,
              pathSegment: key,
            );
            final result = schema._parse(null, propertyContext);
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
        final result = schema._parse(propertyValue, propertyContext);
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

    return SchemaResult.ok(Map<String, Object?>.unmodifiable(validatedMap));
  }

  /// Recursively encodes the runtime [MapValue] back to its boundary form by
  /// invoking each child schema's encode pipeline (`_validateRuntime` followed
  /// by `encodeBoundary`).
  ///
  /// Per requirements §5.5 / §7.2.5, defaults are NOT synthesized on encode:
  /// missing optional properties are simply omitted from the output.
  ///
  /// Per the maintainer A6 decision, when [additionalProperties] is `true`
  /// unknown keys are copied as-is (no child schema exists to recurse into);
  /// when `false`, unknown keys produce
  /// [SchemaEncodeError.unexpectedProperty].
  @override
  @protected
  SchemaResult<Object> encodeBoundary(
    MapValue value,
    SchemaContext context,
  ) {
    final out = <String, Object?>{};
    final encodeErrors = <SchemaError>[];

    // Encode each declared property.
    for (final entry in properties.entries) {
      final key = entry.key;
      final childSchema = entry.value;
      final hasValue = value.containsKey(key);

      if (!hasValue) {
        if (childSchema.isOptional) {
          // Missing optional → omit. Defaults are parse-only (§5.5).
          continue;
        }
        encodeErrors.add(
          SchemaEncodeError.missingRequiredProperty(
            key: key,
            context: context.createChild(
              name: key,
              schema: childSchema,
              value: null,
              pathSegment: key,
            ),
          ),
        );
        continue;
      }

      final childValue = value[key];
      final childContext = context.createChild(
        name: key,
        schema: childSchema,
        value: childValue,
        pathSegment: key,
      );

      // Validate the runtime value through the child schema (operation-aware:
      // childContext inherits operation: encode from the parent).
      final validated =
          childSchema._validateRuntime(childValue, childContext);
      if (validated.isFail) {
        encodeErrors.add(validated.getError());
        continue;
      }
      final v = validated.getOrNull();
      if (v == null) {
        // Nullable child schema with null runtime value: emit null in boundary
        // form. This matches the parse path's nullable handling.
        out[key] = null;
        continue;
      }

      // Recurse: encode runtime → boundary through this child's encoder.
      final encoded = childSchema.encodeBoundary(v, childContext);
      if (encoded.isFail) {
        encodeErrors.add(encoded.getError());
        continue;
      }
      out[key] = encoded.getOrNull();
    }

    // Handle keys present on the input but not declared on this schema.
    final knownKeys = properties.keys.toSet();
    for (final key in value.keys) {
      if (knownKeys.contains(key)) continue;
      if (additionalProperties) {
        // A6 decision: pass-through unknown keys as-is when permitted.
        out[key] = value[key];
      } else {
        encodeErrors.add(
          SchemaEncodeError.unexpectedProperty(
            key: key,
            context: context.createChild(
              name: key,
              schema: this,
              value: value[key],
              pathSegment: key,
            ),
          ),
        );
      }
    }

    if (encodeErrors.isNotEmpty) {
      return SchemaResult.fail(
        SchemaNestedError(errors: encodeErrors, context: context),
      );
    }

    return SchemaResult.ok(Map<String, Object?>.unmodifiable(out));
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
