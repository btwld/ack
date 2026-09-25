import 'package:meta/meta_meta.dart';

// The deprecated presence API is defined in this file.
// ignore_for_file: deprecated_member_use_from_same_package

/// Overrides inferred input-presence for a class-first field.
///
/// [inferred] keeps constructor-based presence. [required] always requires the
/// JSON key. [optional] is valid only when the constructor can accept a missing
/// value, with a discriminator-specific exception for union branches.
@Deprecated(
  'Use @Optional() or @Required(). AckFieldPresence will be removed in 2.0.0.',
)
enum AckFieldPresence { inferred, required, optional }

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

/// Overrides the inferred schema and/or presence for a class-first field.
///
/// [schema] must be a const tear-off of a top-level function returning an Ack
/// schema. The generator validates the declaration and follows its expression.
/// A no-op `@AckField()` is rejected.
///
/// Prefer `@Optional()` and `@Required()` for key presence. [presence] is
/// deprecated and will be removed in 2.0.0.
@Target({TargetKind.field, TargetKind.parameter})
final class AckField {
  /// Creates a field annotation.
  const AckField({
    this.schema,
    @Deprecated(
      'Use @Optional() or @Required(). AckField.presence will be removed in '
      '2.0.0.',
    )
    this.presence = AckFieldPresence.inferred,
  });

  /// Top-level schema-function tear-off followed by `ack_generator`.
  final Object Function()? schema;

  /// Presence override applied after constructor inference.
  @Deprecated(
    'Use @Optional() or @Required(). AckField.presence will be removed in 2.0.0.',
  )
  final AckFieldPresence presence;
}
