part of '../../ack.dart';

/// Provides validation methods for [StringSchema].
extension StringSchemaValidatorExt on StringSchema {
  /// {@macro string_email_validator}
  StringSchema isEmail() => withConstraints([EmailStringValidator()]);

  /// {@macro string_hex_color_validator}
  StringSchema isHexColor() => withConstraints([HexColorStringValidator()]);

  /// {@macro string_is_empty_validator}
  StringSchema isEmpty() => withConstraints([const IsEmptyStringValidator()]);

  /// {@macro string_min_length_validator}
  StringSchema minLength(int min) =>
      withConstraints([MinLengthStringValidator(min)]);

  /// {@macro string_max_length_validator}
  StringSchema maxLength(int max) =>
      withConstraints([MaxLengthStringValidator(max)]);

  /// {@macro string_one_of_validator}
  StringSchema oneOf(List<String> values) =>
      withConstraints([OneOfStringValidator(values)]);

  /// {@macro string_not_one_of_validator}
  StringSchema notOneOf(List<String> values) =>
      withConstraints([NotOneOfStringValidator(values)]);

  /// {@macro enum_string_validator}
  StringSchema isEnum(List<String> values) =>
      withConstraints([EnumStringValidator(values)]);

  /// {@macro string_not_empty_validator}
  StringSchema isNotEmpty() =>
      withConstraints([const NotEmptyStringValidator()]);

  /// {@macro date_time_string_validator}
  StringSchema isDateTime() =>
      withConstraints([const DateTimeStringValidator()]);

  /// {@macro date_string_validator}
  StringSchema isDate() => withConstraints([const DateStringValidator()]);
}

/// {@template date_time_string_validator}
/// Validates that the input string can be parsed into a [DateTime] object.
///
/// Equivalent of calling `DateTime.tryParse(value) != null`
/// {@endtemplate}
class DateTimeStringValidator extends OpenApiConstraintValidator<String> {
  const DateTimeStringValidator();

  @override
  bool isValid(String value) {
    final dateTime = DateTime.tryParse(value);

    return dateTime != null;
  }

  @override
  ConstraintError onError(String value) {
    return buildError(
      message:
          'Invalid date format. Expected a valid ISO 8601 date string (e.g. 2023-01-01T00:00:00.000Z)',
      context: {
        'value': value,
        'expected_format': 'ISO 8601',
        'example': '2023-01-01T00:00:00.000Z',
      },
    );
  }

  @override
  Map<String, Object?> toSchema() => {'format': 'date-time'};
  @override
  String get name => 'datetime';

  @override
  String get description => 'Must be a valid date time string';
}

/// {@template date_string_validator}
/// Validates that the input string can be parsed into a `2017-07-21
/// {@endtemplate}
class DateStringValidator extends OpenApiConstraintValidator<String> {
  const DateStringValidator();

  @override
  bool isValid(String value) {
    // Attempt to parse the input string using DateTime.tryParse
    final date = DateTime.tryParse(value);
    if (date == null) {
      // Parsing failed (invalid date or format)
      return false;
    }
    // Reconstruct the date in 'yyyy-MM-dd' format
    final formatted = '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    // Check if the reconstructed string matches the input
    return formatted == value;
  }

  @override
  ConstraintError onError(String value) {
    return buildError(
      message: 'Invalid date format. Expected a valid YYYY-MM-DD date string',
      context: {
        'value': value,
        'expected_format': 'YYYY-MM-DD',
        'example': '2017-07-21',
      },
    );
  }

  @override
  Map<String, Object?> toSchema() => {'format': 'date'};

  @override
  String get name => 'date';

  @override
  String get description => 'Must be a valid date string in YYYY-MM-DD format';
}

/// {@template enum_string_validator}
/// Validates that the input string is one of the allowed enum values
///
/// Equivalent of calling `enumValues.contains(value)`
/// {@endtemplate}
class EnumStringValidator extends OpenApiConstraintValidator<String> {
  final List<String> enumValues;
  const EnumStringValidator(this.enumValues);

  @override
  bool isValid(String value) => enumValues.contains(value);

  @override
  ConstraintError onError(String value) {
    return buildError(
      message:
          'Value "$value" is not a valid enum value. Must be one of: ${enumValues.join(', ')}',
      context: {
        'value': value,
        'closest_match': findClosestStringMatch(value, enumValues),
        'enumValues': enumValues,
        'total_allowed_values': enumValues.length,
      },
    );
  }

  @override
  Map<String, Object?> toSchema() => {'enum': enumValues};

  @override
  String get name => 'string_enum';

  @override
  String get description => 'Must be one of: ${enumValues.join(', ')}';
}

/// {@template string_email_validator}
/// Validates that the input string matches an email pattern
///
/// Uses regex pattern: `^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$`
/// {@endtemplate}
class EmailStringValidator extends RegexPatternStringValidator {
  EmailStringValidator()
      : super(
          patternName: 'email',
          pattern: r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
          example: 'example@domain.com',
        );
}

/// {@template string_hex_color_validator}
/// Validates that the input string matches a hex color pattern
///
/// Uses regex pattern: `^#?([0-9a-fA-F]{3}|[0-9a-fA-F]{6})$`
/// {@endtemplate}
class HexColorStringValidator extends RegexPatternStringValidator {
  HexColorStringValidator()
      : super(
          patternName: 'hex_color',
          example: '#f0f0f0',
          pattern: r'^#?([0-9a-fA-F]{3}|[0-9a-fA-F]{6})$',
        );
}

/// {@template string_one_of_validator}
/// Validates that the input string exactly matches one of the allowed values
///
/// Uses a regex pattern to match the exact string against the allowed values
/// Example: For values ['a', 'b', 'c'], pattern will be '^(a|b|c)$'
/// {@endtemplate}
class OneOfStringValidator extends RegexPatternStringValidator {
  final List<String> values;
  OneOfStringValidator(this.values)
      : super(
          patternName: 'one_of_values',
          pattern: '^(${values.map((e) => RegExp.escape(e)).join('|')})\$',
          example: values.first,
        );

  @override
  bool isValid(String value) => values.contains(value);

  @override
  ConstraintError onError(String value) {
    return buildError(
      message:
          'Value "$value" is not allowed. Must be one of: ${values.join(', ')}',
      context: {
        'value': value,
        'allowed_values': values,
        'total_allowed_values': values.length,
        'closest_match': findClosestStringMatch(value, values),
      },
    );
  }

  @override
  String get name => 'string_one_of';

  @override
  String get description => 'Must be one of: ${values.join(', ')}';
}

/// {@template string_not_one_of_validator}
/// Validates that the input string is not one of the disallowed values
///
/// Uses a regex pattern to match the exact string against the disallowed values
/// Example: For values ['a', 'b', 'c'], pattern will be '^(?!a|b|c).*$'
/// {@endtemplate}
class NotOneOfStringValidator extends RegexPatternStringValidator {
  final List<String> values;
  NotOneOfStringValidator(this.values)
      : super(
          patternName: 'not_one_of_values',
          pattern: '^(?!${values.map((e) => RegExp.escape(e)).join('|')}).*\$',
          example: 'any_value_except_${values.first}',
        );

  @override
  bool isValid(String value) => !values.contains(value);

  @override
  ConstraintError onError(String value) {
    return buildError(
      message:
          'Value "$value" is not allowed. Must NOT be one of: ${values.join(', ')}',
      context: {
        'value': value,
        'disallowed_values': values,
        'total_disallowed_values': values.length,
        'closest_match': findClosestStringMatch(value, values),
      },
    );
  }

  @override
  String get name => 'string_not_one_of';

  @override
  String get description => 'Must NOT be one of: ${values.join(', ')}';
}

/// {@template string_not_empty_validator}
/// Validates that the input string is not empty
///
/// Equivalent of calling `value.isNotEmpty`
/// {@endtemplate}
class NotEmptyStringValidator extends ConstraintValidator<String> {
  const NotEmptyStringValidator();

  @override
  bool isValid(String value) => value.isNotEmpty;

  @override
  ConstraintError onError(String value) {
    return buildError(
      message: 'String cannot be empty',
      context: {
        'value': value,
        'value_length': value.length,
        'requirement': 'String must contain at least one character',
      },
    );
  }

  @override
  String get name => 'string_not_empty';

  @override
  String get description => 'String cannot be empty';
}

/// Base class for regex-based string validators
class RegexPatternStringValidator extends OpenApiConstraintValidator<String> {
  final String patternName;
  final String pattern;
  final String example;
  RegexPatternStringValidator({
    required this.patternName,
    required this.pattern,
    required this.example,
  }) {
    // Assert that string is not empty
    // and taht it starts with ^ and ends with $ for a complete match
    if (pattern.isEmpty) {
      throw ArgumentError('Pattern cannot be empty');
    }
    if (!pattern.startsWith('^') || !pattern.endsWith(r'$')) {
      throw ArgumentError(r'Pattern must start with ^ and end with $');
    }
  }

  @override
  bool isValid(String value) {
    try {
      final regex = RegExp(pattern);

      return regex.hasMatch(value);
    } catch (e) {
      return false;
    }
  }

  @override
  ConstraintError onError(String value) {
    return buildError(
      message:
          'Invalid $patternName format. The string must match the pattern: $pattern',
      context: {
        'pattern_name': patternName,
        'pattern': pattern,
        'value': value,
        'example': example,
      },
    );
  }

  @override
  Map<String, Object?> toSchema() => {'pattern': pattern, 'format': name};

  @override
  String get name => patternName;

  @override
  String get description =>
      'Must match the pattern: $patternName. Example $example';
}

/// {@template string_is_empty_validator}
/// Validates that the input string is empty
///
/// Equivalent of calling `value.isEmpty`
/// {@endtemplate}
class IsEmptyStringValidator extends ConstraintValidator<String> {
  const IsEmptyStringValidator();

  @override
  bool isValid(String value) => value.isEmpty;

  @override
  ConstraintError onError(String value) {
    return buildError(
      message: 'String must be empty',
      context: {
        'value': value,
        'value_length': value.length,
        'requirement': 'String length must be 0',
      },
    );
  }

  @override
  String get name => 'string_is_empty';

  @override
  String get description => 'String must be empty';
}

/// {@template string_min_length_validator}
/// Validates that the input string length is at least a certain value
///
/// Equivalent of calling `value.length >= min`
/// {@endtemplate}
class MinLengthStringValidator extends OpenApiConstraintValidator<String> {
  final int min;
  const MinLengthStringValidator(this.min);

  @override
  bool isValid(String value) => value.length >= min;

  @override
  ConstraintError onError(String value) {
    return buildError(
      message: 'String is too short. Minimum length is $min characters',
      context: {
        'value': value,
        'current_length': value.length,
        'min_length': min,
        'characters_needed': min - value.length,
      },
    );
  }

  @override
  Map<String, Object?> toSchema() => {'minLength': min};

  @override
  String get name => 'string_min_length';

  @override
  String get description => 'String must be at least $min characters long';
}

/// {@template string_max_length_validator}
/// Validates that the input string length is at most a certain value
///
/// Equivalent of calling `value.length <= max`
/// {@endtemplate}
class MaxLengthStringValidator extends OpenApiConstraintValidator<String> {
  final int max;
  const MaxLengthStringValidator(this.max);

  @override
  bool isValid(String value) => value.length <= max;

  @override
  ConstraintError onError(String value) {
    return buildError(
      message: 'String is too long. Maximum length is $max characters',
      context: {
        'value': value,
        'current_length': value.length,
        'max_length': max,
        'excess_characters': value.length - max,
        'truncated_value': value.substring(0, max),
      },
    );
  }

  @override
  Map<String, Object?> toSchema() => {'maxLength': max};

  @override
  String get name => 'string_max_length';

  @override
  String get description => 'String must be at most $max characters long';
}
