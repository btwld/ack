part of 'schema.dart';

Object? _serializeJsonSchemaDefaultOrNull(Object? defaultValue) {
  if (defaultValue == null) return null;

  try {
    return jsonDecode(jsonEncode(defaultValue));
  } catch (_) {
    return null;
  }
}

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
///     }).transform<Animal>((map) => Cat(map!['name'] as String)),
///     'dog': Ack.object({
///       'type': Ack.literal('dog'),
///       'name': Ack.string(),
///     }).transform<Animal>((map) => Dog(map!['name'] as String)),
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
    super.defaultValue,
    super.constraints,
    super.refinements,
  });

  @override
  SchemaType get schemaType => SchemaType.discriminated;

  @override
  @protected
  SchemaResult<T>? handleNullInput(Object? inputValue, SchemaContext context) {
    if (inputValue != null) return null;

    if (defaultValue != null) {
      final clonedDefault = cloneDefault(defaultValue!);
      if (clonedDefault is Map) {
        return parseAndValidate(clonedDefault, context);
      }

      final safeDefault = clonedDefault is T ? clonedDefault : defaultValue!;
      return applyConstraintsAndRefinements(safeDefault, context);
    }

    if (isNullable) {
      return SchemaResult.ok(null);
    }

    return failNonNullable(context);
  }

  @override
  @protected
  SchemaResult<T> parseAndValidate(Object? inputValue, SchemaContext context) {
    // Use centralized null handling (including cloned default handling).
    final nullResult = handleNullInput(inputValue, context);
    if (nullResult != null) return nullResult;

    // Type guard
    if (inputValue is! Map) {
      final actualType = AckSchema.getSchemaType(inputValue);
      return SchemaResult.fail(
        TypeMismatchError(
          expectedType: schemaType,
          actualType: actualType,
          context: context,
        ),
      );
    }
    final mapValue = inputValue is MapValue
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

    final AckSchema<T>? selectedSubSchema = schemas[discValueRaw];

    if (selectedSubSchema == null) {
      final allowed = schemas.keys.toList(growable: false);
      final enumError = PatternConstraint.enumString(
        allowed,
      ).validate(discValueRaw);

      // Error context for discriminator key, but inherit parent path
      return SchemaResult.fail(
        SchemaConstraintsError(
          constraints: enumError != null ? [enumError] : [],
          context: context.createChild(
            name: discriminatorKey,
            schema: const StringSchema(),
            value: discValueRaw,
            pathSegment:
                discriminatorKey, // Point directly to the failing field
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
  DiscriminatedObjectSchema<T> copyWith({
    String? discriminatorKey,
    Map<String, AckSchema<T>>? schemas,
    bool? isNullable,
    bool? isOptional,
    String? description,
    T? defaultValue,
    List<Constraint<T>>? constraints,
    List<Refinement<T>>? refinements,
  }) {
    return DiscriminatedObjectSchema<T>(
      discriminatorKey: discriminatorKey ?? this.discriminatorKey,
      schemas: schemas ?? this.schemas,
      isNullable: isNullable ?? this.isNullable,
      isOptional: isOptional ?? this.isOptional,
      description: description ?? this.description,
      defaultValue: defaultValue ?? this.defaultValue,
      constraints: constraints ?? this.constraints,
      refinements: refinements ?? this.refinements,
    );
  }

  @override
  Map<String, Object?> toJsonSchema() {
    final anyOfClauses = <Map<String, Object?>>[];
    final serializedDefault = _serializeJsonSchemaDefaultOrNull(defaultValue);
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
      if (!isNullable && serializedDefault != null)
        'default': serializedDefault,
    };

    // Wrap in anyOf with null if nullable
    if (isNullable) {
      return {
        if (description != null) 'description': description,
        if (serializedDefault != null) 'default': serializedDefault,
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
      'defaultValue': defaultValue,
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
    final mapEq = MapEquality<String, AckSchema<T>>();
    return Object.hash(
      baseFieldsHashCode,
      discriminatorKey,
      mapEq.hash(schemas),
    );
  }
}
