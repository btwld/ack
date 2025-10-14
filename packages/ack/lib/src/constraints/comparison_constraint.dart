import 'constraint.dart';

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
class ComparisonConstraint<T extends Object> extends Constraint<T>
    with Validator<T>, JsonSchemaSpec<T> {
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
  static ComparisonConstraint<N> numberMultipleOf<N extends num>(N multiple) {
    if (multiple == 0) {
      throw ArgumentError.value(
        multiple,
        'multiple',
        'multipleOf value cannot be zero',
      );
    }
    return ComparisonConstraint<N>(
      type: ComparisonType.eq,
      threshold: 0,
      multipleValue: multiple,
      valueExtractor: (n) => n.remainder(multiple), // Check if remainder is 0
      constraintKey: 'number_multiple_of',
      description: 'Number must be a multiple of $multiple.',
      customMessageBuilder: (value, _) =>
          'Must be a multiple of $multiple. $value is not.',
    );
  }

  static ComparisonConstraint<N> numberPositive<N extends num>() =>
      ComparisonConstraint<N>(
        type: ComparisonType.gt,
        threshold: 0,
        valueExtractor: (n) => n,
        constraintKey: 'number_positive',
        description: 'Number must be positive.',
        customMessageBuilder: (value, _) => 'Must be positive, but got $value.',
      );

  static ComparisonConstraint<N> numberNegative<N extends num>() =>
      ComparisonConstraint<N>(
        type: ComparisonType.lt,
        threshold: 0,
        valueExtractor: (n) => n,
        constraintKey: 'number_negative',
        description: 'Number must be negative.',
        customMessageBuilder: (value, _) => 'Must be negative, but got $value.',
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
  static ComparisonConstraint<List<E>> listExactItems<E>(int length) =>
      ComparisonConstraint<List<E>>(
        type: ComparisonType.eq,
        threshold: length,
        valueExtractor: (l) => l.length,
        constraintKey: 'list_exact_items',
        description: 'List must have exactly $length items.',
        customMessageBuilder: (value, extracted) =>
            'Must have exactly $length items, got ${extracted.toInt()}.',
      );

  // Object properties count
  static ComparisonConstraint<Map<String, Object?>> objectMinProperties(
    int min,
  ) => ComparisonConstraint<Map<String, Object?>>(
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
  ) => ComparisonConstraint<Map<String, Object?>>(
    type: ComparisonType.lte,
    threshold: max,
    valueExtractor: (m) => m.keys.length,
    constraintKey: 'object_max_properties',
    description: 'Object must have at most $max properties.',
    customMessageBuilder: (value, extracted) =>
        'Too many properties. Maximum $max, got ${extracted.toInt()}.',
  );

  // Generic Comparable factories removed due to type safety and JSON Schema issues.
  // These methods had incorrect type bounds (Comparable<Object> excludes DateTime)
  // and would emit incorrect JSON Schema for non-numeric types.
  // Use the specific typed factories above (numberMin, numberMax, etc.) instead.

  @override
  bool isValid(T value) {
    final num extracted = valueExtractor(value);
    return switch (type) {
      ComparisonType.gt => extracted > threshold,
      ComparisonType.gte => extracted >= threshold,
      ComparisonType.lt => extracted < threshold,
      ComparisonType.lte => extracted <= threshold,
      ComparisonType.eq => () {
          if (multipleValue != null && constraintKey == 'number_multiple_of') {
            // extractor gives remainder; treat near-zero as zero for doubles
            final rem = extracted.abs();
            const eps = 1e-10;
            return rem == 0 || rem < eps;
          }
          return extracted == threshold;
        }(),
      ComparisonType.range => extracted >= threshold && extracted <= maxThreshold!,
    };
  }

  @override
  String buildMessage(T value) {
    // This method is only called if isValid returns false, so value is non-null.
    final nonNullValue = value;
    final num extracted = valueExtractor(nonNullValue);
    if (customMessageBuilder != null) {
      return customMessageBuilder!(nonNullValue, extracted);
    }
    // Default messages
    return switch (type) {
      ComparisonType.gt => 'Must be greater than $threshold, got $extracted.',
      ComparisonType.gte => 'Must be at least $threshold, got $extracted.',
      ComparisonType.lt => 'Must be less than $threshold, got $extracted.',
      ComparisonType.lte => 'Must be at most $threshold, got $extracted.',
      ComparisonType.eq => () {
          if (multipleValue != null && constraintKey == 'number_multiple_of') {
            return 'Must be a multiple of $multipleValue. $value is not.';
          }

          return 'Must be equal to $threshold, got $extracted.';
        }(),
      ComparisonType.range =>
        'Must be between $threshold and ${maxThreshold!}, got $extracted.',
    };
  }

  @override
  Map<String, Object?> toJsonSchema() => switch (type) {
        ComparisonType.gt => {'exclusiveMinimum': threshold},
        ComparisonType.gte => () {
            final isStringLength = constraintKey.startsWith('string_') &&
                (constraintKey.contains('length') ||
                    constraintKey.contains('exact'));
            final isListItems = constraintKey.startsWith('list_');
            final isObjectProperties = constraintKey.startsWith('object_');

            if (isStringLength) return {'minLength': threshold.toInt()};
            if (isListItems) return {'minItems': threshold.toInt()};
            if (isObjectProperties) return {'minProperties': threshold.toInt()};

            return {'minimum': threshold};
          }(),
        ComparisonType.lt => {'exclusiveMaximum': threshold},
        ComparisonType.lte => () {
            final isStringLength = constraintKey.startsWith('string_') &&
                (constraintKey.contains('length') ||
                    constraintKey.contains('exact'));
            final isListItems = constraintKey.startsWith('list_');
            final isObjectProperties = constraintKey.startsWith('object_');

            if (isStringLength) return {'maxLength': threshold.toInt()};
            if (isListItems) return {'maxItems': threshold.toInt()};
            if (isObjectProperties) return {'maxProperties': threshold.toInt()};

            return {'maximum': threshold};
          }(),
        ComparisonType.eq => () {
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
          }(),
        ComparisonType.range => () {
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
          }(),
      };
}
