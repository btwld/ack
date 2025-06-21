// lib/src/schema/schema_model.dart
import 'dart:convert';

import 'package:ack/src/schemas/schema.dart';
import 'package:ack/src/utils/json_schema.dart';
import 'package:ack/src/validation/ack_exception.dart';
import 'package:ack/src/validation/schema_error.dart';
import 'package:meta/meta.dart';

/// Base class for type-safe schema models - no generic needed!
abstract class SchemaModel {
  final Map<String, Object?>? _data;

  const SchemaModel() : _data = null;

  @protected
  const SchemaModel.validated(Map<String, Object?> data) : _data = data;

  /// The schema definition for validation
  ObjectSchema get definition;

  /// Whether this instance has validated data
  bool get hasData => _data != null;

  /// Access to underlying data map for testing purposes only
  @visibleForTesting
  Map<String, Object?> get testData => toMap();

  /// Check if the value is valid (backward compatibility)
  bool get isValid => hasData;

  /// Parse and validate input - returns SchemaModel
  /// Subclasses override this with covariant return type
  SchemaModel parse(Object? input) {
    final result = definition.validate(input);
    if (result.isOk) {
      return createValidated(result.getOrThrow());
    }
    throw AckException(result.getError());
  }

  /// Try parse without throwing
  SchemaModel? tryParse(Object? input) {
    try {
      return parse(input);
    } catch (_) {
      return null;
    }
  }

  /// Factory method for creating validated instances
  @protected
  SchemaModel createValidated(Map<String, Object?> data);

  /// Type-safe value access with better error handling
  @protected
  T getValue<T extends Object>(String key) {
    if (_data == null) {
      throw StateError('No data available - use parse() first');
    }

    final value = _data[key];
    if (value == null) {
      throw StateError('Required field "$key" is null');
    }

    if (value is! T) {
      throw StateError(
        'Field "$key" has incorrect type. Expected $T but got ${value.runtimeType}',
      );
    }

    return value;
  }

  /// Safe nullable value access
  @protected
  T? getValueOrNull<T extends Object>(String key) {
    if (_data == null) return null;

    final value = _data[key];
    if (value == null) return null;

    if (value is! T) {
      throw StateError(
        'Field "$key" has incorrect type. Expected $T? but got ${value.runtimeType}',
      );
    }

    return value;
  }

  /// Export validated data
  Map<String, Object?> toMap() {
    if (_data == null) return const {};

    return Map.unmodifiable(_data);
  }

  /// Generate JSON Schema representation
  Map<String, Object?> toJsonSchema() {
    return JsonSchemaConverter(schema: definition).toSchema();
  }

  /// Convert to JSON string
  String toJson() => jsonEncode(toMap());

  /// Get validation errors if any (backward compatibility)
  SchemaError? getErrors() => null; // No errors if we have data
}

// Using AckException from validation/ack_exception.dart
