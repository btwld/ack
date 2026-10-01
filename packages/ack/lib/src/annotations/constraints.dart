import 'package:meta/meta_meta.dart';

/// Adds `.min(value)` to an inferred numeric schema.
@Target({TargetKind.field, TargetKind.parameter})
final class Min {
  const Min(this.value);

  final num value;
}

/// Adds `.max(value)` to an inferred numeric schema.
@Target({TargetKind.field, TargetKind.parameter})
final class Max {
  const Max(this.value);

  final num value;
}

/// Adds `.multipleOf(value)` to an inferred numeric schema.
@Target({TargetKind.field, TargetKind.parameter})
final class MultipleOf {
  const MultipleOf(this.value);

  final num value;
}

/// Adds `.positive()` to an inferred numeric schema.
@Target({TargetKind.field, TargetKind.parameter})
final class Positive {
  const Positive();
}

/// Adds `.negative()` to an inferred numeric schema.
@Target({TargetKind.field, TargetKind.parameter})
final class Negative {
  const Negative();
}

/// Adds `.minLength(length)` to an inferred string schema.
@Target({TargetKind.field, TargetKind.parameter})
final class MinLength {
  const MinLength(this.length);

  final int length;
}

/// Adds `.maxLength(length)` to an inferred string schema.
@Target({TargetKind.field, TargetKind.parameter})
final class MaxLength {
  const MaxLength(this.length);

  final int length;
}

/// Adds `.matches(pattern)` to an inferred string schema.
@Target({TargetKind.field, TargetKind.parameter})
final class Pattern {
  const Pattern(this.pattern);

  final String pattern;
}

/// Adds `.email()` to an inferred string schema.
@Target({TargetKind.field, TargetKind.parameter})
final class Email {
  const Email();
}

/// Adds `.url()` to an inferred string schema.
@Target({TargetKind.field, TargetKind.parameter})
final class Url {
  const Url();
}

/// Adds `.uuid()` to an inferred string schema.
@Target({TargetKind.field, TargetKind.parameter})
final class Uuid {
  const Uuid();
}

/// Adds `.date()` to an inferred string schema.
@Target({TargetKind.field, TargetKind.parameter})
final class Date {
  const Date();
}

/// Adds `.notEmpty()` to an inferred string schema.
@Target({TargetKind.field, TargetKind.parameter})
final class NotEmpty {
  const NotEmpty();
}

/// Adds `.minItems(count)` to an inferred collection schema.
@Target({TargetKind.field, TargetKind.parameter})
final class MinItems {
  const MinItems(this.count);

  final int count;
}

/// Adds `.maxItems(count)` to an inferred collection schema.
@Target({TargetKind.field, TargetKind.parameter})
final class MaxItems {
  const MaxItems(this.count);

  final int count;
}

/// Adds `.unique()` to an inferred collection schema.
@Target({TargetKind.field, TargetKind.parameter})
final class UniqueItems {
  const UniqueItems();
}
