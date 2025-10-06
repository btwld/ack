import '../common_types.dart';
import 'constraint.dart';

/// Constraint for validating that a value is not null.
/// Typically used internally by `AckSchema` when `isNullable` is false.
class NonNullableConstraint extends Constraint<Object?>
    with Validator<Object?> {
  const NonNullableConstraint()
    : super(
        constraintKey: 'core_non_nullable',
        description: 'Value must not be null.',
      );

  @override
  bool isValid(Object? value) => value != null;

  @override
  String buildMessage(Object? value) => 'Value is required and cannot be null.';
}

/// Constraint for validating that a value is of an expected Dart type.
/// Typically used internally by `AckSchema.tryConvertInput`.
class InvalidTypeConstraint extends Constraint<Object?>
    with Validator<Object?> {
  final Type expectedType;
  final Type? actualType;

  InvalidTypeConstraint({required this.expectedType, Object? inputValue})
    : actualType = inputValue?.runtimeType,
      super(
        constraintKey: 'core_invalid_type',
        description: 'Value must be of type $expectedType.',
      );

  const InvalidTypeConstraint.withTypes({
    required this.expectedType,
    this.actualType,
  }) : super(
         constraintKey: 'core_invalid_type',
         description: 'Value must be of type $expectedType.',
       );

  @override
  bool isValid(Object? value) {
    if (value == null) return false;

    final t = expectedType;
    if (t == Object) return true;
    if (t == String) return value is String;
    if (t == int) return value is int;
    if (t == double) return value is double;
    if (t == bool) return value is bool;
    if (t == MapValue || t == Map) return value is Map;
    if (t == List) return value is List;

    // Conservative fallback for other types
    return value.runtimeType == t;
  }

  @override
  String buildMessage(Object? value) =>
      'Invalid type. Expected $expectedType, but got ${value?.runtimeType ?? "null"}.';

  @override
  Map<String, Object?> buildContext(Object? value) => {
    'expectedType': expectedType,
    'actualType': actualType,
  };
}

// --- Object Specific Constraints ---
// These classes are used to create typed `ConstraintError` instances inside
// `ObjectSchema`'s validation logic. They do not need a `Validator` mixin.

/// Placeholder: Constraint for when an object has properties not defined in its schema
/// and `allowAdditionalProperties` is false.
class ObjectNoAdditionalPropertiesConstraint extends Constraint<MapValue>
    with Validator<MapValue> {
  final String unexpectedPropertyKey;
  ObjectNoAdditionalPropertiesConstraint({required this.unexpectedPropertyKey})
    : super(
        constraintKey: 'object_additional_properties_disallowed',
        description:
            'Object must not contain properties beyond those defined in the schema.',
      );

  @override
  bool isValid(MapValue value) {
    // This logic is handled in ObjectSchema, so this validation is conceptual.
    // We return false to ensure an error is always generated when this is used.
    return false;
  }

  @override
  String buildMessage(MapValue value) {
    return 'Unexpected property found: "$unexpectedPropertyKey".';
  }
}

/// Placeholder: Constraint for when an object is missing a required property.
/// Logic is in ObjectSchema.
class ObjectRequiredPropertiesConstraint extends Constraint<MapValue>
    with Validator<MapValue> {
  final String missingPropertyKey;
  ObjectRequiredPropertiesConstraint({required this.missingPropertyKey})
    : super(
        constraintKey: 'object_required_property_missing',
        description: 'Object must contain all required properties.',
      );

  @override
  bool isValid(MapValue value) {
    return value.containsKey(missingPropertyKey);
  }

  @override
  String buildMessage(MapValue value) {
    return 'Required property "$missingPropertyKey" is missing.';
  }
}
