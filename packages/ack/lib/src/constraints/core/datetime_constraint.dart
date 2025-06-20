import '../constraint.dart';

/// Supported comparison types for DateConstraint.
enum DateComparisonType {
  onOrAfter,
  onOrBefore,
  valid,
}

/// Constraint for comparing or validating [DateTime] values and ISO date strings.
class DateConstraint extends Constraint<DateTime>
    with Validator<DateTime>, JsonSchemaSpec<DateTime> {
  final DateComparisonType type;
  final DateTime? reference;
  final DateTime? referenceEnd; // Used for range

  // Only for the 'valid' format case:
  final bool Function(String)? formatValidator;
  final String Function(String value)? customMessageBuilder;

  const DateConstraint._({
    required this.type,
    this.reference,
    this.referenceEnd,
    required super.constraintKey,
    required super.description,
    this.formatValidator,
    this.customMessageBuilder,
  }) : assert(
          (referenceEnd != null),
          'referenceEnd required for range type',
        );

  // ---------- Format Validators ----------

  /// Validates that a string is a valid ISO 8601 date-time.
  static DateConstraint dateTime() => DateConstraint._(
        type: DateComparisonType.valid,
        constraintKey: 'datetime',
        description: 'Must be a valid ISO 8601 date-time',
        formatValidator: (value) => DateTime.tryParse(value) != null,
        customMessageBuilder: (value) =>
            'Invalid date-time (ISO 8601 required).',
      );

  /// Validates that a string is a valid ISO 8601 date (YYYY-MM-DD).
  static DateConstraint date() => DateConstraint._(
        type: DateComparisonType.valid,
        constraintKey: 'date',
        description: 'Must be a valid date in YYYY-MM-DD format',
        formatValidator: (value) {
          final date = DateTime.tryParse(value);
          if (date == null) return false;
          final formatted = '${date.year.toString().padLeft(4, '0')}-'
              '${date.month.toString().padLeft(2, '0')}-'
              '${date.day.toString().padLeft(2, '0')}';
          return formatted == value;
        },
        customMessageBuilder: (value) =>
            'Invalid date. YYYY-MM-DD required. Ex: 2017-07-21',
      );

  // ---------- Comparison Validators ----------

  /// The input date must be on or after [date] (inclusive).
  factory DateConstraint.onOrAfter(DateTime date) => DateConstraint._(
        type: DateComparisonType.onOrAfter,
        reference: date,
        constraintKey: 'datetime_on_or_after',
        description: 'Must be on or after ${date.toIso8601String()}',
      );

  /// The input date must be on or before [date] (inclusive).
  factory DateConstraint.onOrBefore(DateTime date) => DateConstraint._(
        type: DateComparisonType.onOrBefore,
        reference: date,
        constraintKey: 'datetime_on_or_before',
        description: 'Must be on or before ${date.toIso8601String()}',
      );

  // ---------- Validation ----------

  @override
  bool isValid(DateTime value) {
    switch (type) {
      case DateComparisonType.onOrAfter:
        return !value.isBefore(reference!);
      case DateComparisonType.onOrBefore:
        return !value.isAfter(reference!);
      case DateComparisonType.valid:
        return true;
    }
  }

  /// For format validation, use this method.
  ConstraintError? validateString(String value) {
    if (type == DateComparisonType.valid) {
      final isValid = formatValidator!(value);
      if (!isValid) {
        return ConstraintError(
          message: customMessageBuilder?.call(value) ?? 'Invalid format',
          constraint: this,
          context: {'value': value},
        );
      }
      return null;
    } else {
      // For comparison constraints, require parsing the string first.
      DateTime? parsed = DateTime.tryParse(value);
      if (parsed == null) {
        return ConstraintError(
          message: 'Invalid date-time format.',
          constraint: this,
          context: {'value': value},
        );
      }
      return validate(parsed);
    }
  }

  @override
  String buildMessage(DateTime value) {
    switch (type) {
      case DateComparisonType.onOrAfter:
        return 'Must be on or after ${reference!.toIso8601String()}';
      case DateComparisonType.onOrBefore:
        return 'Must be on or before ${reference!.toIso8601String()}';
      case DateComparisonType.valid:
        return 'Invalid format';
    }
  }

  @override
  Map<String, Object?> buildContext(DateTime value) {
    final context = <String, Object?>{'value': value};
    if (reference != null) context['reference'] = reference;
    if (referenceEnd != null) context['referenceEnd'] = referenceEnd;
    return context;
  }

  @override
  Map<String, Object?> toJsonSchema() {
    switch (type) {
      case DateComparisonType.onOrAfter:
        return {
          'format': 'date-time',
          'minimum': reference!.toIso8601String(),
        };
      case DateComparisonType.onOrBefore:
        return {
          'format': 'date-time',
          'maximum': reference!.toIso8601String(),
        };
      case DateComparisonType.valid:
        return {
          'format': constraintKey == 'date' ? 'date' : 'date-time',
        };
    }
  }
}
