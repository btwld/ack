import 'dart:convert';

import '../constraint.dart';
import '../../helpers.dart';

/// Type of pattern matching operation to perform.
enum PatternType { regex, enumValues, notEnumValues, format }

/// A generic constraint that handles all pattern/format matching operations.
/// 
/// This constraint consolidates multiple specific pattern constraints into a single
/// flexible implementation that can match regex patterns, enums, or custom formats.
class PatternConstraint extends Constraint<String> with Validator<String>, OpenApiSpec<String> {
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
  static PatternConstraint regex(String pattern, {String? patternName, String? example}) => 
    PatternConstraint(
      type: PatternType.regex,
      pattern: RegExp(pattern),
      constraintKey: patternName != null ? 'string_pattern_$patternName' : 'regex',
      description: patternName != null 
        ? 'Must match the pattern: $patternName${example != null ? '. Example: $example' : ''}'
        : 'Must match regex pattern',
      example: example,
    );

  static PatternConstraint email() => PatternConstraint(
    type: PatternType.regex,
    pattern: RegExp(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    constraintKey: 'email',
    description: 'Must be a valid email address',
    example: 'example@domain.com',
    customMessageBuilder: (value) => 'Invalid email format. Ex: example@domain.com',
  );

  static PatternConstraint hexColor() => PatternConstraint(
    type: PatternType.regex,
    pattern: RegExp(r'^#?([0-9a-fA-F]{3}|[0-9a-fA-F]{6})$'),
    constraintKey: 'hex_color',
    description: 'Must be a valid hex color',
    example: '#f0f0f0',
    customMessageBuilder: (value) => 'Invalid hex color format. Ex: #f0f0f0',
  );

  // Factory methods for enum patterns
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

  static PatternConstraint notEnumValues(List<String> values) => PatternConstraint(
    type: PatternType.notEnumValues,
    allowedValues: values,
    constraintKey: 'not_one_of',
    description: 'Must not be one of: $values',
    customMessageBuilder: (value) => 'Disallowed value: Cannot be one of $values',
  );

  // Factory methods for format patterns
  static PatternConstraint dateTime() => PatternConstraint(
    type: PatternType.format,
    formatValidator: (value) => DateTime.tryParse(value) != null,
    constraintKey: 'datetime',
    description: 'Must be a valid ISO 8601 date-time',
    customMessageBuilder: (value) => 'Invalid date-time (ISO 8601 required)',
  );

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
    customMessageBuilder: (value) => 'Invalid date. YYYY-MM-DD required. Ex: 2017-07-21',
  );

  static PatternConstraint json() => PatternConstraint(
    type: PatternType.format,
    formatValidator: (value) {
      try {
        return looksLikeJson(value) && jsonDecode(value) != null;
      } catch (e) {
        return false;
      }
    },
    constraintKey: 'string_json',
    description: 'Must be valid JSON',
    customMessageBuilder: (value) => 'Invalid JSON',
  );

  @override
  bool isValid(String value) {
    switch (type) {
      case PatternType.regex:
        return pattern!.hasMatch(value);
      case PatternType.enumValues:
        return allowedValues!.contains(value);
      case PatternType.notEnumValues:
        return !allowedValues!.contains(value);
      case PatternType.format:
        return formatValidator!(value);
    }
  }

  @override
  Map<String, Object?> buildContext(String value) {
    if (type == PatternType.enumValues && allowedValues != null) {
      final closestMatch = findClosestStringMatch(value, allowedValues!);
      return {
        'closestMatch': closestMatch,
        'allowedValues': allowedValues,
      };
    }
    return super.buildContext(value);
  }

  @override
  String buildMessage(String value) {
    if (customMessageBuilder != null) {
      return customMessageBuilder!(value);
    }
    
    switch (type) {
      case PatternType.regex:
        return example != null 
          ? 'Invalid format. Example: $example'
          : 'Does not match required pattern';
      case PatternType.enumValues:
        return 'Must be one of: ${allowedValues!.map((e) => '"$e"').join(', ')}';
      case PatternType.notEnumValues:
        return 'Cannot be one of: ${allowedValues!.map((e) => '"$e"').join(', ')}';
      case PatternType.format:
        return 'Invalid format';
    }
  }

  @override
  Map<String, Object?> toJsonSchema() {
    switch (type) {
      case PatternType.regex:
        final schema = <String, Object?>{};
        if (pattern != null) {
          schema['pattern'] = pattern!.pattern;
        }
        // Special handling for known formats
        if (constraintKey == 'email') {
          schema['format'] = 'email';
        } else if (constraintKey == 'datetime') {
          schema['format'] = 'date-time';
        } else if (constraintKey == 'date') {
          schema['format'] = 'date';
        }
        return schema;
      case PatternType.enumValues:
        return {'enum': allowedValues};
      case PatternType.notEnumValues:
        return {'not': {'enum': allowedValues}};
      case PatternType.format:
        if (constraintKey == 'datetime') {
          return {'format': 'date-time'};
        } else if (constraintKey == 'date') {
          return {'format': 'date'};
        }
        return {};
    }
  }
}