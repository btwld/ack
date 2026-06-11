import 'constraint.dart';

/// A constraint for validating DateTime values against minimum and maximum bounds.
///
/// This constraint is specifically designed for DateTime validation and provides
/// inclusive range checking (on or after for min, on or before for max).
///
/// Used internally by [Ack.date()] and [Ack.datetime()] schemas when applying
/// [.min()] or [.max()] constraints.
class DateTimeConstraint extends Constraint<DateTime>
    with Validator<DateTime>, JsonSchemaSpec<DateTime> {
  final DateTime reference;

  /// The JSON Schema format associated with the boundary schema.
  ///
  /// Used by schema-model builders for warnings because Draft-7 cannot emit
  /// standard range keywords for date/date-time formats.
  final String jsonSchemaFormat;

  /// The reference value rendered in the boundary schema's format.
  final String formattedReference;

  final bool _isMinimum;

  const DateTimeConstraint._({
    required this.reference,
    required bool isMinimum,
    required this.jsonSchemaFormat,
    required this.formattedReference,
    required super.constraintKey,
    required super.description,
  }) : _isMinimum = isMinimum;

  /// Creates a date-formatted minimum constraint for `Ack.date()`.
  factory DateTimeConstraint.minDate(DateTime date) {
    return DateTimeConstraint._range(date, isMinimum: true, format: 'date');
  }

  /// Creates a date-time-formatted minimum constraint for `Ack.datetime()`.
  factory DateTimeConstraint.minDateTime(DateTime date) {
    return DateTimeConstraint._range(
      date,
      isMinimum: true,
      format: 'date-time',
    );
  }

  /// Creates a date-formatted maximum constraint for `Ack.date()`.
  factory DateTimeConstraint.maxDate(DateTime date) {
    return DateTimeConstraint._range(date, isMinimum: false, format: 'date');
  }

  /// Creates a date-time-formatted maximum constraint for `Ack.datetime()`.
  factory DateTimeConstraint.maxDateTime(DateTime date) {
    return DateTimeConstraint._range(
      date,
      isMinimum: false,
      format: 'date-time',
    );
  }

  factory DateTimeConstraint._range(
    DateTime date, {
    required bool isMinimum,
    required String format,
  }) {
    final formattedReference = format == 'date'
        ? _dateOnly(date)
        : date.toIso8601String();
    final comparison = isMinimum ? 'on or after' : 'on or before';

    return DateTimeConstraint._(
      reference: date,
      isMinimum: isMinimum,
      jsonSchemaFormat: format,
      formattedReference: formattedReference,
      constraintKey: isMinimum ? 'datetime_min' : 'datetime_max',
      description: 'Must be $comparison $formattedReference',
    );
  }

  String _formatValue(DateTime value) {
    if (jsonSchemaFormat == 'date') return _dateOnly(value);

    return value.toIso8601String();
  }

  String get comparisonType => _isMinimum ? 'min' : 'max';

  @override
  bool isValid(DateTime value) =>
      _isMinimum ? !value.isBefore(reference) : !value.isAfter(reference);

  @override
  String buildMessage(DateTime value) =>
      'Date must be ${_isMinimum ? 'on or after' : 'on or before'} '
      '$formattedReference, got ${_formatValue(value)}';

  @override
  Map<String, Object?> buildContext(DateTime value) {
    return {
      'value': _formatValue(value),
      'reference': formattedReference,
      'comparisonType': comparisonType,
    };
  }

  @override
  // `formatMinimum`/`formatMaximum` are Draft 2019-09+ extensions that
  // Draft-7 consumers do not understand. The model builder surfaces these
  // bounds as `datetime_constraint_not_draft7` warnings instead of emitting
  // unrecognized keywords; we mirror that policy here so direct callers see
  // the same output as the model boundary.
  Map<String, Object?> toJsonSchema() => const {};

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DateTimeConstraint) return false;
    if (runtimeType != other.runtimeType) return false;

    return constraintKey == other.constraintKey &&
        description == other.description &&
        _isMinimum == other._isMinimum &&
        reference == other.reference &&
        jsonSchemaFormat == other.jsonSchemaFormat &&
        formattedReference == other.formattedReference;
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    constraintKey,
    description,
    _isMinimum,
    reference,
    jsonSchemaFormat,
    formattedReference,
  );
}

String _dateOnly(DateTime reference) {
  return '${reference.year.toString().padLeft(4, '0')}-'
      '${reference.month.toString().padLeft(2, '0')}-'
      '${reference.day.toString().padLeft(2, '0')}';
}
