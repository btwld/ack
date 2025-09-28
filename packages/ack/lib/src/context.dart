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

  /// The full JSON path from root to this context.
  String get path {
    if (parent == null) {
      return '#';
    }

    final parentPath = parent!.path;
    final segment = pathSegment ?? name;

    // Handle array indices (numeric) vs object properties (string)
    if (RegExp(r'^\d+$').hasMatch(segment)) {
      return '$parentPath[$segment]';
    }

    return parentPath == '#' ? '#/$segment' : '$parentPath/$segment';
  }

  /// Creates a child context for nested validation.
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
    final schemaTypeString = schema.schemaType.toString().split('.').last;
    final valueString = value?.toString() ?? 'null';

    return 'SchemaContext(name: "$name", path: "$path", schema: $schemaTypeString, value: "$valueString")';
  }
}
