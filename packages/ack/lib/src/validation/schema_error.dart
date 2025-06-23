import 'package:meta/meta.dart';

import '../constraints/constraint.dart';
import '../constraints/validators.dart';
import '../context.dart';
import '../schemas/schema.dart';

@immutable
abstract class SchemaError {
  final SchemaContext context;
  final String errorKey;

  const SchemaError({required this.context, required this.errorKey});

  String get name => context.name;
  AckSchema get schema => context.schema;
  Object? get value => context.value;

  Map<String, Object?> toMap() {
    return {
      'errorKey': errorKey,
      'name': name,
      'value': value,
      'schemaType': schema.schemaType.name,
    };
  }

  @override
  String toString() =>
      '$runtimeType(errorKey: $errorKey, name: "$name", value: ${value ?? 'null'}, schema: ${schema.runtimeType})';
}

@immutable
class SchemaUnknownError extends SchemaError {
  final Object error;
  final StackTrace stackTrace;

  SchemaUnknownError({
    required this.error,
    required this.stackTrace,
    required super.context,
  }) : super(errorKey: 'schema_unknown_error');

  @override
  Map<String, Object?> toMap() {
    return {
      ...super.toMap(),
      'errorMessage': error.toString(),
      'stackTrace': stackTrace.toString(),
    };
  }

  @override
  String toString() =>
      'SchemaUnknownError(name: "$name", error: $error)\nStackTrace:\n$stackTrace';
}

@immutable
class SchemaConstraintsError extends SchemaError {
  final List<ConstraintError> constraints;

  SchemaConstraintsError({
    required this.constraints,
    required super.context,
  }) : super(errorKey: 'schema_constraints_error');

  bool get isInvalidType => getConstraint<InvalidTypeConstraint>() != null;
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

  SchemaNestedError({required this.errors, required super.context})
      : super(errorKey: 'schema_nested_error');
  // No specific assertions are needed here, but the constructor is kept
  // for clarity and potential future use.

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
  final String message;

  SchemaValidationError({required this.message, required super.context})
      : super(errorKey: 'schema_validation_error');

  @override
  Map<String, Object?> toMap() {
    return {...super.toMap(), 'message': message};
  }
}

// @visibleForTesting
// class SchemaMockError extends SchemaError {
//   SchemaMockError({super.context = const SchemaMockContext()})
//       : super(errorKey: 'schema_mock_error');
// }
