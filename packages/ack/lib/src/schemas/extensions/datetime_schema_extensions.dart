import '../../constraints/constraint.dart';
import '../../constraints/datetime_constraint.dart';
import '../schema.dart';

/// Extensions for `CodecSchema<String, DateTime>` to add date range
/// validation. Works against the [ConfigurableSchema] surface, not the
/// concrete `CodecSchemaImpl`, so user-provided codec subclasses also
/// benefit.
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
    final configurable = this as ConfigurableSchema<String, DateTime>;
    return configurable.withRuntimeConfig(
      constraints: [...constraints, constraint],
    ) as CodecSchema<String, DateTime>;
  }
}
