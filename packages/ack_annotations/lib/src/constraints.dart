import 'package:meta/meta_meta.dart';

// ============================================================================
// STRING CONSTRAINTS
// ============================================================================

/// String length constraints
@Target({TargetKind.parameter})
class MinLength {
  final int length;
  const MinLength(this.length);
}

@Target({TargetKind.parameter})
class MaxLength {
  final int length;
  const MaxLength(this.length);
}

/// String format constraints
@Target({TargetKind.parameter})
class Email {
  const Email();
}

@Target({TargetKind.parameter})
class Url {
  const Url();
}

/// String pattern constraints
@Target({TargetKind.parameter})
class Pattern {
  final String pattern;
  const Pattern(this.pattern);
}

// ============================================================================
// NUMERIC CONSTRAINTS
// ============================================================================

@Target({TargetKind.parameter})
class Min {
  final num value;
  const Min(this.value);
}

@Target({TargetKind.parameter})
class Max {
  final num value;
  const Max(this.value);
}

@Target({TargetKind.parameter})
class Positive {
  const Positive();
}

@Target({TargetKind.parameter})
class MultipleOf {
  final num value;
  const MultipleOf(this.value);
}

// ============================================================================
// LIST CONSTRAINTS
// ============================================================================

@Target({TargetKind.parameter})
class MinItems {
  final int count;
  const MinItems(this.count);
}

@Target({TargetKind.parameter})
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
@Target({TargetKind.parameter})
class EnumString {
  final List<String> values;
  const EnumString(this.values);
}
