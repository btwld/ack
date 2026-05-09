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

/// An error raised by [AckSchema.encode] / [AckSchema.safeEncode] when the
/// runtime value cannot be serialized back to the schema's boundary form.
///
/// Use the named constructors to produce the right shape for each failure mode.
final class SchemaEncodeError extends SchemaError {
  const SchemaEncodeError._({
    required String message,
    required super.context,
    super.cause,
    super.stackTrace,
  }) : super(message);

  /// The runtime value's type does not match the schema's expected runtime type.
  ///
  /// [expected] is the Dart type the schema requires (e.g. `String`,
  /// `DateTime`, a user class). [actual] is the offending value; the message
  /// reports `actual.runtimeType` directly so this constructor never throws,
  /// even for values outside the JSON primitives (`DateTime`, `Uri`, user
  /// classes). This preserves `safeEncode`'s "never throws" guarantee.
  factory SchemaEncodeError.typeMismatch({
    required Type expected,
    required Object? actual,
    required SchemaContext context,
  }) {
    final actualLabel = actual == null ? 'null' : '${actual.runtimeType}';
    return SchemaEncodeError._(
      message: 'Encode failed: expected $expected, got $actualLabel.',
      context: context,
    );
  }

  /// The schema is non-nullable but the value passed in is `null`.
  factory SchemaEncodeError.nonNullable({required SchemaContext context}) {
    return SchemaEncodeError._(
      message: 'Cannot encode null for a non-nullable schema',
      context: context,
    );
  }

  /// The schema is a one-way transform (no encoder supplied) and cannot
  /// participate in encode. The message points users at [Ack.codec].
  factory SchemaEncodeError.oneWayTransform({required SchemaContext context}) {
    return SchemaEncodeError._(
      message:
          'Cannot encode: this schema is one-way; use Ack.codec(...) for bidirectional behaviour.',
      context: context,
    );
  }

  /// The user-supplied encoder threw an exception.
  factory SchemaEncodeError.encoderThrew({
    required Object cause,
    StackTrace? stackTrace,
    required SchemaContext context,
  }) {
    return SchemaEncodeError._(
      message: 'Encoder threw: $cause',
      context: context,
      cause: cause,
      stackTrace: stackTrace,
    );
  }

  /// A required property is missing from the runtime map being encoded.
  factory SchemaEncodeError.missingRequiredProperty({
    required String key,
    required SchemaContext context,
  }) {
    return SchemaEncodeError._(
      message: 'Missing required property "$key" during encode',
      context: context,
    );
  }

  /// The runtime map contains a property that is not declared by the schema
  /// (and `additionalProperties` is false).
  factory SchemaEncodeError.unexpectedProperty({
    required String key,
    required SchemaContext context,
  }) {
    return SchemaEncodeError._(
      message: 'Unexpected property "$key" during encode',
      context: context,
    );
  }
}
