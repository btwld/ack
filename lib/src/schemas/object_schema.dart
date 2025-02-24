part of '../ack_base.dart';

typedef MapValue = Map<String, Object?>;

final class ObjectSchema extends Schema<MapValue> {
  final Map<String, Schema> _properties;
  final bool additionalProperties;
  final List<String> required;

  ObjectSchema(
    this._properties, {
    this.additionalProperties = false,
    super.constraints,
    this.required = const [],
    super.nullable,
    super.strict,
  });

  @override
  ObjectSchema copyWith({
    bool? additionalProperties,
    List<String>? required,
    Map<String, Schema>? properties,
    List<ConstraintValidator<MapValue>>? constraints,
    bool? nullable,
    bool? strict,
  }) {
    return ObjectSchema(
      properties ?? _properties,
      additionalProperties: additionalProperties ?? this.additionalProperties,
      required: required ?? this.required,
      constraints: constraints ?? _constraints,
      nullable: nullable ?? _nullable,
      strict: strict ?? _strict,
    );
  }

  ObjectSchema extend(
    Map<String, Schema> properties, {
    bool? additionalProperties,
    List<String>? required,
    List<ConstraintValidator<MapValue>>? constraints,
  }) {
    // if property SchemaValue is of SchemaMap, we need to merge them
    final mergedProperties = {..._properties};

    for (final entry in properties.entries) {
      final key = entry.key;
      final prop = entry.value;

      final existingProp = mergedProperties[key];

      if (existingProp is ObjectSchema) {
        mergedProperties[key] = existingProp.extend(
          properties,
          additionalProperties: additionalProperties,
          constraints: constraints,
          required: required,
        );
      } else {
        mergedProperties[key] = prop;
      }
    }

    final requiredProperties =
        <String>{...this.required, ...?required}.toList();

    return copyWith(
      properties: mergedProperties,
      additionalProperties: additionalProperties,
      constraints: [
        ..._constraints,
        ...?constraints,
      ],
      required: requiredProperties,
    );
  }

  @override
  List<SchemaError> validateAsType(MapValue value) {
    final constraintErrors = super.validateAsType(value);

    constraintErrors.addAll([
      ..._validateRequiredProperties(
        value,
        required,
      ),
      if (!additionalProperties)
        ..._validateUnallowedProperties(
          value,
          _properties.keys,
        ),
    ]);

    // Validate properties
    for (final key in _properties.keys) {
      final schemaProp = _properties[key]!;
      final propResult = schemaProp.validate(value[key]);

      propResult.onFail(
        (errors) => constraintErrors.addAll(
          SchemaError.pathSchemas(
            path: key,
            errors: errors,
            message: 'Property $key schema validation failed',
            schema: schemaProp,
          ),
        ),
      );
    }

    return constraintErrors;
  }

  @override
  Map<String, Object?> toMap() {
    return {
      'type': 'object',
      'properties':
          _properties.map((key, value) => MapEntry(key, value.toMap())),
      'additionalProperties': additionalProperties,
      'required': required,
      'nullable': _nullable,
      'strict': _strict,
    };
  }
}

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
      name: 'property_unallowed',
      message: 'Unallowed additional property: $property',
      context: {'property': property},
    );
  }

  // Required
  factory ObjectSchemaError.requiredProperty(String property) {
    return ObjectSchemaError(
      name: 'property_required',
      message: 'Required property: $property',
      context: {'property': property},
    );
  }
}
