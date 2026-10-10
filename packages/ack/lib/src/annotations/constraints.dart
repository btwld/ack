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

  /// Adds `.notEmpty()` to an inferred string schema.
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

  /// Adds `.datetime()` to an inferred string schema.
  const Validate.datetime() : kind = 'datetime', value = null;

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

  /// Adds `.unique()` to an inferred collection schema.
  const Validate.unique() : kind = 'unique', value = null;
}

/// Adds `.min(value)` to an inferred numeric schema.
@Deprecated('Use @Validate.min(...) from package:ack/ack.dart instead.')
@Target({TargetKind.field, TargetKind.parameter})
final class Min {
  const Min(this.value);

  final num value;
}

/// Adds `.max(value)` to an inferred numeric schema.
@Deprecated('Use @Validate.max(...) from package:ack/ack.dart instead.')
@Target({TargetKind.field, TargetKind.parameter})
final class Max {
  const Max(this.value);

  final num value;
}

/// Adds `.multipleOf(value)` to an inferred numeric schema.
@Deprecated('Use @Validate.multipleOf(...) from package:ack/ack.dart instead.')
@Target({TargetKind.field, TargetKind.parameter})
final class MultipleOf {
  const MultipleOf(this.value);

  final num value;
}

/// Adds `.positive()` to an inferred numeric schema.
@Deprecated('Use @Validate.positive() from package:ack/ack.dart instead.')
@Target({TargetKind.field, TargetKind.parameter})
final class Positive {
  const Positive();
}

/// Adds `.negative()` to an inferred numeric schema.
@Deprecated('Use @Validate.negative() from package:ack/ack.dart instead.')
@Target({TargetKind.field, TargetKind.parameter})
final class Negative {
  const Negative();
}

/// Adds `.minLength(length)` to an inferred string schema.
@Deprecated('Use @Validate.minLength(...) from package:ack/ack.dart instead.')
@Target({TargetKind.field, TargetKind.parameter})
final class MinLength {
  const MinLength(this.length);

  final int length;
}

/// Adds `.maxLength(length)` to an inferred string schema.
@Deprecated('Use @Validate.maxLength(...) from package:ack/ack.dart instead.')
@Target({TargetKind.field, TargetKind.parameter})
final class MaxLength {
  const MaxLength(this.length);

  final int length;
}

/// Adds `.matches(pattern)` to an inferred string schema.
@Deprecated('Use @Validate.matches(...) from package:ack/ack.dart instead.')
@Target({TargetKind.field, TargetKind.parameter})
final class Matches {
  const Matches(this.pattern);

  final String pattern;
}

/// Adds `.email()` to an inferred string schema.
@Deprecated('Use @Validate.email() from package:ack/ack.dart instead.')
@Target({TargetKind.field, TargetKind.parameter})
final class Email {
  const Email();
}

/// Adds `.url()` to an inferred string schema.
@Deprecated('Use @Validate.url() from package:ack/ack.dart instead.')
@Target({TargetKind.field, TargetKind.parameter})
final class Url {
  const Url();
}

/// Adds `.uuid()` to an inferred string schema.
@Deprecated('Use @Validate.uuid() from package:ack/ack.dart instead.')
@Target({TargetKind.field, TargetKind.parameter})
final class Uuid {
  const Uuid();
}

/// Adds `.date()` to an inferred string schema.
@Deprecated('Use @Validate.date() from package:ack/ack.dart instead.')
@Target({TargetKind.field, TargetKind.parameter})
final class Date {
  const Date();
}

/// Adds `.notEmpty()` to an inferred string schema.
@Deprecated('Use @Validate.notEmpty() from package:ack/ack.dart instead.')
@Target({TargetKind.field, TargetKind.parameter})
final class NotEmpty {
  const NotEmpty();
}

/// Adds `.minItems(count)` to an inferred collection schema.
@Deprecated('Use @Validate.minItems(...) from package:ack/ack.dart instead.')
@Target({TargetKind.field, TargetKind.parameter})
final class MinItems {
  const MinItems(this.count);

  final int count;
}

/// Adds `.maxItems(count)` to an inferred collection schema.
@Deprecated('Use @Validate.maxItems(...) from package:ack/ack.dart instead.')
@Target({TargetKind.field, TargetKind.parameter})
final class MaxItems {
  const MaxItems(this.count);

  final int count;
}

/// Adds `.unique()` to an inferred collection schema.
@Deprecated('Use @Validate.uniqueItems() from package:ack/ack.dart instead.')
@Target({TargetKind.field, TargetKind.parameter})
final class UniqueItems {
  const UniqueItems();
}
