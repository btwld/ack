part of '../ack.dart';

/// Represents either a successful outcome or a failure.
///
/// A [SchemaResult] encapsulates a successful value (an [Ok] instance)
/// or a failure (a [Fail] instance containing a list of [SchemaError]s).
class SchemaResult<T extends Object> {
  /// Creates a new [SchemaResult] instance.
  const SchemaResult();

  /// Returns a successful result that wraps the given [value].
  static SchemaResult<T> ok<T extends Object>(T value) {
    return Ok(value);
  }

  /// Returns a failure result that wraps the specified list of [errors].
  static SchemaResult<T> fail<T extends Object>(List<SchemaError> errors) {
    return Fail(errors);
  }

  /// Indicates whether this result is successful.
  ///
  /// Returns `true` if this instance is an [Ok].
  bool get isOk => this is Ok<T>;

  /// Indicates whether this result represents a failure.
  ///
  /// Returns `true` if this instance is a [Fail].
  bool get isFail => this is Fail<T>;

  /// Returns the contained value if this result is successful; otherwise, returns `null`.
  T? getOrNull() {
    return match(onOk: (value) => value.getOrNull(), onFail: (_) => null);
  }

  /// Returns the contained value if this result is successful; otherwise, returns the result of [orElse].
  ///
  /// If this instance is an [Ok], it returns its contained value.
  /// Otherwise, it returns the value produced by invoking [orElse].
  T getOrElse(T Function() orElse) {
    return match(
      onOk: (value) => value.getOrElse(orElse),
      onFail: (_) => orElse(),
    );
  }

  /// Returns the contained value if this result is successful; otherwise, throws an [AckException].
  ///
  /// If this instance is an [Ok], it returns its contained value.
  /// Otherwise, it throws an [AckException] with the associated errors.
  T getOrThrow() {
    return match(
      onOk: (value) => value.getOrThrow(),
      onFail: (errors) => throw AckException(errors),
    );
  }

  /// Executes the appropriate callback based on whether this result is successful or a failure.
  ///
  /// If this instance is an [Ok], it invokes [onOk] with the contained value.
  /// If this instance is a [Fail], it invokes [onFail] with the associated errors.
  ///
  /// Returns the result of the invoked callback.
  R match<R>({
    required R Function(Ok<T> value) onOk,
    required R Function(List<SchemaError> errors) onFail,
  }) {
    final self = this;
    if (self is Ok<T>) return onOk(self);

    return onFail((self as Fail<T>).errors);
  }

  /// Invokes [onFail] if this result represents a failure.
  ///
  /// If this instance is a [Fail], it calls [onFail] with its list of errors.
  /// Otherwise, it does nothing.
  void onFail(void Function(List<SchemaError> errors) onFail) {
    match(onOk: (_) {}, onFail: onFail);
  }

  /// Invokes [onOk] if this result is successful.
  ///
  /// If this instance is an [Ok], it calls [onOk] with its contained value.
  /// Otherwise, it does nothing.
  void onOk(void Function(Ok<T> value) onOk) {
    match(onOk: onOk, onFail: (_) {});
  }
}

/// Represents a successful outcome that optionally wraps a value.
///
/// An [Ok] instance indicates that an operation succeeded and may contain a value.
/// If no meaningful value is provided, [getOrNull] returns `null`.
final class Ok<T extends Object> extends SchemaResult<T> {
  final T? _value;

  const

  /// Creates a successful result that wraps the given [value].
  Ok(this._value);

  /// Returns the contained value, or `null` if no value is present.
  @override
  T? getOrNull() => _value;

  /// Returns the contained value if present; otherwise, returns the result of [orElse].
  @override
  T getOrElse(T Function() orElse) {
    return _value ?? orElse();
  }

  /// Returns the contained value, or throws an exception if the value is `null`.
  @override
  T getOrThrow() => _value!;
}

/// Represents a failure outcome with associated errors.
///
/// A [Fail] instance indicates that an operation failed and encapsulates a list
/// of [SchemaError]s describing what went wrong.
class Fail<T extends Object> extends SchemaResult<T> {
  /// The list of errors associated with this failure.
  final List<SchemaError> errors;

  /// Creates a failure result with the specified [errors].
  const Fail(this.errors);
}
