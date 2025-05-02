// lib/src/schema/type_service.dart
class TypeService {
  // Map of model types to schema types and vice versa
  static final Map<Type, Type> _modelToSchemaMap = {};
  static final Map<Type, Type> _schemaToModelMap = {};

  // Register a type mapping
  static void registerTypes<M, S>() {
    // Remove any existing mapping for this model type
    final oldSchemaType = _modelToSchemaMap[M];
    if (oldSchemaType != null) {
      _schemaToModelMap.remove(oldSchemaType);
    }

    // Set up new mappings
    _modelToSchemaMap[M] = S;
    _schemaToModelMap[S] = M;
  }

  // Get schema type for model type
  static Type? getSchemaType(Type modelType) => _modelToSchemaMap[modelType];

  // Get model type for schema type
  static Type? getModelType(Type schemaType) => _schemaToModelMap[schemaType];

  // Check if type is a schema
  static bool isSchemaType(Type type) =>
      _schemaToModelMap.containsKey(type) || type.toString().endsWith('Schema');

  // Type checking helpers
  static bool isListType(Type type) {
    // Check the actual runtime type representation, which typically starts with "_GrowableList<" or similar
    final typeStr = type.toString();

    return typeStr.contains('List<') ||
        typeStr == 'List' ||
        typeStr.startsWith('_') && typeStr.contains('List<');
  }

  static bool isMapType(Type type) {
    // Check the actual runtime type representation, which typically starts with "_Map<" or similar
    final typeStr = type.toString();

    return typeStr.contains('Map<') ||
        typeStr == 'Map' ||
        typeStr.startsWith('_') && typeStr.contains('Map<');
  }

  // Extract element type from List type
  static Type? getElementType(Type listType) {
    final typeStr = listType.toString();
    if (!isListType(listType)) return null;

    // Try to extract what's between List< and >
    final startPattern = 'List<';
    final startIndex = typeStr.indexOf(startPattern);
    if (startIndex == -1) return null;

    final start = startIndex + startPattern.length;
    final end = typeStr.lastIndexOf('>');
    if (end <= start) return null;

    // This is a simplified approach - in a real implementation,
    // you'd need to maintain a map of type names to actual Type objects
    return null;
  }
}
