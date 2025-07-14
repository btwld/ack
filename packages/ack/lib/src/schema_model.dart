import 'dart:convert';

import 'package:meta/meta.dart';

import 'context.dart';
import 'schemas/schema.dart';
import 'validation/ack_exception.dart';
import 'validation/schema_error.dart';
import 'validation/schema_result.dart';

/// Abstract base class for schema models that combine validation and model creation.
///
/// This class provides a type-safe way to validate JSON/Map data and create
/// strongly-typed model instances. Each model class extends this base class
/// and provides its own schema definition and model creation logic.
///
/// Example:
/// ```dart
/// class UserSchemaModel extends SchemaModel<User, ObjectSchema> {
///   @override
///   ObjectSchema buildSchema() => Ack.object({
///     'name': Ack.string(),
///     'email': Ack.string().email(),
///   });
///
///   @override
///   User createFromMap(Map<String, dynamic> map) => User(
///     name: map['name'] as String,
///     email: map['email'] as String,
///   );
/// }
/// ```
abstract class SchemaModel<T extends Object> {

  // Value container
  T? _value;

  // Track whether validation has been attempted
  bool _hasBeenValidated = false;

  /// The parsed and validated model instance.
  ///
  /// Throws [StateError] if accessed before calling a parse method.
  /// Returns null if validation failed or the validated value is null.
  T? get value {
    if (!_hasBeenValidated) {
      throw StateError('Cannot access SchemaModel.value before validation.\n'
          'Call one of these methods first: parse(), parseJson(), parseOrThrow(), or tryParse().\n'
          'Example:\n'
          '  final result = model.parse(data);\n'
          '  if (result.isOk) {\n'
          '    final value = model.value; // Now safe to access\n'
          '  }');
    }

    return _value;
  }

  /// Whether this model has been validated at least once.
  bool get hasBeenValidated => _hasBeenValidated;

  /// The validation schema for this model.
  /// This getter is implemented by generated code.
  @protected
  AckSchema<MapValue> get schema;

  /// Creates a model instance from a validated map.
  /// This method is only called after successful validation.
  @protected
  T createFromMap(Map<String, dynamic> map);

  /// Parses and validates the input, storing the result if successful.
  ///
  /// Returns a [SchemaResult] containing either the validated model instance
  /// or validation errors.
  SchemaResult<T> parse(Object? input) {
    final result = schema.validate(input);
    _hasBeenValidated = true; // Mark as validated regardless of result

    if (result.isOk) {
      try {
        final validatedMap = result.getOrThrow() as Map<String, dynamic>;
        _value = createFromMap(validatedMap);

        return SchemaResult.ok(_value);
      } catch (e) {
        _value = null; // Clear value on creation failure

        return SchemaResult.fail(SchemaValidationError(
            message: 'Model creation failed: $e',
            context: SchemaContext(name: '$T', schema: schema, value: input)));
      }
    }

    _value = null; // Clear value on validation failure

    return SchemaResult.fail(result.getError());
  }

  /// Parses and validates a JSON string.
  SchemaResult<T> parseJson(String json) {
    try {
      return parse(jsonDecode(json));
    } catch (e) {
      return SchemaResult.fail(SchemaValidationError(
          message: 'Invalid JSON: $e',
          context: SchemaContext(name: '$T', schema: schema, value: json)));
    }
  }

  /// Parses and validates the input, throwing an exception if validation fails.
  T parseOrThrow(Object? input) {
    final result = parse(input);
    if (result.isOk) {
      final value = result.getOrNull();
      if (value != null) {
        return value;
      }
      throw AckException([
        SchemaValidationError(
            message: 'Validation succeeded but value is null',
            context: SchemaContext(name: '$T', schema: schema, value: input))
      ]);
    }
    throw AckException([result.getError()]);
  }

  /// Parses and validates the input, returning null if validation fails.
  T? tryParse(Object? input) => parse(input).getOrNull();

  /// Exports the validation schema as a JSON Schema object.
  Map<String, dynamic> toJsonSchema() => schema.toJsonSchema();

  /// Clears the current value and resets validation state.
  void clear() {
    _value = null;
    _hasBeenValidated = false;
  }

  /// Helper method to extract additional properties from a map.
  /// Used by generated code when additionalProperties is enabled.
  @protected
  Map<String, dynamic> extractAdditionalProperties(
    Map<String, dynamic> map,
    Set<String> knownFields,
  ) {
    final additional = <String, dynamic>{};
    for (final entry in map.entries) {
      if (!knownFields.contains(entry.key)) {
        additional[entry.key] = entry.value;
      }
    }

    return additional;
  }
}
