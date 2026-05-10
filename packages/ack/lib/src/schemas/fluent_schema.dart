part of 'schema.dart';

/// A mixin to provide a fluent API for building and modifying schemas.
///
/// It expects the class to have a `copyWith` method that returns an instance
/// of the schema itself (`Schema`).
mixin FluentSchema<DartType extends Object, Schema extends AckSchema<DartType>>
    on AckSchema<DartType> {
  /// Marks the schema as nullable.
  Schema nullable({bool value = true}) => copyWith(isNullable: value) as Schema;

  /// Marks the schema as optional so the field can be omitted from an object.
  ///
  /// See [AckSchemaExtensions.optional] for detailed semantics.
  Schema optional({bool value = true}) => copyWith(isOptional: value) as Schema;

  /// Sets the description for the schema.
  Schema describe(String description) =>
      copyWith(description: description) as Schema;

  /// Alias for describe() for backward compatibility.
  @Deprecated('Use describe() instead. Will be removed in a future version.')
  Schema withDescription(String description) =>
      copyWith(description: description) as Schema;

  /// Wraps this schema in a [DefaultSchema] that supplies [defaultValue]
  /// when the parse-side input is `null`.
  ///
  /// **Breaking change (M12):** previously `withDefault` returned a copy of
  /// the same schema type with `defaultValue` set. It now returns a
  /// [DefaultSchema] wrapper. This means type-specific fluent methods
  /// (e.g. `.minLength`, `.matches` on `StringSchema`) must be applied
  /// **before** `.withDefault(...)`:
  ///
  /// ```dart
  /// // Preferred
  /// Ack.string().minLength(3).withDefault('guest');
  ///
  /// // Won't type-check — DefaultSchema<String> has no .minLength(...)
  /// // Ack.string().withDefault('guest').minLength(3);
  /// ```
  ///
  /// Defaults are parse-only per requirements §5.5: they are synthesized
  /// when parse input is `null`, but never injected on encode.
  DefaultSchema<DartType> withDefault(DartType defaultValue) {
    return DefaultSchema<DartType>(
      inner: this,
      defaultValue: defaultValue,
    );
  }

  /// Adds a validation constraint to the schema.
  Schema withConstraint(Constraint<DartType> constraint) =>
      copyWith(constraints: [...constraints, constraint]) as Schema;

  /// Adds a list of validation constraints to the schema.
  Schema withConstraints(List<Constraint<DartType>> newConstraints) =>
      copyWith(constraints: [...constraints, ...newConstraints]) as Schema;
}
