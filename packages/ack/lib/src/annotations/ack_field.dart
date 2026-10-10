import 'package:meta/meta_meta.dart';

/// Marks a class-first field as optional on the wire.
///
/// The JSON key may be omitted. This does not change whether a present JSON
/// value may be `null`: a nullable Dart type still accepts JSON `null`, and
/// `@NotNull()` rejects it. Valid only when the constructor can accept a
/// missing value, with a discriminator-specific exception for union branches.
@Target({TargetKind.field, TargetKind.parameter})
final class Optional {
  /// Creates an optional-presence annotation.
  const Optional();
}

/// Marks a class-first field as required on the wire.
///
/// The JSON key must be present. This does not change Dart nullability.
@Target({TargetKind.field, TargetKind.parameter})
final class Required {
  /// Creates a required-presence annotation.
  const Required();
}

/// Rejects an explicit JSON `null` without requiring the key to exist.
///
/// Needed only when the Dart type is nullable but a present JSON value must not
/// be `null`. Non-nullable Dart fields already reject JSON `null`; do not add
/// this annotation there. Dart nullability is unchanged: an omitted optional key
/// still becomes `null` on a nullable field, and encoding omits a null Dart
/// value.
@Target({TargetKind.field, TargetKind.parameter})
final class NotNull {
  /// Creates a JSON null-rejection annotation.
  const NotNull();
}

/// Overrides the JSON key, inferred schema, and/or description for a
/// class-first field.
///
/// [name] overrides the wire JSON key for this field.
/// [schema] must be a const tear-off of a top-level function returning an Ack
/// schema. The generator validates the declaration and follows its expression.
/// [description] describes this property, not a nested model's schema.
/// It takes precedence over an `@description` doc tag. A no-op `@AckField()`
/// is rejected.
@Target({TargetKind.field, TargetKind.parameter})
final class AckField {
  /// Creates a field annotation.
  const AckField({
    this.name,
    @Deprecated('Declare a static schema on the field type instead.')
    this.schema,
    this.description,
  });

  /// Explicit JSON key for this property.
  final String? name;

  /// Top-level schema-function tear-off followed by `ack_generator`.
  @Deprecated('Declare a static schema on the field type instead.')
  final Object Function()? schema;

  /// Schema description for this property.
  final String? description;
}
