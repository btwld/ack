part of 'schema.dart';

/// Schema for validating a discriminated union of objects.
///
/// Branches must produce the same runtime type [T]. Boundary type is
/// [JsonMap]. Encoding selects the first branch whose encode succeeds.
@immutable
final class DiscriminatedObjectSchema<T extends Object>
    extends AckSchema<JsonMap, T>
    with FluentSchema<JsonMap, T, DiscriminatedObjectSchema<T>> {
  final String discriminatorKey;
  final Map<String, AckSchema<JsonMap, T>> schemas;

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
  SchemaResult<T> parseAndValidate(Object? inputValue, SchemaContext context) {
    final nullResult = handleNullInput(inputValue, context);
    if (nullResult != null) return nullResult;

    if (inputValue is! Map) {
      return SchemaResult.fail(
        TypeMismatchError(
          expectedType: schemaType,
          actualType: AckSchema.getSchemaType(inputValue),
          context: context,
        ),
      );
    }
    final mapValue = inputValue is JsonMap
        ? inputValue
        : inputValue.cast<String, Object?>();

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

    final AckSchema<JsonMap, T>? selectedSubSchema = schemas[discValueRaw];

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

    final result = selectedSubSchema.parseAndValidate(
      mapValue,
      subSchemaContext,
    );

    if (result.isFail) {
      return result.match(
        onOk: (_) => throw StateError('Unreachable'),
        onFail: (error) => SchemaResult.fail(error),
      );
    }

    final validatedValue = result.getOrThrow()!;

    return applyConstraintsAndRefinements(validatedValue, context);
  }

  @override
  @protected
  SchemaResult<JsonMap> encodeRuntime(T value, SchemaContext context) {
    final errors = <SchemaError>[];
    for (final entry in schemas.entries) {
      final discValue = entry.key;
      final branchSchema = entry.value;
      try {
        final encoded = branchSchema.safeEncode(value);
        if (encoded.isOk) {
          final boundary = encoded.getOrNull();
          if (boundary != null) {
            final merged = Map<String, Object?>.from(boundary);
            merged[discriminatorKey] = discValue;
            return SchemaResult.ok(Map<String, Object?>.unmodifiable(merged));
          }
        } else {
          errors.add(encoded.getError());
        }
      } catch (e, st) {
        errors.add(
          SchemaEncodeError.encoderThrew(
            message: 'Discriminated branch "$discValue" threw: $e',
            context: context,
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
  DiscriminatedObjectSchema<T> copyWithBase({
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
    return baseFieldsEqual(other) &&
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

