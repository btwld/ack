import 'package:ack/src/constraints/constraint.dart';
import 'package:ack/src/helpers.dart';

import '../schemas/schema.dart';

class InvalidTypeConstraint extends Constraint<Object>
    with WithConstraintError<Object> {
  /// The expected type of the value.
  final Type expectedType;

  /// Creates a new [InvalidTypeConstraint] that validates that the value is of the expected type.
  InvalidTypeConstraint({required this.expectedType})
      : super(
          constraintKey: 'invalid_type',
          description: 'Expected type: $expectedType',
        );

  @override
  String buildMessage(Object value) =>
      'Invalid type: (${value.runtimeType}). Expected type: ($expectedType)';
}

class NonNullableConstraint extends Constraint<Object>
    with WithConstraintError<Object?> {
  NonNullableConstraint()
      : super(
          constraintKey: 'non_nullable',
          description: 'Value cannot be null',
        );

  @override
  String buildMessage(Object? value) => 'Cannot be null';
}

/// {@template list_unique_items_validator}
/// Validator that checks if a [List] has unique items
///
/// Equivalent of calling `list.toSet().length == list.length`
/// {@endtemplate}
class ListUniqueItemsConstraint<T extends Object> extends Constraint<List<T>>
    with Validator<List<T>>, JsonSchemaSpec<List<T>> {
  /// {@macro list_unique_items_validator}
  const ListUniqueItemsConstraint()
      : super(
          constraintKey: 'list_unique_items',
          description: 'List items must be unique',
        );

  @override
  bool isValid(List<T> value) => value.duplicates.isEmpty;

  @override
  Map<String, Object?> buildContext(List<T> value) {
    return {'duplicates': value.duplicates.toList()};
  }

  @override
  String buildMessage(List<T> value) {
    final nonUniqueValues = value.duplicates.map((e) => '"$e"').join(', ');

    return 'Must be unique. Duplicates found: $nonUniqueValues';
  }

  @override
  Map<String, Object?> toJsonSchema() => {'uniqueItems': true};
}

/// {@template object_unallowed_property_validator}
/// Validator that checks if a [Map] has unallowed properties
/// {@endtemplate}
class ObjectNoAdditionalPropertiesConstraint extends Constraint<MapValue>
    with Validator<MapValue> {
  final ObjectSchema schema;

  /// {@macro object_unallowed_property_validator}
  ObjectNoAdditionalPropertiesConstraint(this.schema)
      : super(
          constraintKey: 'object_no_additional_properties',
          description:
              'Unallowed additional properties: ${schema.getProperties().keys}',
        );

  Iterable<String> _getUnallowedProperties(MapValue value) =>
      value.keys.toSet().difference(schema.getProperties().keys.toSet());

  @override
  bool isValid(MapValue value) => schema.getAllowsAdditionalProperties()
      ? true
      : _getUnallowedProperties(value).isEmpty;

  @override
  Map<String, Object?> buildContext(MapValue value) {
    return {'unallowedProperties': _getUnallowedProperties(value).toList()};
  }

  @override
  String buildMessage(MapValue value) {
    final unallowedKeys = _getUnallowedProperties(value);

    return 'Extra properties: $unallowedKeys';
  }
}

/// {@template object_required_property_validator}
/// Validator that checks if a [Map] has required properties
/// {@endtemplate}
class ObjectRequiredPropertiesConstraint extends Constraint<MapValue>
    with Validator<MapValue> {
  /// The list of required keys
  final ObjectSchema schema;

  /// {@macro object_required_property_validator}
  ObjectRequiredPropertiesConstraint(this.schema)
      : super(
          constraintKey: 'object_required_properties',
          description: 'Required properties: ${schema.getRequiredProperties()}',
        );

  List<String> _getMissingProperties(MapValue value) => schema
      .getRequiredProperties()
      .toSet()
      .difference(value.keys.toSet())
      .toList();

  @override
  bool isValid(MapValue value) {
    return _getMissingProperties(value).isEmpty;
  }

  @override
  Map<String, Object?> buildContext(MapValue value) {
    return {'missingProperties': _getMissingProperties(value)};
  }

  @override
  String buildMessage(MapValue value) {
    return 'Missing: ${_getMissingProperties(value)}';
  }
}

/// Validates that schemas in a discriminated object are properly structured.
/// Each schema must include the discriminator key as a required property.
class ObjectDiscriminatorStructureConstraint
    extends Constraint<Map<String, ObjectSchema>>
    with Validator<Map<String, ObjectSchema>> {
  final String discriminatorKey;

  ObjectDiscriminatorStructureConstraint(this.discriminatorKey)
      : super(
          constraintKey: 'object_discriminator_structure',
          description:
              'All schemas must have "$discriminatorKey" as a required property',
        );

  /// Returns schemas missing the discriminator key in their properties
  List<String> _getSchemasWithMissingDiscriminator(
    Map<String, ObjectSchema> schemas,
  ) {
    return schemas.entries
        .where((entry) =>
            !entry.value.getProperties().containsKey(discriminatorKey))
        .map((entry) => entry.key)
        .toList();
  }

  /// Returns schemas where the discriminator is not a required property
  List<String> _getSchemasWithNotRequiredDiscriminator(
    Map<String, ObjectSchema> schemas,
  ) {
    return schemas.entries
        .where((entry) =>
            entry.value.getProperties().containsKey(discriminatorKey) &&
            !entry.value.getRequiredProperties().contains(discriminatorKey))
        .map((entry) => entry.key)
        .toList();
  }

  @override
  bool isValid(Map<String, ObjectSchema> value) {
    return _getSchemasWithMissingDiscriminator(value).isEmpty &&
        _getSchemasWithNotRequiredDiscriminator(value).isEmpty;
  }

  @override
  String buildMessage(Map<String, ObjectSchema> value) {
    final missing = _getSchemasWithMissingDiscriminator(value);
    final notRequired = _getSchemasWithNotRequiredDiscriminator(value);

    return '''
Discriminator "$discriminatorKey" must be present & required.
${missing.isNotEmpty ? 'Missing: ($missing)' : ''}
${notRequired.isNotEmpty ? 'Not required: ($notRequired)' : ''}
'''
        .trim();
  }
}

/// Validates that a value has a valid discriminator that matches a known schema.
class ObjectDiscriminatorValueConstraint extends Constraint<MapValue>
    with Validator<MapValue> {
  final String discriminatorKey;
  final Map<String, ObjectSchema> schemas;

  ObjectDiscriminatorValueConstraint(this.discriminatorKey, this.schemas)
      : super(
          constraintKey: 'object_discriminator_value',
          description: 'Value must have a valid discriminator',
        );

  @override
  bool isValid(MapValue value) {
    // Check if discriminator key exists
    if (!value.containsKey(discriminatorKey)) {
      return false;
    }

    // Get the discriminator value
    final discriminatorValue = value[discriminatorKey];

    // Check if value is a string and matches a schema
    return discriminatorValue is String &&
        schemas.containsKey(discriminatorValue);
  }

  @override
  String buildMessage(MapValue value) {
    final discriminatorValue = value[discriminatorKey];
    final validSchemaKeys = schemas.keys.toList();

    if (discriminatorValue == null) {
      return 'Missing discriminator "$discriminatorKey"';
    }

    if (discriminatorValue is! String) {
      return 'Discriminator "$discriminatorKey" must be a string, got ${discriminatorValue.runtimeType}';
    }

    return 'Invalid discriminator: $discriminatorValue. Allowed: ($validSchemaKeys)';
  }
}
