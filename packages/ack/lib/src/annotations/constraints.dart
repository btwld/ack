import 'package:meta/meta_meta.dart';

/// Unified namespace for Ack field and parameter validation annotations.
///
/// Mirrors the fluent schema constraint methods so model files only need
/// `import 'package:ack/ack.dart';`:
///
/// ```dart
/// @Schemable()
/// final class User({
///   @Validate.email() required final String email,
///   @Validate.minLength(2) required final String name,
/// }) with _$UserAck {
///   static final schema = _userSchema;
/// }
/// ```
@Target({TargetKind.field, TargetKind.parameter})
final class Validate {
  /// The constraint identifier inspected by `ack_generator`.
  final String kind;

  /// Optional constraint argument (`num`, `int`, or `String`).
  final Object? value;

  /// Marks a class-first field as optional on the JSON wire.
  ///
  /// The JSON key may be omitted. This does not change whether a present JSON
  /// value may be `null`: a nullable Dart type still accepts JSON `null`, and
  /// [Validate.notNull] rejects it. Valid only when the constructor can accept
  /// a missing value, with a discriminator-specific exception for union
  /// branches.
  const Validate.optional() : kind = 'optional', value = null;

  /// Marks a class-first field as required on the JSON wire.
  ///
  /// The JSON key must be present. This does not change Dart nullability.
  const Validate.required() : kind = 'required', value = null;

  /// Rejects an explicit JSON `null` without requiring the key to exist.
  ///
  /// Needed only when the Dart type is nullable (`T?`) or `JsonMaybe<T>` but a
  /// present JSON value must not be `null`. Non-nullable Dart fields already
  /// reject JSON `null`. Dart nullability is unchanged: an omitted optional key
  /// still becomes `null` on a nullable field, and encoding omits a null Dart
  /// value.
  const Validate.notNull() : kind = 'notNull', value = null;

  /// Adds `.min(value)` to an inferred numeric schema.
  const Validate.min(num this.value) : kind = 'min';

  /// Adds `.max(value)` to an inferred numeric schema.
  const Validate.max(num this.value) : kind = 'max';

  /// Adds `.multipleOf(value)` to an inferred numeric schema.
  const Validate.multipleOf(num this.value) : kind = 'multipleOf';

  /// Adds `.positive()` to an inferred numeric schema.
  const Validate.positive() : kind = 'positive', value = null;

  /// Adds `.negative()` to an inferred numeric schema.
  const Validate.negative() : kind = 'negative', value = null;

  /// Adds `.minLength(length)` to an inferred string schema.
  const Validate.minLength(int length) : kind = 'minLength', value = length;

  /// Adds `.maxLength(length)` to an inferred string schema.
  const Validate.maxLength(int length) : kind = 'maxLength', value = length;

  /// Adds `.matches(pattern)` to an inferred string schema.
  const Validate.matches(String pattern) : kind = 'matches', value = pattern;

  /// Adds `.notEmpty()` to an inferred string or collection (`List` / `Set`) schema.
  const Validate.notEmpty() : kind = 'notEmpty', value = null;

  /// Adds `.email()` to an inferred string schema.
  const Validate.email() : kind = 'email', value = null;

  /// Adds `.url()` to an inferred string schema.
  const Validate.url() : kind = 'url', value = null;

  /// Adds `.uri()` to an inferred string schema.
  const Validate.uri() : kind = 'uri', value = null;

  /// Adds `.uuid()` to an inferred string schema.
  const Validate.uuid() : kind = 'uuid', value = null;

  /// Adds `.date()` to an inferred string schema.
  const Validate.date() : kind = 'date', value = null;

  /// Adds `.datetime()` to an inferred string schema.
  const Validate.dateTime() : kind = 'dateTime', value = null;

  /// Adds `.ip()` to an inferred string schema.
  const Validate.ip({int? version}) : kind = 'ip', value = version;

  /// Adds `.ipv4()` to an inferred string schema.
  const Validate.ipv4() : kind = 'ipv4', value = null;

  /// Adds `.ipv6()` to an inferred string schema.
  const Validate.ipv6() : kind = 'ipv6', value = null;

  /// Adds `.minItems(count)` to an inferred collection schema.
  const Validate.minItems(int count) : kind = 'minItems', value = count;

  /// Adds `.maxItems(count)` to an inferred collection schema.
  const Validate.maxItems(int count) : kind = 'maxItems', value = count;

  /// Adds `.unique()` to an inferred collection schema.
  const Validate.uniqueItems() : kind = 'uniqueItems', value = null;
}
