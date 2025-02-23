part of '../ack_base.dart';

final class StringSchema extends Schema<StringSchema, String> {
  const StringSchema({super.nullable, super.constraints});

  @override
  String? _tryParse(Object value) {
    if (value is String) return value;
    return null;
  }

  @override
  StringSchema copyWith({
    bool? nullable,
    List<ConstraintsValidator<String>>? constraints,
  }) {
    return StringSchema(
      nullable: nullable ?? _nullable,
      constraints: constraints ?? _constraints,
    );
  }
}

extension StringSchemaExt on StringSchema {
  StringSchema isEmail() => withConstraints([const EmailValidator()]);

  StringSchema isHexColor() => withConstraints([const HexColorValidator()]);

  StringSchema isEmpty() => withConstraints([const IsEmptyValidator()]);

  StringSchema minLength(int min) => withConstraints([MinLengthValidator(min)]);

  StringSchema maxLength(int max) => withConstraints([MaxLengthValidator(max)]);

  StringSchema oneOf(List<String> values) =>
      withConstraints([OneOfValidator(values)]);

  StringSchema notOneOf(List<String> values) =>
      withConstraints([NotOneOfValidator(values)]);

  StringSchema isEnum(List<String> values) =>
      withConstraints([EnumValidator(values)]);

  StringSchema isUri() => withConstraints([const UriValidator()]);

  StringSchema isNotEmpty() => withConstraints([const NotEmptyValidator()]);

  StringSchema isDateTime() => withConstraints([const DateTimeValidator()]);
}

/// Validates that the input string can be parsed into a [DateTime] object.
class DateTimeValidator extends ConstraintsValidator<String> {
  const DateTimeValidator()
      : super(
          type: 'datetime',
          description: 'Must be a valid date time string',
        );

  /// Validates the input string and returns null if valid, or an error message if invalid.
  @override
  ConstraintsValidationError? validate(String value) {
    final dateTime = DateTime.tryParse(value);
    if (dateTime != null) {
      return null;
    }
    return ConstraintsValidationError(
      type: type,
      message:
          'Invalid date format. Expected a valid ISO 8601 date string (e.g. 2023-01-01T00:00:00.000Z)',
      context: {
        'value': value,
        'expected_format': 'ISO 8601',
        'example': '2023-01-01T00:00:00.000Z'
      },
    );
  }
}

class EnumValidator extends ConstraintsValidator<String> {
  final List<String> enumValues;
  EnumValidator(this.enumValues)
      : super(
          type: 'string_enum',
          description: 'Must be one of: ${enumValues.join(', ')}',
        );

  @override
  ConstraintsValidationError? validate(String value) {
    if (enumValues.contains(value)) {
      return null;
    }
    return ConstraintsValidationError(
      type: type,
      message:
          'Value "$value" is not a valid enum value. Must be one of: ${enumValues.join(', ')}',
      context: {
        'value': value,
        'closest_match': findClosestStringMatch(value, enumValues),
        'enumValues': enumValues,
        'total_allowed_values': enumValues.length
      },
    );
  }
}

class EmailValidator extends RegexValidator {
  const EmailValidator()
      : super(
          name: 'email',
          pattern: r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
          example: 'example@domain.com',
        );
}

class UriValidator extends ConstraintsValidator<String> {
  const UriValidator()
      : super(
          type: 'string_uri',
          description: 'Must be a valid URI',
        );

  @override
  ConstraintsValidationError? validate(String value) {
    if (Uri.tryParse(value) == null) {
      return ConstraintsValidationError(
        type: type,
        message:
            'Invalid URI format for $value, expected a valid URI string https://example.com',
        context: {
          'value': value,
        },
      );
    }
    return null;
  }
}

class HexColorValidator extends RegexValidator {
  const HexColorValidator()
      : super(
          name: 'hex color',
          example: '#ff0000',
          pattern: r'^#?([0-9a-fA-F]{3}|[0-9a-fA-F]{6})$',
        );
}

class OneOfValidator extends ConstraintsValidator<String> {
  final List<String> values;
  OneOfValidator(this.values)
      : super(
          type: 'string_one_of',
          description: 'Must be one of: ${values.join(', ')}',
        );

  @override
  ConstraintsValidationError? validate(String value) {
    if (values.contains(value)) {
      return null;
    }
    return ConstraintsValidationError(
      type: type,
      message:
          'Value "$value" is not allowed. Must be one of: ${values.join(', ')}',
      context: {
        'value': value,
        'allowed_values': values,
        'total_allowed_values': values.length,
        'closest_match': findClosestStringMatch(value, values)
      },
    );
  }
}

class NotOneOfValidator extends ConstraintsValidator<String> {
  final List<String> values;
  NotOneOfValidator(this.values)
      : super(
          type: 'string_not_one_of',
          description: 'Must NOT be one of: ${values.join(', ')}',
        );

  @override
  ConstraintsValidationError? validate(String value) {
    if (values.contains(value)) {
      return ConstraintsValidationError(
        type: type,
        message:
            'Value "$value" is not allowed. Must NOT be one of: ${values.join(', ')}',
        context: {
          'value': value,
          'disallowed_values': values,
          'total_disallowed_values': values.length,
          'suggestion':
              'Please choose a value that is not in the disallowed list'
        },
      );
    }
    return null;
  }
}

class NotEmptyValidator extends ConstraintsValidator<String> {
  const NotEmptyValidator()
      : super(
          type: 'string_not_empty',
          description: 'String cannot be empty',
        );

  @override
  ConstraintsValidationError? validate(String value) {
    return value.isEmpty
        ? ConstraintsValidationError(
            type: type,
            message: 'String cannot be empty',
            context: {
              'value': value,
              'value_length': value.length,
              'requirement': 'String must contain at least one character'
            },
          )
        : null;
  }
}

class RegexValidator extends ConstraintsValidator<String> {
  final String name;
  final String pattern;
  final String example;
  const RegexValidator({
    required this.name,
    required this.pattern,
    required this.example,
  }) : super(
          type: 'regex',
          description: 'Must match the pattern: $name. Example $example',
        );
  @override
  ConstraintsValidationError? validate(String value) {
    try {
      final regex = RegExp(pattern);
      if (!regex.hasMatch(value)) {
        throw Exception('Invalid regex pattern: $pattern');
      }
      return null;
    } catch (e) {
      return ConstraintsValidationError(
        type: type,
        message:
            'Invalid $name format. The string must match the pattern: $pattern',
        context: {
          'value': value,
          'pattern': pattern,
          'validator_name': name,
          'example': example,
          'value_length': value.length,
          'matches_partially': false,
          'error': e is FormatException ? e.toString() : null
        },
      );
    }
  }
}

class IsEmptyValidator extends ConstraintsValidator<String> {
  const IsEmptyValidator()
      : super(
          type: 'string_is_empty',
          description: 'String must be empty',
        );

  @override
  ConstraintsValidationError? validate(String value) {
    return value.isEmpty
        ? null
        : ConstraintsValidationError(
            type: type,
            message: 'String must be empty',
            context: {
              'value': value,
              'value_length': value.length,
              'requirement': 'String length must be 0'
            },
          );
  }
}

class MinLengthValidator extends ConstraintsValidator<String> {
  final int min;
  const MinLengthValidator(this.min)
      : super(
          type: 'string_min_length',
          description: 'String must be at least $min characters long',
        );

  @override
  ConstraintsValidationError? validate(String value) {
    return value.length >= min
        ? null
        : ConstraintsValidationError(
            type: type,
            message: 'String is too short. Minimum length is $min characters',
            context: {
              'value': value,
              'current_length': value.length,
              'min_length': min,
              'characters_needed': min - value.length
            },
          );
  }
}

class MaxLengthValidator extends ConstraintsValidator<String> {
  final int max;
  const MaxLengthValidator(this.max)
      : super(
          type: 'string_max_length',
          description: 'String must be at most $max characters long',
        );

  @override
  ConstraintsValidationError? validate(String value) {
    return value.length <= max
        ? null
        : ConstraintsValidationError(
            type: type,
            message: 'String is too long. Maximum length is $max characters',
            context: {
              'value': value,
              'current_length': value.length,
              'max_length': max,
              'excess_characters': value.length - max,
              'truncated_value': value.substring(0, max)
            },
          );
  }
}
