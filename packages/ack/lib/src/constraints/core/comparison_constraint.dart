import '../constraint.dart';

/// Type of comparison operation to perform.
enum ComparisonType { gt, gte, lt, lte, eq, range }

/// A generic constraint that handles all numeric comparison operations.
/// 
/// This constraint consolidates multiple specific comparison constraints into a single
/// flexible implementation that can compare any extractable numeric value.
class ComparisonConstraint<T extends Object> extends Constraint<T> with Validator<T>, OpenApiSpec<T> {
  /// The type of comparison to perform.
  final ComparisonType type;
  
  /// The threshold value for comparison.
  final num threshold;
  
  /// The maximum threshold for range comparisons.
  final num? maxThreshold;
  
  /// Function to extract a numeric value from the input for comparison.
  final num Function(T) valueExtractor;
  
  /// Optional custom message builder.
  final String Function(T value, num extracted)? customMessageBuilder;

  const ComparisonConstraint({
    required this.type,
    required this.threshold,
    this.maxThreshold,
    required this.valueExtractor,
    required super.constraintKey,
    required super.description,
    this.customMessageBuilder,
  }) : assert(
          type != ComparisonType.range || maxThreshold != null,
          'maxThreshold is required for range comparisons',
        );

  // Factory methods for string constraints
  static ComparisonConstraint<String> stringMinLength(int min) => 
    ComparisonConstraint<String>(
      type: ComparisonType.gte,
      threshold: min,
      valueExtractor: (value) => value.length,
      constraintKey: 'string_min_length',
      description: 'String must be at least $min characters',
      customMessageBuilder: (value, extracted) => 
        'Too short, min $min characters. Got ${extracted.toInt()}',
    );

  static ComparisonConstraint<String> stringMaxLength(int max) => 
    ComparisonConstraint<String>(
      type: ComparisonType.lte,
      threshold: max,
      valueExtractor: (value) => value.length,
      constraintKey: 'string_max_length',
      description: 'String must be at most $max characters',
      customMessageBuilder: (value, extracted) => 
        'Too long, max $max characters. Got ${extracted.toInt()}',
    );

  static ComparisonConstraint<String> stringExactLength(int length) => 
    ComparisonConstraint<String>(
      type: ComparisonType.eq,
      threshold: length,
      valueExtractor: (value) => value.length,
      constraintKey: 'string_exact_length',
      description: 'String must be exactly $length characters',
      customMessageBuilder: (value, extracted) => 
        'Must be exactly $length characters. Got ${extracted.toInt()}',
    );

  // Factory methods for number constraints
  static ComparisonConstraint<T> numberMin<T extends num>(T min) =>
    ComparisonConstraint<T>(
      type: ComparisonType.gte,
      threshold: min,
      valueExtractor: (value) => value,
      constraintKey: 'number_min',
      description: 'Number must be at least $min',
    );

  static ComparisonConstraint<T> numberMax<T extends num>(T max) =>
    ComparisonConstraint<T>(
      type: ComparisonType.lte,
      threshold: max,
      valueExtractor: (value) => value,
      constraintKey: 'number_max',
      description: 'Number must be at most $max',
    );

  static ComparisonConstraint<T> numberRange<T extends num>(T min, T max) =>
    ComparisonConstraint<T>(
      type: ComparisonType.range,
      threshold: min,
      maxThreshold: max,
      valueExtractor: (value) => value,
      constraintKey: 'number_range',
      description: 'Number must be between $min and $max',
    );

  static ComparisonConstraint<T> numberExclusiveMin<T extends num>(T min) =>
    ComparisonConstraint<T>(
      type: ComparisonType.gt,
      threshold: min,
      valueExtractor: (value) => value,
      constraintKey: 'number_exclusive_min',
      description: 'Number must be greater than $min',
    );

  static ComparisonConstraint<T> numberExclusiveMax<T extends num>(T max) =>
    ComparisonConstraint<T>(
      type: ComparisonType.lt,
      threshold: max,
      valueExtractor: (value) => value,
      constraintKey: 'number_exclusive_max',
      description: 'Number must be less than $max',
    );

  static ComparisonConstraint<T> numberMultipleOf<T extends num>(T multiple) =>
    ComparisonConstraint<T>(
      type: ComparisonType.eq,
      threshold: 0,
      valueExtractor: (value) => value.remainder(multiple),
      constraintKey: 'number_multiple_of',
      description: 'Number must be a multiple of $multiple',
      customMessageBuilder: (value, _) => 'Must be a multiple of $multiple',
    );

  // Factory methods for list constraints
  static ComparisonConstraint<List<T>> listMinItems<T>(int min) =>
    ComparisonConstraint<List<T>>(
      type: ComparisonType.gte,
      threshold: min,
      valueExtractor: (value) => value.length,
      constraintKey: 'list_min_items',
      description: 'List must have at least $min items',
      customMessageBuilder: (value, extracted) => 
        'Too few items, min $min. Got ${extracted.toInt()}',
    );

  static ComparisonConstraint<List<T>> listMaxItems<T>(int max) =>
    ComparisonConstraint<List<T>>(
      type: ComparisonType.lte,
      threshold: max,
      valueExtractor: (value) => value.length,
      constraintKey: 'list_max_items',
      description: 'List must have at most $max items',
      customMessageBuilder: (value, extracted) => 
        'Too many items, max $max. Got ${extracted.toInt()}',
    );

  // Factory methods for object constraints
  static ComparisonConstraint<Map<String, dynamic>> objectMinProperties(int min) =>
    ComparisonConstraint<Map<String, dynamic>>(
      type: ComparisonType.gte,
      threshold: min,
      valueExtractor: (value) => value.length,
      constraintKey: 'object_min_properties',
      description: 'Object must have at least $min properties',
      customMessageBuilder: (value, extracted) => 
        'Too few properties, min $min. Got ${extracted.toInt()}',
    );

  static ComparisonConstraint<Map<String, dynamic>> objectMaxProperties(int max) =>
    ComparisonConstraint<Map<String, dynamic>>(
      type: ComparisonType.lte,
      threshold: max,
      valueExtractor: (value) => value.length,
      constraintKey: 'object_max_properties',
      description: 'Object must have at most $max properties',
      customMessageBuilder: (value, extracted) => 
        'Too many properties, max $max. Got ${extracted.toInt()}',
    );

  @override
  bool isValid(T value) {
    final extracted = valueExtractor(value);
    switch (type) {
      case ComparisonType.gt:
        return extracted > threshold;
      case ComparisonType.gte:
        return extracted >= threshold;
      case ComparisonType.lt:
        return extracted < threshold;
      case ComparisonType.lte:
        return extracted <= threshold;
      case ComparisonType.eq:
        return extracted == threshold;
      case ComparisonType.range:
        return extracted >= threshold && extracted <= maxThreshold!;
    }
  }

  @override
  String buildMessage(T value) {
    if (customMessageBuilder != null) {
      return customMessageBuilder!(value, valueExtractor(value));
    }
    
    final extracted = valueExtractor(value);
    switch (type) {
      case ComparisonType.gt:
        return 'Must be greater than $threshold. Got $extracted';
      case ComparisonType.gte:
        return 'Must be at least $threshold. Got $extracted';
      case ComparisonType.lt:
        return 'Must be less than $threshold. Got $extracted';
      case ComparisonType.lte:
        return 'Must be at most $threshold. Got $extracted';
      case ComparisonType.eq:
        return 'Must equal $threshold. Got $extracted';
      case ComparisonType.range:
        return 'Must be between $threshold and ${maxThreshold ?? threshold}. Got $extracted';
    }
  }

  @override
  Map<String, Object?> toJsonSchema() {
    switch (type) {
      case ComparisonType.gt:
        return {'exclusiveMinimum': threshold};
      case ComparisonType.gte:
        return {'minimum': threshold};
      case ComparisonType.lt:
        return {'exclusiveMaximum': threshold};
      case ComparisonType.lte:
        return {'maximum': threshold};
      case ComparisonType.eq:
        return {'const': threshold};
      case ComparisonType.range:
        return {'minimum': threshold, 'maximum': maxThreshold};
    }
  }
}