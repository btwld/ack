// lib/src/schema/schema_registry.dart
import 'package:ack/src/builder_helpers/type_service.dart';

import '../schemas/schema_model.dart';

// Type definition for schema factory
typedef SchemaFactory = dynamic Function(Object?);

class SchemaRegistry {
  // Map of schema types to schema factories
  static final Map<Type, SchemaFactory> _factories = {};

  // Register a schema factory
  static void register<S extends SchemaModel>(S? Function(Object?) factory) {
    _factories[S] = factory;
    TypeService.registerSchemaType<S>();
  }

  // Create schema by type
  static S? createSchema<S extends SchemaModel>(Object? data) {
    final factory = _factories[S];
    if (factory != null) {
      return factory(data) as S?;
    }

    return null;
  }

  // Create schema by runtime type
  static dynamic createSchemaByType(Type schemaType, Object? data) {
    final factory = _factories[schemaType];

    return factory?.call(data);
  }

  // Check if a schema type is registered
  static bool isRegistered<S>() => _factories.containsKey(S);
}
