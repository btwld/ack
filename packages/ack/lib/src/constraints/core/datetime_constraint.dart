import '../constraint.dart';

/// Type of date/time comparison operation to perform.
enum DateTimeComparisonType { min, max }

/// A constraint for validating DateTime values against minimum and maximum bounds.
///
/// This constraint is specifically designed for DateTime validation and provides
/// inclusive range checking (on or after for min, on or before for max).
///
/// Used internally by [Ack.date()] and [Ack.datetime()] schemas when applying
/// [.min()] or [.max()] constraints.
class DateTimeConstraint extends Constraint<DateTime>
    with Validator<DateTime>, JsonSchemaSpec<DateTime> {
  final DateTimeComparisonType type;
  final DateTime reference;

  const DateTimeConstraint._({
    required this.type,
    required this.reference,
    required super.constraintKey,
    required super.description,
  });

  /// Creates a constraint that validates the DateTime is on or after [date] (inclusive).
  ///
  /// Example:
  /// ```dart
  /// final constraint = DateTimeConstraint.min(DateTime(2000, 1, 1));
  /// constraint.validate(DateTime(2000, 1, 1)); // ✓ Valid (inclusive)
  /// constraint.validate(DateTime(2005, 6, 15)); // ✓ Valid
  /// constraint.validate(DateTime(1999, 12, 31)); // ✗ Invalid
  /// ```
  factory DateTimeConstraint.min(DateTime date) => DateTimeConstraint._(
        type: DateTimeComparisonType.min,
        reference: date,
        constraintKey: 'datetime_min',
        description: 'Must be on or after ${date.toIso8601String()}',
      );

  /// Creates a constraint that validates the DateTime is on or before [date] (inclusive).
  ///
  /// Example:
  /// ```dart
  /// final constraint = DateTimeConstraint.max(DateTime(2025, 12, 31));
  /// constraint.validate(DateTime(2025, 12, 31)); // ✓ Valid (inclusive)
  /// constraint.validate(DateTime(2020, 1, 1)); // ✓ Valid
  /// constraint.validate(DateTime(2026, 1, 1)); // ✗ Invalid
  /// ```
  factory DateTimeConstraint.max(DateTime date) => DateTimeConstraint._(
        type: DateTimeComparisonType.max,
        reference: date,
        constraintKey: 'datetime_max',
        description: 'Must be on or before ${date.toIso8601String()}',
      );

  @override
  bool isValid(DateTime value) {
    switch (type) {
      case DateTimeComparisonType.min:
        return !value.isBefore(reference); // >= (on or after)
      case DateTimeComparisonType.max:
        return !value.isAfter(reference); // <= (on or before)
    }
  }

  @override
  String buildMessage(DateTime value) {
    switch (type) {
      case DateTimeComparisonType.min:
        return 'Date must be on or after ${reference.toIso8601String()}, got ${value.toIso8601String()}';
      case DateTimeComparisonType.max:
        return 'Date must be on or before ${reference.toIso8601String()}, got ${value.toIso8601String()}';
    }
  }

  @override
  Map<String, Object?> buildContext(DateTime value) {
    return {
      'value': value.toIso8601String(),
      'reference': reference.toIso8601String(),
      'comparisonType': type.name,
    };
  }

  @override
  Map<String, Object?> toJsonSchema() {
    // JSON Schema Draft 2019-09 and later support formatMinimum/formatMaximum
    // for validating string formats like dates.
    // See: https://json-schema.org/draft/2019-09/json-schema-validation.html#rfc.section.7.3
    switch (type) {
      case DateTimeComparisonType.min:
        return {'formatMinimum': reference.toIso8601String()};
      case DateTimeComparisonType.max:
        return {'formatMaximum': reference.toIso8601String()};
    }
  }
}
