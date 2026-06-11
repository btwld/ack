part of 'schema.dart';

/// Schema for validating a discriminated union of objects.
///
/// Branches must produce the same runtime type [T]. Boundary type is
/// [JsonMap]. Encoding map runtimes requires the configured discriminator and
/// selects the named branch directly. Non-map model-backed runtimes are probed
/// by runtime type; a runtime that matches more than one branch is rejected as
/// ambiguous. The union writes the discriminator key after branch encoding; if
/// a branch encoder emits it, the value must match the selected branch. Parsed
/// map-backed codec outputs are normalized with the selected discriminator so
/// they remain round-trippable and consistently immutable.
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

  SchemaResult<String> _validateDiscriminatorKey(
    JsonMap mapValue,
    SchemaContext context,
  ) {
    if (!mapValue.containsKey(discriminatorKey)) {
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

    final discValueRaw = mapValue[discriminatorKey];
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

    if (!schemas.containsKey(discValueRaw)) {
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

    return SchemaResult.ok(discValueRaw);
  }

  SchemaResult<T> _normalizeParsedMapRuntime(
    T parsed,
    String discValue,
    SchemaContext context,
  ) {
    final mapValue = jsonMapOrNull(parsed);
    if (mapValue == null) return SchemaResult.ok(parsed);

    if (mapValue.containsKey(discriminatorKey)) {
      final existing = mapValue[discriminatorKey];
      if (existing != discValue) {
        return SchemaResult.fail(
          SchemaValidationError(
            message:
                'Discriminated branch "$discValue" decoded a map runtime with '
                'conflicting "$discriminatorKey" value: $existing.',
            context: context,
          ),
        );
      }
    }

    // Always rebuild as an unmodifiable map carrying the discriminator, whether
    // or not the decoded map already included it. This keeps parsed map-backed
    // codec outputs consistently immutable (like object branches) so the
    // discriminator cannot be mutated post-parse into a different encode branch.
    final Object normalized = switch (parsed) {
      Map<String, String>() => Map<String, String>.unmodifiable({
        discriminatorKey: discValue,
        ...parsed,
      }),
      Map<String, Object>() => Map<String, Object>.unmodifiable({
        discriminatorKey: discValue,
        ...parsed,
      }),
      _ => Map<String, Object?>.unmodifiable({
        discriminatorKey: discValue,
        ...mapValue,
      }),
    };

    if (normalized is T) return SchemaResult.ok(normalized);

    return SchemaResult.fail(
      SchemaValidationError(
        message:
            'Discriminated branch "$discValue" decoded a map runtime that '
            'cannot carry "$discriminatorKey".',
        context: context,
      ),
    );
  }

  /// Encodes [runtime] through [encodeThrough], then writes the union-owned
  /// discriminator onto the boundary. Wraps a thrown encoder in
  /// [SchemaEncodeError.encoderThrew] and rejects a branch that emitted a
  /// conflicting discriminator value.
  SchemaResult<JsonMap> _encodeBranch(
    AckSchema<JsonMap, T> encodeThrough,
    T runtime,
    SchemaContext branchCtx,
    String discValue,
  ) {
    final SchemaResult<JsonMap> encoded;
    try {
      encoded = encodeThrough.encodeWithContext(runtime, branchCtx);
    } catch (e, st) {
      return SchemaResult.fail(
        SchemaEncodeError.encoderThrew(
          message: 'Discriminated branch "$discValue" threw: $e',
          context: branchCtx,
          cause: e,
          stackTrace: st,
        ),
      );
    }
    if (encoded.isFail) return encoded;
    final boundary = encoded.getOrNull();
    if (boundary == null) return encoded;
    final existing = boundary[discriminatorKey];
    if (existing != null && existing != discValue) {
      return SchemaResult.fail(
        SchemaEncodeError.typeMismatch(
          message:
              'Discriminated branch "$discValue" emitted a '
              'conflicting "$discriminatorKey" value: $existing.',
          context: branchCtx,
        ),
      );
    }

    return SchemaResult.ok({discriminatorKey: discValue, ...boundary});
  }

  /// Returns the effective schema for [discriminatorValue].
  ///
  /// The effective schema includes this union's discriminator property as an
  /// exact branch literal, even when the authored branch omitted it. Wrappers
  /// around the branch (codecs, defaults) are preserved.
  ///
  /// When [optionalDiscriminator] is true the injected literal is optional.
  /// This is used only on the encode path, where a branch encoder may legally
  /// omit the union-owned discriminator (the union supplies it afterwards) or
  /// emit it (validated against the literal). Parse, branch selection, and JSON
  /// Schema export keep the discriminator required.
  AckSchema<JsonMap, T> effectiveBranch(
    String discriminatorValue, {
    bool optionalDiscriminator = false,
  }) {
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
          optionalDiscriminator: optionalDiscriminator,
        )
        as AckSchema<JsonMap, T>;
  }

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

    final discriminatorResult = _validateDiscriminatorKey(mapValue, context);
    if (discriminatorResult.isFail) {
      return SchemaResult.fail(discriminatorResult.getError());
    }
    final discValue = discriminatorResult.getOrNull()!;

    // Route through `effectiveBranch` so branches authored without the
    // discriminator property (per PR #107) still validate the literal at parse
    // time. The shared discriminator check guarantees the branch exists, so
    // `effectiveBranch` is always callable here.
    final effective = effectiveBranch(discValue);

    final subSchemaContext = context.createChild(
      name: 'when $discriminatorKey="$discValue"',
      schema: effective,
      value: mapValue,
      pathSegment: '',
    );

    final result = effective.parseWithContext(mapValue, subSchemaContext);
    if (result.isFail) {
      return SchemaResult.fail(result.getError());
    }

    final normalized = _normalizeParsedMapRuntime(
      result.getOrThrow()!,
      discValue,
      context,
    );
    if (normalized.isFail) {
      return SchemaResult.fail(normalized.getError());
    }
    final runtime = normalized.getOrThrow()!;

    return applyConstraintsAndRefinements(runtime, context);
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

    final mapRuntime = jsonMapOrNull(runtime);
    if (mapRuntime != null) {
      // Map runtimes must name their branch explicitly. Validate the
      // discriminator first so missing / non-string / unknown values produce
      // the same focused errors as parse instead of falling back to inference.
      final discResult = _validateDiscriminatorKey(mapRuntime, context);
      if (discResult.isFail) {
        return SchemaResult.fail(discResult.getError());
      }
      final discValue = discResult.getOrNull()!;
      final effective = effectiveBranch(discValue, optionalDiscriminator: true);
      final branchCtx = context.createChild(
        name: 'when $discriminatorKey="$discValue"',
        schema: effective,
        value: runtime,
        pathSegment: '',
        operation: SchemaOperation.encode,
      );

      final encoded = _encodeBranch(effective, runtime, branchCtx, discValue);
      if (encoded.isFail) return SchemaResult.fail(encoded.getError());
      final boundary = encoded.getOrNull();
      if (boundary != null) {
        return SchemaResult.ok(Map.unmodifiable(boundary));
      }

      // Null boundary from a successful encode is not expected here; surface
      // a matching nested error to preserve the original fallback.
      return SchemaResult.fail(
        SchemaNestedError(errors: const [], context: context),
      );
    }

    // Slow path: a non-map runtime (typed/model) names no branch, so probe by
    // runtime validation. Require exactly one branch to validate and encode;
    // reject a runtime that matches more than one branch instead of silently
    // picking the first.
    final errors = <SchemaError>[];
    JsonMap? matchedBoundary;
    String? matchedDiscValue;
    for (final discValue in schemas.keys) {
      // Select the branch via the effective schema (its literal discriminator
      // gates selection per PR #107); the union itself writes the discriminator
      // onto the encoded boundary in [_encodeBranch].
      final effective = effectiveBranch(discValue, optionalDiscriminator: true);
      final branchCtx = context.createChild(
        name: 'when $discriminatorKey="$discValue"',
        schema: effective,
        value: runtime,
        pathSegment: '',
        operation: SchemaOperation.encode,
      );

      final branchValidation = effective.validateRuntimeWithContext(
        runtime,
        branchCtx,
      );
      if (branchValidation.isFail) {
        errors.add(branchValidation.getError());
        continue;
      }
      final encoded = _encodeBranch(effective, runtime, branchCtx, discValue);
      if (encoded.isFail) {
        errors.add(encoded.getError());
        continue;
      }
      final boundary = encoded.getOrNull();
      if (boundary == null) continue;

      if (matchedBoundary != null) {
        return SchemaResult.fail(
          SchemaValidationError(
            message:
                'Discriminated encode is ambiguous: the runtime matches both '
                'the "$matchedDiscValue" and "$discValue" branches. Encode a '
                'value whose runtime type selects a single branch.',
            context: context,
          ),
        );
      }
      matchedBoundary = boundary;
      matchedDiscValue = discValue;
    }

    if (matchedBoundary != null) {
      return SchemaResult.ok(Map.unmodifiable(matchedBoundary));
    }

    return SchemaResult.fail(
      SchemaNestedError(errors: errors, context: context),
    );
  }

  @override
  DiscriminatedObjectSchema<T> copyWith({
    String? discriminatorKey,
    Map<String, AckSchema<JsonMap, T>>? schemas,
    bool? isNullable,
    bool? isOptional,
    String? description,
    List<Constraint<T>>? constraints,
    List<Refinement<T>>? refinements,
  }) {
    return DiscriminatedObjectSchema(
      discriminatorKey: discriminatorKey ?? this.discriminatorKey,
      schemas: schemas ?? this.schemas,
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
  SchemaType get schemaType => SchemaType.discriminated;

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
