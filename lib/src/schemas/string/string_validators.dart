part of '../../ack_base.dart';

/// Validates that the input string can be parsed into a [DateTime] object.
class DateTimeValidator extends ConstraintValidator<String> {
  const DateTimeValidator();

  @override
  bool check(String value) {
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
  String get name => 'datetime';

  @override
  String get description => 'Must be a valid date time string';
}

class EnumValidator extends ConstraintValidator<String> {
  final List<String> enumValues;
  const EnumValidator(this.enumValues);

  @override
  bool check(String value) => enumValues.contains(value);

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
  String get name => 'string_enum';

  @override
  String get description => 'Must be one of: ${enumValues.join(', ')}';
}

class EmailValidator extends RegexValidator {
  const EmailValidator()
      : super(
          patternName: 'is_email',
          pattern: r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
          example: 'example@domain.com',
        );
}

class HexColorValidator extends RegexValidator {
  const HexColorValidator()
      : super(
          patternName: 'is_hex_color',
          example: '#f0f0f0',
          pattern: r'^#?([0-9a-fA-F]{3}|[0-9a-fA-F]{6})$',
        );
}

class OneOfValidator extends ConstraintValidator<String> {
  final List<String> values;
  const OneOfValidator(this.values);

  @override
  bool check(String value) => values.contains(value);

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

class NotOneOfValidator extends ConstraintValidator<String> {
  final List<String> values;
  const NotOneOfValidator(this.values);

  @override
  bool check(String value) => !values.contains(value);

  @override
  ConstraintError onError(String value) {
    return buildError(
      message:
          'Value "$value" is not allowed. Must NOT be one of: ${values.join(', ')}',
      context: {
        'value': value,
        'disallowed_values': values,
        'total_disallowed_values': values.length,
        'suggestion':
            'Please choose a value that is not in the disallowed list',
      },
    );
  }

  @override
  String get name => 'string_not_one_of';

  @override
  String get description => 'Must NOT be one of: ${values.join(', ')}';
}

class NotEmptyValidator extends ConstraintValidator<String> {
  const NotEmptyValidator();

  @override
  bool check(String value) => value.isNotEmpty;

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

class RegexValidator extends ConstraintValidator<String> {
  final String patternName;
  final String pattern;
  final String example;
  const RegexValidator({
    required this.patternName,
    required this.pattern,
    required this.example,
  });

  @override
  bool check(String value) {
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
  String get name => patternName;

  @override
  String get description =>
      'Must match the pattern: $patternName. Example $example';
}

class IsEmptyValidator extends ConstraintValidator<String> {
  const IsEmptyValidator();

  @override
  bool check(String value) => value.isEmpty;

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

class MinLengthValidator extends ConstraintValidator<String> {
  final int min;
  const MinLengthValidator(this.min);

  @override
  bool check(String value) => value.length >= min;

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
  String get name => 'string_min_length';

  @override
  String get description => 'String must be at least $min characters long';
}

class MaxLengthValidator extends ConstraintValidator<String> {
  final int max;
  const MaxLengthValidator(this.max);

  @override
  bool check(String value) => value.length <= max;

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
  String get name => 'string_max_length';

  @override
  String get description => 'String must be at most $max characters long';
}
