import '../../constraints/duration_constraint.dart';
import '../schema.dart';

/// Extensions for `TransformedSchema<int, Duration>` to add range validation.
///
/// These extensions work with schemas created by [Ack.duration()], which parse
/// integer milliseconds into [Duration] objects.
///
/// Example:
/// ```dart
/// // Timeout validation
/// final timeoutSchema = Ack.duration().min(Duration(minutes: 1)).max(Duration(hours: 1));
/// ```
extension DurationSchemaExtensions on TransformedSchema<int, Duration> {
  /// Constrains the duration to be on or after [minDuration] (inclusive).
  ///
  /// The constraint is applied to the transformed Duration value, after the
  /// integer has been validated and converted.
  TransformedSchema<int, Duration> min(Duration minDuration) {
    return copyWith(
      constraints: [...constraints, DurationConstraint.min(minDuration)],
    );
  }

  /// Constrains the duration to be on or before [maxDuration] (inclusive).
  ///
  /// The constraint is applied to the transformed Duration value, after the
  /// integer has been validated and converted.
  TransformedSchema<int, Duration> max(Duration maxDuration) {
    return copyWith(
      constraints: [...constraints, DurationConstraint.max(maxDuration)],
    );
  }
}
