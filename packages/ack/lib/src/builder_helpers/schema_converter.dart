// lib/src/schema/schema_converter.dart
import 'package:ack/src/builder_helpers/schema_registry.dart';
import 'package:ack/src/builder_helpers/type_service.dart';

/// A utility class for converting values between different types in the schema system.
///
/// The SchemaConverter handles conversions between raw data, schema objects, and model instances.
/// It plays a key role in ensuring type safety when working with nested data structures.
class SchemaConverter {
  /// Converts a value to the target type, supporting schema and model conversions.
  ///
  /// This method is used internally by the schema system to provide type-safe access
  /// to property values. It handles several conversion scenarios:
  ///
  /// 1. Direct matches: Returns the value if it's already the target type
  /// 2. Schema conversions: Converts maps to schema objects when targeting schema types
  /// 3. Model conversions: When targeting model types, converts maps to schemas then to models
  /// 4. List conversions: Applies the same logic to lists of values
  ///
  /// Example:
  /// ```dart
  /// // Converting a map to a schema type
  /// final addressMap = {'street': '123 Main St', 'city': 'New York'};
  /// final schema = SchemaConverter.convertValue<AddressSchema>(addressMap);
  ///
  /// // Converting a map directly to a model type (internal usage)
  /// final address = SchemaConverter.convertValue<Address>(addressMap);
  /// ```
  ///
  /// @param value The value to convert
  /// @return The converted value, or null if conversion is not possible
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
        if (schema != null) {
          // If the target type is the model type, automatically convert
          if (T == modelType) {
            return schema.toModel() as T;
          }

          return schema as T;
        }
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
              if (schema != null) {
                // If target type is a list of models, convert each item
                if (elementType == modelType) {
                  result.add(schema.toModel());
                } else {
                  result.add(schema);
                }
              }
            }
          }

          return result as T?;
        }
      }
    }

    return null;
  }
}
