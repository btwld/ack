import 'package:meta/meta.dart';

import '../constraints/constraint.dart';
import '../constraints/validators.dart';
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

  Map<String, Object?> toMap() {
    return {
      'message': message,
      'name': name,
      'value': value,
      'schemaType': schema.schemaType.name,
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
class SchemaUnknownError extends SchemaError {
  SchemaUnknownError({
    required Object error,
    required StackTrace stackTrace,
    required super.context,
  }) : super(
          'An unknown error occurred: $error',
          stackTrace: stackTrace,
          cause: error,
        );

  @override
  Map<String, Object?> toMap() {
    return {
      ...super.toMap(),
      'errorMessage': cause?.toString(),
      'stackTrace': stackTrace?.toString(),
    };
  }

  @override
  String toString() =>
      'SchemaUnknownError(name: "$name", error: ${cause ?? 'null'})\nStackTrace:\n${stackTrace ?? 'null'}';
}

@immutable
class SchemaConstraintsError extends SchemaError {
  final List<ConstraintError> constraints;

  SchemaConstraintsError({
    required this.constraints,
    required super.context,
  }) : super(
          'Constraints not met: ${constraints.map((c) => c.message).join(', ')}',
        );

  bool get isNonNullable => getConstraint<NonNullableConstraint>() != null;

  ConstraintError? getConstraint<S extends Constraint>() {
    for (final constraintError in constraints) {
      if (constraintError.constraint.runtimeType == S) {
        return constraintError;
      }
    }
    // Fallback for generic constraints
    final baseClassName = S.toString().split('<').first;
    for (final constraintError in constraints) {
      if (constraintError.constraint.runtimeType.toString().split('<').first ==
          baseClassName) {
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

  S? getSchemaError<S extends SchemaError>() {
    for (final error in errors) {
      if (error is S) return error;
    }

    return null;
  }

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

// @visibleForTesting
// class SchemaMockError extends SchemaError {
//   SchemaMockError({super.context = const SchemaMockContext()})
//       : super(errorKey: 'schema_mock_error');
// }
