// lib/src/schema/schema_registry.dart
import 'package:ack/src/builder_helpers/type_service.dart';

import '../schemas/schema_model.dart';

// Type definition for schema factory
typedef SchemaFactory<M> = SchemaModel<M> Function(Object?);

class SchemaRegistry {
  // Map of model types to schema factories
  static final Map<Type, SchemaFactory> _factories = {};

  // Register a schema factory
  static void register<M, S extends SchemaModel<M>>(
    S Function(Object?) factory,
  ) {
    _factories[M] = factory;
    TypeService.registerTypes<M, S>();
  }

  // Create schema for a model type
  static SchemaModel? createSchema(Type modelType, Object? data) {
    final factory = _factories[modelType];
    if (factory == null) return null;

    return factory(data);
  }

  // Check if a model type is registered
  static bool isRegistered<M>() => _factories.containsKey(M);
}
