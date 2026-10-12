import 'package:meta/meta_meta.dart';

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
  const AckField({this.name, this.schema, this.description});

  /// Explicit JSON key for this property.
  final String? name;

  /// Top-level schema-function tear-off followed by `ack_generator`.
  final Object Function()? schema;

  /// Schema description for this property.
  final String? description;
}
