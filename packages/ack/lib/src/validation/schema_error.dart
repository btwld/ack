import 'package:ack/src/helpers.dart';
import 'package:meta/meta.dart';

import '../constraints/constraint.dart';
import '../constraints/validators.dart';
import '../context.dart';
import '../schemas/schema.dart';

/// Extension to add firstOrNull to Iterable
extension IterableExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

abstract class SchemaError extends SchemaContext {
  final String errorKey;

  const SchemaError({
    required super.name,
    required super.schema,
    required super.value,
    required this.errorKey,
  });

  Map<String, Object?> toMap() {
    return {
      'errorKey': errorKey,
      'schema': schema.toMap(),
      'value': value,
      'name': name,
    };
  }

  @override
  String toString() =>
      '$runtimeType: errorKey: $errorKey, name: $name, schema: ${schema.runtimeType}, value: ${value ?? 'N/A'}';
}

class SchemaUnknownError extends SchemaError {
  final Object error;
  final StackTrace stackTrace;
  SchemaUnknownError({
    required this.error,
    required this.stackTrace,
    required SchemaContext context,
  }) : super(
          errorKey: 'schema_unknown_error',
          name: context.name,
          schema: context.schema,
          value: context.value,
        );

  @override
  String toString() => '$SchemaUnknownError: $error \n$stackTrace';

  @override
  Map<String, Object?> toMap() {
    return {...super.toMap(), 'error': error, 'stackTrace': stackTrace};
  }
}

class SchemaConstraintsError extends SchemaError {
  final List<ConstraintError> constraints;
  SchemaConstraintsError({
    required this.constraints,
    required SchemaContext context,
  }) : super(
          errorKey: 'schema_constraints_error',
          name: context.name,
          schema: context.schema,
          value: context.value,
        );

  bool get isInvalidType => getConstraint<InvalidTypeConstraint>().isTruthy;

  bool get isNonNullable => getConstraint<NonNullableConstraint>().isTruthy;

  ConstraintError? getConstraint<S extends Constraint>() {
    final constraint = constraints.firstWhereOrNull((e) => e.type == S);
    if (constraint != null) return constraint;

    final nonStrictConstraint = constraints.firstWhereOrNull(
      (e) =>
          e.type.toString().split('<').first == S.toString().split('<').first,
    );

    if (nonStrictConstraint != null) {
      throw Exception(
        'Constraint $S not found, but ${nonStrictConstraint.type} was found. '
        'Ensure you specify the correct generic type for the constraint.',
      );
    }

    return null;
  }

  @override
  Map<String, Object?> toMap() {
    return {
      ...super.toMap(),
      'constraints': constraints.map((e) => e.toMap()).toList(),
    };
  }
}

class SchemaNestedError extends SchemaError {
  final List<SchemaError> errors;

  SchemaNestedError({required this.errors, required SchemaContext context})
      : super(
          errorKey: 'schema_nested_error',
          name: context.name,
          schema: context.schema,
          value: context.value,
        ) {
    assert(schema is ObjectSchema || schema is ListSchema,
        'NestedSchemaError must be used with ObjectSchema or ListSchema');
  }

  S? getSchemaError<S extends SchemaError>() {
    return errors.whereType<S>().firstOrNull;
  }

  @override
  Map<String, Object?> toMap() {
    return {...super.toMap(), 'errors': errors.map((e) => e.toMap()).toList()};
  }
}

@visibleForTesting
class SchemaMockError extends SchemaError {
  SchemaMockError({SchemaContext context = const SchemaMockContext()})
      : super(
          errorKey: 'schema_mock_error',
          name: context.name,
          schema: context.schema,
          value: context.value,
        );
}

Map<String, Object?> composeSchemaErrorMap(SchemaError error) {
  Map<String, Object?> errorMap;

  if (error is SchemaConstraintsError) {
    errorMap = {
      'value': error.value,
      'errors': error.constraints.map((c) => c.message).toList(),
    };
  } else if (error is SchemaNestedError) {
    errorMap = {};
    for (final e in error.errors) {
      errorMap.addAll(composeSchemaErrorMap(e));
    }
  } else if (error is SchemaUnknownError) {
    errorMap = {'error': error.error, 'stackTrace': error.stackTrace};
  } else {
    errorMap = {};
  }

  return {
    error.name: <String, Object?>{
      // 'errorKey': error.errorKey,
      // 'value': error.value,
      ...errorMap,
    },
  };
}
