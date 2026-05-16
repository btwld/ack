import 'package:meta/meta.dart';

import 'schemas/schema.dart';

/// Represents the context in which a schema operation is occurring.
@immutable
class SchemaContext {
  final String name;
  final Object? value;
  final AckSchema schema;
  final SchemaContext? parent;
  final String? pathSegment;
  final SchemaOperation operation;

  const SchemaContext({
    required this.name,
    required this.schema,
    required this.value,
    this.parent,
    this.pathSegment,
    this.operation = SchemaOperation.parse,
  });

  /// Escapes a JSON Pointer segment per RFC 6901.
  static String _escapeJsonPointerSegment(String segment) {
    return segment.replaceAll('~', '~0').replaceAll('/', '~1');
  }

  /// The full JSON Pointer path (RFC 6901) from root to this context.
  String get path {
    if (parent == null) {
      return '#';
    }

    final parentPath = parent!.path;

    if (pathSegment == '') {
      return parentPath;
    }

    final segment = pathSegment ?? name;
    final escapedSegment = _escapeJsonPointerSegment(segment);

    return parentPath == '#'
        ? '#/$escapedSegment'
        : '$parentPath/$escapedSegment';
  }

  /// Creates a child context for nested validation.
  ///
  /// The child inherits the parent's [operation] unless overridden.
  SchemaContext createChild({
    required String name,
    required AckSchema schema,
    required Object? value,
    String? pathSegment,
    SchemaOperation? operation,
  }) {
    return SchemaContext(
      name: name,
      schema: schema,
      value: value,
      parent: this,
      pathSegment: pathSegment,
      operation: operation ?? this.operation,
    );
  }

  @override
  String toString() {
    final schemaTypeString = schema.schemaTypeName;
    final valueString = value?.toString() ?? 'null';

    return 'SchemaContext(name: "$name", path: "$path", schema: $schemaTypeString, value: "$valueString", operation: ${operation.name})';
  }
}
