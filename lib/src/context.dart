import 'dart:async';

import 'package:ack/src/schemas/schema.dart';

import 'validation/schema_result.dart';

final kSchemaContextKey = #schemaContextKey;

class SchemaContext {
  final String name;
  final Object? value;
  final Schema schema;

  const SchemaContext({
    required this.name,
    required this.schema,
    required this.value,
  });
}

SchemaResult<T> executeWithContext<T extends Object>(
  SchemaContext context,
  SchemaResult<T> Function() action,
) {
  return wrapWithViolationContext(context, () => action());
}

T wrapWithViolationContext<T>(SchemaContext context, T Function() action) {
  return Zone.current
      .fork(zoneValues: {kSchemaContextKey: context}).run(action);
}

SchemaContext getCurrentSchemaContext() {
  try {
    return Zone.current[kSchemaContextKey] as SchemaContext;
  } catch (e) {
    Error.throwWithStackTrace(
      StateError(
        'SchemaMetadata.augment must be called within a Schema context',
      ),
      StackTrace.current,
    );
  }
}

class SchemaMockContext extends SchemaContext {
  const SchemaMockContext()
      : super(
          name: 'mock_context',
          schema: const StringSchema(),
          value: 'mock_value',
        );
}
