import 'dart:async';

import 'package:meta/meta.dart';

import 'schemas/schema.dart';
import 'validation/schema_result.dart';

final _kSchemaContextKey = #ackSchemaContextKeyV2;

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
  String toString() =>
      'SchemaContext(name: $name, value: ${value?.toString().substring(0, (value?.toString().length ?? 0) > 50 ? 50 : (value?.toString().length ?? 0))}, schema: ${schema.runtimeType})';
}

/// Executes an action within a specific [SchemaContext].
SchemaResult<T> executeWithContext<T>(
  SchemaContext context,
  SchemaResult<T> Function(SchemaContext currentContext) action,
) {
  return Zone.current.fork(
      zoneValues: {_kSchemaContextKey: context}).run(() => action(context));
}

/// Retrieves the current [SchemaContext] from the active [Zone].
SchemaContext getCurrentSchemaContext() {
  final context = Zone.current[_kSchemaContextKey];
  if (context is SchemaContext) {
    return context;
  }
  throw StateError(
    'getCurrentSchemaContext() must be called within a Zone established by executeWithContext.',
  );
}

// /// A mock context for testing purposes.
// @visibleForTesting
// class SchemaMockContext extends SchemaContext {
//   const SchemaMockContext()
//       : super(
//           name: 'mock_context',
//           schema:
//               const StringSchema(),
//           value: 'mock_value',
//         );
// }
