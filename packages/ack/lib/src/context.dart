import 'package:meta/meta.dart';

import 'schemas/schema.dart';

/// Represents the context in which a schema validation is occurring.
@immutable
class SchemaContext {
  final String name;
  final Object? value;
  final AckSchema schema;

  const SchemaContext({
    required this.name,
    required this.schema,
    required this.value,
  });

  @override
  String toString() {
    final schemaTypeString = schema.schemaType.toString().split('.').last;
    final valueString = value?.toString() ?? 'null';

    return 'SchemaContext(name: "$name", schema: $schemaTypeString, value: "$valueString")';
  }
}
