part of 'schema.dart';

/// Schema for validating a discriminated union of objects.
///
/// Based on a `discriminatorKey` (e.g., 'type'), it uses one of the provided
/// `schemas` to validate the object.
///
/// Child schemas may be plain [ObjectSchema] branches that return
/// `Map<String, Object?>`, or transformed schemas whose base schema is an
/// [ObjectSchema]. All branches must produce the same output type [T].
///
/// ```dart
/// final schema = Ack.discriminated<Animal>(
///   discriminatorKey: 'type',
///   schemas: {
///     'cat': Ack.object({
///       'type': Ack.literal('cat'),
///       'name': Ack.string(),
///     }).transform<Animal>((map) => Cat(map['name'] as String)),
///     'dog': Ack.object({
///       'type': Ack.literal('dog'),
///       'name': Ack.string(),
///     }).transform<Animal>((map) => Dog(map['name'] as String)),
///   },
/// );
/// ```
@immutable
final class DiscriminatedObjectSchema<T extends Object> extends AckSchema<T>
    with FluentSchema<T, DiscriminatedObjectSchema<T>> {
  final String discriminatorKey;
  final Map<String, AckSchema<T>> schemas;

  const DiscriminatedObjectSchema({
    required this.discriminatorKey,
    required this.schemas,
    super.isNullable,
    super.isOptional,
    super.description,
    super.constraints,
    super.refinements,
  });

  @override
  SchemaType get schemaType => SchemaType.discriminated;

  /// Selects a branch from `schemas` using the value at [discriminatorKey],
  /// then delegates to that branch. Constraints/refinements on this schema
  /// are applied by [_parse] after this returns.
  @override
  @protected
  SchemaResult<T> decodeBoundary(Object? input, SchemaContext context) {
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

    final Object? discValueRaw = mapValue[discriminatorKey];

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

    final AckSchema<T>? selectedSubSchema = schemas[discValueRaw];

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

    // Validate the selected branch; branch name for debug only
    final subSchemaContext = context.createChild(
      name: 'when $discriminatorKey="$discValueRaw"',
      schema: selectedSubSchema,
      value: mapValue,
      pathSegment: '', // Inherit parent path
    );

    final baseSubSchema = unwrapDiscriminatedBranchSchema(selectedSubSchema);
    if (baseSubSchema is! ObjectSchema) {
      return SchemaResult.fail(
        SchemaValidationError(
          message: 'Discriminated branches must be object-backed schemas',
          context: subSchemaContext,
        ),
      );
    }

    final result =
        selectedSubSchema._parse(mapValue, subSchemaContext);

    if (result.isFail) {
      return result.match(
        onOk: (_) => throw StateError('Unreachable'),
        onFail: (error) => SchemaResult.fail(error),
      );
    }

    final validated = result.getOrThrow();
    if (validated == null) {
      // Defensive: branches must produce a non-null value. The dispatcher
      // would short-circuit constraint application on `Ok(null)` anyway.
      if (!isNullable) return failNonNullable(context);
      return SchemaResult.ok(null);
    }
    return SchemaResult.ok(validated);
  }

  /// Validates a runtime value against the union.
  ///
  /// Two cases:
  /// * **Map runtime value** (e.g. `T extends MapValue`, plain object
  ///   branches): dispatches strictly by [discriminatorKey]. A map that
  ///   says `{type: "cat"}` MUST validate as the `cat` branch — failures
  ///   under that branch fail the whole schema; we do not fall through to
  ///   another branch (that would defeat discriminated semantics).
  /// * **Non-map domain object** (e.g. codec branches with output type
  ///   `Animal`): tries each branch's `_validateRuntime` in declaration
  ///   order, first success wins.
  ///
  /// This schema's own constraints/refinements are applied here exactly
  /// once after a branch produces a value. [encodeBoundary] does not
  /// re-apply them.
  @override
  @protected
  SchemaResult<T> _validateRuntime(Object? value, SchemaContext context) {
    if (value == null) {
      if (isNullable) return SchemaResult.ok(null);
      return SchemaResult.fail(_failNullForRuntime(context));
    }

    if (value is Map) {
      final mapValue = _asStringKeyedMap(value);
      if (mapValue == null) {
        return SchemaResult.fail(_failTypeMismatchForRuntime(value, context));
      }
      return _validateMapByDiscriminator(mapValue, context);
    }

    return _validateDomainObject(value, context);
  }

  /// Encodes a runtime value back to its boundary map.
  ///
  /// Same Case A / Case B split as [_validateRuntime]. Output must be a
  /// string-keyed map; if a branch's encode succeeds but produces a non-map
  /// the branch is treated as failed.
  @override
  @protected
  SchemaResult<Object> encodeBoundary(T value, SchemaContext context) {
    if (value is Map) {
      final mapValue = _asStringKeyedMap(value);
      if (mapValue == null) {
        return SchemaResult.fail(_failTypeMismatchForRuntime(value, context));
      }
      return _encodeMapByDiscriminator(mapValue, context);
    }
    return _encodeDomainObject(value, context);
  }

  // -- Case A helpers ---------------------------------------------------------

  SchemaContext _discriminatorChild(
    SchemaContext parent,
    Object? discValue,
  ) =>
      parent.createChild(
        name: discriminatorKey,
        schema: const StringSchema(),
        value: discValue,
        pathSegment: discriminatorKey,
      );

  SchemaContext _branchChild(
    SchemaContext parent,
    String discValue,
    AckSchema branch,
    Object? value,
  ) =>
      parent.createChild(
        name: 'when $discriminatorKey="$discValue"',
        schema: branch,
        value: value,
        pathSegment: '', // inherit parent path; branch name is debug-only
      );

  /// Resolves the discriminator-selected branch for [mapValue], or returns
  /// a discriminator-positioned failure (missing / non-string / unknown).
  ///
  /// On success the result holds the matched branch schema.
  SchemaResult<AckSchema<T>> _resolveBranch(
    MapValue mapValue,
    SchemaContext context,
  ) {
    final Object? discValueRaw = mapValue[discriminatorKey];

    if (discValueRaw == null) {
      final ce = ObjectRequiredPropertiesConstraint(
        missingPropertyKey: discriminatorKey,
      ).validate(mapValue);
      return SchemaResult.fail(
        SchemaConstraintsError(
          constraints: ce != null ? [ce] : const [],
          context: _discriminatorChild(context, null),
        ),
      );
    }

    if (discValueRaw is! String) {
      final ce = InvalidTypeConstraint(expectedType: String).validate(
        discValueRaw,
      );
      return SchemaResult.fail(
        SchemaConstraintsError(
          constraints: ce != null ? [ce] : const [],
          context: _discriminatorChild(context, discValueRaw),
        ),
      );
    }

    final selected = schemas[discValueRaw];
    if (selected == null) {
      final allowed = schemas.keys.toList(growable: false);
      final ee = PatternConstraint.enumString(allowed).validate(discValueRaw);
      return SchemaResult.fail(
        SchemaConstraintsError(
          constraints: ee != null ? [ee] : const [],
          context: _discriminatorChild(context, discValueRaw),
        ),
      );
    }

    final base = unwrapDiscriminatedBranchSchema(selected);
    if (base is! ObjectSchema) {
      return SchemaResult.fail(
        SchemaValidationError(
          message: 'Discriminated branches must be object-backed schemas',
          context: _branchChild(context, discValueRaw, selected, mapValue),
        ),
      );
    }

    return SchemaResult.ok(selected);
  }

  SchemaResult<T> _validateMapByDiscriminator(
    MapValue mapValue,
    SchemaContext context,
  ) {
    final resolved = _resolveBranch(mapValue, context);
    if (resolved.isFail) return SchemaResult.fail(resolved.getError());
    final selected = resolved.getOrThrow()!;
    final discValue = mapValue[discriminatorKey] as String;
    final branchContext =
        _branchChild(context, discValue, selected, mapValue);

    final branchResult = selected._validateRuntime(mapValue, branchContext);
    if (branchResult.isFail) return branchResult;

    final validated = branchResult.getOrThrow();
    if (validated == null) {
      // Branch returned ok(null) for a non-null map input. Honour outer
      // nullability.
      if (!isNullable) return SchemaResult.fail(_failNullForRuntime(context));
      return SchemaResult.ok(null);
    }
    return applyConstraintsAndRefinements(validated, context);
  }

  SchemaResult<Object> _encodeMapByDiscriminator(
    MapValue mapValue,
    SchemaContext context,
  ) {
    final resolved = _resolveBranch(mapValue, context);
    if (resolved.isFail) return SchemaResult.fail(resolved.getError());
    final selected = resolved.getOrThrow()!;
    final discValue = mapValue[discriminatorKey] as String;
    final branchContext =
        _branchChild(context, discValue, selected, mapValue);

    // Per discriminated semantics, a matched branch's encode failure fails
    // the whole schema — no fallthrough to other branches.
    final encoded = selected.encodeBoundary(mapValue as T, branchContext);
    if (encoded.isFail) return encoded;

    final encodedValue = encoded.getOrNull();
    final encodedMap = _asStringKeyedMap(encodedValue);
    if (encodedMap == null) {
      return SchemaResult.fail(
        SchemaValidationError(
          message:
              'Discriminated branch "$discValue" encoded to non-map value',
          context: branchContext,
        ),
      );
    }
    return SchemaResult.ok(encodedMap);
  }

  // -- Case B helpers ---------------------------------------------------------

  SchemaContext _domainBranchChild(
    SchemaContext parent,
    int index,
    String discValue,
    AckSchema branch,
    Object? value,
  ) =>
      parent.createChild(
        name: 'discriminated:$discValue',
        schema: branch,
        value: value,
        pathSegment: '', // inherit parent path
      );

  SchemaResult<T> _validateDomainObject(
    Object value,
    SchemaContext context,
  ) {
    final errors = <SchemaError>[];
    var index = 0;
    for (final entry in schemas.entries) {
      final discValue = entry.key;
      final branch = entry.value;
      final branchContext =
          _domainBranchChild(context, index++, discValue, branch, value);
      final result = branch._validateRuntime(value, branchContext);
      if (result.isOk) {
        final validated = result.getOrNull();
        if (validated == null) {
          if (!isNullable) {
            return SchemaResult.fail(_failNullForRuntime(context));
          }
          return SchemaResult.ok(null);
        }
        return applyConstraintsAndRefinements(validated, context);
      }
      errors.add(result.getError());
    }
    return SchemaResult.fail(
      SchemaNestedError(errors: errors, context: context),
    );
  }

  SchemaResult<Object> _encodeDomainObject(
    Object value,
    SchemaContext context,
  ) {
    final errors = <SchemaError>[];
    var index = 0;
    for (final entry in schemas.entries) {
      final discValue = entry.key;
      final branch = entry.value;
      final branchContext =
          _domainBranchChild(context, index++, discValue, branch, value);

      final validated = branch._validateRuntime(value, branchContext);
      if (validated.isFail) {
        errors.add(validated.getError());
        continue;
      }
      final branchValue = validated.getOrNull();
      if (branchValue == null) {
        // Nullable branch matched null. Honour outer nullability.
        if (!isNullable) {
          errors.add(_failNullForRuntime(context));
          continue;
        }
        return SchemaResult.ok(null);
      }

      final encoded = branch.encodeBoundary(branchValue, branchContext);
      if (encoded.isFail) {
        errors.add(encoded.getError());
        continue;
      }
      final encodedMap = _asStringKeyedMap(encoded.getOrNull());
      if (encodedMap == null) {
        errors.add(
          SchemaValidationError(
            message:
                'Discriminated branch "$discValue" encoded to non-map value',
            context: branchContext,
          ),
        );
        continue;
      }
      return SchemaResult.ok(encodedMap);
    }
    return SchemaResult.fail(
      SchemaNestedError(errors: errors, context: context),
    );
  }

  @override
  DiscriminatedObjectSchema<T> copyWith({
    String? discriminatorKey,
    Map<String, AckSchema<T>>? schemas,
    bool? isNullable,
    bool? isOptional,
    String? description,
    List<Constraint<T>>? constraints,
    List<Refinement<T>>? refinements,
  }) {
    return DiscriminatedObjectSchema<T>(
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
  Map<String, Object?> toJsonSchema() {
    final anyOfClauses = <Map<String, Object?>>[];
    schemas.forEach((discriminatorValue, branchSchema) {
      final baseSchema = unwrapDiscriminatedBranchSchema(branchSchema);
      if (baseSchema is! ObjectSchema) {
        throw ArgumentError(
          'Discriminated branches must be object-backed schemas.',
        );
      }
      final subSchemaJson = branchSchema.toJsonSchema();
      // Constrain discriminator property with type and const
      subSchemaJson['properties'] = {
        ...?(subSchemaJson['properties'] as Map?),
        discriminatorKey: {'type': 'string', 'const': discriminatorValue},
      };
      // Build required array with discriminator first
      final existingRequired =
          (subSchemaJson['required'] as List?)?.cast<String>() ?? <String>[];
      final requiredFields = <String>[
        discriminatorKey,
        ...existingRequired.where((field) => field != discriminatorKey),
      ];
      subSchemaJson['required'] = requiredFields;
      anyOfClauses.add(subSchemaJson);
    });

    final baseSchema = {
      'anyOf': anyOfClauses,
      if (!isNullable && description != null) 'description': description,
    };

    // Wrap in anyOf with null if nullable
    if (isNullable) {
      return {
        if (description != null) 'description': description,
        'anyOf': [
          mergeConstraintSchemas(baseSchema),
          {'type': 'null'},
        ],
      };
    }

    return mergeConstraintSchemas(baseSchema);
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
    if (other is! DiscriminatedObjectSchema) return false;
    const mapEq = MapEquality<String, AckSchema>();
    return baseFieldsEqualErased(other) &&
        discriminatorKey == other.discriminatorKey &&
        mapEq.equals(schemas, other.schemas);
  }

  @override
  int get hashCode {
    const mapEq = MapEquality<String, AckSchema>();
    return Object.hash(
      baseFieldsHashCode,
      discriminatorKey,
      mapEq.hash(schemas),
    );
  }
}
