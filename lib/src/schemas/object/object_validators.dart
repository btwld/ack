part of '../../ack_base.dart';

List<ObjectSchemaError> _validateRequiredProperties(
  MapValue value,
  Iterable<String> requiredKeys,
) {
  return requiredKeys
      .toSet()
      .difference(value.keys.toSet())
      .map(ObjectSchemaError.requiredProperty)
      .toList();
}

List<ObjectSchemaError> _validateUnallowedProperties(
  MapValue value,
  Iterable<String> allowedKeys,
) {
  return value.keys
      .toSet()
      .difference(allowedKeys.toSet())
      .map(ObjectSchemaError.unallowedProperty)
      .toList();
}

final class ObjectSchemaError extends ConstraintError {
  ObjectSchemaError({
    required super.message,
    required super.context,
    required String name,
  }) : super(name: 'object_$name');

  factory ObjectSchemaError.unallowedProperty(String property) {
    return ObjectSchemaError(
      message: 'Unallowed additional property: $property',
      context: {'property': property},
      name: 'property_unallowed',
    );
  }

  factory ObjectSchemaError.requiredProperty(String property) {
    return ObjectSchemaError(
      message: 'Required property: $property',
      context: {'property': property},
      name: 'property_required',
    );
  }
}
