// lib/src/schema/schema_model.dart
import 'dart:convert';

import 'package:ack/src/builder_helpers/schema_converter.dart';
import 'package:ack/src/schemas/schema.dart';
import 'package:ack/src/validation/ack_exception.dart';
import 'package:ack/src/validation/schema_error.dart';
import 'package:ack/src/validation/schema_result.dart';

/// Base class for type-safe schema models
abstract class SchemaModel<T> {
  final Map<String, Object?> _data = {};
  late final bool _isValid;
  late final SchemaError? _error;

  /// Create from any value, validating it automatically
  SchemaModel(Object? value) {
    _initialize(value);
  }

  void _initialize(Object? value) {
    // Run validation on the schema
    final result = _validateValue(value);
    _isValid = result.isOk;
    _error = result.isFail ? result.getError() : null;

    // Store the validated data if valid
    if (result.isOk && result.getOrNull() is Map<String, Object?>) {
      _data.addAll(result.getOrNull() as Map<String, Object?>);
    }
  }

  /// Validate the input value
  SchemaResult _validateValue(Object? value) {
    final schema = getSchema();

    return schema.validate(value);
  }

  /// Check if the value is valid
  bool get isValid => _isValid;

  /// Abstract method to get the schema for validation
  AckSchema getSchema();

  /// Get validation errors if any
  SchemaError? getErrors() => _error;

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
  T toModel() {
    if (!isValid) {
      throw AckException(getErrors()!);
    }
    // Implementation provided by subclasses
    throw UnimplementedError('Subclasses must implement toModel()');
  }

  /// Convert to JSON string
  String toJson() => jsonEncode(_data);

  /// Check if a property exists in the schema
  bool containsKey(String key) => _data.containsKey(key);
}

// Using AckException from validation/ack_exception.dart
