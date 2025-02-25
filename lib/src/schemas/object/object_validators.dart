part of '../../ack.dart';

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

/// Provides validation methods for [ObjectSchema].
extension ObjectSchemaValidatorsExt on ObjectSchema {
  /// {@macro object_min_properties_validator}
  /// Example:
  /// ```dart
  /// final schema = Ack.object({
  ///   'id': Ack.string(),
  ///   'name': Ack.string(),
  /// }).minProperties(1);
  /// ```
  ObjectSchema minProperties(int min) {
    return withConstraints([MinPropertiesObjectValidator(min: min)]);
  }

  /// {@macro object_max_properties_validator}
  /// Example:
  /// ```dart
  /// final schema = Ack.object({
  ///   'id': Ack.string(),
  ///   'name': Ack.string(),
  /// }).maxProperties(3);
  /// ```
  ObjectSchema maxProperties(int max) {
    return withConstraints([MaxPropertiesObjectValidator(max: max)]);
  }
}

/// {@template object_min_properties_validator}
/// Validator that checks if a [Map] has at least a minimum number of properties
///
/// Equivalent of calling `map.length >= min`
/// {@endtemplate}
class MinPropertiesObjectValidator
    extends OpenApiConstraintValidator<MapValue> {
  /// The minimum number of properties required
  final int min;

  const MinPropertiesObjectValidator({required this.min});

  @override
  bool isValid(MapValue value) => value.length >= min;

  @override
  ConstraintError onError(MapValue value) {
    return buildError(
      message: 'Object must have at least $min properties',
      context: {'min': min, 'value': value},
    );
  }

  @override
  Map<String, Object?> toSchema() => {'minProperties': min};

  @override
  String get name => 'object_min_properties';

  @override
  String get description => 'Object must have at least $min properties';
}

/// {@template object_max_properties_validator}
/// Validator that checks if a [Map] has at most a maximum number of properties
///
/// Equivalent of calling `map.length <= max`
/// {@endtemplate}
class MaxPropertiesObjectValidator
    extends OpenApiConstraintValidator<MapValue> {
  /// The maximum number of properties allowed
  final int max;

  const MaxPropertiesObjectValidator({required this.max});

  @override
  bool isValid(MapValue value) => value.length <= max;

  @override
  ConstraintError onError(MapValue value) {
    return buildError(
      message: 'Object must have at most $max properties',
      context: {'max': max, 'value': value},
    );
  }

  @override
  Map<String, Object?> toSchema() => {'maxProperties': max};

  @override
  String get name => 'object_max_properties';

  @override
  String get description => 'Object must have at most $max properties';
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
