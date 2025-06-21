/// Utilities for type checking and manipulation
class TypeUtils {
  static const _primitiveTypes = {
    'String',
    'int',
    'double',
    'num',
    'bool',
    'dynamic',
    'Object',
  };
  
  /// Check if a type name is a primitive Dart type
  static bool isPrimitiveType(String typeName) {
    return _primitiveTypes.contains(typeName);
  }
  
  /// Check if a type name is a collection type
  static bool isCollectionType(String typeName) {
    return typeName == 'List' || 
           typeName == 'Set' || 
           typeName == 'Map' ||
           typeName.startsWith('List<') ||
           typeName.startsWith('Set<') ||
           typeName.startsWith('Map<');
  }
}
