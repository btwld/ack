import 'package:meta/meta.dart';
import 'package:standard_schema/standard_schema.dart';

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
  AnyAckSchema get schema => context.schema;
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
  final SchemaType _expectedJsonType;

  final SchemaType _actualJsonType;
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

extension StandardIssueConversion on SchemaError {
  /// Converts this Ack error tree into flat Standard Schema issues.
  List<StandardIssue> toStandardIssues() =>
      _standardIssuesFor(this).toList(growable: false);
}

Iterable<StandardIssue> _standardIssuesFor(SchemaError error) sync* {
  switch (error) {
    case SchemaNestedError(errors: final errors) when errors.isNotEmpty:
      for (final nested in errors) {
        yield* _standardIssuesFor(nested);
      }
    case SchemaConstraintsError(:final constraints) when constraints.isNotEmpty:
      for (final constraint in constraints) {
        yield StandardIssue(
          message: constraint.message,
          path: _standardPath(error.context),
        );
      }
    default:
      yield StandardIssue(
        message: error.message,
        path: _standardPath(error.context),
      );
  }
}

List<Object> _standardPath(SchemaContext context) {
  final reversed = <Object>[];
  var cursor = context;

  while (cursor.parent != null) {
    final parent = cursor.parent!;
    final segment = cursor.pathSegment;

    if (segment != null && segment.isNotEmpty) {
      reversed.add(_standardPathKey(parent, segment));
    }

    cursor = parent;
  }

  return reversed.reversed.toList(growable: false);
}

Object _standardPathKey(SchemaContext parent, String segment) {
  if (parent.schema is ListSchema) {
    return int.tryParse(segment) ?? segment;
  }
  return segment;
}

@immutable
class SchemaValidationError extends SchemaError {
  SchemaValidationError({
    required String message,
    required super.context,
    super.cause,
    super.stackTrace,
  }) : super(message);
}

final class SchemaTransformError extends SchemaError {
  const SchemaTransformError({
    required String message,
    required super.context,
    super.cause,
    super.stackTrace,
  }) : super(message);
}

/// Categorizes encode-side failures so callers can react programmatically.
enum SchemaEncodeFailureKind {
  nonNullable,
  typeMismatch,
  oneWayTransform,
  encoderThrew,
  missingRequiredProperty,
  unexpectedProperty,
}

/// Errors raised during the encode path (Runtime → Boundary).
@immutable
final class SchemaEncodeError extends SchemaError {
  final SchemaEncodeFailureKind kind;
  final String? propertyKey;

  const SchemaEncodeError._({
    required this.kind,
    required String message,
    required super.context,
    super.cause,
    super.stackTrace,
    this.propertyKey,
  }) : super(message);

  factory SchemaEncodeError.nonNullable({required SchemaContext context}) {
    return SchemaEncodeError._(
      kind: SchemaEncodeFailureKind.nonNullable,
      message: 'Cannot encode null value for non-nullable schema.',
      context: context,
    );
  }

  factory SchemaEncodeError.typeMismatch({
    required String message,
    required SchemaContext context,
  }) {
    return SchemaEncodeError._(
      kind: SchemaEncodeFailureKind.typeMismatch,
      message: message,
      context: context,
    );
  }

  factory SchemaEncodeError.oneWayTransform({
    required SchemaContext context,
    String message =
        'This schema is a one-way transform and does not support encode.',
  }) {
    return SchemaEncodeError._(
      kind: SchemaEncodeFailureKind.oneWayTransform,
      message: message,
      context: context,
    );
  }

  factory SchemaEncodeError.encoderThrew({
    required String message,
    required SchemaContext context,
    Object? cause,
    StackTrace? stackTrace,
  }) {
    return SchemaEncodeError._(
      kind: SchemaEncodeFailureKind.encoderThrew,
      message: message,
      context: context,
      cause: cause,
      stackTrace: stackTrace,
    );
  }

  factory SchemaEncodeError.missingRequiredProperty({
    required String propertyKey,
    required SchemaContext context,
  }) {
    return SchemaEncodeError._(
      kind: SchemaEncodeFailureKind.missingRequiredProperty,
      message: 'Required property "$propertyKey" missing from encoded value.',
      context: context,
      propertyKey: propertyKey,
    );
  }

  factory SchemaEncodeError.unexpectedProperty({
    required String propertyKey,
    required SchemaContext context,
  }) {
    return SchemaEncodeError._(
      kind: SchemaEncodeFailureKind.unexpectedProperty,
      message: 'Unexpected property "$propertyKey" in encoded value.',
      context: context,
      propertyKey: propertyKey,
    );
  }

  @override
  Map<String, Object?> toMap() {
    return {
      ...super.toMap(),
      'encodeKind': kind.name,
      if (propertyKey != null) 'propertyKey': propertyKey,
    };
  }
}
