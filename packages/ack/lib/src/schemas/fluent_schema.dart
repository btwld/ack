part of 'schema.dart';

/// Provides a fluent builder API for schemas with a strongly-typed `copyWith`.
///
/// `FluentSchema` is used by primitives and composites that return their own
/// concrete type from `copyWith`.
mixin FluentSchema<
  Boundary extends Object,
  Runtime extends Object,
  Schema extends AckSchema<Boundary, Runtime>
>
    on AckSchema<Boundary, Runtime> {
  /// Returns a copy of this schema with the given fields replaced.
  Schema copyWith({
    bool? isNullable,
    bool? isOptional,
    String? description,
    List<Constraint<Runtime>>? constraints,
    List<Refinement<Runtime>>? refinements,
  });

  @override
  Schema withRuntimeConfig({
    bool? isNullable,
    bool? isOptional,
    String? description,
    List<Constraint<Runtime>>? constraints,
    List<Refinement<Runtime>>? refinements,
  }) {
    return copyWith(
      isNullable: isNullable,
      isOptional: isOptional,
      description: description,
      constraints: constraints,
      refinements: refinements,
    );
  }

  /// Marks the schema as nullable.
  @override
  Schema nullable({bool value = true}) => copyWith(isNullable: value);

  /// Marks the schema as optional so the field can be omitted from an object.
  @override
  Schema optional({bool value = true}) => copyWith(isOptional: value);

  /// Sets the description for the schema.
  @override
  Schema describe(String description) => copyWith(description: description);

  /// Adds a validation constraint to the schema.
  @override
  Schema withConstraint(Constraint<Runtime> constraint) =>
      copyWith(constraints: [...constraints, constraint]);

  /// Adds a list of validation constraints to the schema.
  @override
  Schema withConstraints(List<Constraint<Runtime>> newConstraints) =>
      copyWith(constraints: [...constraints, ...newConstraints]);

  /// Adds a custom validation check that runs after all other validations.
  @override
  Schema refine(
    bool Function(Runtime value) validate, {
    String message = 'The value did not pass the custom validation.',
  }) {
    final newRefinement = (validate: validate, message: message);
    return copyWith(refinements: [...refinements, newRefinement]);
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
