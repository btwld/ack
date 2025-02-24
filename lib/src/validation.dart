part of 'ack_base.dart';

sealed class SchemaError {
  final String _message;
  final String type;
  final Map<String, Object?> context;

  const SchemaError({
    required this.type,
    required String message,
    this.context = const {},
  }) : _message = message;

  String get _contextMessage => context.isEmpty
      ? ''
      : context.entries.map((e) => '${e.key}: ${e.value}').join('\n');

  String get message => _message;

  Map<String, Object?> toMap() {
    return {
      'type': type,
      'message': _message,
      'context': context,
    };
  }

  String toJson() => prettyJson(toMap());

  @override
  String toString() => 'SchemaError: ${toJson()}';

  static InvalidTypeSchemaError invalidType({
    required Type valueType,
    required Type expectedType,
  }) {
    return InvalidTypeSchemaError(
      valueType: valueType,
      expectedType: expectedType,
    );
  }

  static NonNullableValueSchemaError nonNullableValue() {
    return NonNullableValueSchemaError();
  }

  static UnknownExceptionSchemaError unknownException({
    Object? error,
    StackTrace? stackTrace,
  }) {
    return UnknownExceptionSchemaError(
      error: error,
      stackTrace: stackTrace,
    );
  }

  static PathSchemaError _pathSchema({
    required String path,
    required String message,
    required List<SchemaError> errors,
    required Schema schema,
  }) {
    return PathSchemaError(
      path: path,
      errors: errors,
      message: message,
      schema: schema,
    );
  }

  static List<SchemaError> pathSchemas({
    required String path,
    required String message,
    required List<SchemaError> errors,
    required Schema schema,
  }) {
    List<SchemaError> schemaErrors = [];

    for (final error in errors) {
      if (error is PathSchemaError) {
        schemaErrors.add(error.withRootPath(path));
      } else {
        schemaErrors.add(
          _pathSchema(
            path: path,
            message: message,
            errors: [error],
            schema: schema,
          ),
        );
      }
    }
    return schemaErrors;
  }
}

class AckException implements Exception {
  final List<SchemaError> errors;
  final StackTrace? stackTrace;

  const AckException(this.errors, {this.stackTrace});

  Map<String, dynamic> toMap() {
    return {
      'errors': errors.map((e) => e.toMap()).toList(),
    };
  }

  String toJson() => prettyJson(toMap());

  @override
  String toString() {
    return 'AckException: ${toJson()}';
  }
}

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
    if (this is Ok<T>) return onOk((this as Ok<T>).value);
    return onFail((this as Fail<T>).errors);
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
/// Represents an error result.
class Fail<T extends Object> extends SchemaResult<T> {
  final List<SchemaError> errors;
  const Fail(this.errors);
}

const _unit = Null._();

class Null {
  const Null._();
}

final class InvalidTypeSchemaError extends SchemaError {
  static const String key = 'invalid_type';

  final Type valueType;
  final Type expectedType;
  InvalidTypeSchemaError({
    required this.valueType,
    required this.expectedType,
  }) : super(
          type: key,
          message: 'Invalid type of $valueType, expected $expectedType',
          context: {
            'valueType': valueType.toString(),
            'expectedType': expectedType.toString(),
          },
        );
}

final class NonNullableValueSchemaError extends SchemaError {
  static const String key = 'non_nullable_value';
  NonNullableValueSchemaError()
      : super(
          type: key,
          message: 'Non nullable value is null',
        );
}

final class UnknownExceptionSchemaError extends SchemaError {
  static const String key = 'unknown_exception';
  final Object? error;
  final StackTrace? stackTrace;
  UnknownExceptionSchemaError({
    this.error,
    this.stackTrace,
  }) : super(
          type: key,
          message: 'Unknown Exception when validating schema $error',
          context: {
            'error': error,
            'stackTrace': stackTrace,
          },
        );
}

sealed class ConstraintValidator<T> {
  String get name;
  String get description;

  const ConstraintValidator();

  bool check(T value);

  ConstraintError? validate(T value) => check(value) ? null : onError(value);

  ConstraintError onError(T value);

  Map<String, Object?> toMap() {
    return {
      'name': name,
      'description': description,
    };
  }

  String toJson() => prettyJson(toMap());

  @protected
  ConstraintError buildError({
    required String message,
    required Map<String, Object?> context,
  }) {
    return ConstraintError(
      name: name,
      message: message,
      context: context,
    );
  }

  @override
  String toString() => toJson();
}

final class ConstraintError extends SchemaError {
  static const String key = 'constraint_error';
  final String name;
  const ConstraintError({
    required this.name,
    required super.message,
    required super.context,
  }) : super(type: key);
}

final class PathSchemaError extends SchemaError {
  static const String key = 'path_schema_error';
  final Schema schema;
  final String path;
  final List<SchemaError> errors;
  PathSchemaError({
    required this.path,
    required this.schema,
    required super.message,
    required this.errors,
  }) : super(
          type: key,
          context: {
            'errors': errors.map((e) => e.toMap()).toList(),
            'path': path,
          },
        );

  PathSchemaError withRootPath(String rootKey) {
    return PathSchemaError(
      path: '$rootKey.$path',
      schema: schema,
      errors: errors,
      message: message,
    );
  }
}
