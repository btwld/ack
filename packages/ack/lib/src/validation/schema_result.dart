import 'ack_exception.dart';
import 'schema_error.dart';

/// Represents either a successful outcome or a failure.
///
/// A [SchemaResult] encapsulates a successful value (an [Ok] instance)
/// or a failure (a [Fail] instance containing a list of [SchemaError]s).
sealed class SchemaResult<T extends Object> {
  /// Creates a new [SchemaResult] instance.
  const SchemaResult();

  /// Returns a successful result that wraps the given [value].
  static SchemaResult<T> ok<T extends Object>(T value) {
    return Ok(value);
  }

  /// Returns a failure result that wraps the specified list of [errors].
  static SchemaResult<T> fail<T extends Object>(SchemaError error) {
    return Fail(error);
  }

  static SchemaResult<T> unit<T extends Object>() {
    return Ok(null);
  }

  /// Indicates whether this result is successful.
  ///
  /// Returns `true` if this instance is an [Ok].
  bool get isOk => this is Ok<T>;

  /// Indicates whether this result represents a failure.
  ///
  /// Returns `true` if this instance is a [Fail].
  bool get isFail => this is Fail<T>;

  /// Returns the list of errors associated with this result.
  ///
  /// If this result is successful, it returns an empty list.
  /// If this result is a failure, it returns the list of errors.
  SchemaError getError() {
    return match(
      onOk: (_) => throw Exception('Cannot get error from Ok'),
      onFail: (error) => error,
    );
  }

  /// Returns the contained value if this result is successful; otherwise, returns `null`.
  T? getOrNull() {
    return match(onOk: (value) => value, onFail: (_) => null);
  }

  /// Returns the contained value if this result is successful; otherwise, returns the result of [orElse].
  ///
  /// If this instance is an [Ok], it returns its contained value.
  /// Otherwise, it returns the value produced by invoking [orElse].
  T getOrElse(T Function() orElse) {
    return match(onOk: (value) => value ?? orElse(), onFail: (_) => orElse());
  }

  /// Returns the contained value if this result is successful; otherwise, throws an [AckException].
  ///
  /// If this instance is an [Ok], it returns its contained value.
  /// Otherwise, it throws an [AckException] with the associated errors.
  T getOrThrow() {
    return match(
      onOk: (value) => value ?? (throw Exception('Value of ok is null')),
      onFail: (error) => throw AckException(error),
    );
  }

  /// Executes the appropriate callback based on whether this result is successful or a failure.
  ///
  /// If this instance is an [Ok], it invokes [onOk] with the contained value.
  /// If this instance is a [Fail], it invokes [onFail] with the associated errors.
  ///
  /// Returns the result of the invoked callback.
  R match<R>({
    required R Function(T? value) onOk,
    required R Function(SchemaError error) onFail,
  }) {
    final self = this;

    if (self is Ok<T>) {
      final value = self._value;

      return onOk(value);
    }

    return onFail((self as Fail<T>).error);
  }

  /// Invokes [onFail] if this result represents a failure.
  ///
  /// If this instance is a [Fail], it calls [onFail] with its list of errors.
  /// Otherwise, it does nothing.
  void onFail(void Function(SchemaError error) onFail) {
    match(onOk: (_) {}, onFail: onFail);
  }

  /// Invokes [onOk] if this result is successful.
  ///
  /// If this instance is an [Ok], it calls [onOk] with its contained value.
  /// Otherwise, it does nothing.
  void onOk(void Function(T value) onOk) {
    match(onOk: (value) => value == null ? () : onOk(value), onFail: (_) {});
  }
}

/// Represents a successful outcome that optionally wraps a value.
///
/// An [Ok] instance indicates that an operation succeeded and may contain a value.
/// If no meaningful value is provided, [getOrNull] returns `null`.
final class Ok<T extends Object> extends SchemaResult<T> {
  final T? _value;

  const Ok(this._value);
}

/// Represents a failure outcome with associated errors.
///
/// A [Fail] instance indicates that an operation failed and encapsulates a list
/// of [SchemaError]s describing what went wrong.
class Fail<T extends Object> extends SchemaResult<T> {
  /// The list of errors associated with this failure.

  final SchemaError error;

  /// Creates a failure result with the specified [error].
  const Fail(this.error);
}
