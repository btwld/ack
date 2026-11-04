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

    for (final key in mapValue.keys) {
      if (properties.containsKey(key)) continue;
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

    if (context is _ObjectEncodeContext &&
        context._hasValidated(this, mapValue)) {
      return SchemaResult.ok(mapValue);
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

    for (final key in mapValue.keys) {
      if (properties.containsKey(key)) continue;
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

    final result = applyConstraintsAndRefinements(mapValue, context);
    if (result.isOk && context is _ObjectEncodeContext) {
      context._rememberValidation(this, mapValue);
    }
    return result;
  }

  @override
  @protected
  SchemaResult<JsonMap> encodeWithContext(
    JsonMap value,
    SchemaContext context,
  ) {
    if (context is! _ObjectEncodeContext) {
      context = _ObjectEncodeContext(context);
    }
    final validated = validateRuntimeWithContext(value, context);
    if (validated.isFail) return SchemaResult.fail(validated.getError());

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
        continue;
      }
      if (propertyValue == null) {
        if (schema.acceptsNull) encoded[key] = null;
        continue;
      }
      try {
        final r = schema.encodeWithContext(propertyValue, propertyCtx);
        if (r.isFail) {
          errors.add(r.getError());
        } else {
          encoded[key] = r.getOrNull();
        }
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
      }
    }

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

// Cache successful object checks within one encode, separately per property path.
final class _ObjectEncodeContext extends SchemaContext {
  _ObjectEncodeContext(SchemaContext source, [_ObjectEncodeContext? prior])
    : _children = prior?._children ?? {},
      _validated = prior?._validated ?? HashMap.identity(),
      super(
        name: source.name,
        schema: source.schema,
        value: source.value,
        parent: source.parent,
        pathSegment: source.pathSegment,
        operation: source.operation,
      );

  final Map<String, _ObjectEncodeContext> _children;
  final Map<ObjectSchema, (JsonMap, JsonMap)> _validated;

  bool _hasValidated(ObjectSchema schema, JsonMap value) {
    final previous = _validated[schema];
    if (previous == null || !identical(previous.$1, value)) return false;
    final snapshot = previous.$2;
    return value.length == snapshot.length &&
        snapshot.entries.every(
          (entry) =>
              value.containsKey(entry.key) &&
              identical(value[entry.key], entry.value),
        );
  }

  void _rememberValidation(ObjectSchema schema, JsonMap value) {
    if (parent == null) return;
    _validated[schema] = (value, Map.of(value));
  }

  @override
  SchemaContext createChild({
    required String name,
    required AnyAckSchema schema,
    required Object? value,
    String? pathSegment,
    SchemaOperation? operation,
  }) {
    final child = super.createChild(
      name: name,
      schema: schema,
      value: value,
      pathSegment: pathSegment,
      operation: operation,
    );
    if (schema is NumSchema ||
        schema is StringSchema ||
        schema is BooleanSchema) {
      return child;
    }
    if (pathSegment == '') return _ObjectEncodeContext(child, this);
    final key = pathSegment ?? name;
    return _children[key] = _ObjectEncodeContext(child, _children[key]);
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
