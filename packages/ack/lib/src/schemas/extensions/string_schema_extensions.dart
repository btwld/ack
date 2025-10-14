import '../../constraints/core/comparison_constraint.dart';
import '../../constraints/core/ip_constraint.dart';
import '../../constraints/core/pattern_constraint.dart';
import '../../constraints/string/literal_constraint.dart';
import '../schema.dart';
import 'ack_schema_extensions.dart';

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

  /// Adds a constraint that the string must not be empty.
  StringSchema notEmpty() {
    return minLength(1);
  }

  /// Adds a constraint that the string must be a valid email address.
  StringSchema email() {
    return withConstraint(PatternConstraint.email());
  }

  /// Adds a constraint that the string must be a valid URL.
  StringSchema url() {
    return withConstraint(PatternConstraint.uri());
  }

  /// Adds a constraint that the string must be a valid UUID.
  StringSchema uuid() {
    return withConstraint(PatternConstraint.uuid());
  }

  /// Adds a constraint that the string must match the given regex pattern.
  /// Patterns are automatically anchored (^ and $) to match the entire string.
  /// Use [contains] for partial matching anywhere in the string.
  StringSchema matches(String pattern, {String? example, String? message}) {
    // Auto-anchor the pattern for full-string matching
    final anchoredPattern = _anchorPattern(pattern);
    final constraint = PatternConstraint.regex(anchoredPattern, example: example);

    return constrain(constraint, message: message) as StringSchema;
  }

  /// Adds a constraint that the string must contain the given [pattern] somewhere.
  StringSchema contains(String pattern, {String? example, String? message}) {
    return constrain(
          PatternConstraint.contains(pattern, example: example),
          message: message,
        )
        as StringSchema;
  }

  /// Adds a constraint that the string must be a valid ISO 8601 date-time.
  StringSchema datetime() {
    return withConstraint(PatternConstraint.dateTimeIso8601());
  }

  /// Adds a constraint that the string must be a valid ISO 8601 date (YYYY-MM-DD).
  StringSchema date() {
    return withConstraint(PatternConstraint.dateIso8601());
  }

  /// Adds a constraint that the string must be a valid time (HH:MM:SS).
  StringSchema time() {
    return withConstraint(PatternConstraint.time());
  }

  /// Adds a constraint that the string must start with [value].
  StringSchema startsWith(String value) {
    return withConstraint(PatternConstraint.startsWith(value));
  }

  /// Adds a constraint that the string must end with [value].
  StringSchema endsWith(String value) {
    return withConstraint(PatternConstraint.endsWith(value));
  }

  /// Adds a constraint that the string must be a valid URI.
  StringSchema uri() {
    return withConstraint(PatternConstraint.uri());
  }

  /// Adds a constraint that the string must be a valid IP address.
  /// If [version] is provided, it must be 4 or 6.
  StringSchema ip({int? version}) {
    return withConstraint(IpConstraint(version: version));
  }

  /// Adds a constraint that the string must be a valid IPv4 address.
  StringSchema ipv4() => ip(version: 4);

  /// Adds a constraint that the string must be a valid IPv6 address.
  StringSchema ipv6() => ip(version: 6);

  /// Adds a constraint that the string must be one of the allowed values.
  StringSchema enumString(List<String> allowedValues) {
    return withConstraint(PatternConstraint.enumString(allowedValues));
  }

  /// Adds a constraint that the string must be exactly equal to [value].
  /// Similar to Zod's `z.literal("value")`.
  StringSchema literal(String value) {
    return withConstraint(StringLiteralConstraint(value));
  }

  /// Trims leading and trailing whitespace from the string before validation.
  /// Returns a transformed schema that applies String.trim() to the input.
  TransformedSchema<String, String> trim() {
    return transform((s) => s?.trim() ?? '');
  }

  /// Converts the string to lowercase after validation.
  /// Returns a transformed schema that applies String.toLowerCase() to the input.
  TransformedSchema<String, String> toLowerCase() {
    return transform((s) => s?.toLowerCase() ?? '');
  }

  /// Converts the string to uppercase after validation.
  /// Returns a transformed schema that applies String.toUpperCase() to the input.
  TransformedSchema<String, String> toUpperCase() {
    return transform((s) => s?.toUpperCase() ?? '');
  }

  /// Helper method to intelligently anchor a regex pattern.
  ///
  /// - If pattern already has both ^ and $, returns as-is
  /// - If partially anchored, completes the anchoring
  /// - If unanchored, wraps in non-capturing group and adds anchors
  String _anchorPattern(String pattern) {
    if (pattern.isEmpty) {
      return r'^$';
    }

    // Check if pattern has unescaped anchors
    final hasStartAnchor = pattern.startsWith('^') && !_isEscapedAtStart(pattern);
    final hasEndAnchor = pattern.endsWith(r'$') && !_isEscapedAtEnd(pattern);

    // If both anchors exist, return as-is
    if (hasStartAnchor && hasEndAnchor) {
      return pattern;
    }

    // If partially anchored, complete the anchoring
    if (hasStartAnchor && !hasEndAnchor) {
      return '$pattern\$';
    }
    if (!hasStartAnchor && hasEndAnchor) {
      return '^$pattern';
    }

    // No anchors - escape any unescaped ^ or $ in the pattern before wrapping
    final escapedPattern = _escapeInternalAnchors(pattern);
    return '^(?:$escapedPattern)\$';
  }

  /// Escapes any unescaped ^ or $ characters in the pattern
  /// to prevent them from being interpreted as anchors when wrapped
  String _escapeInternalAnchors(String pattern) {
    final buffer = StringBuffer();
    int backslashCount = 0;

    for (int i = 0; i < pattern.length; i++) {
      final char = pattern[i];

      if (char == '\\') {
        backslashCount++;
        buffer.write(char);
      } else if ((char == '^' || char == r'$') && backslashCount % 2 == 0) {
        // This is an unescaped ^ or $, so escape it
        buffer.write('\\');
        buffer.write(char);
        backslashCount = 0;
      } else {
        buffer.write(char);
        backslashCount = 0;
      }
    }

    return buffer.toString();
  }

  /// Checks if the ^ at the start of the pattern is escaped
  bool _isEscapedAtStart(String pattern) {
    if (!pattern.startsWith('^')) return false;
    // ^ at position 0 cannot be escaped by a preceding backslash
    return false;
  }

  /// Checks if the $ at the end of the pattern is escaped
  bool _isEscapedAtEnd(String pattern) {
    if (!pattern.endsWith(r'$')) return false;
    if (pattern.length < 2) return false;

    // Count preceding backslashes
    int backslashCount = 0;
    for (int i = pattern.length - 2; i >= 0; i--) {
      if (pattern[i] == '\\') {
        backslashCount++;
      } else {
        break;
      }
    }

    // If odd number of backslashes, the $ is escaped
    return backslashCount % 2 == 1;
  }
}
