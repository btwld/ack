part of '../ack_base.dart';

typedef MapValue = Map<String, Object?>;

final class ObjectSchema extends Schema<ObjectSchema, MapValue> {
  final Map<String, Schema> _properties;
  final bool additionalProperties;
  final List<String> required;

  const ObjectSchema(
    this._properties, {
    this.additionalProperties = false,
    super.constraints = const [],
    this.required = const [],
    super.nullable,
  });

  @override
  ObjectSchema copyWith({
    bool? additionalProperties,
    List<String>? required,
    Map<String, Schema>? properties,
    List<ConstraintsValidator<MapValue>>? constraints,
    bool? nullable,
  }) {
    return ObjectSchema(
      properties ?? _properties,
      additionalProperties: additionalProperties ?? this.additionalProperties,
      required: required ?? this.required,
      constraints: constraints ?? _constraints,
      nullable: nullable ?? _nullable,
    );
  }

  @override
  MapValue? _tryParse(Object value) {
    return value is MapValue ? value : null;
  }

  ObjectSchema extend(
    Map<String, Schema> properties, {
    bool? additionalProperties,
    List<String>? required,
    List<ConstraintsValidator<MapValue>>? constraints,
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

    return copyWith(
      properties: mergedProperties,
      additionalProperties: additionalProperties,
      constraints: constraints,
      required: required,
    );
  }

  @override
  List<ObjectConstraintsValidationError> _validateParsed(MapValue value) {
    final errors = <ObjectConstraintsValidationError>[];
    final valueKeys = value.keys.toSet();
    final schemaKeys = _properties.keys.toSet();
    final requiredKeys = required.toSet();

    // Check for unallowed additional properties
    if (!additionalProperties) {
      for (final key in valueKeys.difference(schemaKeys)) {
        errors.add(
            ObjectConstraintsValidationError.unallowedAdditionalProperty(key));
      }
    }

    // Validate properties
    for (final key in schemaKeys) {
      final schemaProp = _properties[key]!;
      final prop = value[key];
      if (prop == null) {
        if (requiredKeys.contains(key)) {
          errors.add(
              ObjectConstraintsValidationError.requiredPropertyMissing(key));
        }
      } else {
        final result = schemaProp.validate(prop);
        result.onFail(
          (e) => errors.add(
            ObjectConstraintsValidationError.propertySchema(key, e),
          ),
        );
      }
    }

    return errors;
  }

  @override
  Map<String, Object?> toMap() {
    return {
      'type': 'object',
      'properties':
          _properties.map((key, value) => MapEntry(key, value.toMap())),
    };
  }
}

final class ObjectConstraintsValidationError
    extends ConstraintsValidationError {
  const ObjectConstraintsValidationError._({
    required super.type,
    required super.message,
    required super.context,
  });

  factory ObjectConstraintsValidationError.unallowedAdditionalProperty(
    String propertyKey,
  ) {
    return ObjectConstraintsValidationError._(
      type: 'unallowed_additional_property',
      message: 'Unallowed additional property $propertyKey',
      context: {
        'propertyKey': propertyKey,
      },
    );
  }

  factory ObjectConstraintsValidationError.requiredPropertyMissing(
    String propertyKey,
  ) {
    return ObjectConstraintsValidationError._(
      type: 'required_property_missing',
      message: 'Property $propertyKey is required',
      context: {
        'propertyKey': propertyKey,
      },
    );
  }

  factory ObjectConstraintsValidationError.propertySchema(
    String propertyKey,
    SchemaValidationError error,
  ) {
    return ObjectConstraintsValidationError._(
      type: 'property_schema_error',
      message: 'Property $propertyKey schema validation failed',
      context: {
        'propertyKey': propertyKey,
        'error': error.toMap(),
      },
    );
  }
}
