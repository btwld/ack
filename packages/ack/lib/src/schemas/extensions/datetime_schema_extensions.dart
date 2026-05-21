import '../../constraints/constraint.dart';
import '../../constraints/datetime_constraint.dart';
import '../../schema_model/ack_schema_model_builder.dart';
import '../schema.dart';

/// Extensions for `CodecSchema<String, DateTime>` to add date range
/// validation.
extension DateTimeSchemaExtensions on CodecSchema<String, DateTime> {
  /// Constrains the date to be on or after [minDate] (inclusive).
  CodecSchema<String, DateTime> min(DateTime minDate) {
    return _addConstraint(_dateTimeConstraint(this, minDate, isMinimum: true));
  }

  /// Constrains the date to be on or before [maxDate] (inclusive).
  CodecSchema<String, DateTime> max(DateTime maxDate) {
    return _addConstraint(_dateTimeConstraint(this, maxDate, isMinimum: false));
  }

  CodecSchema<String, DateTime> _addConstraint(
    Constraint<DateTime> constraint,
  ) {
    return withRuntimeConfig(constraints: [...constraints, constraint]);
  }
}

DateTimeConstraint _dateTimeConstraint(
  CodecSchema<String, DateTime> schema,
  DateTime reference, {
  required bool isMinimum,
}) {
  final format = _dateTimeJsonFormat(schema);
  _validateDateTimeReference(reference, format);

  return switch ((format, isMinimum)) {
    ('date', true) => DateTimeConstraint.minDate(reference),
    ('date', false) => DateTimeConstraint.maxDate(reference),
    ('date-time', true) => DateTimeConstraint.minDateTime(reference),
    ('date-time', false) => DateTimeConstraint.maxDateTime(reference),
    _ => throw StateError('Unsupported DateTime JSON Schema format: $format'),
  };
}

String _dateTimeJsonFormat(CodecSchema<String, DateTime> schema) {
  final inputSchema = schema.inputSchema as AckSchema<String, Object>;
  final model = inputSchema.toSchemaModel();
  return switch (model.format) {
    'date' => 'date',
    'date-time' => 'date-time',
    _ => 'date-time',
  };
}

void _validateDateTimeReference(DateTime reference, String format) {
  switch (format) {
    case 'date':
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
    case 'date-time':
      if (!reference.isUtc) {
        throw ArgumentError.value(
          reference,
          'reference',
          'Ack.datetime() constraints require a UTC DateTime.',
        );
      }
    default:
      throw StateError('Unsupported DateTime JSON Schema format: $format');
  }
}
