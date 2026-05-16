import '../../constraints/datetime_constraint.dart';
import '../schema.dart';

/// Extensions for `CodecSchema<String, DateTime>` to add date range validation.
extension DateTimeSchemaExtensions on CodecSchema<String, DateTime> {
  /// Constrains the date to be on or after [minDate] (inclusive).
  CodecSchema<String, DateTime> min(DateTime minDate) {
    final self = this;
    if (self is CodecSchemaImpl<String, dynamic, DateTime>) {
      return self.copyWith(
        constraints: [...self.constraints, DateTimeConstraint.min(minDate)],
      );
    }
    throw StateError(
      'min() requires CodecSchemaImpl, got ${self.runtimeType}',
    );
  }

  /// Constrains the date to be on or before [maxDate] (inclusive).
  CodecSchema<String, DateTime> max(DateTime maxDate) {
    final self = this;
    if (self is CodecSchemaImpl<String, dynamic, DateTime>) {
      return self.copyWith(
        constraints: [...self.constraints, DateTimeConstraint.max(maxDate)],
      );
    }
    throw StateError(
      'max() requires CodecSchemaImpl, got ${self.runtimeType}',
    );
  }
}
