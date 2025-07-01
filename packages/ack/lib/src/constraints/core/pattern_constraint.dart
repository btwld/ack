import 'dart:convert';

import '../../helpers.dart';
import '../constraint.dart';

/// Type of pattern matching operation.
enum PatternType { regex, enumString, notEnumString, format }

/// A generic constraint for string pattern/format validations.
///
/// Handles regex matching, checking against a list of allowed/disallowed enum strings,
/// and validating against predefined formats (like date, email) using either regex
/// or custom validation functions.
///
/// It will always pass if the input value is `null`.
class PatternConstraint extends Constraint<String?>
    with Validator<String?>, JsonSchemaSpec<String?> {
  final PatternType type;
  final RegExp? pattern; // For PatternType.regex
  final List<String>?
      allowedValues; // For PatternType.enumString, PatternType.notEnumString
  final bool Function(String value)? formatValidator; // For PatternType.format

  final String? example; // Optional example for documentation/error messages
  final String Function(String value)? customMessageBuilder;

  // Mapping logic for "format" vs "pattern"
  static const Map<String, String> _keyToFormat = {
    'string_format_email': 'email',
    'string_format_uuid': 'uuid',
    'string_format_datetime': 'date-time',
    'string_format_date': 'date',
    'string_format_time': 'time',
    'string_format_uri': 'uri',
    'string_format_ipv4': 'ipv4',
    'string_format_ipv6': 'ipv6',
    'string_format_hostname': 'hostname',
  };

  const PatternConstraint({
    required super.constraintKey,
    required super.description,
    required this.type,
    this.pattern,
    this.allowedValues,
    this.formatValidator,
    this.example,
    this.customMessageBuilder,
  }) : assert(
          (type == PatternType.regex && pattern != null) ||
              ((type == PatternType.enumString ||
                      type == PatternType.notEnumString) &&
                  allowedValues != null) ||
              (type == PatternType.format && formatValidator != null),
          'Pattern, allowedValues, or formatValidator must be provided based on type.',
        );

  // --- Factory methods ---
  static PatternConstraint regex(
    String regexPattern, {
    String? patternName,
    String? example,
  }) =>
      PatternConstraint(
        type: PatternType.regex,
        pattern: RegExp(regexPattern),
        constraintKey: patternName != null
            ? 'string_pattern_$patternName'
            : 'custom_regex_pattern',
        description: patternName != null
            ? 'Must match the $patternName pattern.'
            : 'Must match regex: $regexPattern',
        example: example,
      );

  static PatternConstraint email() => PatternConstraint(
        type: PatternType.regex,
        pattern: RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'),
        constraintKey: 'string_format_email',
        description: 'Must be a valid email address.',
        example: 'user@example.com',
        customMessageBuilder: (v) =>
            'Invalid email format. Expected format like user@example.com, got "$v".',
      );

  static PatternConstraint uuid() => PatternConstraint(
        type: PatternType.regex,
        pattern: RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
        ),
        constraintKey: 'string_format_uuid',
        description: 'Must be a valid UUID.',
        example: '123e4567-e89b-12d3-a456-426614174000',
        customMessageBuilder: (v) => 'Invalid UUID format, got "$v".',
      );

  static PatternConstraint hexColor() => PatternConstraint(
        type: PatternType.regex,
        pattern: RegExp(r'^#?([0-9a-fA-F]{3}|[0-9a-fA-F]{6})$'),
        constraintKey: 'string_format_hexcolor',
        description: 'Must be a valid hex color code (e.g., #RRGGBB or #RGB).',
        example: '#FF0000',
        customMessageBuilder: (v) => 'Invalid hex color format, got "$v".',
      );

  static PatternConstraint enumString(List<String> values) => PatternConstraint(
        type: PatternType.enumString,
        allowedValues: values,
        constraintKey: 'string_enum',
        description: 'Must be one of: ${values.join(", ")}.',
        customMessageBuilder: (v) {
          final closest = findClosestStringMatch(v, values);
          final suggestion = closest != null && closest != v
              ? ' Did you mean "$closest"?'
              : '';

          return 'Value "$v" is not one of the allowed values: ${values.map((e) => '"$e"').join(', ')}.$suggestion';
        },
      );

  static PatternConstraint notEnumString(List<String> disallowedValues) =>
      PatternConstraint(
        type: PatternType.notEnumString,
        allowedValues: disallowedValues,
        constraintKey: 'string_not_enum',
        description: 'Must not be one of: ${disallowedValues.join(", ")}.',
        customMessageBuilder: (v) =>
            'Value "$v" is disallowed. Cannot be one of: ${disallowedValues.map((e) => '"$e"').join(', ')}.',
      );

  static PatternConstraint dateTimeIso8601() => PatternConstraint(
        type: PatternType.format,
        formatValidator: (v) =>
            DateTime.tryParse(v)?.toIso8601String() == v ||
            DateTime.tryParse(v) !=
                null, // Stricter check for ISO8601, but allow with timezone
        constraintKey: 'string_format_datetime',
        description: 'Must be a valid ISO 8601 date-time string.',
        example: '2023-10-27T10:30:00Z',
        customMessageBuilder: (v) =>
            'Invalid ISO 8601 date-time format, got "$v".',
      );

  static PatternConstraint dateIso8601() => PatternConstraint(
        type: PatternType.format,
        formatValidator: (v) {
          if (v.length != 10) return false;
          final date = DateTime.tryParse(v);
          if (date == null) return false;
          // Check if it's just a date part and matches YYYY-MM-DD
          try {
            return date.toIso8601String().startsWith(v);
          } catch (_) {
            return false;
          }
        },
        constraintKey: 'string_format_date',
        description: 'Must be a valid ISO 8601 date string (YYYY-MM-DD).',
        example: '2023-10-27',
        customMessageBuilder: (v) =>
            'Invalid ISO 8601 date format (YYYY-MM-DD), got "$v".',
      );

  static PatternConstraint jsonString() => PatternConstraint(
        type: PatternType.format,
        formatValidator: (v) {
          try {
            jsonDecode(v);

            return true;
          } catch (_) {
            return false;
          }
        },
        constraintKey: 'string_format_json',
        description: 'Must be a valid JSON formatted string.',
        customMessageBuilder: (v) => 'Invalid JSON string format.',
      );

  @override
  bool isValid(String? value) {
    if (value == null) {
      // This constraint validates the value, not its nullability.
      return true;
    }
    switch (type) {
      case PatternType.regex:
        return pattern!.hasMatch(value);
      case PatternType.enumString:
        return allowedValues!.contains(value);
      case PatternType.notEnumString:
        return !allowedValues!.contains(value);
      case PatternType.format:
        return formatValidator!(value);
    }
  }

  @override
  String buildMessage(String? value) {
    // This method is only called if isValid returns false, so value is non-null.
    final nonNullValue = value!;
    if (customMessageBuilder != null) {
      return customMessageBuilder!(nonNullValue);
    }
    // Default messages
    switch (type) {
      case PatternType.regex:
        return 'Value "$nonNullValue" does not match required pattern${example != null ? " (e.g., $example)" : ""}.';
      case PatternType.enumString:
        final closest = findClosestStringMatch(nonNullValue, allowedValues!);
        final suggestion = closest != null && closest != nonNullValue
            ? ' Did you mean "$closest"?'
            : '';

        return 'Value "$nonNullValue" is not one of the allowed values: ${allowedValues!.map((e) => '"$e"').join(', ')}.$suggestion';
      case PatternType.notEnumString:
        return 'Value "$nonNullValue" is disallowed. Cannot be one of: ${allowedValues!.map((e) => '"$e"').join(', ')}.';
      case PatternType.format:
        return 'Value "$nonNullValue" is not a valid ${constraintKey.replaceFirst("string_format_", "")}${example != null ? " (e.g., $example)" : ""}.';
    }
  }

  @override
  Map<String, Object?> buildContext(String? value) {
    final baseContext = super.buildContext(value);
    if (value != null &&
        type == PatternType.enumString &&
        allowedValues != null) {
      final closestMatch = findClosestStringMatch(value, allowedValues!);

      return {
        ...baseContext,
        'allowedValues': allowedValues,
        if (closestMatch != null) 'closestMatchSuggestion': closestMatch,
      };
    }

    return baseContext;
  }

  @override
  Map<String, Object?> toJsonSchema() {
    switch (type) {
      case PatternType.regex:
        final standardFormat = _keyToFormat[constraintKey];
        if (standardFormat != null) {
          return {'format': standardFormat};
        }

        return {'pattern': pattern!.pattern};
      case PatternType.enumString:
        return {'enum': allowedValues};
      case PatternType.notEnumString:
        return {
          'not': {'enum': allowedValues},
        };
      case PatternType.format:
        final standardFormat = _keyToFormat[constraintKey];
        if (standardFormat != null) {
          return {'format': standardFormat};
        }

        return {};
    }
  }
}
