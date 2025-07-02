part of 'schema.dart';

/// A mixin to provide a fluent API for building and modifying schemas.
///
/// It expects the class to have a `copyWith` method that returns an instance
/// of the schema itself (`Schema`).
mixin FluentSchema<DartType extends Object, Schema extends AckSchema<DartType>>
    on AckSchema<DartType> {
  /// Marks the schema as nullable.

  Schema nullable({bool value = true}) => copyWith(isNullable: value) as Schema;

  /// Sets the description for the schema.

  Schema withDescription(String? newDescription) =>
      copyWith(description: newDescription) as Schema;

  /// Sets the default value for the schema.

  Schema withDefault(DartType newDefaultValue) =>
      copyWith(defaultValue: newDefaultValue) as Schema;

  /// Adds a validation constraint to the schema.

  Schema withConstraint(Constraint<DartType> constraint) =>
      copyWith(constraints: [...constraints, constraint]) as Schema;

  /// Adds a list of validation constraints to the schema.

  Schema withConstraints(List<Constraint<DartType>> newConstraints) =>
      copyWith(constraints: [...constraints, ...newConstraints]) as Schema;
}
