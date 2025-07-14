import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';

/// Error messages with specific guidance for common ack_generator issues
class GenErrorMessages {
  /// Creates an enhanced error message for annotation parsing failures
  static InvalidGenerationSourceError forAnnotationError(
    ClassElement element,
    Object error,
  ) {
    final errorString = error.toString();

    // Parse common annotation field errors
    if (errorString.contains('Class AckModel does not have field')) {
      final fieldName = _extractMissingField(errorString);
      return _createAnnotationFieldError(element, fieldName);
    }

    // Parse type conversion errors
    if (errorString.contains('FormatException') ||
        errorString.contains('type')) {
      return _createAnnotationTypeError(element, errorString);
    }

    // Fallback for other annotation errors
    return InvalidGenerationSourceError(
      'Invalid @AckModel annotation on class ${element.name}',
      element: element,
      todo: '''
• Check annotation syntax: @AckModel(...)
• Ensure all field values have correct types
• Update ack_annotations package if using old version
• Error details: $error
• Documentation: https://docs.package/annotations
''',
    );
  }

  /// Creates an enhanced error message for schema generation failures
  static InvalidGenerationSourceError forSchemaGenerationError(
    ClassElement element,
    Object error,
  ) {
    final errorString = error.toString();

    // Parse field type errors
    if (errorString.contains('Unsupported') || errorString.contains('type')) {
      return _createFieldTypeError(element, errorString);
    }

    // Parse circular reference errors
    if (errorString.contains('circular') || errorString.contains('recursive')) {
      return _createCircularReferenceError(element, errorString);
    }

    // Fallback for other generation errors
    return InvalidGenerationSourceError(
      'Schema generation failed for class ${element.name}',
      element: element,
      todo: '''
• Check that all field types are supported:
  ✓ Primitives: String, int, double, bool
  ✓ Collections: List<T>, Map<String, T>, Set<T>
  ✓ Nested models with @AckModel annotation
  ✓ Enums with string values
• Avoid deeply nested collections (e.g., List<Map<String, List<T>>>)
• Ensure no circular references between models
• Error details: $error
''',
    );
  }

  /// Creates specific error for missing annotation fields
  static InvalidGenerationSourceError _createAnnotationFieldError(
    ClassElement element,
    String? fieldName,
  ) {
    return switch (fieldName) {
      'discriminatedKey' ||
      'discriminatedValue' =>
        InvalidGenerationSourceError(
          'Missing discriminated type fields in @AckModel annotation',
          element: element,
          todo: '''
• Update ack_annotations package to latest version:
  dart pub upgrade ack_annotations
• Or add fields manually to annotation definition
• Current @AckModel missing: discriminatedKey, discriminatedValue
• Example usage:
  @AckModel(discriminatedKey: 'type')    // For abstract base class
  @AckModel(discriminatedValue: 'cat')   // For concrete subclass
''',
        ),
      'model' => InvalidGenerationSourceError(
          'Missing model field in @AckModel annotation',
          element: element,
          todo: '''
• Update ack_annotations package to latest version:
  dart pub upgrade ack_annotations
• The 'model' field controls SchemaModel class generation
• Example: @AckModel(model: true) generates both schema and SchemaModel
''',
        ),
      _ => InvalidGenerationSourceError(
          'Unknown field "$fieldName" missing from @AckModel annotation',
          element: element,
          todo: '''
• Update ack_annotations package: dart pub upgrade ack_annotations
• Check annotation syntax and available fields
• Valid fields: schemaName, description, additionalProperties, 
  additionalPropertiesField, model, discriminatedKey, discriminatedValue
''',
        ),
    };
  }

  /// Creates specific error for annotation type mismatches
  static InvalidGenerationSourceError _createAnnotationTypeError(
    ClassElement element,
    String errorDetails,
  ) {
    return InvalidGenerationSourceError(
      'Invalid value type in @AckModel annotation',
      element: element,
      todo: '''
• Check annotation field types:
  - schemaName: String?
  - description: String?
  - additionalProperties: bool (default: false)
  - additionalPropertiesField: String?
  - model: bool (default: false)
  - discriminatedKey: String? (abstract classes only)
  - discriminatedValue: String? (concrete classes only)
• Example: @AckModel(model: true, description: "User model")
• Error details: $errorDetails
''',
    );
  }

  /// Creates specific error for unsupported field types
  static InvalidGenerationSourceError _createFieldTypeError(
    ClassElement element,
    String errorDetails,
  ) {
    return InvalidGenerationSourceError(
      'Unsupported field type in class ${element.name}',
      element: element,
      todo: '''
• Supported types:
  ✓ Primitives: String, int, double, bool, num
  ✓ Collections: List<T>, Set<T>, Map<String, T>
  ✓ Nested models with @AckModel annotation
  ✓ Enums (string-based)
  ✓ Nullable versions (e.g., String?, List<String>?)
• Unsupported:
  ✗ Deep nesting: List<Map<String, List<T>>>
  ✗ Non-string map keys: Map<int, String>
  ✗ Custom classes without @AckModel
• Error details: $errorDetails
''',
    );
  }

  /// Creates specific error for circular references
  static InvalidGenerationSourceError _createCircularReferenceError(
    ClassElement element,
    String errorDetails,
  ) {
    return InvalidGenerationSourceError(
      'Circular reference detected in model ${element.name}',
      element: element,
      todo: '''
• Break circular references by:
  1. Using composition instead of inheritance
  2. Making one side of the relationship optional
  3. Using string identifiers instead of direct references
• Example fix:
  // Before: User has Company, Company has List<User>
  // After: User has Company, Company has List<String> userIds
• Error details: $errorDetails
''',
    );
  }

  /// Extracts the missing field name from error message
  static String? _extractMissingField(String errorMessage) {
    final match =
        RegExp(r'does not have field "(\w+)"').firstMatch(errorMessage);
    return match?.group(1);
  }
}
