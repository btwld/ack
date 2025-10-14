import 'dart:convert';

import '../helpers.dart';
import 'constraint.dart';

/// Type of pattern matching operation.
enum PatternType { regex, enumString, notEnumString, format }

/// A generic constraint for string pattern/format validations.
///
/// Handles regex matching, checking against a list of allowed/disallowed enum strings,
/// and validating against predefined formats (like date, email) using either regex
/// or custom validation functions.
class PatternConstraint extends Constraint<String>
    with Validator<String>, JsonSchemaSpec<String> {
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
  }) {
    // Validate regex pattern at construction time with actionable error
    late final RegExp compiledPattern;
    try {
      compiledPattern = RegExp(regexPattern);
    } on FormatException catch (e) {
      throw ArgumentError.value(
        regexPattern,
        'regexPattern',
        'Invalid regular expression pattern: ${e.message}',
      );
    }

    return PatternConstraint(
      type: PatternType.regex,
      pattern: compiledPattern,
      constraintKey: patternName != null
          ? 'string_pattern_$patternName'
          : 'custom_regex_pattern',
      description: patternName != null
          ? 'Must match the $patternName pattern.'
          : 'Must match regex: $regexPattern',
      example: example,
    );
  }

  static PatternConstraint email() => PatternConstraint(
    type: PatternType.regex,
    pattern: RegExp(
      r'''^(?!\.)(?!.*\.\.)([A-Za-z0-9_'+\-\.]*)[A-Za-z0-9_+-]@([A-Za-z0-9][A-Za-z0-9\-]*\.)+[A-Za-z]{2,}$''',
    ),
    constraintKey: 'string_format_email',
    description: 'Must be a valid email address.',
    example: 'user@example.com',
    customMessageBuilder: (v) =>
        'Invalid email format. Expected format like user@example.com, got "$v".',
  );

  static PatternConstraint uuid() => PatternConstraint(
    type: PatternType.regex,
    pattern: RegExp(
      r'^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}|00000000-0000-0000-0000-000000000000|ffffffff-ffff-ffff-ffff-ffffffffffff)$',
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

  static PatternConstraint uri() => PatternConstraint(
    type: PatternType.format,
    formatValidator: (v) {
      final u = Uri.tryParse(v);
      return u != null && u.hasScheme && u.host.isNotEmpty;
    },
    constraintKey: 'string_format_uri',
    description: 'Must be a valid URI.',
    customMessageBuilder: (v) => 'Invalid URI format, got "$v".',
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

  static PatternConstraint notEnumString(
    List<String> disallowedValues,
  ) => PatternConstraint(
    type: PatternType.notEnumString,
    allowedValues: disallowedValues,
    constraintKey: 'string_not_enum',
    description: 'Must not be one of: ${disallowedValues.join(", ")}.',
    customMessageBuilder: (v) =>
        'Value "$v" is disallowed. Cannot be one of: ${disallowedValues.map((e) => '"$e"').join(', ')}.',
  );

  static PatternConstraint startsWith(String prefix) => PatternConstraint(
    type: PatternType.regex,
    pattern: RegExp('^${RegExp.escape(prefix)}'),
    constraintKey: 'string.startsWith',
    description: 'Value must start with "$prefix".',
    customMessageBuilder: (v) => '"$v" does not start with "$prefix".',
  );

  static PatternConstraint endsWith(String suffix) => PatternConstraint(
    type: PatternType.regex,
    pattern: RegExp('${RegExp.escape(suffix)}\$'),
    constraintKey: 'string.endsWith',
    description: 'Value must end with "$suffix".',
    customMessageBuilder: (v) => '"$v" does not end with "$suffix".',
  );

  static PatternConstraint contains(String pattern, {String? example}) =>
      PatternConstraint(
        type: PatternType.regex,
        pattern: RegExp(pattern),
        constraintKey: 'string_contains',
        description: 'Must contain pattern "$pattern".',
        example: example,
        customMessageBuilder: (v) =>
            'Value "$v" must contain pattern "$pattern".',
      );

  static PatternConstraint dateTimeIso8601() => PatternConstraint(
    type: PatternType.format,
    // RFC 3339 / ISO-8601 validation using Dart's built-in DateTime parser
    // Dart's tryParse implements RFC 3339, which is a subset of ISO-8601
    formatValidator: (v) {
      // Use Dart's built-in RFC 3339/ISO-8601 parser
      final dt = DateTime.tryParse(v);
      if (dt == null) return false;

      // Must contain 'T' separator (distinguishes datetime from date-only)
      // Must contain timezone indicator (Z or +/-HH:MM)
      final hasTimeSeparator = v.contains('T') || v.contains('t');
      final hasTimezone =
          v.endsWith('Z') ||
          v.endsWith('z') ||
          RegExp(r'[+-]\d{2}:\d{2}$').hasMatch(v);

      return hasTimeSeparator && hasTimezone;
    },
    constraintKey: 'string_format_datetime',
    description: 'Must be a valid ISO 8601 date-time string.',
    example: '2023-10-27T10:30:00Z',
    customMessageBuilder: (v) => 'Invalid ISO 8601 date-time format, got "$v".',
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

  static PatternConstraint time() => PatternConstraint(
    type: PatternType.format,
    formatValidator: (value) {
      final match = RegExp(r'^\d{2}:\d{2}:\d{2}$').firstMatch(value);
      if (match == null) return false;
      final parts = value.split(':').map(int.parse).toList();
      if (parts.length != 3) return false;
      final hours = parts[0];
      final minutes = parts[1];
      final seconds = parts[2];
      return hours >= 0 &&
          hours < 24 &&
          minutes >= 0 &&
          minutes < 60 &&
          seconds >= 0 &&
          seconds < 60;
    },
    constraintKey: 'string_format_time',
    description: 'Must be a valid time in HH:MM:SS format.',
    example: '23:59:59',
    customMessageBuilder: (value) =>
        'Invalid time format (HH:MM:SS), got "$value".',
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
  bool isValid(String value) => switch (type) {
        PatternType.regex => pattern!.hasMatch(value),
        PatternType.enumString => allowedValues!.contains(value),
        PatternType.notEnumString => !allowedValues!.contains(value),
        PatternType.format => formatValidator!(value),
      };

  @override
  String buildMessage(String value) {
    final nonNullValue = value;
    if (customMessageBuilder != null) {
      return customMessageBuilder!(nonNullValue);
    }
    // Default messages
    return switch (type) {
      PatternType.regex =>
        'Value "$nonNullValue" does not match required pattern${example != null ? " (e.g., $example)" : ""}.',
      PatternType.enumString => () {
          final closest = findClosestStringMatch(nonNullValue, allowedValues!);
          final suggestion = closest != null && closest != nonNullValue
              ? ' Did you mean "$closest"?'
              : '';

          return 'Value "$nonNullValue" is not one of the allowed values: ${allowedValues!.map((e) => '"$e"').join(', ')}.$suggestion';
        }(),
      PatternType.notEnumString =>
        'Value "$nonNullValue" is disallowed. Cannot be one of: ${allowedValues!.map((e) => '"$e"').join(', ')}.',
      PatternType.format =>
        'Value "$nonNullValue" is not a valid ${constraintKey.replaceFirst("string_format_", "")}${example != null ? " (e.g., $example)" : ""}.',
    };
  }

  @override
  Map<String, Object?> buildContext(String value) {
    final baseContext = super.buildContext(value);
    if (type == PatternType.enumString && allowedValues != null) {
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
  Map<String, Object?> toJsonSchema() => switch (type) {
        PatternType.regex => () {
            final standardFormat = _keyToFormat[constraintKey];
            if (standardFormat != null) {
              // For email and uuid, include BOTH format and pattern (match Zod)
              return {'format': standardFormat, 'pattern': pattern!.pattern};
            }

            return {'pattern': pattern!.pattern};
          }(),
        PatternType.enumString => {'enum': allowedValues},
        PatternType.notEnumString => {
            'not': {'enum': allowedValues},
          },
        PatternType.format => () {
            final standardFormat = _keyToFormat[constraintKey];
            if (standardFormat != null) {
              return {'format': standardFormat};
            }

            return <String, Object?>{};
          }(),
      };
}
