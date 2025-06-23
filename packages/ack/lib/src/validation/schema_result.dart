import 'ack_exception.dart';
import 'schema_error.dart';

/// Represents the outcome of a schema validation, which can either be
/// a success ([Ok]) containing the validated value, or a failure ([Fail])
/// containing a [SchemaError].
///
/// This class promotes explicit error handling without relying on exceptions
/// for control flow when using the `validate()` method.
sealed class SchemaResult<T> {
  const SchemaResult();

  /// Creates a successful result wrapping the given [value].
  static SchemaResult<T> ok<T>(T value) {
    return Ok(value);
  }

  /// Creates a failure result wrapping the specified [error].
  static SchemaResult<T> fail<T>(SchemaError error) {
    return Fail(error);
  }

  /// Indicates whether this result is successful.
  bool get isOk => this is Ok<T>;

  /// Indicates whether this result represents a failure.
  bool get isFail => this is Fail<T>;

  /// Returns the [SchemaError] if this result is a failure.
  /// Throws a [StateError] if called on a successful result.
  SchemaError getError() {
    return switch (this) {
      Ok() => throw StateError('Cannot get error from a successful Ok result.'),
      Fail(error: final e) => e,
    };
  }

  /// Returns the contained value if this result is successful; otherwise, returns `null`.
  /// The returned value itself can be `null` if `T` is nullable (e.g. `T = String?`)
  /// and the validation resulted in `Ok(null)`.
  T? getOrNull() {
    return switch (this) {
      Ok(value: final v) => v,
      Fail() => null,
    };
  }

  /// Returns the contained value if successful, otherwise returns the result of [orElse].
  /// If the successful value is `null` (for nullable schemas), [orElse] is still NOT called.
  T getOrElse(T Function() orElse) {
    return switch (this) {
      Ok(value: final v) => v,
      Fail() => orElse(),
    };
  }

  /// Returns the contained value if successful; otherwise, throws an [AckException].
  /// The returned value can be `null` if the schema is nullable.
  T getOrThrow() {
    return switch (this) {
      Ok(value: final v) => v,
      Fail(error: final e) => throw AckException(e),
    };
  }

  /// Executes one of the provided callbacks based on the result's type.
  R match<R>({
    required R Function(T value) onOk,
    required R Function(SchemaError error) onFail,
  }) {
    return switch (this) {
      Ok(value: final v) => onOk(v),
      Fail(error: final e) => onFail(e),
    };
  }

  /// Executes [action] if this result is a failure.
  void ifFail(void Function(SchemaError error) action) {
    if (this case Fail(error: final e)) {
      action(e);
    }
  }

  /// Executes [action] if this result is successful.
  /// The [value] passed to the action can be `null` if `T` is nullable.
  void ifOk(void Function(T value) action) {
    if (this case Ok(value: final v)) {
      action(v);
    }
  }
}

/// Represents a successful validation outcome, optionally wrapping a [value].
/// The [_value] can be `null` if `T` is nullable (e.g., `T = String?`).
class Ok<T> extends SchemaResult<T> {
  final T _value;
  const Ok(this._value);

  T get value => _value;
}

/// Represents a failed validation outcome, containing a [SchemaError].
class Fail<T> extends SchemaResult<T> {
  final SchemaError error;
  const Fail(this.error);
}
