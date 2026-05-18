part of 'schema.dart';

/// Shared contract for schemas that add runtime behavior around an inner
/// boundary-facing schema.
///
/// Wrappers keep their own runtime-side configuration and delegate boundary
/// shape traversal to [inner]. Converters can follow [inner] to recover the
/// encoded JSON shape, then merge wrapper-owned metadata such as description,
/// nullability, defaults, and generated marker fields.
mixin WrapperSchema<
  Boundary extends Object,
  Runtime extends Object,
  Schema extends AckSchema<Boundary, Runtime>
>
    on AckSchema<Boundary, Runtime> {
  /// The wrapped schema used for boundary-shape traversal.
  AnyAckSchema get inner;

  /// Returns a copy with runtime-side configuration replaced.
  @protected
  Schema copyWithRuntimeConfig({
    bool? isNullable,
    bool? isOptional,
    String? description,
    List<Constraint<Runtime>>? constraints,
    List<Refinement<Runtime>>? refinements,
  });

  /// Returns a copy with runtime-side configuration replaced.
  @override
  Schema withRuntimeConfig({
    bool? isNullable,
    bool? isOptional,
    String? description,
    List<Constraint<Runtime>>? constraints,
    List<Refinement<Runtime>>? refinements,
  }) {
    return copyWithRuntimeConfig(
      isNullable: isNullable,
      isOptional: isOptional,
      description: description,
      constraints: constraints,
      refinements: refinements,
    );
  }

  /// Marks the schema as nullable.
  @override
  Schema nullable({bool value = true}) {
    return copyWithRuntimeConfig(isNullable: value);
  }

  /// Marks the schema as optional so the field can be omitted from an object.
  @override
  Schema optional({bool value = true}) {
    return copyWithRuntimeConfig(isOptional: value);
  }

  /// Sets the description for the schema.
  @override
  Schema describe(String description) {
    return copyWithRuntimeConfig(description: description);
  }

  /// Alias for [describe].
  @Deprecated('Use describe() instead. Will be removed in a future version.')
  @override
  Schema withDescription(String description) {
    return describe(description);
  }

  /// Adds a validation constraint to the schema.
  @override
  Schema withConstraint(Constraint<Runtime> constraint) {
    return copyWithRuntimeConfig(constraints: [...constraints, constraint]);
  }

  /// Adds validation constraints to the schema.
  @override
  Schema withConstraints(List<Constraint<Runtime>> newConstraints) {
    return copyWithRuntimeConfig(
      constraints: [...constraints, ...newConstraints],
    );
  }

  /// Adds a custom validation check that runs after all other validations.
  @override
  Schema refine(
    bool Function(Runtime value) validate, {
    String message = 'The value did not pass the custom validation.',
  }) {
    final newRefinement = (validate: validate, message: message);
    return copyWithRuntimeConfig(refinements: [...refinements, newRefinement]);
  }

  /// Adds a raw [constraint] to the schema.
  @override
  Schema constrain(Constraint<Runtime> constraint, {String? message}) {
    if (constraint is! Validator<Runtime>) {
      throw ArgumentError(
        'Constraint ${constraint.runtimeType} must implement Validator<Runtime>.',
      );
    }
    final effectiveConstraint = message == null
        ? constraint
        : _ConstraintMessageOverride<Runtime>(constraint, message);
    return withConstraint(effectiveConstraint);
  }

  /// Applies wrapper-owned JSON Schema metadata to an inner boundary schema.
  @protected
  Map<String, Object?> applyWrapperJsonSchemaMetadata(
    Map<String, Object?> baseSchema, {
    Object? serializedDefault,
    Map<String, Object?> metadata = const {},
  }) {
    // Precedence is intentional: inner boundary schema first, generated
    // wrapper metadata second, then user-facing wrapper description last.
    final branchSchema = mergeConstraintSchemas({
      ...baseSchema,
      ...metadata,
      if (description != null) 'description': description,
    });

    if (!isNullable || _jsonSchemaHasNullBranch(branchSchema)) {
      return {
        ...branchSchema,
        if (serializedDefault != null) 'default': serializedDefault,
      };
    }

    return {
      if (description != null) 'description': description,
      if (serializedDefault != null) 'default': serializedDefault,
      'anyOf': [
        branchSchema,
        {'type': 'null'},
      ],
    };
  }
}

bool _jsonSchemaHasNullBranch(Map<String, Object?> schema) {
  if (schema['type'] == 'null') return true;

  return _jsonSchemaCompositionHasNullBranch(schema['anyOf']) ||
      _jsonSchemaCompositionHasNullBranch(schema['oneOf']);
}

bool _jsonSchemaCompositionHasNullBranch(Object? composition) {
  if (composition is! List) return false;
  return composition.any(
    (branch) =>
        branch is Map<String, Object?> && _jsonSchemaHasNullBranch(branch),
  );
}
