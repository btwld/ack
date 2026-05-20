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

  /// Alias for describe() for backward compatibility.
  @Deprecated('Use describe() instead. Will be removed in a future version.')
  @override
  Schema withDescription(String description) =>
      copyWith(description: description);

  /// Adds a validation constraint to the schema.
  @override
  Schema withConstraint(Constraint<Runtime> constraint) =>
      copyWith(constraints: [...constraints, constraint]);

  /// Adds a list of validation constraints to the schema.
  @override
  Schema withConstraints(List<Constraint<Runtime>> newConstraints) =>
      copyWith(constraints: [...constraints, ...newConstraints]);
}
