// lib/src/schema/schema_model.dart
import 'dart:convert';

import 'package:ack/src/schemas/schema.dart';
import 'package:ack/src/validation/schema_error.dart';
import 'package:ack/src/validation/schema_result.dart';
import 'package:meta/meta.dart';

@Deprecated('Use BaseSchema instead')
typedef SchemaModel = BaseSchema;

/// Base class for type-safe schema models
abstract class BaseSchema {
  /// The data stored in this model (protected access for subclasses)
  @protected
  final Map<String, Object?> _data = {};
  late final bool _isValid;
  late final SchemaError? _error;

  /// Create from any value, validating it automatically
  BaseSchema(Object? value) {
    _initialize(value);
  }

  /// Create from pre-validated data (internal use)
  @protected
  BaseSchema.validated(Map<String, Object?> validatedData) {
    _data.addAll(validatedData);
    _isValid = true;
    _error = null;
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

  /// Internal validation method
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

  /// Get a value from the validated data.
  /// For primitives, returns the value directly (already converted by schema validation).
  /// For complex types, returns raw value - conversion handled by generated getters.
  @protected
  V? getValue<V>(String key) {
    final value = _data[key];

    return value as V?;
  }

  /// Access via subscript operator
  Object? operator [](String key) => _data[key];

  /// Get raw data
  Map<String, Object?> toMap() => Map.from(_data);

  // NOTE: parse() and tryParse() are now implemented as static methods
  // on generated schema classes, as per the documented API design.
  // They are no longer instance methods on the base BaseSchema class.

  /// Convert to JSON string
  String toJson() => jsonEncode(_data);

  /// Check if a property exists in the schema
  bool containsKey(String key) => _data.containsKey(key);
}

// Using AckException from validation/ack_exception.dart
