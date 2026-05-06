part of 'schema.dart';

/// Schema for validating a discriminated union of objects.
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

  @override
  @protected
  SchemaResult<T> validate(Object? value, SchemaContext context) {
    if (value == null) {
      if (isNullable) return SchemaResult.ok(null);
      return failNull(context);
    }

    if (value is Map) {
      final mapValue = _toMapValue(value);
      if (mapValue == null) {
        return failTypeMismatch(value, context);
      }
      return _validateMap(mapValue, context);
    }

    if (value is! T) {
      return failTypeMismatch(value, context);
    }

    return _validateByBranchTrial(value, context);
  }

  SchemaResult<T> _validateMap(MapValue mapValue, SchemaContext context) =>
      _withBranch<T>(mapValue, context, (selected, disc) {
        final branchCtx = _branchContext(selected, mapValue, disc, context);
        final objectCheck = _requireObjectBackedBranch(selected, branchCtx);
        if (objectCheck != null) return objectCheck;

        final result = selected.validate(mapValue, branchCtx);
        if (result.isFail) return result.castFail();
        return applyConstraintsAndRefinements(result.getOrThrow()!, context);
      });

  /// Resolves the discriminator key and selects the matching branch schema,
  /// dispatching to [onResolved] on success. Failures (missing/wrong-typed
  /// discriminator, unknown value) short-circuit with [_failDiscriminator].
  SchemaResult<R> _withBranch<R extends Object>(
    MapValue mapValue,
    SchemaContext context,
    SchemaResult<R> Function(AckSchema<T> selected, String disc) onResolved,
  ) {
    final discValueRaw = mapValue[discriminatorKey];

    if (discValueRaw == null) {
      final ce = ObjectRequiredPropertiesConstraint(
        missingPropertyKey: discriminatorKey,
      ).validate(mapValue);
      return _failDiscriminator<R>(ce, null, context);
    }
    if (discValueRaw is! String) {
      final ce = InvalidTypeConstraint(
        expectedType: String,
      ).validate(discValueRaw);
      return _failDiscriminator<R>(ce, discValueRaw, context);
    }

    final selected = schemas[discValueRaw];
    if (selected == null) {
      final allowed = schemas.keys.toList(growable: false);
      final ce = PatternConstraint.enumString(allowed).validate(discValueRaw);
      return _failDiscriminator<R>(ce, discValueRaw, context);
    }

    return onResolved(selected, discValueRaw);
  }

  SchemaContext _branchContext(
    AckSchema<T> selected,
    Object value,
    String discValue,
    SchemaContext context,
  ) {
    return context.createChild(
      name: 'when $discriminatorKey="$discValue"',
      schema: selected,
      value: value,
      pathSegment: '',
    );
  }

  SchemaResult<T>? _requireObjectBackedBranch(
    AckSchema<T> selected,
    SchemaContext branchCtx,
  ) {
    final base = unwrapDiscriminatedBranchSchema(selected);
    if (base is ObjectSchema) return null;
    return SchemaResult.fail(
      SchemaValidationError(
        message: 'Discriminated branches must be object-backed schemas',
        context: branchCtx,
      ),
    );
  }

  SchemaResult<T> _validateByBranchTrial(T value, SchemaContext context) {
    final errors = <SchemaError>[];

    for (final entry in schemas.entries) {
      final branchCtx = _branchContext(entry.value, value, entry.key, context);
      final result = entry.value.validate(value, branchCtx);
      if (result.isOk) {
        return applyConstraintsAndRefinements(result.getOrThrow()!, context);
      }
      errors.add(result.getError());
    }

    return SchemaResult.fail(
      SchemaNestedError(errors: errors, context: context),
    );
  }

  @override
  @protected
  SchemaResult<T> decodeBoundary(Object? input, SchemaContext context) {
    if (input == null) {
      if (isNullable) return SchemaResult.ok(null);
      return failNull(context);
    }

    if (input is! Map) {
      return validate(input, context);
    }

    final mapValue = _toMapValue(input);
    if (mapValue == null) {
      return failTypeMismatch(input, context);
    }

    return _withBranch<T>(mapValue, context, (selected, disc) {
      final branchCtx = _branchContext(selected, mapValue, disc, context);
      final objectCheck = _requireObjectBackedBranch(selected, branchCtx);
      if (objectCheck != null) return objectCheck;

      final result = selected.decodeBoundary(mapValue, branchCtx);
      if (result.isFail) return result.castFail();
      return applyConstraintsAndRefinements(result.getOrThrow()!, context);
    });
  }

  @override
  @protected
  SchemaResult<Object> encodeBoundary(T value, SchemaContext context) {
    if (value is Map) {
      final mapValue = _toMapValue(value);
      if (mapValue == null) return failTypeMismatch(value, context).castFail();

      return _withBranch<Object>(mapValue, context, (selected, disc) {
        final branchCtx = _branchContext(selected, mapValue, disc, context);
        return _encodeWithSchema(selected, mapValue, branchCtx);
      });
    }

    final errors = <SchemaError>[];
    for (final entry in schemas.entries) {
      final branchCtx = _branchContext(entry.value, value, entry.key, context);
      final result = _encodeWithSchema(entry.value, value, branchCtx);
      if (result.isOk) return result;
      errors.add(result.getError());
    }

    return SchemaResult.fail(
      SchemaNestedError(errors: errors, context: context),
    );
  }

  SchemaResult<R> _failDiscriminator<R extends Object>(
    ConstraintError? constraint,
    Object? value,
    SchemaContext parent,
  ) {
    return SchemaResult.fail(
      SchemaConstraintsError(
        constraints: constraint != null ? [constraint] : const [],
        context: parent.createChild(
          name: discriminatorKey,
          schema: const StringSchema(),
          value: value,
          pathSegment: discriminatorKey,
        ),
      ),
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
      subSchemaJson['properties'] = {
        ...?(subSchemaJson['properties'] as Map?),
        discriminatorKey: {'type': 'string', 'const': discriminatorValue},
      };
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
