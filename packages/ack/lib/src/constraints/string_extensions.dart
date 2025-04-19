import '../schemas/schema.dart';
import 'constraint.dart';
import 'validators.dart';

/// Extension methods for [StringSchema] to provide additional validation capabilities.
extension StringSchemaExtensions on StringSchema {
  StringSchema _add(Validator<String> validator) =>
      withConstraints([validator]);

  /// {@macro email_validator}
  StringSchema isEmail() => _add(StringEmailConstraint());

  /// {@macro hex_color_validator}
  StringSchema isHexColor() => _add(StringHexColorValidator());

  /// {@macro is_empty_validator}
  StringSchema isEmpty() => _add(const StringEmptyConstraint());

  /// {@macro min_length_validator}
  StringSchema minLength(int min) => _add(StringMinLengthConstraint(min));

  /// {@macro max_length_validator}
  StringSchema maxLength(int max) => _add(StringMaxLengthConstraint(max));

  /// {@macro not_one_of_validator}
  StringSchema notOneOf(List<String> values) =>
      _add(StringNotOneOfValidator(values));

  /// {@macro is_json_validator}
  StringSchema isJson() => _add(const StringJsonValidator());

  /// {@macro enum_validator}
  StringSchema isEnum(List<String> values) =>
      _add(StringEnumConstraint(values));

  /// {@macro not_empty_validator}
  StringSchema isNotEmpty() => _add(const StringNotEmptyValidator());

  /// {@macro date_time_validator}
  StringSchema isDateTime() => _add(const StringDateTimeConstraint());

  /// {@macro date_validator}
  StringSchema isDate() => _add(const StringDateConstraint());

  /// Validates that the string contains a pattern.
  /// 
  /// This is useful for validating that a string contains certain characters,
  /// like uppercase letters, digits, etc.
  /// 
  /// Example:
  /// ```dart
  /// // Password must contain at least one uppercase letter
  /// final passwordSchema = Ack.string.matches(r'[A-Z]');
  /// ```
  StringSchema matches(String pattern, {String? example}) {
    // For partial matching, we use .*pattern.* to match anywhere in the string
    final cleanPattern = pattern.replaceAll(r'^', '').replaceAll(r'$', '');
    final wrappedPattern = r'^.*' + cleanPattern + r'.*$';
    
    return constrain(
      StringRegexConstraint(
        patternName: 'matches',
        pattern: wrappedPattern,
        example: example ?? 'Example matching $pattern',
      ),
    );
  }
}
