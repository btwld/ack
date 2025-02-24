part of '../ack_base.dart';

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
