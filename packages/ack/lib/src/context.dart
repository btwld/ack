import 'package:meta/meta.dart';

import 'schemas/schema.dart';

/// Represents the context in which a schema operation is occurring.
@immutable
class SchemaContext {
  final String name;
  final Object? value;
  final AnyAckSchema schema;
  final SchemaContext? parent;

  /// Raw path key for this context.
  ///
  /// Object properties use string keys, list items use integer indexes, and
  /// transparent wrapper branches use `''` so JSON Pointer rendering can skip
  /// an implementation-only schema layer.
  final Object? pathSegment;
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

    final pathSegment = this.pathSegment;
    if (pathSegment == '') {
      return parentPath;
    }

    final segment = (pathSegment ?? name).toString();
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
    required AnyAckSchema schema,
    required Object? value,
    Object? pathSegment,
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
