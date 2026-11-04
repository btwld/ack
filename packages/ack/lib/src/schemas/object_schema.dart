part of 'schema.dart';

/// Schema for validating `JsonMap` shaped values.
///
/// `ObjectSchema` has identical boundary and runtime types
/// (`AckSchema<JsonMap, JsonMap>`). Use [AckSchemaExtensions.codec] to map an
/// object shape to a typed Dart model.
///
/// ## Optional / nullable semantics
///
/// The parse and encode paths treat present-null differently from absence:
///
/// * **Parse**: `optional` means the key may be absent. If the key IS
///   present with a null value, the property schema must also be
///   `nullable` or the parse fails with a non-nullable constraint error.
///   This includes a `withDefault` property: its default fills a missing
///   key, and fills a present `null` only when the property is `nullable`.
/// * **Encode**: a key present with `null` whose schema is `optional`
///   (but not `nullable`) is omitted from the encoded output rather than
///   emitted as `null`. This is so a model encoder can simply write
///   `'color': value.color` and let optional nulls disappear.
///
/// A default-wrapped property encodes a missing or null value as its validated
/// default. To emit an explicit `null`, use a nullable property without a default.
@immutable
final class ObjectSchema extends AckSchema<JsonMap, JsonMap>
    with FluentSchema<JsonMap, JsonMap, ObjectSchema> {
  final Map<String, AnyAckSchema> properties;
  final bool additionalProperties;

  ObjectSchema(
    Map<String, AnyAckSchema>? properties, {
    this.additionalProperties = false,
    super.isNullable,
    super.isOptional,
    super.description,
    super.constraints,
    super.refinements,
  }) : properties = Map.unmodifiable(properties ?? const {});

  @override
  @protected
  SchemaResult<JsonMap> parseWithContext(Object? value, SchemaContext context) {
    final nullResult = handleNullInput(value, context);
    if (nullResult != null) return nullResult;

    final mapValue = jsonMapOrNull(value);
    if (mapValue == null) {
      return SchemaResult.fail(
        _buildTypeMismatch(
          expectedType: schemaType,
          actualValue: value,
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
        if (_propertyNullPolicy(schema, missing: true).useDefault) {
          final childCtx = context.createChild(
            name: key,
            schema: schema,
            value: null,
            pathSegment: key,
          );
          (schema as DefaultSchema)
              .resolveDefaultWithContext(childCtx)
              .match(
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
      // A default fills a missing key. A present `null` is a value, so a
      // default-wrapped property applies its default to it only when the
      // property also accepts `null`.
      if (propertyValue == null &&
          schema is DefaultSchema &&
          !_propertyNullPolicy(schema).allowNull) {
        errors.add(schema.failNonNullable(propertyCtx).getError());
        continue;
      }
      schema
          .parseWithContext(propertyValue, propertyCtx)
          .match(
            onOk: (v) {
              validatedMap[key] = v;
            },
            onFail: errors.add,
          );
    }

    _checkAdditionalProperties(mapValue, context, errors, parsed: validatedMap);

    if (errors.isNotEmpty) {
      return SchemaResult.fail(
        SchemaNestedError(errors: errors, context: context),
      );
    }

    return applyConstraintsAndRefinements(
      UnmodifiableMapView(validatedMap),
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

    final mapValue = jsonMapOrNull(value);
    if (mapValue == null) {
      return SchemaResult.fail(
        _buildTypeMismatch(
          expectedType: schemaType,
          actualValue: value,
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
        if (schema.isOptional ||
            (isEncode &&
                _propertyNullPolicy(
                  schema,
                  missing: true,
                  encode: true,
                ).useDefault)) {
          continue;
        }
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
              SchemaConstraintsError(constraints: [ce], context: propertyCtx),
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
        if (_propertyNullPolicy(schema, encode: isEncode).allowNull) {
          continue;
        }
        if (isEncode) {
          errors.add(SchemaEncodeError.nonNullable(context: propertyCtx));
        } else {
          final ce = NonNullableConstraint().validate(null);
          if (ce != null) {
            errors.add(
              SchemaConstraintsError(constraints: [ce], context: propertyCtx),
            );
          }
        }
        continue;
      }

      final r = schema.validateRuntimeWithContext(propertyValue, propertyCtx);
      if (r.isFail) errors.add(r.getError());
    }

    _checkAdditionalProperties(mapValue, context, errors, isEncode: isEncode);

    if (errors.isNotEmpty) {
      return SchemaResult.fail(
        SchemaNestedError(errors: errors, context: context),
      );
    }

    return applyConstraintsAndRefinements(mapValue, context);
  }

  void _checkAdditionalProperties(
    JsonMap value,
    SchemaContext context,
    List<SchemaError> errors, {
    JsonMap? parsed,
    bool isEncode = false,
  }) {
    for (final key in value.keys) {
      if (properties.containsKey(key)) continue;
      if (additionalProperties) {
        if (parsed != null) parsed[key] = value[key];
        continue;
      }
      final extraCtx = context.createChild(
        name: key,
        schema: this,
        value: value[key],
        pathSegment: key,
      );
      errors.add(
        isEncode
            ? SchemaEncodeError.unexpectedProperty(
                propertyKey: key,
                context: extraCtx,
              )
            : SchemaConstraintsError(
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

  @override
  @protected
  SchemaResult<JsonMap> encodeWithContext(
    JsonMap value,
    SchemaContext context,
  ) {
    final encoded = <String, Object?>{};
    final errors = <SchemaError>[];

    for (final entry in properties.entries) {
      final key = entry.key;
      final schema = entry.value;
      final hasValue = value.containsKey(key);
      final propertyCtx = context.createChild(
        name: key,
        schema: schema,
        value: hasValue ? value[key] : null,
        pathSegment: key,
        operation: SchemaOperation.encode,
      );
      final Object? propertyValue;
      if (schema is DefaultSchema &&
          value[key] == null &&
          _propertyNullPolicy(
            schema,
            missing: !hasValue,
            encode: true,
          ).useDefault) {
        final defaultResult = schema.resolveDefaultWithContext(propertyCtx);
        if (defaultResult.isFail) {
          errors.add(defaultResult.getError());
          continue;
        }
        propertyValue = defaultResult.getOrNull();
      } else if (hasValue) {
        propertyValue = value[key];
      } else {
        if (!schema.isOptional) {
          errors.add(
            SchemaEncodeError.missingRequiredProperty(
              propertyKey: key,
              context: propertyCtx,
            ),
          );
        }
        continue;
      }
      if (propertyValue == null) {
        if (schema.acceptsNull) {
          encoded[key] = null;
        } else if (!schema.isOptional) {
          errors.add(SchemaEncodeError.nonNullable(context: propertyCtx));
        }
        continue;
      }
      // Objects validate their children and refinements as they encode. Do not
      // prevalidate subtrees or reuse checks across sibling encoder callbacks.
      var valueSchema = schema;
      while (valueSchema is DefaultSchema) {
        valueSchema = valueSchema.inner;
      }
      final SchemaResult<Object> r;
      if (valueSchema is ObjectSchema) {
        final mapValue = jsonMapOrNull(propertyValue);
        if (mapValue == null) {
          errors.add(
            _buildTypeMismatch(
              expectedType: valueSchema.schemaType,
              actualValue: propertyValue,
              context: propertyCtx,
            ),
          );
          continue;
        }
        r = valueSchema.encodeWithContext(mapValue, propertyCtx);
      } else {
        final validated = schema.validateRuntimeWithContext(
          propertyValue,
          propertyCtx,
        );
        if (validated.isFail) {
          errors.add(validated.getError());
          continue;
        }
        try {
          r = schema.encodeWithContext(propertyValue, propertyCtx);
        } catch (e, st) {
          _rethrowIfError(e, st);
          errors.add(
            SchemaEncodeError.encoderThrew(
              message: 'Property "$key" encoder threw: $e',
              context: propertyCtx,
              cause: e,
              stackTrace: st,
            ),
          );
          continue;
        }
      }
      if (r.isFail) {
        errors.add(r.getError());
      } else {
        encoded[key] = r.getOrNull();
      }
    }

    _checkAdditionalProperties(value, context, errors, isEncode: true);

    if (additionalProperties) {
      for (final key in value.keys) {
        if (!properties.containsKey(key)) {
          encoded[key] = value[key];
        }
      }
    }

    if (errors.isNotEmpty) {
      return SchemaResult.fail(
        SchemaNestedError(errors: errors, context: context),
      );
    }

    final validated = applyConstraintsAndRefinements(value, context);
    if (validated.isFail) return SchemaResult.fail(validated.getError());
    return SchemaResult.ok(UnmodifiableMapView(encoded));
  }

  @override
  ObjectSchema copyWith({
    Map<String, AnyAckSchema>? properties,
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
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ObjectSchema) return false;
    const mapEq = MapEquality<String, AnyAckSchema>();

    return baseFieldsEqual(other) &&
        additionalProperties == other.additionalProperties &&
        mapEq.equals(properties, other.properties);
  }

  @override
  SchemaType get schemaType => SchemaType.object;

  @override
  int get hashCode {
    const mapEq = MapEquality<String, AnyAckSchema>();

    return Object.hash(
      baseFieldsHashCode,
      additionalProperties,
      mapEq.hash(properties),
    );
  }
}

// Called only for a missing key or null value. Parse and encode intentionally
// differ: only encode omits optional non-nullable nulls and defaults all nulls.
({bool useDefault, bool allowNull}) _propertyNullPolicy(
  AnyAckSchema schema, {
  bool missing = false,
  bool encode = false,
}) {
  final useDefault =
      schema is DefaultSchema && (missing || encode || schema.acceptsNull);
  return (
    useDefault: useDefault,
    allowNull:
        useDefault || schema.acceptsNull || (encode && schema.isOptional),
  );
}
