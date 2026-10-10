import 'package:meta/meta.dart';

import '../context.dart';
import '../schemas/schema.dart';
import '../utils/collection_utils.dart';
import 'schema_error.dart';
import 'schema_result.dart';

/// Dart contract for the Standard Schema v1 and Standard JSON Schema v1
/// specifications (`https://standardschema.dev/`).
///
/// Validation libraries implement or expose [StandardSchemaV1] (for example,
/// via `AckSchema.standard`) so framework, router, form, and AI/agent tooling
/// can consume schemas generically without vendor-specific adapters.
abstract interface class StandardSchemaV1<Input, Output> {
  /// The Standard Schema specification version (`1`).
  int get version;

  /// The schema library vendor identifier (for Ack, `'ack'`).
  String get vendor;

  /// Validates [value] and returns either a [StandardSchemaSuccess] with the
  /// parsed output or a [StandardSchemaFailure] with a list of [StandardSchemaIssue]s.
  StandardSchemaResult<Output> validate(Object? value);

  /// Renders this schema as a JSON Schema map per the Standard JSON Schema
  /// companion specification.
  Map<String, Object?> toJsonSchema();
}

/// The outcome of a [StandardSchemaV1.validate] invocation.
@immutable
sealed class StandardSchemaResult<Output> {
  const StandardSchemaResult();

  /// Creates a successful validation result.
  const factory StandardSchemaResult.success(Output? value) =
      StandardSchemaSuccess<Output>;

  /// Creates a failed validation result with [issues].
  factory StandardSchemaResult.failure(List<StandardSchemaIssue> issues) =
      StandardSchemaFailure<Output>;

  /// Whether validation succeeded.
  bool get isSuccess => this is StandardSchemaSuccess<Output>;

  /// Whether validation failed.
  bool get isFailure => this is StandardSchemaFailure<Output>;

  /// The validated value when successful, or `null` when validation failed.
  Output? get valueOrNull => switch (this) {
    StandardSchemaSuccess(:final value) => value,
    StandardSchemaFailure() => null,
  };

  /// The validation issues when failed, or `null` when validation succeeded.
  List<StandardSchemaIssue>? get issues => switch (this) {
    StandardSchemaSuccess() => null,
    StandardSchemaFailure(:final issues) => issues,
  };
}

/// A successful [StandardSchemaResult] wrapping the validated [value].
@immutable
final class StandardSchemaSuccess<Output> extends StandardSchemaResult<Output> {
  /// Creates a successful result.
  const StandardSchemaSuccess(this.value);

  /// The validated output value (`null` only when the schema accepts `null`).
  final Output? value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StandardSchemaSuccess<Object?> &&
          deepEquals(value, other.value));

  @override
  int get hashCode => Object.hash(StandardSchemaSuccess, deepHashCode(value));

  @override
  String toString() => 'StandardSchemaSuccess($value)';
}

/// A failed [StandardSchemaResult] containing one or more [issues].
@immutable
final class StandardSchemaFailure<Output> extends StandardSchemaResult<Output> {
  /// Creates a failed result with an unmodifiable copy of [issues].
  StandardSchemaFailure(Iterable<StandardSchemaIssue> issues)
    : issues = List<StandardSchemaIssue>.unmodifiable(issues);

  /// The non-empty list of validation issues reported by the schema.
  @override
  final List<StandardSchemaIssue> issues;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StandardSchemaFailure<Object?> &&
          deepEquals(issues, other.issues));

  @override
  int get hashCode => Object.hash(StandardSchemaFailure, deepHashCode(issues));

  @override
  String toString() => 'StandardSchemaFailure($issues)';
}

/// A single validation issue reported by [StandardSchemaV1.validate].
@immutable
final class StandardSchemaIssue {
  /// Creates a validation issue with a human-readable [message] and an
  /// optional [path] from the root input to the failing location.
  StandardSchemaIssue({required this.message, Iterable<Object>? path})
    : path = List<Object>.unmodifiable(path ?? const <Object>[]);

  /// Human-readable description of the validation failure.
  final String message;

  /// Path segments (`String` property keys and `int` array indices) from the
  /// root value to the failing location. Empty when the issue occurred at the
  /// root value.
  final List<Object> path;

  /// Converts this issue to a JSON-compatible map matching the Standard Schema
  /// v1 issue shape.
  Map<String, Object?> toMap() => {
    'message': message,
    if (path.isNotEmpty) 'path': path,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StandardSchemaIssue &&
          message == other.message &&
          deepEquals(path, other.path));

  @override
  int get hashCode => Object.hash(message, deepHashCode(path));

  @override
  String toString() => path.isEmpty
      ? 'StandardSchemaIssue(message: $message)'
      : 'StandardSchemaIssue(message: $message, path: $path)';
}

/// [StandardSchemaV1] adapter backed by an [AckSchema].
@immutable
final class AckStandardSchema<Boundary extends Object, Runtime extends Object>
    implements StandardSchemaV1<Boundary, Runtime> {
  /// Creates a Standard Schema v1 view over [schema].
  const AckStandardSchema(this.schema);

  /// The underlying Ack schema.
  final AckSchema<Boundary, Runtime> schema;

  @override
  int get version => 1;

  @override
  String get vendor => 'ack';

  @override
  StandardSchemaResult<Runtime> validate(Object? value) {
    return switch (schema.safeParse(value)) {
      Ok(value: final parsed) => StandardSchemaResult.success(parsed),
      Fail(:final error) => StandardSchemaResult.failure(_collectIssues(error)),
    };
  }

  @override
  Map<String, Object?> toJsonSchema() => schema.toJsonSchema();

  static List<StandardSchemaIssue> _collectIssues(SchemaError error) {
    final issues = <StandardSchemaIssue>[];
    _appendIssues(error, issues);
    if (issues.isEmpty) {
      issues.add(
        StandardSchemaIssue(
          message: error.message,
          path: _extractPathSegments(error),
        ),
      );
    }
    return issues;
  }

  static void _appendIssues(
    SchemaError error,
    List<StandardSchemaIssue> output,
  ) {
    switch (error) {
      case SchemaNestedError(:final errors) when errors.isNotEmpty:
        for (final child in errors) {
          _appendIssues(child, output);
        }
      case SchemaConstraintsError(:final constraints)
          when constraints.isNotEmpty:
        final path = _extractPathSegments(error);
        for (final violation in constraints) {
          output.add(
            StandardSchemaIssue(message: violation.message, path: path),
          );
        }
      case TypeMismatchError() ||
          SchemaConstraintsError() ||
          SchemaNestedError() ||
          SchemaValidationError() ||
          SchemaTransformError() ||
          SchemaEncodeError():
        output.add(
          StandardSchemaIssue(
            message: error.message,
            path: _extractPathSegments(error),
          ),
        );
    }
  }

  static List<Object> _extractPathSegments(SchemaError error) {
    final contextSegments = _segmentsFromContext(error.context);
    if (contextSegments.isNotEmpty) return contextSegments;
    final pointer = error.path;
    if (pointer.isEmpty || pointer == '#') return const [];
    final stripped = pointer.startsWith('#/')
        ? pointer.substring(2)
        : pointer.startsWith('/')
        ? pointer.substring(1)
        : pointer;
    if (stripped.isEmpty) return const [];
    return [
      for (final raw in stripped.split('/')) _unescapeJsonPointerSegment(raw),
    ];
  }

  static List<Object> _segmentsFromContext(SchemaContext context) {
    final reversed = <Object>[];
    SchemaContext? current = context;
    while (current != null && current.parent != null) {
      final parent = current.parent!;
      final rawSegment = current.pathSegment;
      if (rawSegment != '') {
        final segment = rawSegment ?? current.name;
        final isArrayParent =
            parent.value is List || parent.schema is ListSchema;
        final parsedIndex = isArrayParent ? int.tryParse(segment) : null;
        reversed.add(parsedIndex ?? segment);
      }
      current = parent;
    }
    return reversed.reversed.toList(growable: false);
  }

  static String _unescapeJsonPointerSegment(String segment) =>
      segment.replaceAll('~1', '/').replaceAll('~0', '~');
}
