/// Annotation library for Ack schema model-class generation.
///
/// Import this library to use `@AckInfer()` on top-level schema declarations or
/// `@AckModel()` on hand-written model classes processed by `ack_generator`.
/// Deprecated `@AckType()` remains available for Ack 1.1 compatibility.
///
/// Class-first models apply the generated `_$ClassAck` mixin and may use
/// [AckUnknownPropertyPolicy], `@Optional()`, `@Required()`, `@NotNull()`,
/// and `@AckField(schema: ...)` to describe wire extras, field presence,
/// and custom field codecs. Deprecated [AckFieldPresence] remains available
/// during migration.
/// Import `format_annotations.dart` with a prefix for `@Uri()` and
/// `@DateTime()`, whose names also belong to Dart core types.
library;

export 'package:json_annotation/json_annotation.dart' show JsonKey;
export 'src/ack_field.dart';
export 'src/ack_infer.dart';
export 'src/ack_model.dart';
export 'src/ack_type.dart';
export 'src/constraints.dart';
