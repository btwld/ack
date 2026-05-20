import 'constraint.dart';

/// Type of date/time comparison operation to perform.
enum DateTimeComparisonType { min, max }

/// Boundary format used when serializing date/time JSON Schema constraints.
enum DateTimeConstraintFormat { date, dateTime }

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
  final DateTimeConstraintFormat format;

  const DateTimeConstraint._({
    required this.type,
    required this.reference,
    required this.format,
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
  factory DateTimeConstraint.min(
    DateTime date, {
    DateTimeConstraintFormat format = DateTimeConstraintFormat.dateTime,
  }) {
    return DateTimeConstraint._(
      type: DateTimeComparisonType.min,
      reference: date,
      format: format,
      constraintKey: 'datetime_min',
      description: 'Must be on or after ${_formatReference(date, format)}',
    );
  }

  /// Creates a constraint that validates the DateTime is on or before [date] (inclusive).
  ///
  /// Example:
  /// ```dart
  /// final constraint = DateTimeConstraint.max(DateTime(2025, 12, 31));
  /// constraint.validate(DateTime(2025, 12, 31)); // ✓ Valid (inclusive)
  /// constraint.validate(DateTime(2020, 1, 1)); // ✓ Valid
  /// constraint.validate(DateTime(2026, 1, 1)); // ✗ Invalid
  /// ```
  factory DateTimeConstraint.max(
    DateTime date, {
    DateTimeConstraintFormat format = DateTimeConstraintFormat.dateTime,
  }) {
    return DateTimeConstraint._(
      type: DateTimeComparisonType.max,
      reference: date,
      format: format,
      constraintKey: 'datetime_max',
      description: 'Must be on or before ${_formatReference(date, format)}',
    );
  }

  @override
  bool isValid(DateTime value) => switch (type) {
    DateTimeComparisonType.min => !value.isBefore(
      reference,
    ), // >= (on or after)
    DateTimeComparisonType.max => !value.isAfter(
      reference,
    ), // <= (on or before)
  };

  @override
  String buildMessage(DateTime value) => switch (type) {
    DateTimeComparisonType.min =>
      'Date must be on or after ${_formatReference(reference, format)}, got ${value.toIso8601String()}',
    DateTimeComparisonType.max =>
      'Date must be on or before ${_formatReference(reference, format)}, got ${value.toIso8601String()}',
  };

  @override
  Map<String, Object?> buildContext(DateTime value) {
    return {
      'value': value.toIso8601String(),
      'reference': reference.toIso8601String(),
      'comparisonType': type.name,
    };
  }

  @override
  Map<String, Object?> toJsonSchema() =>
      // JSON Schema Draft 2019-09 and later support formatMinimum/formatMaximum
      // for validating string formats like dates.
      // See: https://json-schema.org/draft/2019-09/json-schema-validation.html#rfc.section.7.3
      switch (type) {
        DateTimeComparisonType.min => {
          'formatMinimum': _formatReference(reference, format),
        },
        DateTimeComparisonType.max => {
          'formatMaximum': _formatReference(reference, format),
        },
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DateTimeConstraint) return false;
    if (runtimeType != other.runtimeType) return false;
    return constraintKey == other.constraintKey &&
        description == other.description &&
        type == other.type &&
        reference == other.reference &&
        format == other.format;
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    constraintKey,
    description,
    type,
    reference,
    format,
  );
}

String _formatReference(DateTime reference, DateTimeConstraintFormat format) {
  return switch (format) {
    DateTimeConstraintFormat.date =>
      '${reference.year.toString().padLeft(4, '0')}-'
          '${reference.month.toString().padLeft(2, '0')}-'
          '${reference.day.toString().padLeft(2, '0')}',
    DateTimeConstraintFormat.dateTime => reference.toIso8601String(),
  };
}
