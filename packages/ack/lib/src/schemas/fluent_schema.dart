part of 'schema.dart';

/// Provides a fluent builder API for schemas with a strongly-typed `copyWith`.
mixin FluentSchema<
  Boundary extends Object,
  Runtime extends Object,
  Schema extends AckSchema<Boundary, Runtime>
> on AckSchema<Boundary, Runtime> {
  /// Returns a copy of this schema with the given fields replaced.
  ///
  /// Subclasses implement this so the fluent helpers can preserve concrete
  /// types.
  Schema copyWith({
    bool? isNullable,
    bool? isOptional,
    String? description,
    List<Constraint<Runtime>>? constraints,
    List<Refinement<Runtime>>? refinements,
  });

  /// Marks the schema as nullable.
  Schema nullable({bool value = true}) => copyWith(isNullable: value);

  /// Marks the schema as optional so the field can be omitted from an object.
  Schema optional({bool value = true}) => copyWith(isOptional: value);

  /// Sets the description for the schema.
  Schema describe(String description) =>
      copyWith(description: description);

  /// Alias for describe() for backward compatibility.
  @Deprecated('Use describe() instead. Will be removed in a future version.')
  Schema withDescription(String description) =>
      copyWith(description: description);

  /// Wraps this schema in a [DefaultSchema] that supplies [defaultValue] when
  /// the input is null.
  DefaultSchema<Boundary, Runtime> withDefault(Runtime defaultValue) {
    return DefaultSchema<Boundary, Runtime>(
      inner: this,
      defaultValue: defaultValue,
    );
  }

  /// Adds a validation constraint to the schema.
  Schema withConstraint(Constraint<Runtime> constraint) =>
      copyWith(constraints: [...constraints, constraint]);

  /// Adds a list of validation constraints to the schema.
  Schema withConstraints(List<Constraint<Runtime>> newConstraints) =>
      copyWith(constraints: [...constraints, ...newConstraints]);
}
