part of 'ack_base.dart';

sealed class ValidationError {
  final String _message;
  final String type;
  final Map<String, Object?> context;

  const ValidationError({
    required this.type,
    required String message,
    this.context = const {},
  }) : _message = message;

  String get _contextMessage => context.isEmpty
      ? ''
      : context.entries.map((e) => '${e.key}: ${e.value}').join('\n');

  String get message => '$type:\n$_message\n\n$_contextMessage';

  Map<String, Object?> toMap() {
    return {
      'type': type,
      'message': _message,
      'context': context,
    };
  }
}

class ValidationContext {
  final Map<String, Object?> _context;

  const ValidationContext({required Map<String, Object?> context})
      : _context = context;

  String get message => _context.isEmpty
      ? ''
      : _context.entries.map((e) => '${e.key}: ${e.value}').join('\n');
}

class AckException implements Exception {
  final SchemaValidationError error;
  final StackTrace? stackTrace;

  const AckException(this.error, {this.stackTrace});

  Map<String, dynamic> toJson() {
    return {
      'error': error.toMap(),
    };
  }

  @override
  String toString() {
    return 'SchemaValidationException: $toJson()';
  }
}

/// A class representing a Result which can be either `Ok` (success) or `Fail` (failure).
class SchemaResult<T extends Object, E extends SchemaValidationError> {
  const SchemaResult();

  /// Returns `true` if the result is `Ok`
  bool get isOk => this is Ok<T, E>;

  /// Returns `true` if the result is `Fail`
  bool get isFail => this is Fail<T, E>;

  R match<R>({
    required R Function(T value) onOk,
    required R Function(E error) onFail,
  }) {
    if (this is Ok<T, E>) return onOk((this as Ok<T, E>).value);
    return onFail((this as Fail<T, E>).error);
  }

  void onFail(void Function(E error) onFail) {
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
final class Ok<T extends Object, E extends SchemaValidationError>
    extends SchemaResult<T, E> {
  final T value;
  const Ok(this.value);

  const Ok.unit() : value = _unit as T;
}

/// Represents an error result.
/// Represents an error result.
class Fail<T extends Object, E extends SchemaValidationError>
    extends SchemaResult<T, E> {
  final E error;
  const Fail(this.error);
}

const _unit = Null._();

class Null {
  const Null._();
}
