import '../../constraints/core/comparison_constraint.dart';
import '../../constraints/string/format_constraint.dart';
import '../../constraints/string/literal_constraint.dart';
import '../../constraints/string/string_enum_constraint.dart';
import '../schema.dart';

/// Adds fluent validation methods to [StringSchema].
extension StringSchemaExtensions on StringSchema {
  /// Adds a constraint that the string's length must be at least [n].
  StringSchema minLength(int n) {
    return withConstraint(ComparisonConstraint.stringMinLength(n));
  }

  /// Adds a constraint that the string's length must be no more than [n].
  StringSchema maxLength(int n) {
    return withConstraint(ComparisonConstraint.stringMaxLength(n));
  }

  /// Adds a constraint that the string's length must be exactly [n].
  StringSchema length(int n) {
    return withConstraint(ComparisonConstraint.stringExactLength(n));
  }

  /// Adds a constraint that the string must be a valid email address.
  StringSchema email() {
    return withConstraint(EmailConstraint());
  }

  /// Adds a constraint that the string must be a valid URL.
  StringSchema url() {
    return withConstraint(UrlConstraint());
  }

  /// Adds a constraint that the string must be a valid UUID.
  StringSchema uuid() {
    return withConstraint(UuidConstraint());
  }

  /// Adds a constraint that the string must match the given regex pattern.
  StringSchema matches(String pattern, {String? example}) {
    return withConstraint(MatchesConstraint(pattern, example: example));
  }

  /// Adds a constraint that the string must be a valid ISO 8601 date-time.
  StringSchema datetime() {
    return withConstraint(DateTimeConstraint());
  }

  /// Adds a constraint that the string must start with [value].
  StringSchema startsWith(String value) {
    return withConstraint(StartsWithConstraint(value));
  }

  /// Adds a constraint that the string must end with [value].
  StringSchema endsWith(String value) {
    return withConstraint(EndsWithConstraint(value));
  }

  /// Adds a constraint that the string must be a valid IP address.
  /// If [version] is provided, it must be 4 or 6.
  StringSchema ip({int? version}) {
    return withConstraint(IpConstraint(version: version));
  }

  /// Adds a constraint that the string must be one of the allowed values.
  StringSchema enumString(List<String> allowedValues) {
    return withConstraint(StringEnumConstraint(allowedValues));
  }

  /// Adds a constraint that the string must be exactly equal to [value].
  /// Similar to Zod's `z.literal("value")`.
  StringSchema literal(String value) {
    return withConstraint(StringLiteralConstraint(value));
  }
}
