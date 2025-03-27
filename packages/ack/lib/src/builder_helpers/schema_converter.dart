// lib/src/schema/schema_converter.dart
import 'package:ack/src/builder_helpers/schema_registry.dart';
import 'package:ack/src/builder_helpers/type_service.dart';

class SchemaConverter {
  // Convert a value to the target type
  static T? convertValue<T>(dynamic value) {
    if (value == null) return null;

    // Direct type match
    if (value is T) return value;

    // Handle schema types
    if (value is Map<String, dynamic> && TypeService.isSchemaType(T)) {
      final modelType = TypeService.getModelType(T);
      if (modelType != null) {
        // Create schema of the model type, which should return the schema type T
        final schema = SchemaRegistry.createSchema(modelType, value);
        if (schema != null) return schema as T;
      }
    }

    // Handle lists of schema types
    if (value is List && TypeService.isListType(T)) {
      final elementType = TypeService.getElementType(T);
      if (elementType != null && TypeService.isSchemaType(elementType)) {
        final modelType = TypeService.getModelType(elementType);
        if (modelType != null) {
          final result = <dynamic>[];
          for (final item in value) {
            if (item is Map<String, dynamic>) {
              // Create schema of the element's model type
              final schema = SchemaRegistry.createSchema(modelType, item);
              if (schema != null) result.add(schema);
            }
          }

          return result as T?;
        }
      }
    }

    return null;
  }
}
