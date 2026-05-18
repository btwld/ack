import '../../constraints/constraint.dart';
import '../../constraints/datetime_constraint.dart';
import '../schema.dart';

/// Extensions for `CodecSchema<String, DateTime>` to add date range
/// validation.
extension DateTimeSchemaExtensions on CodecSchema<String, DateTime> {
  /// Constrains the date to be on or after [minDate] (inclusive).
  CodecSchema<String, DateTime> min(DateTime minDate) =>
      _addConstraint(DateTimeConstraint.min(minDate));

  /// Constrains the date to be on or before [maxDate] (inclusive).
  CodecSchema<String, DateTime> max(DateTime maxDate) =>
      _addConstraint(DateTimeConstraint.max(maxDate));

  CodecSchema<String, DateTime> _addConstraint(
    Constraint<DateTime> constraint,
  ) {
    return withRuntimeConfig(constraints: [...constraints, constraint]);
  }
}
