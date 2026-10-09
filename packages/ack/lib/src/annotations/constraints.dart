import 'package:meta/meta_meta.dart';

/// Unified namespace for Ack field and parameter constraint annotations.
///
/// Mirrors the fluent schema constraint methods so model files only need
/// `import 'package:ack/ack.dart';`:
///
/// ```dart
/// @Schemable()
/// final class User with _$UserAck {
///   const User({required this.email, required this.name});
///
///   @Check.email()
///   final String email;
///
///   @Check.minLength(2)
///   final String name;
/// }
/// ```
@Target({TargetKind.field, TargetKind.parameter})
final class Check {
  /// The constraint identifier inspected by `ack_generator`.
  final String kind;

  /// Optional constraint argument (`num`, `int`, or `String`).
  final Object? value;

  /// Adds `.min(value)` to an inferred numeric schema.
  const Check.min(num this.value) : kind = 'min';

  /// Adds `.max(value)` to an inferred numeric schema.
  const Check.max(num this.value) : kind = 'max';

  /// Adds `.multipleOf(value)` to an inferred numeric schema.
  const Check.multipleOf(num this.value) : kind = 'multipleOf';

  /// Adds `.positive()` to an inferred numeric schema.
  const Check.positive() : kind = 'positive', value = null;

  /// Adds `.negative()` to an inferred numeric schema.
  const Check.negative() : kind = 'negative', value = null;

  /// Adds `.minLength(length)` to an inferred string schema.
  const Check.minLength(int length) : kind = 'minLength', value = length;

  /// Adds `.maxLength(length)` to an inferred string schema.
  const Check.maxLength(int length) : kind = 'maxLength', value = length;

  /// Adds `.matches(pattern)` to an inferred string schema.
  const Check.matches(String pattern) : kind = 'matches', value = pattern;

  /// Adds `.notEmpty()` to an inferred string schema.
  const Check.notEmpty() : kind = 'notEmpty', value = null;

  /// Adds `.email()` to an inferred string schema.
  const Check.email() : kind = 'email', value = null;

  /// Adds `.url()` to an inferred string schema.
  const Check.url() : kind = 'url', value = null;

  /// Adds `.uri()` to an inferred string schema.
  const Check.uri() : kind = 'uri', value = null;

  /// Adds `.uuid()` to an inferred string schema.
  const Check.uuid() : kind = 'uuid', value = null;

  /// Adds `.date()` to an inferred string schema.
  const Check.date() : kind = 'date', value = null;

  /// Adds `.datetime()` to an inferred string schema.
  const Check.dateTime() : kind = 'dateTime', value = null;

  /// Adds `.datetime()` to an inferred string schema.
  const Check.datetime() : kind = 'datetime', value = null;

  /// Adds `.ip()` to an inferred string schema.
  const Check.ip({int? version}) : kind = 'ip', value = version;

  /// Adds `.ipv4()` to an inferred string schema.
  const Check.ipv4() : kind = 'ipv4', value = null;

  /// Adds `.ipv6()` to an inferred string schema.
  const Check.ipv6() : kind = 'ipv6', value = null;

  /// Adds `.minItems(count)` to an inferred collection schema.
  const Check.minItems(int count) : kind = 'minItems', value = count;

  /// Adds `.maxItems(count)` to an inferred collection schema.
  const Check.maxItems(int count) : kind = 'maxItems', value = count;

  /// Adds `.unique()` to an inferred collection schema.
  const Check.uniqueItems() : kind = 'uniqueItems', value = null;

  /// Adds `.unique()` to an inferred collection schema.
  const Check.unique() : kind = 'unique', value = null;
}

/// Adds `.min(value)` to an inferred numeric schema.
@Deprecated('Use @Check.min(...) from package:ack/ack.dart instead.')
@Target({TargetKind.field, TargetKind.parameter})
final class Min {
  const Min(this.value);

  final num value;
}

/// Adds `.max(value)` to an inferred numeric schema.
@Deprecated('Use @Check.max(...) from package:ack/ack.dart instead.')
@Target({TargetKind.field, TargetKind.parameter})
final class Max {
  const Max(this.value);

  final num value;
}

/// Adds `.multipleOf(value)` to an inferred numeric schema.
@Deprecated('Use @Check.multipleOf(...) from package:ack/ack.dart instead.')
@Target({TargetKind.field, TargetKind.parameter})
final class MultipleOf {
  const MultipleOf(this.value);

  final num value;
}

/// Adds `.positive()` to an inferred numeric schema.
@Deprecated('Use @Check.positive() from package:ack/ack.dart instead.')
@Target({TargetKind.field, TargetKind.parameter})
final class Positive {
  const Positive();
}

/// Adds `.negative()` to an inferred numeric schema.
@Deprecated('Use @Check.negative() from package:ack/ack.dart instead.')
@Target({TargetKind.field, TargetKind.parameter})
final class Negative {
  const Negative();
}

/// Adds `.minLength(length)` to an inferred string schema.
@Deprecated('Use @Check.minLength(...) from package:ack/ack.dart instead.')
@Target({TargetKind.field, TargetKind.parameter})
final class MinLength {
  const MinLength(this.length);

  final int length;
}

/// Adds `.maxLength(length)` to an inferred string schema.
@Deprecated('Use @Check.maxLength(...) from package:ack/ack.dart instead.')
@Target({TargetKind.field, TargetKind.parameter})
final class MaxLength {
  const MaxLength(this.length);

  final int length;
}

/// Adds `.matches(pattern)` to an inferred string schema.
@Deprecated('Use @Check.matches(...) from package:ack/ack.dart instead.')
@Target({TargetKind.field, TargetKind.parameter})
final class Matches {
  const Matches(this.pattern);

  final String pattern;
}

/// Adds `.email()` to an inferred string schema.
@Deprecated('Use @Check.email() from package:ack/ack.dart instead.')
@Target({TargetKind.field, TargetKind.parameter})
final class Email {
  const Email();
}

/// Adds `.url()` to an inferred string schema.
@Deprecated('Use @Check.url() from package:ack/ack.dart instead.')
@Target({TargetKind.field, TargetKind.parameter})
final class Url {
  const Url();
}

/// Adds `.uuid()` to an inferred string schema.
@Deprecated('Use @Check.uuid() from package:ack/ack.dart instead.')
@Target({TargetKind.field, TargetKind.parameter})
final class Uuid {
  const Uuid();
}

/// Adds `.date()` to an inferred string schema.
@Deprecated('Use @Check.date() from package:ack/ack.dart instead.')
@Target({TargetKind.field, TargetKind.parameter})
final class Date {
  const Date();
}

/// Adds `.notEmpty()` to an inferred string schema.
@Deprecated('Use @Check.notEmpty() from package:ack/ack.dart instead.')
@Target({TargetKind.field, TargetKind.parameter})
final class NotEmpty {
  const NotEmpty();
}

/// Adds `.minItems(count)` to an inferred collection schema.
@Deprecated('Use @Check.minItems(...) from package:ack/ack.dart instead.')
@Target({TargetKind.field, TargetKind.parameter})
final class MinItems {
  const MinItems(this.count);

  final int count;
}

/// Adds `.maxItems(count)` to an inferred collection schema.
@Deprecated('Use @Check.maxItems(...) from package:ack/ack.dart instead.')
@Target({TargetKind.field, TargetKind.parameter})
final class MaxItems {
  const MaxItems(this.count);

  final int count;
}

/// Adds `.unique()` to an inferred collection schema.
@Deprecated('Use @Check.uniqueItems() from package:ack/ack.dart instead.')
@Target({TargetKind.field, TargetKind.parameter})
final class UniqueItems {
  const UniqueItems();
}
