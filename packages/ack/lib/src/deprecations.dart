// deprecations.dart
//
// Deprecated type aliases and legacy implementations for backwards compatibility.
// These aliases will be removed in a future release. Please migrate to the new types.

import 'dart:convert';

import 'constraints/constraint.dart';
import 'constraints/core/comparison_constraint.dart';
import 'constraints/core/pattern_constraint.dart';
import 'constraints/list_extensions.dart';
import 'constraints/number_extensions.dart';
import 'constraints/validators.dart';
import 'helpers.dart';
import 'schemas/schema.dart';
import 'validation/ack_exception.dart';

@Deprecated('Use Validator<T> instead')
typedef ConstraintValidator<T extends Object> = Validator<T>;

@Deprecated('Use Validator<T> instead')
typedef OpenApiConstraintValidator<T extends Object> = Validator<T>;

// --- List Validators ---

@Deprecated('Use ListUniqueItemsConstraint instead')
typedef UniqueItemsListValidator<T extends Object>
    = ListUniqueItemsConstraint<T>;

// --- Exceptions ---

@Deprecated('Use AckViolationException instead')
typedef AckViolationException = AckException;

// --- Legacy Constraint Interfaces ---
// These constraint interfaces were removed in 0.3.0 and replaced with generic implementations

/// Legacy NumberExclusiveMinConstraint with identical behavior to 0.2.0-beta.1
@Deprecated('Use ComparisonConstraint.numberExclusiveMin() instead')
class NumberExclusiveMinConstraint<T extends num> extends Constraint<T>
    with Validator<T>, JsonSchemaSpec<T> {
  final T min;

  const NumberExclusiveMinConstraint(this.min)
      : super(
          constraintKey: 'number_exclusive_min',
          description: 'Must be greater than $min',
        );

  @override
  bool isValid(T value) => value > min;

  @override
  String buildMessage(T value) => 'Must be greater than $min';

  @override
  Map<String, Object?> toJsonSchema() =>
      {'minimum': min, 'exclusiveMinimum': true};
}

/// Legacy NumberExclusiveMaxConstraint with identical behavior to 0.2.0-beta.1
@Deprecated('Use ComparisonConstraint.numberExclusiveMax() instead')
class NumberExclusiveMaxConstraint<T extends num> extends Constraint<T>
    with Validator<T>, JsonSchemaSpec<T> {
  final T max;

  const NumberExclusiveMaxConstraint(this.max)
      : super(
          constraintKey: 'number_exclusive_max',
          description: 'Must be less than $max',
        );

  @override
  bool isValid(T value) => value < max;

  @override
  String buildMessage(T value) => 'Must be less than $max';

  @override
  Map<String, Object?> toJsonSchema() =>
      {'maximum': max, 'exclusiveMaximum': true};
}

/// Legacy StringDateTimeConstraint with identical behavior to 0.2.0-beta.1
@Deprecated('Use PatternConstraint.dateTime() instead')
class StringDateTimeConstraint extends Constraint<String>
    with Validator<String>, JsonSchemaSpec<String> {
  const StringDateTimeConstraint()
      : super(
          constraintKey: 'string_date_time',
          description: 'Must be a valid date time string',
        );

  @override
  bool isValid(String value) => DateTime.tryParse(value) != null;

  @override
  String buildMessage(String value) => 'Invalid date-time (ISO 8601 required)';

  @override
  Map<String, Object?> toJsonSchema() => {'format': 'date-time'};
}

/// Legacy StringDateConstraint with identical behavior to 0.2.0-beta.1
@Deprecated('Use PatternConstraint.date() instead')
class StringDateConstraint extends Constraint<String>
    with Validator<String>, JsonSchemaSpec<String> {
  const StringDateConstraint()
      : super(
          constraintKey: 'string_date',
          description: 'Must be a valid date string in YYYY-MM-DD format',
        );

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
  String buildMessage(String value) =>
      'Invalid date. YYYY-MM-DD required. Ex: 2017-07-21';

  @override
  Map<String, Object?> toJsonSchema() => {'format': 'date'};
}

/// Legacy StringEnumConstraint with identical behavior to 0.2.0-beta.1
@Deprecated('Use PatternConstraint.enumValues() instead')
class StringEnumConstraint extends Constraint<String>
    with Validator<String>, JsonSchemaSpec<String> {
  final List<String> enumValues;

  const StringEnumConstraint(this.enumValues)
      : super(
          constraintKey: 'string_enum',
          description: 'Must be one of: $enumValues}',
        );

  @override
  bool isValid(String value) => enumValues.contains(value);

  @override
  Map<String, Object?> buildContext(String value) {
    final closestMatch = findClosestStringMatch(value, enumValues);
    return {'closestMatch': closestMatch, 'allowedValues': enumValues};
  }

  @override
  String buildMessage(String value) {
    final closestMatch = findClosestStringMatch(value, enumValues);
    final allowedValues = enumValues.map((e) => '"$e"').join(', ');

    return closestMatch != null
        ? 'Did you mean "$closestMatch"? Allowed: $allowedValues'
        : 'Allowed: $allowedValues';
  }

  @override
  Map<String, Object?> toJsonSchema() => {'enum': enumValues};
}

/// Base class for regex-based string validators (legacy implementation)
@Deprecated('Use PatternConstraint.regex() instead')
class StringRegexConstraint extends Constraint<String>
    with Validator<String>, JsonSchemaSpec<String> {
  /// The regex pattern to match
  final String pattern;

  /// An example value that matches the pattern
  final String example;

  final String patternName;

  /// {@macro regex_pattern_string_validator}
  StringRegexConstraint({
    required this.patternName,
    required this.pattern,
    required this.example,
  }) : super(
          constraintKey: 'string_pattern_$patternName',
          description: 'Must match the pattern: $patternName. Example $example',
        ) {
    // Assert that string is not empty
    // and that it starts with ^ and ends with $ for a complete match
    if (pattern.isEmpty) {
      throw ArgumentError('Pattern cannot be empty');
    }
    if (!pattern.startsWith('^') || !pattern.endsWith(r'$')) {
      throw ArgumentError(r'Pattern must start with ^ and end with \$');
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
  String buildMessage(String value) {
    return 'Invalid $patternName format. Ex: $example';
  }

  @override
  Map<String, Object?> toJsonSchema() =>
      {'pattern': pattern, 'name': constraintKey};
}

/// Legacy StringEmailConstraint with identical behavior to 0.2.0-beta.1
@Deprecated('Use PatternConstraint.email() instead')
class StringEmailConstraint extends StringRegexConstraint {
  StringEmailConstraint()
      : super(
          patternName: 'email',
          example: 'example@domain.com',
          pattern: r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
        );
}

// StringRegexConstraint is now implemented as a class above

/// Legacy StringHexColorValidator with identical behavior to 0.2.0-beta.1
@Deprecated('Use PatternConstraint.hexColor() instead')
class StringHexColorValidator extends StringRegexConstraint {
  StringHexColorValidator()
      : super(
          patternName: 'hex_color',
          example: '#f0f0f0',
          pattern: r'^#?([0-9a-fA-F]{3}|[0-9a-fA-F]{6})$',
        );
}

/// Legacy StringNotOneOfValidator with identical behavior to 0.2.0-beta.1
@Deprecated('Use PatternConstraint.notEnumValues() instead')
class StringNotOneOfValidator extends StringRegexConstraint {
  final List<String> disallowedValues;

  StringNotOneOfValidator(this.disallowedValues)
      : super(
          patternName: 'not_one_of',
          pattern:
              '^(?!${disallowedValues.map((e) => RegExp.escape(e)).join('|')}).*\$',
          example: 'Any value except: $disallowedValues',
        );

  @override
  bool isValid(String value) => !disallowedValues.contains(value);

  @override
  String buildMessage(String value) {
    return 'Disallowed value: Cannot be one of $disallowedValues';
  }
}

/// Legacy StringNotEmptyValidator with identical behavior to 0.2.0-beta.1
@Deprecated('Use ComparisonConstraint.stringMinLength(1) instead')
class StringNotEmptyValidator extends Constraint<String>
    with Validator<String> {
  const StringNotEmptyValidator()
      : super(
          constraintKey: 'string_not_empty',
          description: 'String cannot be empty',
        );

  @override
  bool isValid(String value) => value.isNotEmpty;

  @override
  String buildMessage(String value) => 'Cannot be empty';
}

/// Legacy StringJsonValidator with identical behavior to 0.2.0-beta.1
@Deprecated('Use PatternConstraint.json() instead')
class StringJsonValidator extends Constraint<String> with Validator<String> {
  const StringJsonValidator()
      : super(
          constraintKey: 'string_json',
          description: 'Must be a valid JSON string',
        );

  @override
  bool isValid(String value) {
    try {
      return looksLikeJson(value) && jsonDecode(value) != null;
    } catch (e) {
      return false;
    }
  }

  @override
  String buildMessage(String value) => 'Invalid JSON';
}

/// Legacy StringEmptyConstraint with identical behavior to 0.2.0-beta.1
@Deprecated('Use ComparisonConstraint.stringExactLength(0) instead')
class StringEmptyConstraint extends Constraint<String> with Validator<String> {
  const StringEmptyConstraint()
      : super(
          constraintKey: 'string_empty',
          description: 'String must be empty',
        );

  @override
  bool isValid(String value) => value.isEmpty;

  @override
  String buildMessage(String value) => 'Should be empty';
}

/// Legacy StringMinLengthConstraint with identical behavior to 0.2.0-beta.1
@Deprecated('Use ComparisonConstraint.stringMinLength() instead')
class StringMinLengthConstraint extends Constraint<String>
    with Validator<String>, JsonSchemaSpec<String> {
  final int min;

  const StringMinLengthConstraint(this.min)
      : super(
          constraintKey: 'string_min_length',
          description: 'String must be at least $min characters long',
        );

  @override
  bool isValid(String value) => value.length >= min;

  @override
  String buildMessage(String value) => 'Too short, min $min characters';

  @override
  Map<String, Object?> toJsonSchema() => {'minLength': min};
}

/// Legacy StringMaxLengthConstraint with identical behavior to 0.2.0-beta.1
@Deprecated('Use ComparisonConstraint.stringMaxLength() instead')
class StringMaxLengthConstraint extends Constraint<String>
    with Validator<String>, JsonSchemaSpec<String> {
  final int max;

  const StringMaxLengthConstraint(this.max)
      : super(
          constraintKey: 'string_max_length',
          description: 'String must be at most $max characters long',
        );

  @override
  bool isValid(String value) => value.length <= max;

  @override
  String buildMessage(String value) => 'Too long, max $max characters';

  @override
  Map<String, Object?> toJsonSchema() => {'maxLength': max};
}

/// Legacy ListMinItemsConstraint with identical behavior to 0.2.0-beta.1
@Deprecated('Use ComparisonConstraint.listMinItems() instead')
class ListMinItemsConstraint<T extends Object> extends Constraint<List<T>>
    with Validator<List<T>>, JsonSchemaSpec<List<T>> {
  final int min;

  const ListMinItemsConstraint(this.min)
      : super(
          constraintKey: 'list_min_items',
          description: 'List must have at least $min items',
        );

  @override
  bool isValid(List<T> value) => value.length >= min;

  @override
  String buildMessage(List<T> value) {
    return 'Too few items, min $min. Got ${value.length}';
  }

  @override
  Map<String, Object?> toJsonSchema() => {'minItems': min};
}

/// Legacy ListMaxItemsConstraint with identical behavior to 0.2.0-beta.1
@Deprecated('Use ComparisonConstraint.listMaxItems() instead')
class ListMaxItemsConstraint<T extends Object> extends Constraint<List<T>>
    with Validator<List<T>>, JsonSchemaSpec<List<T>> {
  final int max;

  const ListMaxItemsConstraint(this.max)
      : super(
          constraintKey: 'list_max_items',
          description: 'List must have at most $max items',
        );

  @override
  bool isValid(List<T> value) => value.length <= max;

  @override
  String buildMessage(List<T> value) {
    return 'Too many items, max $max. Got ${value.length}';
  }

  @override
  Map<String, Object?> toJsonSchema() => {'maxItems': max};
}

/// Legacy NumberMinConstraint with identical behavior to 0.2.0-beta.1
@Deprecated('Use ComparisonConstraint.numberMin() instead')
class NumberMinConstraint<T extends num> extends Constraint<T>
    with Validator<T>, JsonSchemaSpec<T> {
  final T min;
  final bool exclusive;

  const NumberMinConstraint(this.min, {bool? exclusive})
      : exclusive = exclusive ?? false,
        super(
          constraintKey: 'number_min',
          description: 'Must be greater than or equal to $min',
        );

  @override
  bool isValid(num value) => exclusive ? value > min : value >= min;

  @override
  String buildMessage(T value) {
    return exclusive
        ? 'Too low. Must be more than $min'
        : 'Too low. Must be $min or more';
  }

  @override
  Map<String, Object?> toJsonSchema() => {
        'minimum': min,
        if (exclusive) 'exclusiveMinimum': exclusive,
      };
}

/// Legacy NumberMultipleOfConstraint with identical behavior to 0.2.0-beta.1
@Deprecated('Use ComparisonConstraint.numberMultipleOf() instead')
class NumberMultipleOfConstraint<T extends num> extends Constraint<T>
    with Validator<T>, JsonSchemaSpec<T> {
  final T multiple;

  const NumberMultipleOfConstraint(this.multiple)
      : super(
          constraintKey: 'number_multiple_of',
          description: 'Must be a multiple of $multiple',
        );

  @override
  bool isValid(num value) => value % multiple == 0;

  @override
  String buildMessage(T value) => 'Not a multiple of $multiple';

  @override
  Map<String, Object?> toJsonSchema() => {'multipleOf': multiple};
}

/// Legacy NumberMaxConstraint with identical behavior to 0.2.0-beta.1
@Deprecated('Use ComparisonConstraint.numberMax() instead')
class NumberMaxConstraint<T extends num> extends Constraint<T>
    with Validator<T>, JsonSchemaSpec<T> {
  final T max;
  final bool exclusive;

  const NumberMaxConstraint(this.max, {bool? exclusive})
      : exclusive = exclusive ?? false,
        super(
          constraintKey: 'number_max',
          description: 'Must be less than or equal to $max',
        );

  @override
  bool isValid(num value) => exclusive ? value < max : value <= max;

  @override
  String buildMessage(T value) {
    return exclusive
        ? 'Too high. Must be less than $max'
        : 'Too high. Must be $max or less';
  }

  @override
  Map<String, Object?> toJsonSchema() => {
        'maximum': max,
        if (exclusive) 'exclusiveMaximum': exclusive,
      };
}

/// Legacy NumberRangeConstraint with identical behavior to 0.2.0-beta.1
@Deprecated('Use ComparisonConstraint.numberRange() instead')
class NumberRangeConstraint<T extends num> extends Constraint<T>
    with Validator<T>, JsonSchemaSpec<T> {
  final T min;
  final T max;
  final bool exclusive;

  const NumberRangeConstraint(this.min, this.max, {bool? exclusive})
      : exclusive = exclusive ?? false,
        super(
          constraintKey: 'number_range',
          description: 'Must be between $min and $max',
        );

  @override
  bool isValid(num value) {
    if (exclusive) {
      return value > min && value < max;
    } else {
      return value >= min && value <= max;
    }
  }

  @override
  String buildMessage(T value) {
    return exclusive
        ? 'Out of range. Must be between $min and $max (exclusive)'
        : 'Out of range. Must be between $min and $max (inclusive)';
  }

  @override
  Map<String, Object?> toJsonSchema() => {
        'minimum': min,
        'maximum': max,
        if (exclusive) 'exclusiveMinimum': exclusive,
        if (exclusive) 'exclusiveMaximum': exclusive,
      };
}

/// Legacy ObjectMinPropertiesConstraint with identical behavior to 0.2.0-beta.1
@Deprecated('Use ComparisonConstraint.objectMinProperties() instead')
class ObjectMinPropertiesConstraint extends Constraint<Map<String, Object?>>
    with Validator<Map<String, Object?>>, JsonSchemaSpec<Map<String, Object?>> {
  final int min;

  const ObjectMinPropertiesConstraint({required this.min})
      : super(
          constraintKey: 'object_min_properties',
          description: 'Object must have at least $min properties',
        );

  @override
  bool isValid(Map<String, Object?> value) => value.length >= min;

  @override
  String buildMessage(Map<String, Object?> value) {
    return 'Too few properties, min $min. Got ${value.length}';
  }

  @override
  Map<String, Object?> toJsonSchema() => {'minProperties': min};
}

/// Legacy ObjectMaxPropertiesConstraint with identical behavior to 0.2.0-beta.1
@Deprecated('Use ComparisonConstraint.objectMaxProperties() instead')
class ObjectMaxPropertiesConstraint extends Constraint<Map<String, Object?>>
    with Validator<Map<String, Object?>>, JsonSchemaSpec<Map<String, Object?>> {
  final int max;

  const ObjectMaxPropertiesConstraint({required this.max})
      : super(
          constraintKey: 'object_max_properties',
          description: 'Object must have at most $max properties',
        );

  @override
  bool isValid(Map<String, Object?> value) => value.length <= max;

  @override
  String buildMessage(Map<String, Object?> value) {
    return 'Too many properties, max $max. Got ${value.length}';
  }

  @override
  Map<String, Object?> toJsonSchema() => {'maxProperties': max};
}

// --- Legacy Constraint Factory Methods ---
// Factory methods for creating legacy constraint instances with the same API

/// Legacy factory methods for constraint creation
class LegacyConstraints {
  /// Create a NumberExclusiveMinConstraint (deprecated)
  @Deprecated('Use ComparisonConstraint.numberExclusiveMin() instead')
  static ComparisonConstraint<T> numberExclusiveMin<T extends num>(T min) =>
      ComparisonConstraint.numberExclusiveMin(min);

  /// Create a NumberExclusiveMaxConstraint (deprecated)
  @Deprecated('Use ComparisonConstraint.numberExclusiveMax() instead')
  static ComparisonConstraint<T> numberExclusiveMax<T extends num>(T max) =>
      ComparisonConstraint.numberExclusiveMax(max);

  /// Create a StringDateTimeConstraint (deprecated)
  @Deprecated('Use PatternConstraint.dateTime() instead')
  static PatternConstraint stringDateTime() => PatternConstraint.dateTime();

  /// Create a StringDateConstraint (deprecated)
  @Deprecated('Use PatternConstraint.date() instead')
  static PatternConstraint stringDate() => PatternConstraint.date();

  /// Create a StringEnumConstraint (deprecated)
  @Deprecated('Use PatternConstraint.enumValues() instead')
  static PatternConstraint stringEnum(List<String> values) =>
      PatternConstraint.enumValues(values);

  /// Create a StringEmailConstraint (deprecated)
  @Deprecated('Use PatternConstraint.email() instead')
  static PatternConstraint stringEmail() => PatternConstraint.email();

  /// Create a StringRegexConstraint (deprecated)
  @Deprecated('Use PatternConstraint.regex() instead')
  static PatternConstraint stringRegex(String pattern, {String? patternName}) =>
      PatternConstraint.regex(pattern, patternName: patternName);

  /// Create a StringHexColorValidator (deprecated)
  @Deprecated('Use PatternConstraint.hexColor() instead')
  static PatternConstraint stringHexColor() => PatternConstraint.hexColor();

  /// Create a StringNotOneOfValidator (deprecated)
  @Deprecated('Use PatternConstraint.notEnumValues() instead')
  static PatternConstraint stringNotOneOf(List<String> values) =>
      PatternConstraint.notEnumValues(values);

  /// Create a StringNotEmptyValidator (deprecated)
  @Deprecated('Use ComparisonConstraint.stringMinLength(1) instead')
  static ComparisonConstraint<String> stringNotEmpty() =>
      ComparisonConstraint.stringMinLength(1);

  /// Create a StringJsonValidator (deprecated)
  @Deprecated('Use PatternConstraint.json() instead')
  static PatternConstraint stringJson() => PatternConstraint.json();

  /// Create a StringEmptyConstraint (deprecated)
  @Deprecated('Use ComparisonConstraint.stringExactLength(0) instead')
  static ComparisonConstraint<String> stringEmpty() =>
      ComparisonConstraint.stringExactLength(0);

  /// Create a StringMinLengthConstraint (deprecated)
  @Deprecated('Use ComparisonConstraint.stringMinLength() instead')
  static ComparisonConstraint<String> stringMinLength(int min) =>
      ComparisonConstraint.stringMinLength(min);

  /// Create a StringMaxLengthConstraint (deprecated)
  @Deprecated('Use ComparisonConstraint.stringMaxLength() instead')
  static ComparisonConstraint<String> stringMaxLength(int max) =>
      ComparisonConstraint.stringMaxLength(max);

  /// Create a ListMinItemsConstraint (deprecated)
  @Deprecated('Use ComparisonConstraint.listMinItems() instead')
  static ComparisonConstraint<List<T>> listMinItems<T>(int min) =>
      ComparisonConstraint.listMinItems<T>(min);

  /// Create a ListMaxItemsConstraint (deprecated)
  @Deprecated('Use ComparisonConstraint.listMaxItems() instead')
  static ComparisonConstraint<List<T>> listMaxItems<T>(int max) =>
      ComparisonConstraint.listMaxItems<T>(max);

  /// Create a NumberMinConstraint (deprecated)
  @Deprecated('Use ComparisonConstraint.numberMin() instead')
  static ComparisonConstraint<T> numberMin<T extends num>(T min) =>
      ComparisonConstraint.numberMin(min);

  /// Create a NumberMultipleOfConstraint (deprecated)
  @Deprecated('Use ComparisonConstraint.numberMultipleOf() instead')
  static ComparisonConstraint<T> numberMultipleOf<T extends num>(T multiple) =>
      ComparisonConstraint.numberMultipleOf(multiple);

  /// Create a NumberMaxConstraint (deprecated)
  @Deprecated('Use ComparisonConstraint.numberMax() instead')
  static ComparisonConstraint<T> numberMax<T extends num>(T max) =>
      ComparisonConstraint.numberMax(max);

  /// Create a NumberRangeConstraint (deprecated)
  @Deprecated('Use ComparisonConstraint.numberRange() instead')
  static ComparisonConstraint<T> numberRange<T extends num>(T min, T max) =>
      ComparisonConstraint.numberRange(min, max);

  /// Create an ObjectMinPropertiesConstraint (deprecated)
  @Deprecated('Use ComparisonConstraint.objectMinProperties() instead')
  static ComparisonConstraint<Map<String, dynamic>> objectMinProperties(
    int min,
  ) =>
      ComparisonConstraint.objectMinProperties(min);

  /// Create an ObjectMaxPropertiesConstraint (deprecated)
  @Deprecated('Use ComparisonConstraint.objectMaxProperties() instead')
  static ComparisonConstraint<Map<String, dynamic>> objectMaxProperties(
    int max,
  ) =>
      ComparisonConstraint.objectMaxProperties(max);
}

// --- Legacy SchemaRegistry API ---
// The SchemaRegistry API was simplified in 0.3.0 to remove model type complexity
//
// Breaking changes in SchemaRegistry:
// 1. register<M, S>() -> register<S>() (removed model type parameter M)
// 2. createSchema(modelType, data) -> createSchema<S>(data) (removed modelType parameter)
//
// Migration guide:
// - Old: SchemaRegistry.register<UserModel, UserSchema>(factory)
// - New: SchemaRegistry.register<UserSchema>(factory)
//
// - Old: SchemaRegistry.createSchema(UserModel, data)
// - New: SchemaRegistry.createSchema<UserSchema>(data)
//
// Note: These are signature changes to existing methods, not new methods.
// Users need to update their method calls to use the new signatures.

// --- Numeric Schemas ---
// Previously you might have used minValue/maxValue.
// Now use min/max methods defined in the NumSchemaValidatorExt extension.

extension LegacyNumSchemaExtensions<T extends num> on NumSchema<T> {
  @Deprecated('Use min(T min) instead')
  NumSchema<T> minValue(T min) => this.min(min);

  @Deprecated('Use max(T max) instead')
  NumSchema<T> maxValue(T max) => this.max(max);

  @Deprecated('Use range(T min, T max) instead')
  NumSchema<T> rangeNum(T min, T max) => range(min, max);

  @Deprecated('Use multipleOf(T multiple) instead')
  NumSchema<T> multipleOfNum(T multiple) => multipleOf(multiple);
}

// --- List Schemas ---
// Old extension methods for lists may have used different names.
// For example, if you previously used .minLength() or .maxLength() on lists,
// map these to the new .minItems() or .maxItems() respectively.

extension LegacyListSchemaExtensions<T extends Object> on ListSchema<T> {
  @Deprecated('Use minItems(int min) instead')
  ListSchema<T> minLength(int min) => minItems(min);

  @Deprecated('Use maxItems(int max) instead')
  ListSchema<T> maxLength(int max) => maxItems(max);
}

// --- Legacy SchemaModel API Changes ---
// These methods were removed or changed in 0.3.0 as part of the API modernization
//
// REMOVED METHODS (no direct replacement):
// - getSchema() -> Use 'definition' getter instead
// - toModel() -> Create model instances manually from schema properties
// - containsKey(key) -> Use toMap().containsKey(key) or check getValue(key) != null
// - binary[] operator -> Use getValue<T>(key) method instead
// - validated constructor -> Use valid() constructor instead
//
// PARAMETER CHANGES (methods still exist):
// - parse(Object? input, {String? debugName}) -> parse(Object? data)
// - tryParse(Object? input, {String? debugName}) -> tryParse(Object? data)
// - SchemaModel(Object? value) -> SchemaModel() (removed value parameter)
//
// Migration guide:
// - Replace schema.getSchema() with schema.definition
// - Replace schema[key] with schema.getValue<T>(key)
// - Replace schema.containsKey(key) with schema.toMap().containsKey(key)
// - Remove debugName parameter from parse() and tryParse() calls
// - Create model instances manually instead of using toModel()
