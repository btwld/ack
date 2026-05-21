part of 'schema.dart';

/// ACK-internal infrastructure for schemas that wrap another boundary-facing
/// schema.
///
/// Wrappers add runtime behavior (e.g. codecs, defaults) while preserving an
/// inner schema for boundary-shape traversal, schema-model export, and
/// discriminated-branch rewriting. The canonical JSON export path is
/// `AckSchema → AckSchemaModel → JSON`; wrappers do not render JSON directly.
///
/// Not a public extension point for application code. Consumers should use
/// `Ack.*` factories (`withDefault`, `codec`, `transform`, `model`) instead of
/// implementing this mixin themselves.
@internal
mixin WrapperSchema<
  Boundary extends Object,
  Runtime extends Object,
  Schema extends AckSchema<Boundary, Runtime>
>
    on AckSchema<Boundary, Runtime> {
  /// The wrapped schema used for boundary-shape traversal.
  AnyAckSchema get inner;

  /// Returns a copy of this wrapper with [inner] swapped for [newInner].
  ///
  /// Used by traversal utilities (e.g. discriminated-branch synthesis) that
  /// need to rewrite the underlying boundary schema while preserving wrapper
  /// configuration and behavior.
  Schema copyWithInner(AnyAckSchema newInner);

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

}
