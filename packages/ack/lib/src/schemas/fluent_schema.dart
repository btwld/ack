part of 'schema.dart';

/// A mixin to provide a fluent API for building and modifying schemas.
///
/// It expects the class to have a `copyWith` method that returns an instance
/// of the schema itself (`Schema`).
mixin FluentSchema<DartType extends Object, Schema extends AckSchema<DartType>>
    on AckSchema<DartType> {
  /// Marks the schema as nullable.
  Schema nullable({bool value = true}) => copyWith(isNullable: value) as Schema;

  /// Marks the schema as optional (field can be omitted from an object).
  Schema optional({bool value = true}) => copyWith(isOptional: value) as Schema;

  /// Sets the description for the schema.
  Schema describe(String description) =>
      copyWith(description: description) as Schema;

  /// Alias for describe() for backward compatibility.
  Schema withDescription(String description) =>
      copyWith(description: description) as Schema;

  /// Sets the default value for the schema.
  Schema withDefault(DartType defaultValue) =>
      copyWith(defaultValue: defaultValue) as Schema;

  /// Adds a validation constraint to the schema.
  Schema withConstraint(Constraint<DartType> constraint) =>
      copyWith(constraints: [...constraints, constraint]) as Schema;

  /// Adds a list of validation constraints to the schema.
  Schema withConstraints(List<Constraint<DartType>> newConstraints) =>
      copyWith(constraints: [...constraints, ...newConstraints]) as Schema;
}
