part of 'schema.dart';

MapValue? _toMapValue(Object value) {
  if (value is Map<String, Object?>) return value;
  if (value is! Map) return null;

  final converted = <String, Object?>{};
  for (final entry in value.entries) {
    final key = entry.key;
    if (key is! String) return null;
    converted[key] = entry.value;
  }
  return converted;
}

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
    super.constraints,
    super.refinements,
  }) : properties = properties ?? const {};

  @override
  SchemaType get schemaType => SchemaType.object;

  @override
  @protected
  SchemaResult<MapValue> _validateRuntime(
    Object? value,
    SchemaContext context,
  ) => _validateProperties(
    value,
    context,
    (schema, propertyValue, ctx) => schema._validateRuntime(propertyValue, ctx),
  );

  @override
  @protected
  SchemaResult<MapValue> decodeBoundary(Object? input, SchemaContext context) =>
      _validateProperties(
        input,
        context,
        (schema, propertyValue, ctx) =>
            schema.decodeBoundary(propertyValue, ctx),
      );

  SchemaResult<MapValue> _validateProperties(
    Object? value,
    SchemaContext context,
    SchemaResult<Object> Function(
      AckSchema schema,
      Object? propertyValue,
      SchemaContext ctx,
    )
    handle,
  ) {
    if (value == null) {
      if (isNullable) return SchemaResult.ok(null);
      return failNull(context);
    }

    final mapValue = _toMapValue(value);
    if (mapValue == null) {
      return failTypeMismatch(value, context);
    }

    final out = <String, Object?>{};
    final errors = <SchemaError>[];

    for (final entry in properties.entries) {
      final key = entry.key;
      final schema = entry.value;
      final hasValue = mapValue.containsKey(key);

      final propertyContext = context.createChild(
        name: key,
        schema: schema,
        value: hasValue ? mapValue[key] : null,
        pathSegment: key,
      );

      if (!hasValue) {
        if (schema.isOptional) {
          // Encode never synthesizes defaults and never validates absent
          // fields, so skip discardable validation work entirely. Letting it
          // run would also silently swallow any error it produced.
          if (context.operation == SchemaOperation.encode) continue;

          final result = handle(schema, null, propertyContext);
          if (result.isOk) {
            final validated = result.getOrNull();
            if (validated != null) out[key] = validated;
          } else if (providesParseDefault(schema)) {
            // Schema supplies a default somewhere in its wrapper stack; if the
            // default itself failed validation, surface it.
            errors.add(result.getError());
          }
          continue;
        }

        final ce = ObjectRequiredPropertiesConstraint(
          missingPropertyKey: key,
        ).validate(mapValue);
        if (ce != null) {
          errors.add(
            SchemaConstraintsError(constraints: [ce], context: propertyContext),
          );
        }
        continue;
      }

      final result = handle(schema, mapValue[key], propertyContext);
      result.match(
        onOk: (validated) {
          out[key] = validated;
        },
        onFail: errors.add,
      );
    }

    for (final key in mapValue.keys) {
      if (!properties.containsKey(key)) {
        if (additionalProperties) {
          out[key] = mapValue[key];
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

    if (errors.isNotEmpty) {
      return SchemaResult.fail(
        SchemaNestedError(errors: errors, context: context),
      );
    }

    return applyConstraintsAndRefinements(
      Map<String, Object?>.unmodifiable(out),
      context,
    );
  }

  @override
  @protected
  SchemaResult<Object> encodeBoundary(MapValue value, SchemaContext context) {
    final encodedMap = <String, Object?>{};
    final errors = <SchemaError>[];

    for (final entry in properties.entries) {
      final key = entry.key;
      final schema = entry.value;
      final hasValue = value.containsKey(key);
      final propertyContext = context.createChild(
        name: key,
        schema: schema,
        value: hasValue ? value[key] : null,
        pathSegment: key,
      );

      if (!hasValue) {
        if (schema.isOptional) continue;
        errors.add(
          SchemaEncodeError(
            message: 'Required property "$key" is missing during encode.',
            context: propertyContext,
          ),
        );
        continue;
      }

      final result = _encodeWithSchema(schema, value[key], propertyContext);
      result.match(
        onOk: (encodedValue) {
          encodedMap[key] = encodedValue;
        },
        onFail: errors.add,
      );
    }

    for (final key in value.keys) {
      if (!properties.containsKey(key)) {
        if (additionalProperties) {
          encodedMap[key] = value[key];
        } else {
          errors.add(
            SchemaEncodeError(
              message:
                  'Property "$key" is not allowed during encode '
                  '(additionalProperties is false).',
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
    List<Constraint<MapValue>>? constraints,
    List<Refinement<MapValue>>? refinements,
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
