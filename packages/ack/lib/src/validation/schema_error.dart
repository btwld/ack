import 'package:meta/meta.dart';

import '../constraints/constraint.dart';
import '../context.dart';
import '../schemas/schema.dart';

@immutable
abstract class SchemaError {
  final String message;
  final SchemaContext context;
  final Object? cause;
  final StackTrace? stackTrace;

  const SchemaError(
    this.message, {
    required this.context,
    this.cause,
    this.stackTrace,
  });

  String get name => context.name;
  AckSchema get schema => context.schema;
  Object? get value => context.value;
  String get path => context.path;

  /// Returns a human-readable error string with path information.
  String toErrorString() {
    return '$message at path: $path';
  }

  Map<String, Object?> toMap() {
    return {
      'message': message,
      'name': name,
      'value': value,
      'schemaType': schema.schemaTypeName,
      'path': path,
    };
  }

  @override
  String toString() {
    final loc = context.name;
    final val = context.value;
    final trace = stackTrace != null ? '\n$stackTrace' : '';
    final causeMsg = cause != null ? '\nCaused by: $cause' : '';

    return 'Validation failed for "$loc" with value "${val ?? 'null'}": $message$causeMsg$trace';
  }
}

@immutable
class TypeMismatchError extends SchemaError {
  TypeMismatchError({
    required SchemaType expectedType,
    required SchemaType actualType,
    required SchemaContext context,
  }) : _expectedJsonType = expectedType,
       _actualJsonType = actualType,
       super(
         'Expected ${expectedType.typeName}, got ${actualType.typeName}',
         context: context,
       );

  final SchemaType _expectedJsonType;
  final SchemaType _actualJsonType;

  String get expectedType => _expectedJsonType.typeName;
  String get actualType => _actualJsonType.typeName;

  @override
  String toErrorString() {
    return 'Expected ${_expectedJsonType.typeName}, got ${_actualJsonType.typeName} at path: ${context.path}';
  }

  @override
  Map<String, Object?> toMap() {
    return {
      ...super.toMap(),
      'expectedType': expectedType,
      'actualType': actualType,
    };
  }
}

class SchemaConstraintsError extends SchemaError {
  final List<ConstraintError> constraints;

  SchemaConstraintsError({required this.constraints, required super.context})
    : super(
        'Constraints not met: ${constraints.map((c) => c.message).join(', ')}',
      );

  ConstraintError? getConstraint<S extends Constraint>() {
    for (final constraintError in constraints) {
      if (constraintError.constraint is S) {
        return constraintError;
      }
    }
    return null;
  }

  @override
  Map<String, Object?> toMap() {
    return {
      ...super.toMap(),
      'constraintViolations': constraints.map((e) => e.toMap()).toList(),
    };
  }
}

@immutable
class SchemaNestedError extends SchemaError {
  final List<SchemaError> errors;

  const SchemaNestedError({required this.errors, required super.context})
    : super('One or more nested schemas failed validation.');

  @override
  Map<String, Object?> toMap() {
    return {
      ...super.toMap(),
      'nestedErrors': errors.map((e) => e.toMap()).toList(),
    };
  }
}

@immutable
class SchemaValidationError extends SchemaError {
  SchemaValidationError({required String message, required super.context})
    : super(message);
}

final class SchemaTransformError extends SchemaError {
  const SchemaTransformError({
    required String message,
    required super.context,
    super.cause,
    super.stackTrace,
  }) : super(message);
}
