import 'package:meta/meta.dart';

import 'schemas/schema.dart';

enum _SchemaPathSegmentKind { property, listIndex, passThrough }

/// A typed path segment used by [SchemaContext].
///
/// String object keys and integer list indexes must stay distinct for standard
/// issue paths. Use [SchemaPathSegment.passThrough] for composition branches
/// that should not add a user-visible path segment.
@immutable
final class SchemaPathSegment {
  final _SchemaPathSegmentKind _kind;

  final Object? _value;

  const SchemaPathSegment.property(String key)
    : _kind = _SchemaPathSegmentKind.property,
      _value = key;

  const SchemaPathSegment.index(int index)
    : assert(index >= 0, 'List path indexes must be non-negative.'),
      _kind = _SchemaPathSegmentKind.listIndex,
      _value = index;

  const SchemaPathSegment.passThrough()
    : _kind = _SchemaPathSegmentKind.passThrough,
      _value = null;

  Object? get _issueValue {
    return switch (_kind) {
      _SchemaPathSegmentKind.property => _value as String,
      _SchemaPathSegmentKind.listIndex => _value as int,
      _SchemaPathSegmentKind.passThrough => null,
    };
  }

  String? get _jsonPointerValue {
    return switch (_kind) {
      _SchemaPathSegmentKind.property => _value as String,
      _SchemaPathSegmentKind.listIndex => (_value as int).toString(),
      _SchemaPathSegmentKind.passThrough => null,
    };
  }
}

/// Represents the context in which a schema operation is occurring.
@immutable
class SchemaContext {
  final String name;
  final Object? value;
  final AnyAckSchema schema;
  final SchemaContext? parent;
  final SchemaPathSegment? pathSegment;
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

    final segment = pathSegment ?? SchemaPathSegment.property(name);
    final pointerValue = segment._jsonPointerValue;
    if (pointerValue == null) {
      return parentPath;
    }

    final escapedSegment = _escapeJsonPointerSegment(pointerValue);

    return parentPath == '#'
        ? '#/$escapedSegment'
        : '$parentPath/$escapedSegment';
  }

  /// Raw path segments from root to this context.
  ///
  /// Object keys are exposed as strings and list indexes as integers. Branch
  /// pass-through segments do not add to the path.
  List<Object> get pathSegments {
    final parentSegments = parent?.pathSegments ?? const <Object>[];
    if (parent == null) return parentSegments;

    final segment = pathSegment ?? SchemaPathSegment.property(name);
    final pathValue = segment._issueValue;
    if (pathValue == null) return parentSegments;

    return [...parentSegments, pathValue];
  }

  /// Creates a child context for nested validation.
  ///
  /// The child inherits the parent's [operation] unless overridden.
  SchemaContext createChild({
    required String name,
    required AnyAckSchema schema,
    required Object? value,
    SchemaPathSegment? pathSegment,
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
