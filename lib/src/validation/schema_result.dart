part of '../ack_base.dart';

/// A class representing a Result which can be either `Ok` (success) or `Fail` (failure).
class SchemaResult<T extends Object> {
  const SchemaResult();

  /// Returns `true` if the result is `Ok`
  bool get isOk => this is Ok<T>;

  /// Returns `true` if the result is `Fail`
  bool get isFail => this is Fail<T>;

  static SchemaResult<T> ok<T extends Object>(T value) {
    return Ok(value);
  }

  static SchemaResult<T> fail<T extends Object>(List<SchemaError> errors) {
    return Fail(errors);
  }

  R match<R>({
    required R Function(T value) onOk,
    required R Function(List<SchemaError> errors) onFail,
  }) {
    final self = this;
    if (self is Ok<T>) return onOk(self.value);
    return onFail((self as Fail<T>).errors);
  }

  void onFail(void Function(List<SchemaError> errors) onFail) {
    match(
      onOk: (_) {},
      onFail: (error) => onFail(error),
    );
  }

  void onOk(void Function(T value) onOk) {
    match(
      onOk: (value) => onOk(value),
      onFail: (_) {},
    );
  }
}

/// Represents a successful result.
final class Ok<T extends Object> extends SchemaResult<T> {
  final T value;
  const Ok(this.value);

  const Ok.unit() : value = _unit as T;
}

/// Represents an error result.
class Fail<T extends Object> extends SchemaResult<T> {
  final List<SchemaError> errors;
  const Fail(this.errors);
}

const _unit = Null._();

class Null {
  const Null._();
}
