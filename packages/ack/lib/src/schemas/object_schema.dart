part of 'schema.dart';

/// Eagerly normalizes [value] into a `Map<String, Object?>` if every key is a
/// String. Returns `null` otherwise. Unlike `Map.cast<String, Object?>()`,
/// which is a lazy view that throws `TypeError` on iteration when keys do not
/// match, this helper walks once and cannot throw — preserving the
/// "safeParse / safeEncode never throws" guarantee for malformed input.
MapValue? _asStringKeyedMap(Object? value) {
  if (value is Map<String, Object?>) return value;
  if (value is! Map) return null;
  final out = <String, Object?>{};
  for (final entry in value.entries) {
    final key = entry.key;
    if (key is! String) return null;
    out[key] = entry.value;
  }
  return out;
}

/// True when [schema] supplies a parse-time default — i.e. its
/// [AckSchema.handleParseNull] would synthesize a value rather than fall
/// through to the dispatcher's nullable / non-nullable handling.
/// [DefaultSchema] is the sole owner of parse-time defaults.
bool _providesParseDefault(AckSchema schema) {
  return schema is DefaultSchema;
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

  /// Decodes a non-null boundary value into `MapValue`. Each property is
  /// decoded recursively through its schema's `_parse(...)` so child
  /// constraints still apply. The schema's own constraints are applied by
  /// [_parse] after this returns.
  @override
  @protected
  SchemaResult<MapValue> decodeBoundary(Object? input, SchemaContext context) {
    final mapValue = _asStringKeyedMap(input);
    if (mapValue == null) {
      return SchemaResult.fail(
        AckSchema.parseTypeMismatch(
          expectedType: schemaType,
          actualValue: input,
          context: context,
        ),
      );
    }
    final validatedMap = <String, Object?>{};
    final validationErrors = <SchemaError>[];

    // Validate all properties defined in the schema
    for (final entry in properties.entries) {
      final key = entry.key;
      final schema = entry.value;
      final hasValue = mapValue.containsKey(key);

      if (!hasValue) {
        // Property missing from input.
        if (schema.isOptional) {
          // Optional field with a parse-time default — pass `null` to trigger
          // the child's [AckSchema.handleParseNull], which synthesizes the
          // default. [_providesParseDefault] is the canonical
          // "this child supplies a default" check.
          if (_providesParseDefault(schema)) {
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

  /// Validates a runtime map shape against the declared properties.
  ///
  /// Runs child runtime validation BEFORE applying object-level
  /// constraints/refinements, so refinements that downcast (e.g.
  /// `(m['a'] as int) > 0`) observe a structurally-valid map.
  ///
  /// Operation-aware error production:
  /// - Missing required key: encode → [SchemaEncodeError.missingRequiredProperty];
  ///   parse → [ObjectRequiredPropertiesConstraint].
  /// - Unknown key with `additionalProperties: false`: encode →
  ///   [SchemaEncodeError.unexpectedProperty]; parse →
  ///   [ObjectNoAdditionalPropertiesConstraint].
  ///
  /// Returns an unmodifiable canonical `Map<String, Object?>`.
  @override
  @protected
  SchemaResult<MapValue> _validateRuntime(
    Object? value,
    SchemaContext context,
  ) {
    if (value == null) {
      if (isNullable) return SchemaResult.ok(null);
      return SchemaResult.fail(_failNullForRuntime(context));
    }
    final mapValue = _asStringKeyedMap(value);
    if (mapValue == null) {
      return SchemaResult.fail(_failTypeMismatchForRuntime(value, context));
    }
    final validated = <String, Object?>{};
    final errors = <SchemaError>[];
    final isEncode = context.operation == SchemaOperation.encode;

    for (final entry in properties.entries) {
      final key = entry.key;
      final childSchema = entry.value;
      final present = mapValue.containsKey(key);

      if (!present) {
        if (childSchema.isOptional) {
          // Defaults are parse-only; on encode we never synthesize. On the
          // parse side, decodeBoundary handles default synthesis explicitly,
          // so _validateRuntime here can omit missing optionals uniformly.
          continue;
        }
        // Missing required key.
        if (isEncode) {
          errors.add(
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
        } else {
          final ce = ObjectRequiredPropertiesConstraint(
            missingPropertyKey: key,
          ).validate(mapValue);
          if (ce != null) {
            errors.add(
              SchemaConstraintsError(
                constraints: [ce],
                context: context.createChild(
                  name: key,
                  schema: childSchema,
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
      final propertyContext = context.createChild(
        name: key,
        schema: childSchema,
        value: propertyValue,
        pathSegment: key,
      );
      final result = childSchema._validateRuntime(
        propertyValue,
        propertyContext,
      );
      result.match(
        onOk: (v) {
          validated[key] = v;
        },
        onFail: errors.add,
      );
    }

    // Handle unknown keys.
    final knownKeys = properties.keys.toSet();
    for (final key in mapValue.keys) {
      if (knownKeys.contains(key)) continue;
      if (additionalProperties) {
        validated[key] = mapValue[key];
        continue;
      }
      if (isEncode) {
        errors.add(
          SchemaEncodeError.unexpectedProperty(
            key: key,
            context: context.createChild(
              name: key,
              schema: this,
              value: mapValue[key],
              pathSegment: key,
            ),
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

    final canonical = Map<String, Object?>.unmodifiable(validated);
    return applyConstraintsAndRefinements(canonical, context);
  }

  /// Translates a canonical runtime [MapValue] into its boundary form by
  /// invoking each child schema's `encodeBoundary`. The dispatcher's
  /// [_validateRuntime] has already validated children, omitted missing
  /// optionals, and rejected missing-required / disallowed-additional keys
  /// — so this method only needs to translate runtime → boundary, never
  /// re-validate.
  @override
  @protected
  SchemaResult<Object> encodeBoundary(MapValue value, SchemaContext context) {
    final out = <String, Object?>{};
    final encodeErrors = <SchemaError>[];

    for (final entry in properties.entries) {
      final key = entry.key;
      // Optional properties omitted by _validateRuntime are absent here.
      if (!value.containsKey(key)) continue;

      final childSchema = entry.value;
      final childValue = value[key];
      final childContext = context.createChild(
        name: key,
        schema: childSchema,
        value: childValue,
        pathSegment: key,
      );

      if (childValue == null) {
        // Nullable child schema held null at runtime → null in boundary form.
        out[key] = null;
        continue;
      }

      final encoded = childSchema.encodeBoundary(childValue, childContext);
      if (encoded.isFail) {
        encodeErrors.add(encoded.getError());
        continue;
      }
      out[key] = encoded.getOrNull();
    }

    // Pass through additional keys present in the canonical map. They are
    // only present when `additionalProperties: true`; otherwise
    // _validateRuntime already rejected them.
    final knownKeys = properties.keys.toSet();
    for (final key in value.keys) {
      if (!knownKeys.contains(key)) {
        out[key] = value[key];
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
      // All non-optional fields are required
      if (!entry.value.isOptional) {
        requiredFields.add(entry.key);
      }
    }

    // `additionalProperties: true` is emitted as `{}` (the always-true schema)
    // for compatibility with JSON Schema Draft-7 consumers that prefer the
    // schema form over the boolean form.
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
