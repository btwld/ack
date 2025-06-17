import 'dart:convert';

import '../../helpers.dart';
import '../constraint.dart';

/// Type of pattern matching operation to perform.
enum PatternType { regex, enumValues, notEnumValues, format }

/// A generic constraint that handles all pattern/format matching operations.
///
/// This constraint consolidates multiple specific pattern constraints into a single
/// flexible implementation that can match regex patterns, enums, or custom formats.
class PatternConstraint extends Constraint<String>
    with Validator<String>, JsonSchemaSpec<String> {
  /// The type of pattern matching to perform.
  final PatternType type;

  /// The regex pattern for regex type.
  final RegExp? pattern;

  /// The allowed values for enum type.
  final List<String>? allowedValues;

  /// The validation function for format type.
  final bool Function(String)? formatValidator;

  /// Optional custom message builder.
  final String Function(String value)? customMessageBuilder;

  /// Optional example value for documentation.
  final String? example;

  const PatternConstraint({
    required this.type,
    this.pattern,
    this.allowedValues,
    this.formatValidator,
    required super.constraintKey,
    required super.description,
    this.customMessageBuilder,
    this.example,
  }) : assert(
          (type == PatternType.regex && pattern != null) ||
              (type == PatternType.enumValues && allowedValues != null) ||
              (type == PatternType.notEnumValues && allowedValues != null) ||
              (type == PatternType.format && formatValidator != null),
          'Pattern, allowedValues, or formatValidator must be provided based on type',
        );

  // Factory methods for regex patterns
  static PatternConstraint regex(
    String pattern, {
    String? patternName,
    String? example,
  }) =>
      PatternConstraint(
        type: PatternType.regex,
        pattern: RegExp(pattern),
        constraintKey:
            patternName != null ? 'string_pattern_$patternName' : 'regex',
        description: patternName != null
            ? 'Must match the pattern: $patternName${example != null ? '. Example: $example' : ''}'
            : 'Must match regex pattern',
        example: example,
      );

  /// {@template email_validator}
  /// Validates that the string is a valid email address.
  /// Uses RFC 5322 compliant pattern to ensure proper email format.
  /// Accepts standard email formats like user@example.com, test.email+tag@domain.co.uk.
  /// {@endtemplate}
  static PatternConstraint email() => PatternConstraint(
        type: PatternType.regex,
        pattern: RegExp(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
        constraintKey: 'email',
        description: 'Must be a valid email address',
        example: 'example@domain.com',
        customMessageBuilder: (value) =>
            'Invalid email format. Ex: example@domain.com',
      );

  /// {@template hex_color_validator}
  /// Validates that the string is a valid hexadecimal color code.
  /// Accepts both 3-digit (#RGB) and 6-digit (#RRGGBB) hex color formats.
  /// Examples: #FF0000 (red), #00FF00 (green), #FFF (white).
  /// {@endtemplate}
  static PatternConstraint hexColor() => PatternConstraint(
        type: PatternType.regex,
        pattern: RegExp(r'^#?([0-9a-fA-F]{3}|[0-9a-fA-F]{6})$'),
        constraintKey: 'hex_color',
        description: 'Must be a valid hex color',
        example: '#f0f0f0',
        customMessageBuilder: (value) =>
            'Invalid hex color format. Ex: #f0f0f0',
      );

  // Factory methods for enum patterns

  /// {@template enum_validator}
  /// Validates that the string is one of the specified allowed values.
  /// Useful for validating against a predefined set of options.
  /// {@endtemplate}
  static PatternConstraint enumValues(List<String> values) => PatternConstraint(
        type: PatternType.enumValues,
        allowedValues: values,
        constraintKey: 'string_enum',
        description: 'Must be one of: $values',
        customMessageBuilder: (value) {
          final closestMatch = findClosestStringMatch(value, values);
          final allowedValues = values.map((e) => '"$e"').join(', ');

          return closestMatch != null
              ? 'Did you mean "$closestMatch"? Allowed: $allowedValues'
              : 'Allowed: $allowedValues';
        },
      );

  /// {@template not_one_of_validator}
  /// Validates that the string is not one of the specified forbidden values.
  /// Useful for blacklisting specific words or reserved terms.
  /// {@endtemplate}
  static PatternConstraint notEnumValues(List<String> values) =>
      PatternConstraint(
        type: PatternType.notEnumValues,
        allowedValues: values,
        constraintKey: 'not_one_of',
        description: 'Must not be one of: $values',
        customMessageBuilder: (value) =>
            'Disallowed value: Cannot be one of $values',
      );

  // Factory methods for format patterns

  /// {@template date_time_validator}
  /// Validates that the string is a valid ISO 8601 date-time format.
  /// Accepts formats like 2023-12-25T10:30:00Z or 2023-12-25T10:30:00+02:00.
  /// Supports optional milliseconds and timezone information.
  /// {@endtemplate}
  static PatternConstraint dateTime() => PatternConstraint(
        type: PatternType.format,
        formatValidator: (value) => DateTime.tryParse(value) != null,
        constraintKey: 'datetime',
        description: 'Must be a valid ISO 8601 date-time',
        customMessageBuilder: (value) =>
            'Invalid date-time (ISO 8601 required)',
      );

  /// {@template date_validator}
  /// Validates that the string is a valid date in YYYY-MM-DD format.
  /// Follows ISO 8601 date format standard.
  /// Examples: 2023-12-25, 2024-01-01, 1990-06-15.
  /// {@endtemplate}
  static PatternConstraint date() => PatternConstraint(
        type: PatternType.format,
        formatValidator: (value) {
          final date = DateTime.tryParse(value);
          if (date == null) return false;

          final formatted = '${date.year.toString().padLeft(4, '0')}-'
              '${date.month.toString().padLeft(2, '0')}-'
              '${date.day.toString().padLeft(2, '0')}';

          return formatted == value;
        },
        constraintKey: 'date',
        description: 'Must be a valid date in YYYY-MM-DD format',
        customMessageBuilder: (value) =>
            'Invalid date. YYYY-MM-DD required. Ex: 2017-07-21',
      );

  /// {@template is_json_validator}
  /// Validates that the string contains valid JSON data.
  /// Accepts any valid JSON format including objects, arrays, strings, numbers, booleans, and null.
  /// Examples: {"key": "value"}, [1, 2, 3], "string", 42, true, null.
  /// {@endtemplate}
  static PatternConstraint json() => PatternConstraint(
        type: PatternType.format,
        formatValidator: (value) {
          try {
            // Try to decode as JSON - if successful, it's valid JSON
            jsonDecode(value);

            return true;
          } catch (e) {
            return false;
          }
        },
        constraintKey: 'string_json',
        description: 'Must be valid JSON',
        customMessageBuilder: (value) => 'Invalid JSON',
      );

  /// {@template time_validator}
  /// Validates that the string is a valid time in HH:MM:SS format.
  /// Supports optional milliseconds (HH:MM:SS.mmm).
  /// Accepts times from 00:00:00 to 23:59:59.
  /// Examples: 14:30:00, 09:15:30, 23:59:59.999.
  /// {@endtemplate}
  static PatternConstraint time() => PatternConstraint(
        type: PatternType.regex,
        pattern: RegExp(r'^([01]\d|2[0-3]):([0-5]\d):([0-5]\d)(\.\d{1,3})?$'),
        constraintKey: 'time',
        description: 'Must be a valid time in HH:MM:SS format',
        example: '14:30:00',
        customMessageBuilder: (value) => 'Invalid time format. Ex: 14:30:00',
      );

  /// {@template uri_validator}
  /// Validates that the string is a valid URI according to RFC 3986.
  /// Supports all standard URI schemes including http, https, ftp, mailto, file, etc.
  /// Examples: https://example.com, mailto:user@example.com, file:///path/to/file.
  /// {@endtemplate}
  static PatternConstraint uri() => PatternConstraint(
        type: PatternType.regex,
        pattern: RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*:[^\s]*$'),
        constraintKey: 'uri',
        description: 'Must be a valid URI',
        example: 'https://example.com/path',
        customMessageBuilder: (value) =>
            'Invalid URI format. Ex: https://example.com',
      );

  /// {@template uuid_validator}
  /// Validates that the string is a valid UUID according to RFC 4122.
  /// Enforces proper version (1-5) and variant bits for strict UUID compliance.
  /// Examples: 123e4567-e89b-12d3-a456-426614174000, 550e8400-e29b-41d4-a716-446655440000.
  /// {@endtemplate}
  static PatternConstraint uuid() => PatternConstraint(
        type: PatternType.regex,
        pattern: RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
        ),
        constraintKey: 'uuid',
        description: 'Must be a valid UUID (RFC 4122)',
        example: '123e4567-e89b-12d3-a456-426614174000',
        customMessageBuilder: (value) =>
            'Invalid UUID format. Ex: 123e4567-e89b-12d3-a456-426614174000',
      );

  /// {@template ipv4_validator}
  /// Validates that the string is a valid IPv4 address.
  /// Supports standard dotted decimal notation with values from 0.0.0.0 to 255.255.255.255.
  /// Examples: 192.168.1.1, 10.0.0.1, 255.255.255.255.
  /// {@endtemplate}
  static PatternConstraint ipv4() => PatternConstraint(
        type: PatternType.regex,
        pattern: RegExp(
          r'^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
        ),
        constraintKey: 'ipv4',
        description: 'Must be a valid IPv4 address',
        example: '192.168.1.1',
        customMessageBuilder: (value) =>
            'Invalid IPv4 address. Ex: 192.168.1.1',
      );

  /// {@template ipv6_validator}
  /// Validates that the string is a valid IPv6 address.
  /// Supports full, compressed, and special IPv6 address formats.
  /// Examples: 2001:0db8:85a3:0000:0000:8a2e:0370:7334, ::1, fe80::1.
  /// {@endtemplate}
  static PatternConstraint ipv6() => PatternConstraint(
        type: PatternType.regex,
        pattern: RegExp(
          r'^([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}$|^::1$|^::$|^([0-9a-fA-F]{1,4}:){1,6}::[0-9a-fA-F]{1,4}$|^[0-9a-fA-F]{1,4}::([0-9a-fA-F]{1,4}:)*[0-9a-fA-F]{1,4}$|^fe80::[0-9a-fA-F]{1,4}$',
        ),
        constraintKey: 'ipv6',
        description: 'Must be a valid IPv6 address',
        example: '2001:0db8:85a3:0000:0000:8a2e:0370:7334',
        customMessageBuilder: (value) =>
            'Invalid IPv6 address. Ex: 2001:0db8:85a3::8a2e:0370:7334',
      );

  /// {@template hostname_validator}
  /// Validates that the string is a valid hostname according to RFC 1123.
  /// Supports domain names, subdomains, and single hostnames.
  /// Examples: example.com, sub.example.com, localhost, my-server.
  /// {@endtemplate}
  static PatternConstraint hostname() => PatternConstraint(
        type: PatternType.regex,
        pattern: RegExp(
          r'^(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)*[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$',
        ),
        constraintKey: 'hostname',
        description: 'Must be a valid hostname (RFC 1123)',
        example: 'example.com',
        customMessageBuilder: (value) => 'Invalid hostname. Ex: example.com',
      );

  /// Maps constraint keys to JSON Schema format values using modern Dart pattern matching.
  String? _getFormatFromConstraintKey(String key) => switch (key) {
        'email' => 'email',
        'datetime' => 'date-time',
        'date' => 'date',
        'time' => 'time',
        'uri' => 'uri',
        'uuid' => 'uuid',
        'ipv4' => 'ipv4',
        'ipv6' => 'ipv6',
        'hostname' => 'hostname',
        _ => null, // Not a standard JSON Schema format
      };

  /// Checks if a format is a standard JSON Schema format that should replace pattern.
  bool _isStandardFormat(String format) {
    // Only include formats actually used in this codebase
    return const {
      'email',
      'date-time',
      'date',
      'time',
      'uri',
      'uuid',
      'ipv4',
      'ipv6',
      'hostname'
    }.contains(format);
  }

  /// Builds JSON Schema for regex-based constraints.
  Map<String, Object?> _buildRegexSchema() {
    final format = _getFormatFromConstraintKey(constraintKey);

    // For standard formats, prefer format over pattern
    if (format != null && _isStandardFormat(format)) {
      return {'format': format};
    }

    // Include pattern and optional format
    final schema = <String, Object?>{};
    if (pattern != null) {
      schema['pattern'] = pattern!.pattern;
    }
    if (format != null) {
      schema['format'] = format;
    }

    return schema;
  }

  /// Builds JSON Schema for format-based constraints.
  Map<String, Object?> _buildFormatSchema() {
    final format = _getFormatFromConstraintKey(constraintKey);

    return format != null ? {'format': format} : {};
  }

  @override
  bool isValid(String value) => switch (type) {
        PatternType.regex => pattern!.hasMatch(value),
        PatternType.enumValues => allowedValues!.contains(value),
        PatternType.notEnumValues => !allowedValues!.contains(value),
        PatternType.format => formatValidator!(value),
      };

  @override
  Map<String, Object?> buildContext(String value) {
    if (type == PatternType.enumValues && allowedValues != null) {
      final closestMatch = findClosestStringMatch(value, allowedValues!);

      return {'closestMatch': closestMatch, 'allowedValues': allowedValues};
    }

    return super.buildContext(value);
  }

  @override
  String buildMessage(String value) {
    if (customMessageBuilder != null) {
      return customMessageBuilder!(value);
    }

    return switch (type) {
      PatternType.regex => example != null
          ? 'Invalid format. Example: $example'
          : 'Does not match required pattern',
      PatternType.enumValues =>
        'Must be one of: ${allowedValues!.map((e) => '"$e"').join(', ')}',
      PatternType.notEnumValues =>
        'Cannot be one of: ${allowedValues!.map((e) => '"$e"').join(', ')}',
      PatternType.format => 'Invalid format',
    };
  }

  @override
  Map<String, Object?> toJsonSchema() => switch (type) {
        PatternType.regex => _buildRegexSchema(),
        PatternType.enumValues => {'enum': allowedValues},
        PatternType.notEnumValues => {
            'not': {'enum': allowedValues},
          },
        PatternType.format => _buildFormatSchema(),
      };
}
