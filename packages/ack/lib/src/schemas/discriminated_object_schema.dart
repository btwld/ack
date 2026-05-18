part of 'schema.dart';

/// Schema for validating a discriminated union of objects.
///
/// Branches must produce the same runtime type [T]. Boundary type is
/// [JsonMap]. Encoding selects the first branch whose runtime validation
/// AND encode succeed, then re-inserts the discriminator key.
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

    final subSchemaContext = context.createChild(
      name: 'when $discriminatorKey="$discValueRaw"',
      schema: selectedSubSchema,
      value: mapValue,
      pathSegment: '',
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

    final result = selectedSubSchema.parseWithContext(
      mapValue,
      subSchemaContext,
    );
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
    final errors = <SchemaError>[];
    for (final entry in schemas.entries) {
      final discValue = entry.key;
      final branchSchema = entry.value;
      final branchCtx = context.createChild(
        name: 'when $discriminatorKey="$discValue"',
        schema: branchSchema,
        value: value,
        pathSegment: '',
        operation: SchemaOperation.encode,
      );
      try {
        final branchValidation = branchSchema.validateRuntimeWithContext(
          value,
          branchCtx,
        );
        if (branchValidation.isFail) {
          errors.add(branchValidation.getError());
          continue;
        }
        final encoded = branchSchema.encodeWithContext(value, branchCtx);
        if (encoded.isOk) {
          final boundary = encoded.getOrNull();
          if (boundary != null) {
            final emittedDiscriminator = boundary.containsKey(discriminatorKey);
            // Policy A: if the branch already emitted the discriminator key,
            // require it to match this branch's discriminator value. Until
            // discriminator-key ownership lands, this catches branches that
            // disagree with the union routing.
            if (emittedDiscriminator &&
                boundary[discriminatorKey] != discValue) {
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
            final merged = emittedDiscriminator
                ? boundary
                : (Map<String, Object?>.from(boundary)
                    ..[discriminatorKey] = discValue);
            return SchemaResult.ok(Map<String, Object?>.unmodifiable(merged));
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
      subSchemaJson['required'] = <String>[
        discriminatorKey,
        ...existingRequired.where((field) => field != discriminatorKey),
      ];
      anyOfClauses.add(subSchemaJson);
    });

    return wrapCompositeWithNullable({
      'anyOf': anyOfClauses,
      if (!isNullable && description != null) 'description': description,
    });
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
