/// Utilities for naming conventions
class NamingUtils {
  /// Convert class name to schema class name
  static String getSchemaClassName(String className) {
    return '${className}Schema';
  }
  
  /// Convert field name to JSON key (camelCase to snake_case if needed)
  static String toJsonKey(String fieldName) {
    // For now, keep it simple - use field name as-is
    return fieldName;
  }
}
