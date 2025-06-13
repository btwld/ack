// lib/src/schema/type_service.dart
/// A utility class for managing schema type registration.
///
/// This service maintains a registry of schema types to support
/// runtime type checking and schema instantiation.
class TypeService {
  // Set of registered schema types
  static final Set<Type> _schemaTypes = {};

  // Map of type names to actual Type objects for type resolution
  static final Map<String, Type> _typeNameToType = {};

  /// Register a schema type for runtime resolution.
  static void registerSchemaType<S>() {
    _schemaTypes.add(S);
    // Also register the type name mapping
    _typeNameToType[S.toString()] = S;
  }

  /// Check if a type is a registered schema type.
  static bool isSchemaType(Type type) =>
      _schemaTypes.contains(type) || type.toString().endsWith('Schema');
}
