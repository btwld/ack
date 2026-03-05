import 'constraint.dart';

/// Type of duration comparison operation to perform.
enum DurationComparisonType { min, max }

/// A constraint for validating Duration values against minimum and maximum bounds.
///
/// This constraint is specifically designed for Duration validation and provides
/// inclusive range checking (on or after for min, on or before for max, in
/// milliseconds).
///
/// Used internally by [Ack.duration()] schemas when applying [.min()] or [.max()]
/// constraints.
class DurationConstraint extends Constraint<Duration>
    with Validator<Duration>, JsonSchemaSpec<Duration> {
  final DurationComparisonType type;
  final Duration reference;

  const DurationConstraint._({
    required this.type,
    required this.reference,
    required super.constraintKey,
    required super.description,
  });

  /// Creates a constraint that validates the Duration is on or after [duration]
  /// (in milliseconds), inclusive.
  ///
  /// Example:
  /// ```dart
  /// final constraint = DurationConstraint.min(Duration(seconds: 5));
  /// constraint.validate(Duration(seconds: 5)); // ✓ Valid (inclusive)
  /// constraint.validate(Duration(seconds: 10)); // ✓ Valid
  /// constraint.validate(Duration(seconds: 4)); // ✗ Invalid
  /// ```
  factory DurationConstraint.min(Duration duration) => DurationConstraint._(
    type: DurationComparisonType.min,
    reference: duration,
    constraintKey: 'duration_min',
    description: 'Must be at least ${duration.inMilliseconds} milliseconds.',
  );

  /// Creates a constraint that validates the Duration is on or before [duration]
  /// (in milliseconds), inclusive.
  ///
  /// Example:
  /// ```dart
  /// final constraint = DurationConstraint.max(Duration(minutes: 30));
  /// constraint.validate(Duration(minutes: 30)); // ✓ Valid (inclusive)
  /// constraint.validate(Duration(minutes: 29)); // ✓ Valid
  /// constraint.validate(Duration(minutes: 31)); // ✗ Invalid
  /// ```
  factory DurationConstraint.max(Duration duration) => DurationConstraint._(
    type: DurationComparisonType.max,
    reference: duration,
    constraintKey: 'duration_max',
    description: 'Must be at most ${duration.inMilliseconds} milliseconds.',
  );

  @override
  bool isValid(Duration value) => switch (type) {
    DurationComparisonType.min =>
      value.inMilliseconds >= reference.inMilliseconds,
    DurationComparisonType.max =>
      value.inMilliseconds <= reference.inMilliseconds,
  };

  @override
  String buildMessage(Duration value) => switch (type) {
    DurationComparisonType.min =>
      'Duration must be at least ${reference.inMilliseconds} milliseconds, got ${value.inMilliseconds} milliseconds.',
    DurationComparisonType.max =>
      'Duration must be at most ${reference.inMilliseconds} milliseconds, got ${value.inMilliseconds} milliseconds.',
  };

  @override
  Map<String, Object?> buildContext(Duration value) {
    return {
      'value': value.inMilliseconds,
      'reference': reference.inMilliseconds,
      'comparisonType': type.name,
    };
  }

  @override
  Map<String, Object?> toJsonSchema() => switch (type) {
    DurationComparisonType.min => {'minimum': reference.inMilliseconds},
    DurationComparisonType.max => {'maximum': reference.inMilliseconds},
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DurationConstraint) return false;
    if (runtimeType != other.runtimeType) return false;
    return constraintKey == other.constraintKey &&
        description == other.description &&
        type == other.type &&
        reference == other.reference;
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, constraintKey, description, type, reference);
}
