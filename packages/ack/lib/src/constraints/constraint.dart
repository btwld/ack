import 'package:meta/meta.dart';

/// Base class for all validation constraints.
///
/// A [Constraint] defines a specific rule that a value must adhere to.
/// It holds a unique `constraintKey` for identification and a `description`.
@immutable
abstract class Constraint<T> {
  final String constraintKey;
  final String description;

  const Constraint({required this.constraintKey, required this.description});

  /// Serializes the basic information of this constraint to a map.
  Map<String, Object?> toMap() {
    return {'constraintKey': constraintKey, 'description': description};
  }

  @override
  String toString() =>
      '$runtimeType(constraintKey: $constraintKey, description: "$description")';
}

/// Represents an error that occurred due to a violated constraint.
///
/// It holds the [constraint] that failed, a descriptive [message],
/// and optional [context] providing more details about the failure.
@immutable
class ConstraintError {
  final Constraint constraint;
  final String message;
  final Map<String, Object?>? context;

  const ConstraintError({
    required this.constraint,
    required this.message,
    this.context,
  });

  /// The unique key of the constraint that failed.
  String get constraintKey => constraint.constraintKey;

  /// Serializes this error to a map.
  Map<String, Object?> toMap() {
    return {
      'message': message,
      'constraintKey': constraint.constraintKey,
      'constraintDescription': constraint.description,
      if (context != null) 'context': context,
    };
  }

  @override
  String toString() =>
      'ConstraintError(key: $constraintKey, message: "$message")';
}

/// Mixin for constraints that can be converted to a JSON Schema representation.
///
/// This mixin defines the contract for converting constraint validation rules
/// into a format compliant with JSON Schema (typically Draft-07 or later).
mixin JsonSchemaSpec<T> on Constraint<T> {
  /// Converts this constraint to its JSON Schema representation.
  ///
  /// Returns a map containing JSON Schema keywords that represent this constraint.
  /// Example: `{'minLength': 5}` or `{'pattern': '^[a-z]+$'}`.
  Map<String, Object?> toJsonSchema();
}

/// Mixin defining the core validation logic for a [Constraint].
///
/// It provides a structure for checking if a `value` is valid, building
/// an appropriate error `message`, and constructing a `context` map for failures.
mixin Validator<T> on Constraint<T> {
  /// Checks if the given [value] is valid according to this constraint.
  @protected
  bool isValid(T value);

  /// Builds a descriptive error message for an invalid [value].
  @protected
  String buildMessage(T value);

  /// Builds an optional context map providing additional details for an invalid [value].
  /// Stores both the raw value and its string representation for debugging.
  @protected
  Map<String, Object?> buildContext(T value) => {
    'inputValue': value,
    'stringValue': value.toString(),
  };

  /// Validates the [value] against this constraint.
  ///
  /// Returns a [ConstraintError] if the value is invalid, otherwise returns `null`.
  ConstraintError? validate(T value) {
    if (isValid(value)) {
      return null;
    }

    return ConstraintError(
      constraint: this,
      message: buildMessage(value),
      context: buildContext(value),
    );
  }
}
