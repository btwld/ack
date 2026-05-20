import '../../constraints/constraint.dart';
import '../../constraints/datetime_constraint.dart';
import '../../schema_model/ack_schema_model_builder.dart';
import '../schema.dart';

/// Extensions for `CodecSchema<String, DateTime>` to add date range
/// validation.
extension DateTimeSchemaExtensions on CodecSchema<String, DateTime> {
  /// Constrains the date to be on or after [minDate] (inclusive).
  CodecSchema<String, DateTime> min(DateTime minDate) {
    final format = _dateTimeConstraintFormat(this);
    _validateDateTimeReference(minDate, format);
    return _addConstraint(DateTimeConstraint.min(minDate, format: format));
  }

  /// Constrains the date to be on or before [maxDate] (inclusive).
  CodecSchema<String, DateTime> max(DateTime maxDate) {
    final format = _dateTimeConstraintFormat(this);
    _validateDateTimeReference(maxDate, format);
    return _addConstraint(DateTimeConstraint.max(maxDate, format: format));
  }

  CodecSchema<String, DateTime> _addConstraint(
    Constraint<DateTime> constraint,
  ) {
    return withRuntimeConfig(constraints: [...constraints, constraint]);
  }
}

DateTimeConstraintFormat _dateTimeConstraintFormat(
  CodecSchema<String, DateTime> schema,
) {
  final inputSchema = schema.inputSchema as AckSchema<String, Object>;
  final model = inputSchema.toSchemaModel();
  return switch (model.format) {
    'date' => DateTimeConstraintFormat.date,
    'date-time' => DateTimeConstraintFormat.dateTime,
    _ => DateTimeConstraintFormat.dateTime,
  };
}

void _validateDateTimeReference(
  DateTime reference,
  DateTimeConstraintFormat format,
) {
  switch (format) {
    case DateTimeConstraintFormat.date:
      if (reference.isUtc ||
          reference.hour != 0 ||
          reference.minute != 0 ||
          reference.second != 0 ||
          reference.millisecond != 0 ||
          reference.microsecond != 0) {
        throw ArgumentError.value(
          reference,
          'reference',
          'Ack.date() constraints require a local DateTime at midnight.',
        );
      }
    case DateTimeConstraintFormat.dateTime:
      if (!reference.isUtc) {
        throw ArgumentError.value(
          reference,
          'reference',
          'Ack.datetime() constraints require a UTC DateTime.',
        );
      }
  }
}
