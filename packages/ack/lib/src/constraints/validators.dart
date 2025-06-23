import '../helpers.dart';
// import '../schemas/schema.dart'; // This file doesn't exist yet, will be created later.
import 'constraint.dart';

// Temporary typedef to resolve linter errors. This will be defined in `schema.dart`.
typedef MapValue = Map<String, Object?>;

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
    // This is a tricky validation. The main purpose is for error reporting.
    // `value is expectedType` is the ideal check, but `expectedType` is a variable.
    // For now, we focus on the error message, which is the primary use.
    if (value == null) {
      return false; // Or should depend on schema nullability? No, this is for type.
    }

    return value.runtimeType == expectedType;
  }

  @override
  String buildMessage(Object? value) =>
      'Invalid type. Expected $expectedType, but got ${value?.runtimeType ?? "null"}.';
}

/// Validates that all items in a list are unique.
/// It will always pass if the input value is `null`.
class ListUniqueItemsConstraint<E> extends Constraint<List<E>?>
    with Validator<List<E>?>, JsonSchemaSpec<List<E>?> {
  const ListUniqueItemsConstraint()
      : super(
          constraintKey: 'list_unique_items',
          description: 'All items in the list must be unique.',
        );

  @override
  bool isValid(List<E>? value) {
    if (value == null) return true;

    return value.duplicates.isEmpty;
  }

  @override
  Map<String, Object?> buildContext(List<E>? value) =>
      {'duplicateItems': value?.duplicates.toList()};

  @override
  String buildMessage(List<E>? value) {
    final nonUnique = value?.duplicates.map((e) => '"$e"').join(', ');

    return 'List items must be unique. Duplicates found: $nonUnique.';
  }

  @override
  Map<String, Object?> toJsonSchema() => {'uniqueItems': true};
}

/// A generic constraint that validates a value against a custom pattern function.
class PatternConstraint<T> extends Constraint<T> with Validator<T> {
  final String expectedPattern;
  final bool Function(T value) _isValid;

  const PatternConstraint(this._isValid, this.expectedPattern)
      : super(
          constraintKey: 'pattern',
          description: 'Value must match the expected pattern.',
        );

  @override
  bool isValid(T value) {
    return _isValid(value);
  }

  @override
  String buildMessage(T value) {
    return 'Value does not match the expected pattern: $expectedPattern.';
  }
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
