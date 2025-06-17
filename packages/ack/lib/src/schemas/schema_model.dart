// lib/src/schema/schema_model.dart
import 'dart:convert';

import 'package:ack/src/schemas/schema.dart';
import 'package:ack/src/validation/schema_error.dart';
import 'package:meta/meta.dart';

@Deprecated('Use BaseSchema instead')
typedef SchemaModel<Self extends BaseSchema<Self>> = BaseSchema<Self>;

/// Base class for type-safe schema models with generic type parameter for type-safe parse methods
abstract class BaseSchema<Self extends BaseSchema<Self>> {
  /// The data stored in this model (protected access for subclasses)
  @protected
  final Map<String, Object?> _data;
  final bool _isValid;
  final SchemaError? _error;

  // Default constructor for parser instances
  const BaseSchema()
      : _data = const {},
        _isValid = false,
        _error = null;

  @protected
  const BaseSchema.internal(this._data, this._isValid, this._error);

  @protected
  const BaseSchema.valid(Map<String, Object?> data)
      : _data = data,
        _isValid = true,
        _error = null;

  BaseSchema.invalid(SchemaError error)
      : _data = const {},
        _isValid = false,
        _error = error;

  ObjectSchema get definition;

  /// Check if the value is valid
  bool get isValid => _isValid;

  /// Access to underlying data map for testing purposes only
  @visibleForTesting
  Map<String, Object?> get testData => Map.from(_data);

  /// Parse with validation - core implementation
  /// Returns a validated instance of the concrete schema type
  Self parse(Object? data);

  /// Non-throwing parse - convenience wrapper around parse()
  /// Returns null if validation fails
  Self? tryParse(Object? data) {
    try {
      return parse(data);
    } catch (_) {
      return null;
    }
  }

  /// Get validation errors if any
  SchemaError? getErrors() => _error;

  /// Get a value from the validated data.
  /// For primitives, returns the value directly (already converted by schema validation).
  /// For complex types, returns raw value - conversion handled by generated getters.
  @protected
  V? getValue<V>(String key) {
    if (isValid == false) {
      throw StateError(
        'Schema is not valid, cannot access value for key: $key',
      );
    }
    final value = _data[key];

    return value as V?;
  }

  /// Get raw data
  Map<String, Object?> toMap() => Map.from(_data);

  // NOTE: parse() and tryParse() are now implemented as static methods
  // on generated schema classes, as per the documented API design.
  // They are no longer instance methods on the base BaseSchema class.

  /// Convert to JSON string
  String toJson() => jsonEncode(_data);
}

// Using AckException from validation/ack_exception.dart
