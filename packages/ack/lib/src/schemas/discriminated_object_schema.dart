part of 'schema.dart';

/// Schema for validating a discriminated union of objects.
///
/// Branches must produce the same runtime type [T]. Boundary type is
/// [JsonMap]. Encoding selects the first branch whose runtime validation
/// AND encode succeed. Branch encoders must emit the discriminator key.
@immutable
final class DiscriminatedObjectSchema<T extends Object>
    extends AckSchema<JsonMap, T>
    with FluentSchema<JsonMap, T, DiscriminatedObjectSchema<T>> {
  final String discriminatorKey;
  final Map<String, AckSchema<JsonMap, T>> schemas;

  DiscriminatedObjectSchema({
    required this.discriminatorKey,
    required Map<String, AckSchema<JsonMap, T>> schemas,
    super.isNullable,
    super.isOptional,
    super.description,
    super.constraints,
    super.refinements,
  }) : schemas = Map.unmodifiable(schemas) {
    if (discriminatorKey.isEmpty) {
      throw ArgumentError.value(
        discriminatorKey,
        'discriminatorKey',
        'must not be empty',
      );
    }
    if (schemas.isEmpty) {
      throw ArgumentError.value(schemas, 'schemas', 'must not be empty');
    }
    if (schemas.containsKey('')) {
      throw ArgumentError.value(
        schemas,
        'schemas',
        'branch keys must not be empty',
      );
    }
    for (final entry in schemas.entries) {
      final label = entry.key;
      final base = unwrapDiscriminatedBranchSchema(entry.value);
      if (base is LazySchema) {
        throw ArgumentError.value(
          entry.value,
          'schemas["$label"]',
          'Discriminated branches cannot be Ack.lazy(...) - the discriminator '
              'property cannot be analyzed through a deferred reference.',
        );
      }
      if (base is! ObjectSchema) {
        throw ArgumentError.value(
          entry.value,
          'schemas["$label"]',
          'Discriminated branches must be object-backed schemas.',
        );
      }
      // Union-owned discriminator (PR #107): if a branch declares the
      // discriminator property, it must accept the branch label. Otherwise
      // the union synthesizes the literal automatically via [effectiveBranch].
      final branchDiscriminator = base.properties[discriminatorKey];
      if (branchDiscriminator != null &&
          !discriminatorPropertyAcceptsValue(
            propertySchema: branchDiscriminator,
            discriminatorValue: label,
          )) {
        throw ArgumentError.value(
          entry.value,
          'schemas["$label"]',
          'Discriminator property "$discriminatorKey" in branch "$label" '
              'must be Ack.literal("$label") or Ack.enumString containing '
              '"$label".',
        );
      }
    }
  }

  /// Returns the effective schema for [discriminatorValue].
  ///
  /// The effective schema includes this union's discriminator property as an
  /// exact branch literal, even when the authored branch omitted it. Wrappers
  /// around the branch (codecs, defaults) are preserved.
  AckSchema<JsonMap, T> effectiveBranch(String discriminatorValue) {
    final branchSchema = schemas[discriminatorValue];
    if (branchSchema == null) {
      throw ArgumentError.value(
        discriminatorValue,
        'discriminatorValue',
        'No discriminated branch is registered for this value.',
      );
    }
    return effectiveDiscriminatedBranch(
          discriminatorKey: discriminatorKey,
          discriminatorValue: discriminatorValue,
          branchSchema: branchSchema,
        )
        as AckSchema<JsonMap, T>;
  }

  @override
  SchemaType get schemaType => SchemaType.discriminated;

  @override
  @protected
  SchemaResult<T> parseWithContext(Object? value, SchemaContext context) {
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

    final discValueRaw = mapValue[discriminatorKey];

    if (discValueRaw == null) {
      final constraintError = ObjectRequiredPropertiesConstraint(
        missingPropertyKey: discriminatorKey,
      ).validate(mapValue);

      return SchemaResult.fail(
        SchemaConstraintsError(
          constraints: constraintError != null ? [constraintError] : [],
          context: context.createChild(
            name: discriminatorKey,
            schema: const StringSchema(),
            value: null,
            pathSegment: discriminatorKey,
          ),
        ),
      );
    }

    if (discValueRaw is! String) {
      final constraintError = InvalidTypeConstraint(
        expectedType: String,
      ).validate(discValueRaw);

      return SchemaResult.fail(
        SchemaConstraintsError(
          constraints: constraintError != null ? [constraintError] : [],
          context: context.createChild(
            name: discriminatorKey,
            schema: const StringSchema(),
            value: discValueRaw,
            pathSegment: discriminatorKey,
          ),
        ),
      );
    }

    final selectedSubSchema = schemas[discValueRaw];

    if (selectedSubSchema == null) {
      final allowed = schemas.keys.toList(growable: false);
      final enumError = PatternConstraint.enumString(
        allowed,
      ).validate(discValueRaw);

      return SchemaResult.fail(
        SchemaConstraintsError(
          constraints: enumError != null ? [enumError] : [],
          context: context.createChild(
            name: discriminatorKey,
            schema: const StringSchema(),
            value: discValueRaw,
            pathSegment: discriminatorKey,
          ),
        ),
      );
    }

    // Route through `effectiveBranch` so branches authored without the
    // discriminator property (per PR #107) still validate the literal at parse
    // time. The constructor guarantees `selectedSubSchema` unwraps to an
    // `ObjectSchema`, so `effectiveBranch` is always callable here.
    final effective = effectiveBranch(discValueRaw);

    final subSchemaContext = context.createChild(
      name: 'when $discriminatorKey="$discValueRaw"',
      schema: effective,
      value: mapValue,
      pathSegment: '',
    );

    final result = effective.parseWithContext(mapValue, subSchemaContext);
    if (result.isFail) {
      return SchemaResult.fail(result.getError());
    }
    return applyConstraintsAndRefinements(result.getOrThrow()!, context);
  }

  @override
  @protected
  SchemaResult<T> validateRuntimeWithContext(
    Object? value,
    SchemaContext context,
  ) {
    final nullResult = handleNullInput(value, context);
    if (nullResult != null) return nullResult;
    if (value is! T) {
      return SchemaResult.fail(
        SchemaValidationError(
          message:
              'Discriminated runtime is ${value.runtimeType}, expected $T.',
          context: context,
        ),
      );
    }
    return applyConstraintsAndRefinements(value, context);
  }

  @override
  @protected
  SchemaResult<JsonMap> encodeWithContext(T value, SchemaContext context) {
    final validated = validateRuntimeWithContext(value, context);
    if (validated.isFail) {
      return SchemaResult.fail(validated.getError());
    }
    final runtime = validated.getOrNull();
    if (runtime == null) return SchemaResult.ok(null);

    final errors = <SchemaError>[];
    for (final discValue in schemas.keys) {
      // Use the effective branch so per-PR-#107 the literal discriminator
      // gates branch selection (validate) and the encoded boundary carries
      // the discriminator key (encode), even for branches that did not
      // declare the property themselves.
      final effective = effectiveBranch(discValue);
      final branchCtx = context.createChild(
        name: 'when $discriminatorKey="$discValue"',
        schema: effective,
        value: runtime,
        pathSegment: '',
        operation: SchemaOperation.encode,
      );
      try {
        final branchValidation = effective.validateRuntimeWithContext(
          runtime,
          branchCtx,
        );
        if (branchValidation.isFail) {
          errors.add(branchValidation.getError());
          continue;
        }
        final encoded = effective.encodeWithContext(runtime, branchCtx);
        if (encoded.isOk) {
          final boundary = encoded.getOrNull();
          if (boundary != null) {
            final emittedDiscriminator = boundary.containsKey(discriminatorKey);
            if (!emittedDiscriminator) {
              errors.add(
                SchemaEncodeError.typeMismatch(
                  message:
                      'Discriminated branch "$discValue" must emit '
                      '"$discriminatorKey".',
                  context: branchCtx,
                ),
              );
              continue;
            }
            if (boundary[discriminatorKey] != discValue) {
              errors.add(
                SchemaEncodeError.typeMismatch(
                  message:
                      'Discriminated branch "$discValue" emitted a '
                      'conflicting "$discriminatorKey" value: '
                      '${boundary[discriminatorKey]}.',
                  context: branchCtx,
                ),
              );
              continue;
            }
            return SchemaResult.ok(Map<String, Object?>.unmodifiable(boundary));
          }
        } else {
          errors.add(encoded.getError());
        }
      } catch (e, st) {
        errors.add(
          SchemaEncodeError.encoderThrew(
            message: 'Discriminated branch "$discValue" threw: $e',
            context: branchCtx,
            cause: e,
            stackTrace: st,
          ),
        );
      }
    }
    return SchemaResult.fail(
      SchemaNestedError(errors: errors, context: context),
    );
  }

  @override
  DiscriminatedObjectSchema<T> copyWith({
    bool? isNullable,
    bool? isOptional,
    String? description,
    List<Constraint<T>>? constraints,
    List<Refinement<T>>? refinements,
  }) {
    return DiscriminatedObjectSchema<T>(
      discriminatorKey: discriminatorKey,
      schemas: schemas,
      isNullable: isNullable ?? this.isNullable,
      isOptional: isOptional ?? this.isOptional,
      description: description ?? this.description,
      constraints: constraints ?? this.constraints,
      refinements: refinements ?? this.refinements,
    );
  }

  @override
  Map<String, Object?> toMap() {
    return {
      'type': schemaType.typeName,
      'isNullable': isNullable,
      'description': description,
      'constraints': constraints.map((c) => c.toMap()).toList(),
      'discriminatorKey': discriminatorKey,
      'schemas': schemas.length,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DiscriminatedObjectSchema<Object>) return false;
    const mapEq = MapEquality<String, AnyAckSchema>();
    return baseFieldsEqual(other) &&
        discriminatorKey == other.discriminatorKey &&
        mapEq.equals(schemas, other.schemas);
  }

  @override
  int get hashCode {
    const mapEq = MapEquality<String, AnyAckSchema>();
    return Object.hash(
      baseFieldsHashCode,
      discriminatorKey,
      mapEq.hash(schemas),
    );
  }
}
