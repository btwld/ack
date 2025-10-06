import 'package:meta/meta.dart';

import 'schemas/schema.dart';

/// Represents the context in which a schema validation is occurring.
@immutable
class SchemaContext {
  final String name;
  final Object? value;
  final AckSchema schema;
  final SchemaContext? parent;
  final String? pathSegment;

  const SchemaContext({
    required this.name,
    required this.schema,
    required this.value,
    this.parent,
    this.pathSegment,
  });

  /// Escapes a JSON Pointer segment per RFC 6901.
  ///
  /// Per RFC 6901, `~` must be escaped as `~0` and `/` must be escaped as `~1`.
  static String _escapeJsonPointerSegment(String segment) {
    return segment.replaceAll('~', '~0').replaceAll('/', '~1');
  }

  /// The full JSON Pointer path (RFC 6901) from root to this context.
  ///
  /// Returns a JSON Pointer string like `#/user/name` or `#/items/0`.
  /// The `#` prefix indicates this is a JSON Pointer reference.
  /// Special characters in segments (`~` and `/`) are escaped per RFC 6901.
  ///
  /// If pathSegment is explicitly set to empty string '', the child inherits
  /// the parent's path without adding a new segment.
  String get path {
    if (parent == null) {
      return '#';
    }

    final parentPath = parent!.path;

    // Empty string pathSegment means "inherit parent path, don't add segment"
    if (pathSegment == '') {
      return parentPath;
    }

    final segment = pathSegment ?? name;
    final escapedSegment = _escapeJsonPointerSegment(segment);

    // All segments (including array indices) use `/` separator per RFC 6901
    return parentPath == '#'
        ? '#/$escapedSegment'
        : '$parentPath/$escapedSegment';
  }

  /// Creates a child context for nested validation.
  ///
  /// If [pathSegment] is an empty string (''), the child inherits the parent's
  /// path without adding a new segment. This is useful for schemas like AnyOf
  /// or DiscriminatedObject that should not pollute the JSON Pointer path with
  /// internal structure (e.g., avoiding paths like `#/field/anyOf:0`).
  SchemaContext createChild({
    required String name,
    required AckSchema schema,
    required Object? value,
    String? pathSegment,
  }) {
    return SchemaContext(
      name: name,
      schema: schema,
      value: value,
      parent: this,
      pathSegment: pathSegment,
    );
  }

  @override
  String toString() {
    final schemaTypeString = schema.schemaTypeName;
    final valueString = value?.toString() ?? 'null';

    return 'SchemaContext(name: "$name", path: "$path", schema: $schemaTypeString, value: "$valueString")';
  }
}
