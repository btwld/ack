import '../schemas/schema.dart';
import 'constraint.dart';
import 'core/comparison_constraint.dart';
import 'core/pattern_constraint.dart';
import 'string/literal_constraint.dart';

/// Extension methods for [StringSchema] to provide additional validation capabilities.
extension StringSchemaExtensions on StringSchema {
  StringSchema _add(Validator<String> validator) =>
      withConstraints([validator]);

  /// {@macro email_validator}
  StringSchema email() => _add(PatternConstraint.email());

  /// {@macro email_validator}
  @Deprecated('Use email() instead for consistent naming')
  StringSchema isEmail() => email();

  /// {@macro hex_color_validator}
  StringSchema hexColor() => _add(PatternConstraint.hexColor());

  /// {@macro hex_color_validator}
  @Deprecated('Use hexColor() instead for consistent naming')
  StringSchema isHexColor() => hexColor();

  /// {@macro is_empty_validator}
  StringSchema empty() => _add(ComparisonConstraint.stringExactLength(0));

  /// {@macro is_empty_validator}
  @Deprecated('Use empty() instead for consistent naming')
  StringSchema isEmpty() => empty();

  /// {@macro min_length_validator}
  StringSchema minLength(int min) =>
      _add(ComparisonConstraint.stringMinLength(min));

  /// {@macro max_length_validator}
  StringSchema maxLength(int max) =>
      _add(ComparisonConstraint.stringMaxLength(max));

  /// {@macro not_one_of_validator}
  StringSchema notOneOf(List<String> values) =>
      _add(PatternConstraint.notEnumValues(values));

  /// {@macro is_json_validator}
  StringSchema json() => _add(PatternConstraint.json());

  /// {@macro is_json_validator}
  @Deprecated('Use json() instead for consistent naming')
  StringSchema isJson() => json();

  /// {@macro enum_validator}
  StringSchema enumString(List<String> values) =>
      _add(PatternConstraint.enumString(values));

  /// {@macro enum_validator}
  @Deprecated('Use enumString() instead for consistent naming')
  StringSchema isEnum(List<String> values) => enumString(values);

  /// {@macro not_empty_validator}
  StringSchema notEmpty() => minLength(1);

  /// {@macro not_empty_validator}
  @Deprecated('Use notEmpty() instead for consistent naming')
  StringSchema isNotEmpty() => notEmpty();

  /// {@macro date_time_validator}
  StringSchema dateTime() => _add(PatternConstraint.dateTime());

  /// {@macro date_validator}
  StringSchema date() => _add(PatternConstraint.date());

  /// {@macro date_time_validator}
  @Deprecated('Use dateTime() instead for consistent naming')
  StringSchema isDateTime() => dateTime();

  /// {@macro date_time_validator}
  @Deprecated('Use dateTime() instead for proper camelCase naming')
  StringSchema datetime() => dateTime();

  /// {@macro date_validator}
  @Deprecated('Use date() instead for consistent naming')
  StringSchema isDate() => date();

  /// {@macro time_validator}
  StringSchema time() => _add(PatternConstraint.time());

  /// {@macro uri_validator}
  StringSchema uri() => _add(PatternConstraint.uri());

  /// {@macro uuid_validator}
  StringSchema uuid() => _add(PatternConstraint.uuid());

  /// {@macro ipv4_validator}
  StringSchema ipv4() => _add(PatternConstraint.ipv4());

  /// {@macro ipv6_validator}
  StringSchema ipv6() => _add(PatternConstraint.ipv6());

  /// {@macro hostname_validator}
  StringSchema hostname() => _add(PatternConstraint.hostname());

  /// Validates that the string fully matches a pattern.
  ///
  /// This is useful for validating that a string conforms to a specific format,
  /// such as alphanumeric characters only, date formats, etc.
  ///
  /// The pattern is automatically anchored with ^ and $ if not already present,
  /// ensuring the entire string matches the pattern.
  ///
  /// Example:
  /// ```dart
  /// // Username must be alphanumeric with underscores
  /// final usernameSchema = Ack.string.matches(r'[a-zA-Z0-9_]+');
  ///
  /// // Date in YYYY-MM-DD format
  /// final dateSchema = Ack.string.matches(r'\d{4}-\d{2}-\d{2}');
  /// ```
  StringSchema matches(String pattern, {String? example}) {
    // Ensure the pattern is anchored for full string validation
    String fullPattern = pattern;
    if (!pattern.startsWith('^')) {
      fullPattern = '^$fullPattern';
    }
    if (!pattern.endsWith(r'$')) {
      fullPattern = fullPattern + r'$';
    }

    return constrain(
      PatternConstraint.regex(
        fullPattern,
        patternName: 'matches',
        example: example ?? 'Example matching $pattern',
      ),
    );
  }

  /// Validates that the string contains a pattern.
  ///
  /// This is useful for validating that a string contains certain characters,
  /// like uppercase letters, digits, etc.
  ///
  /// Example:
  /// ```dart
  /// // Password must contain at least one uppercase letter
  /// final passwordSchema = Ack.string.contains(r'[A-Z]');
  /// ```
  StringSchema contains(String pattern, {String? example}) {
    // For partial matching, we use .*pattern.* to match anywhere in the string
    final cleanPattern = pattern.replaceAll(r'^', '').replaceAll(r'$', '');
    final wrappedPattern = r'^.*' + cleanPattern + r'.*$';

    return constrain(
      PatternConstraint.regex(
        wrappedPattern,
        patternName: 'contains',
        example: example ?? 'Example containing $pattern',
      ),
    );
  }

  /// Validates that the string exactly equals the provided value.
  ///
  /// This is particularly useful for discriminator fields in discriminated schemas.
  ///
  /// Example:
  /// ```dart
  /// // Type must be exactly 'user'
  /// final typeSchema = Ack.string.literal('user');
  /// ```
  StringSchema literal(String value) {
    return _add(StringLiteralConstraint(value));
  }
}
