part of 'schema.dart';

/// Schema for validating a discriminated union of objects.
///
/// Branches must produce the same runtime type [T]; the boundary type is
/// [JsonMap]. Each branch is treated as if it were extended with the configured
/// discriminator as an exact `Ack.literal` (see [effectiveBranch]), so authoring
/// a branch without the discriminator is purely a convenience.
///
/// At runtime the union is a thin router: the value must carry the discriminator
/// key for both parse input and encode input. The union reads the discriminator,
/// selects the named branch, and validates/encodes the value against that single
/// branch. It never injects, synthesizes, or probes the discriminator. A
/// non-[JsonMap] runtime, or a map missing the discriminator, fails with a
/// focused error.
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

  /// Returns the effective schema for [discriminatorValue].
  ///
  /// The effective schema includes this union's discriminator property as an
  /// exact, required branch literal, even when the authored branch omitted it.
  /// Wrappers around the branch (codecs, defaults) are preserved. A value
  /// flowing through the branch must carry the discriminator.
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

    // The runtime value must carry the discriminator. A non-map runtime cannot,
    // so it fails directly instead of being branch-probed.
    final mapRuntime = jsonMapOrNull(runtime);
    if (mapRuntime == null) {
      return SchemaResult.fail(
        SchemaValidationError(
          message:
              'Discriminated encode requires a Map carrying '
              '"$discriminatorKey"; got ${runtime.runtimeType}.',
          context: context,
        ),
      );
    }

    // Validate the discriminator first so missing / non-string / unknown values
    // produce the same focused errors as parse, then encode through the single
    // named branch. The branch's required literal rejects a mismatched value.
    final discResult = _validateDiscriminatorKey(mapRuntime, context);
    if (discResult.isFail) {
      return SchemaResult.fail(discResult.getError());
    }
    final discValue = discResult.getOrNull()!;
    final effective = effectiveBranch(discValue);
    final branchCtx = context.createChild(
      name: 'when $discriminatorKey="$discValue"',
      schema: effective,
      value: runtime,
      pathSegment: '',
      operation: SchemaOperation.encode,
    );

    final encoded = effective.encodeWithContext(runtime, branchCtx);
    if (encoded.isFail) return SchemaResult.fail(encoded.getError());
    final boundary = encoded.getOrNull();
    if (boundary == null) {
      return SchemaResult.fail(
        SchemaNestedError(errors: const [], context: context),
      );
    }

    return SchemaResult.ok(Map.unmodifiable(boundary));
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
