/// Constants for commonly used Ack-specific types in code generation.
///
/// This utility class provides centralized type references for code_builder refer() calls.
class AckTypes {
  // Private constructor to prevent instantiation
  AckTypes._();

  // Ack-specific type string constants (for code_builder refer() calls)

  /// Reference to Object? type for nullable parameters
  static const objectType = 'Object?';

  /// Reference to ObjectSchema type for schema fields and returns
  static const objectSchema = 'ObjectSchema';

  /// Reference to AckSchema type for schema method returns
  static const ackSchema = 'AckSchema';

  /// Reference to `Map<String, Object?>` type for additional properties and JSON schema
  static const mapStringObject = 'Map<String, Object?>';
}
