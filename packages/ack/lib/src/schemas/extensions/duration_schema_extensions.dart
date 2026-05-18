import '../../constraints/constraint.dart';
import '../../constraints/duration_constraint.dart';
import '../schema.dart';

/// Extensions for `CodecSchema<int, Duration>` to add range validation.
extension DurationSchemaExtensions on CodecSchema<int, Duration> {
  /// Constrains the duration to be on or after [minDuration] (inclusive).
  CodecSchema<int, Duration> min(Duration minDuration) =>
      _addConstraint(DurationConstraint.min(minDuration));

  /// Constrains the duration to be on or before [maxDuration] (inclusive).
  CodecSchema<int, Duration> max(Duration maxDuration) =>
      _addConstraint(DurationConstraint.max(maxDuration));

  CodecSchema<int, Duration> _addConstraint(Constraint<Duration> constraint) {
    return withRuntimeConfig(constraints: [...constraints, constraint]);
  }
}
