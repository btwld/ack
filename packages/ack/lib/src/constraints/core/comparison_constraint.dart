import '../constraint.dart';

/// Type of comparison operation to perform.
enum ComparisonType { gt, gte, lt, lte, eq, range }

/// A generic constraint for various comparison-based validations.
///
/// This versatile constraint handles comparisons like minimum/maximum length for strings/lists,
/// min/max value for numbers, property counts for objects, etc., by using a
/// `valueExtractor` function to get a numeric value from the input type `T`.
///
/// It is generic on the non-nullable type `T`, but validates the nullable type `T?`.
/// It will always pass if the input value is `null`.
class ComparisonConstraint<T extends Object> extends Constraint<T?>
    with Validator<T?>, JsonSchemaSpec<T?> {
  final ComparisonType type;
  final num threshold;
  final num? maxThreshold; // Required for ComparisonType.range
  final num? multipleValue; // For 'multipleOf' style checks

  final num Function(T) valueExtractor;

  /// Optional custom message builder. If provided, overrides default messages.
  final String Function(T value, num extractedValue)? customMessageBuilder;

  const ComparisonConstraint({
    required super.constraintKey,
    required super.description,
    required this.type,
    required this.threshold,
    this.maxThreshold,
    this.multipleValue,
    required this.valueExtractor,
    this.customMessageBuilder,
  }) : assert(
          type != ComparisonType.range || maxThreshold != null,
          'maxThreshold is required for range comparisons.',
        );

  // --- Factory methods for specific use cases ---

  // String length
  static ComparisonConstraint<String> stringMinLength(int min) =>
      ComparisonConstraint<String>(
        type: ComparisonType.gte,
        threshold: min,
        valueExtractor: (s) => s.length,
        constraintKey: 'string_min_length',
        description: 'String must be at least $min characters.',
        customMessageBuilder: (value, extracted) =>
            'Too short. Minimum $min characters, got ${extracted.toInt()}.',
      );
  static ComparisonConstraint<String> stringMaxLength(int max) =>
      ComparisonConstraint<String>(
        type: ComparisonType.lte,
        threshold: max,
        valueExtractor: (s) => s.length,
        constraintKey: 'string_max_length',
        description: 'String must be at most $max characters.',
        customMessageBuilder: (value, extracted) =>
            'Too long. Maximum $max characters, got ${extracted.toInt()}.',
      );
  static ComparisonConstraint<String> stringExactLength(int length) =>
      ComparisonConstraint<String>(
        type: ComparisonType.eq,
        threshold: length,
        valueExtractor: (s) => s.length,
        constraintKey: 'string_exact_length',
        description: 'String must be exactly $length characters.',
        customMessageBuilder: (value, extracted) =>
            'Must be exactly $length characters, got ${extracted.toInt()}.',
      );

  // Number value
  static ComparisonConstraint<N> numberMin<N extends num>(N min) =>
      ComparisonConstraint<N>(
        type: ComparisonType.gte,
        threshold: min,
        valueExtractor: (n) => n,
        constraintKey: 'number_min',
        description: 'Number must be at least $min.',
      );
  static ComparisonConstraint<N> numberMax<N extends num>(N max) =>
      ComparisonConstraint<N>(
        type: ComparisonType.lte,
        threshold: max,
        valueExtractor: (n) => n,
        constraintKey: 'number_max',
        description: 'Number must be at most $max.',
      );
  static ComparisonConstraint<N> numberExclusiveMin<N extends num>(N min) =>
      ComparisonConstraint<N>(
        type: ComparisonType.gt,
        threshold: min,
        valueExtractor: (n) => n,
        constraintKey: 'number_exclusive_min',
        description: 'Number must be greater than $min.',
      );
  static ComparisonConstraint<N> numberExclusiveMax<N extends num>(N max) =>
      ComparisonConstraint<N>(
        type: ComparisonType.lt,
        threshold: max,
        valueExtractor: (n) => n,
        constraintKey: 'number_exclusive_max',
        description: 'Number must be less than $max.',
      );
  static ComparisonConstraint<N> numberRange<N extends num>(N min, N max) =>
      ComparisonConstraint<N>(
        type: ComparisonType.range,
        threshold: min,
        maxThreshold: max,
        valueExtractor: (n) => n,
        constraintKey: 'number_range',
        description: 'Number must be between $min and $max (inclusive).',
      );
  static ComparisonConstraint<N> numberMultipleOf<N extends num>(N multiple) =>
      ComparisonConstraint<N>(
        type: ComparisonType.eq,
        threshold: 0,
        multipleValue: multiple,
        valueExtractor: (n) => n.remainder(multiple), // Check if remainder is 0
        constraintKey: 'number_multiple_of',
        description: 'Number must be a multiple of $multiple.',
        customMessageBuilder: (value, _) =>
            'Must be a multiple of $multiple. $value is not.',
      );

  // List items count
  static ComparisonConstraint<List<E>> listMinItems<E>(int min) =>
      ComparisonConstraint<List<E>>(
        type: ComparisonType.gte,
        threshold: min,
        valueExtractor: (l) => l.length,
        constraintKey: 'list_min_items',
        description: 'List must have at least $min items.',
        customMessageBuilder: (value, extracted) =>
            'Too few items. Minimum $min, got ${extracted.toInt()}.',
      );
  static ComparisonConstraint<List<E>> listMaxItems<E>(int max) =>
      ComparisonConstraint<List<E>>(
        type: ComparisonType.lte,
        threshold: max,
        valueExtractor: (l) => l.length,
        constraintKey: 'list_max_items',
        description: 'List must have at most $max items.',
        customMessageBuilder: (value, extracted) =>
            'Too many items. Maximum $max, got ${extracted.toInt()}.',
      );

  // Object properties count
  static ComparisonConstraint<Map<String, Object?>> objectMinProperties(
    int min,
  ) =>
      ComparisonConstraint<Map<String, Object?>>(
        type: ComparisonType.gte,
        threshold: min,
        valueExtractor: (m) => m.keys.length,
        constraintKey: 'object_min_properties',
        description: 'Object must have at least $min properties.',
        customMessageBuilder: (value, extracted) =>
            'Too few properties. Minimum $min, got ${extracted.toInt()}.',
      );
  static ComparisonConstraint<Map<String, Object?>> objectMaxProperties(
    int max,
  ) =>
      ComparisonConstraint<Map<String, Object?>>(
        type: ComparisonType.lte,
        threshold: max,
        valueExtractor: (m) => m.keys.length,
        constraintKey: 'object_max_properties',
        description: 'Object must have at most $max properties.',
        customMessageBuilder: (value, extracted) =>
            'Too many properties. Maximum $max, got ${extracted.toInt()}.',
      );

  // Additional factory methods for simple value comparisons

  /// Creates a constraint that checks if a comparable value is less than the specified threshold
  static ComparisonConstraint<T> lessThan<T extends Comparable<Object>>(
    T compareValue,
  ) =>
      ComparisonConstraint(
        type: ComparisonType.lt,
        threshold: compareValue is num ? compareValue : 0,
        valueExtractor: (value) =>
            value is num ? value : value.compareTo(compareValue),
        constraintKey: 'less_than',
        description: 'Value must be less than $compareValue.',
        customMessageBuilder: (value, _) => 'Must be less than $compareValue.',
      );

  /// Creates a constraint that checks if a comparable value is less than or equal to the specified threshold
  static ComparisonConstraint<T> lessThanOrEqual<T extends Comparable<Object>>(
    T compareValue,
  ) =>
      ComparisonConstraint(
        type: ComparisonType.lte,
        threshold: compareValue is num ? compareValue : 0,
        valueExtractor: (value) =>
            value is num ? value : value.compareTo(compareValue),
        constraintKey: 'less_than_or_equal',
        description: 'Value must be less than or equal to $compareValue.',
        customMessageBuilder: (value, _) =>
            'Must be less than or equal to $compareValue.',
      );

  /// Creates a constraint that checks if a comparable value is greater than the specified threshold
  static ComparisonConstraint<T> greaterThan<T extends Comparable<Object>>(
    T compareValue,
  ) =>
      ComparisonConstraint(
        type: ComparisonType.gt,
        threshold: compareValue is num ? compareValue : 0,
        valueExtractor: (value) =>
            value is num ? value : value.compareTo(compareValue),
        constraintKey: 'greater_than',
        description: 'Value must be greater than $compareValue.',
        customMessageBuilder: (value, _) =>
            'Must be greater than $compareValue.',
      );

  /// Creates a constraint that checks if a comparable value is greater than or equal to the specified threshold
  static ComparisonConstraint<T>
      greaterThanOrEqual<T extends Comparable<Object>>(T compareValue) =>
          ComparisonConstraint(
            type: ComparisonType.gte,
            threshold: compareValue is num ? compareValue : 0,
            valueExtractor: (value) =>
                value is num ? value : value.compareTo(compareValue),
            constraintKey: 'greater_than_or_equal',
            description:
                'Value must be greater than or equal to $compareValue.',
            customMessageBuilder: (value, _) =>
                'Must be greater than or equal to $compareValue.',
          );

  @override
  bool isValid(T? value) {
    if (value == null) {
      // This constraint validates the value, not its nullability.
      // A null value is considered valid by this constraint.
      return true;
    }
    final num extracted = valueExtractor(value);
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
        return extracted ==
            threshold; // For multipleOf, extractor gives remainder, so check against 0
      case ComparisonType.range:
        return extracted >= threshold && extracted <= maxThreshold!;
    }
  }

  @override
  String buildMessage(T? value) {
    // This method is only called if isValid returns false, so value is non-null.
    final nonNullValue = value!;
    final num extracted = valueExtractor(nonNullValue);
    if (customMessageBuilder != null) {
      return customMessageBuilder!(nonNullValue, extracted);
    }
    // Default messages
    switch (type) {
      case ComparisonType.gt:
        return 'Must be greater than $threshold, got $extracted.';
      case ComparisonType.gte:
        return 'Must be at least $threshold, got $extracted.';
      case ComparisonType.lt:
        return 'Must be less than $threshold, got $extracted.';
      case ComparisonType.lte:
        return 'Must be at most $threshold, got $extracted.';
      case ComparisonType.eq:
        if (multipleValue != null && constraintKey == 'number_multiple_of') {
          return 'Must be a multiple of $multipleValue. $value is not.';
        }

        return 'Must be equal to $threshold, got $extracted.';
      case ComparisonType.range:
        return 'Must be between $threshold and ${maxThreshold!}, got $extracted.';
    }
  }

  @override
  Map<String, Object?> toJsonSchema() {
    switch (type) {
      case ComparisonType.gt:
        return {'exclusiveMinimum': threshold};
      case ComparisonType.gte:
        final isStringLength = constraintKey.startsWith('string_') &&
            (constraintKey.contains('length') ||
                constraintKey.contains('exact'));
        final isListItems = constraintKey.startsWith('list_');
        final isObjectProperties = constraintKey.startsWith('object_');

        if (isStringLength) return {'minLength': threshold.toInt()};
        if (isListItems) return {'minItems': threshold.toInt()};
        if (isObjectProperties) return {'minProperties': threshold.toInt()};

        return {'minimum': threshold};
      case ComparisonType.lt:
        return {'exclusiveMaximum': threshold};
      case ComparisonType.lte:
        final isStringLength = constraintKey.startsWith('string_') &&
            (constraintKey.contains('length') ||
                constraintKey.contains('exact'));
        final isListItems = constraintKey.startsWith('list_');
        final isObjectProperties = constraintKey.startsWith('object_');

        if (isStringLength) return {'maxLength': threshold.toInt()};
        if (isListItems) return {'maxItems': threshold.toInt()};
        if (isObjectProperties) return {'maxProperties': threshold.toInt()};

        return {'maximum': threshold};
      case ComparisonType.eq:
        final isMultipleOf =
            constraintKey == 'number_multiple_of' && multipleValue != null;
        final isStringLength = constraintKey.startsWith('string_') &&
            (constraintKey.contains('length') ||
                constraintKey.contains('exact'));

        if (isMultipleOf) return {'multipleOf': multipleValue};
        if (isStringLength) {
          return {
            'minLength': threshold.toInt(),
            'maxLength': threshold.toInt(),
          };
        }

        return {'const': threshold};
      case ComparisonType.range:
        final isStringLength = constraintKey.startsWith('string_') &&
            (constraintKey.contains('length') ||
                constraintKey.contains('exact'));
        final isListItems = constraintKey.startsWith('list_');
        final isObjectProperties = constraintKey.startsWith('object_');

        if (isStringLength) {
          return {
            'minLength': threshold.toInt(),
            'maxLength': maxThreshold!.toInt(),
          };
        }
        if (isListItems) {
          return {
            'minItems': threshold.toInt(),
            'maxItems': maxThreshold!.toInt(),
          };
        }
        if (isObjectProperties) {
          return {
            'minProperties': threshold.toInt(),
            'maxProperties': maxThreshold!.toInt(),
          };
        }

        return {'minimum': threshold, 'maximum': maxThreshold};
    }
  }
}
