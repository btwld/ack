import 'package:ack/src/schemas/schema.dart';

class SchemaContext {
  final String name;
  final Object? value;
  final AckSchema schema;

  const SchemaContext({
    required this.name,
    required this.schema,
    required this.value,
  });
}

class SchemaMockContext extends SchemaContext {
  const SchemaMockContext()
      : super(
          name: 'mock_context',
          schema: const StringSchema(),
          value: 'mock_value',
        );
}
