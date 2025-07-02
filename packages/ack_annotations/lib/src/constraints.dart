import 'package:meta/meta_meta.dart';

// ============================================================================
// STRING CONSTRAINTS
// ============================================================================

/// String length constraints
@Target({TargetKind.field})
class MinLength {
  final int length;
  const MinLength(this.length);
}

@Target({TargetKind.field})
class MaxLength {
  final int length;
  const MaxLength(this.length);
}

/// String format constraints
@Target({TargetKind.field})
class Email {
  const Email();
}

@Target({TargetKind.field})
class Url {
  const Url();
}

/// String pattern constraints
@Target({TargetKind.field})
class Pattern {
  final String pattern;
  const Pattern(this.pattern);
}

// ============================================================================
// NUMERIC CONSTRAINTS
// ============================================================================

@Target({TargetKind.field})
class Min {
  final num value;
  const Min(this.value);
}

@Target({TargetKind.field})
class Max {
  final num value;
  const Max(this.value);
}

@Target({TargetKind.field})
class Positive {
  const Positive();
}

@Target({TargetKind.field})
class MultipleOf {
  final num value;
  const MultipleOf(this.value);
}

// ============================================================================
// LIST CONSTRAINTS
// ============================================================================

@Target({TargetKind.field})
class MinItems {
  final int count;
  const MinItems(this.count);
}

@Target({TargetKind.field})
class MaxItems {
  final int count;
  const MaxItems(this.count);
}

// ============================================================================
// ENUM CONSTRAINTS
// ============================================================================

/// String enum constraint - accepts a list of string values
/// Generates: .enumString(['value1', 'value2', ...])
/// Usage: @EnumString(['draft', 'published', 'archived'])
/// This is for validating string fields against a set of allowed string values
@Target({TargetKind.field})
class EnumString {
  final List<String> values;
  const EnumString(this.values);
}

