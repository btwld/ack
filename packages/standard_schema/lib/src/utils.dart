import 'standard_schema.dart';

/// Returns the dot-notation path of an [issue] (for example `user.tags.1`), or
/// `null` when the issue has no path or any segment is not a string or number.
///
/// Direct port of `getDotPath` from `@standard-schema/utils`.
String? getDotPath(StandardIssue issue) {
  if (issue.path.isEmpty) return null;
  final dotPath = StringBuffer();
  for (final segment in issue.path) {
    final key = segment is StandardPathSegment ? segment.key : segment;
    if (key is String || key is num) {
      if (dotPath.isNotEmpty) dotPath.write('.');
      dotPath.write(key);
    } else {
      return null;
    }
  }
  return dotPath.toString();
}

/// An [Exception] wrapping the [issues] of a failed Standard Schema validation,
/// exposing the first issue's [message]. The standard way to throw on failure.
///
/// Port of `SchemaError` from `@standard-schema/utils`, renamed to avoid
/// colliding with Ack's own `SchemaError` (which `package:ack` re-exports).
class StandardSchemaError implements Exception {
  /// Wraps [issues]. Throws [ArgumentError] when [issues] is empty: a failure
  /// always carries at least one issue, and [message] is taken from the first.
  StandardSchemaError(List<StandardIssue> issues)
    : message = issues.isEmpty
          ? throw ArgumentError.value(issues, 'issues', 'must not be empty')
          : issues.first.message,
      issues = List.unmodifiable(issues);

  /// The issues describing why validation failed. Never empty.
  final List<StandardIssue> issues;

  /// The error message, taken from the first issue.
  final String message;

  @override
  String toString() => 'StandardSchemaError: $message';
}
