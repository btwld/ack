import '../../constraints/duration_constraint.dart';
import '../schema.dart';

/// Extensions for `CodecSchema<int, Duration>` to add range validation.
extension DurationSchemaExtensions on CodecSchema<int, Duration> {
  /// Constrains the duration to be on or after [minDuration] (inclusive).
  CodecSchema<int, Duration> min(Duration minDuration) {
    final self = this;
    if (self is CodecSchemaImpl<int, dynamic, Duration>) {
      return self.copyWith(
        constraints: [
          ...self.constraints,
          DurationConstraint.min(minDuration),
        ],
      );
    }
    throw StateError(
      'min() requires CodecSchemaImpl, got ${self.runtimeType}',
    );
  }

  /// Constrains the duration to be on or before [maxDuration] (inclusive).
  CodecSchema<int, Duration> max(Duration maxDuration) {
    final self = this;
    if (self is CodecSchemaImpl<int, dynamic, Duration>) {
      return self.copyWith(
        constraints: [
          ...self.constraints,
          DurationConstraint.max(maxDuration),
        ],
      );
    }
    throw StateError(
      'max() requires CodecSchemaImpl, got ${self.runtimeType}',
    );
  }
}
