// lib/src/schema/schema_model.dart
import 'dart:convert';

import 'package:ack/src/builder_helpers/schema_converter.dart';
import 'package:ack/src/builder_helpers/schema_registry.dart';
import 'package:ack/src/validation/schema_result.dart';
import 'package:meta/meta.dart';

/// Base class for type-safe schema models
abstract class SchemaModel<T> {
  final Map<String, Object?> _data;

  /// Create from data map
  SchemaModel(this._data);

  // Static parse methods are implemented by subclasses

  /// Static method to transform and validate any object using the registered schema for its type
  ///
  /// This method uses the SchemaRegistry to find the appropriate schema for the given model type,
  /// then validates the data and transforms it to the target model.
  ///
  /// - `data`: The data map to validate and transform
  /// - `modelType`: The target model type to transform to (must be registered with SchemaRegistry)
  ///
  /// Returns a SchemaResult containing either the transformed model or validation errors
  static S get<S extends SchemaModel>(Map<String, Object?> data) {
    final schema = SchemaRegistry.createSchema(S, data);
    if (schema == null) {
      throw Exception('No schema registered for type $S');
    }

    return schema as S;
  }

  @protected
  void initialize();

  /// Get a value with type safety
  V? getValue<V>(String key) {
    final value = _data[key];

    return SchemaConverter.convertValue(value);
  }

  /// Access via subscript operator
  Object? operator [](String key) => _data[key];

  /// Get raw data
  Map<String, Object?> toMap() => Map.from(_data);

  /// Convert to a model instance
  T toModel();

  /// Validate the current data
  SchemaResult validate();

  /// Convert to JSON string
  String toJson() => jsonEncode(_data);

  /// Check if a property exists in the schema
  bool containsKey(String key) => _data.containsKey(key);
}
