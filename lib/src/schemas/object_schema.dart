part of '../ack_base.dart';

typedef MapValue = Map<String, Object?>;

final class ObjectSchema extends Schema<MapValue> {
  final Map<String, Schema> _properties;
  final bool additionalProperties;
  final List<String> required;

  ObjectSchema(
    this._properties, {
    this.additionalProperties = false,
    List<ConstraintsValidator<MapValue>>? constraints,
    this.required = const [],
    super.nullable,
  }) : super(
          constraints: [
            if (!additionalProperties)
              UnallowedAdditionalPropertyValidator(
                _properties.keys.toSet(),
              ),
            if (required.isNotEmpty)
              RequiredPropertyMissingValidator(
                required.toSet(),
              ),
            // ...?constraints,
          ],
        );

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
  List<ConstraintsValidationError> _validateParsed(MapValue value) {
    final constraintErrors = super._validateParsed(value);

    // Validate properties
    for (final key in _properties.keys) {
      final schemaProp = _properties[key]!;
      final propResult = schemaProp.validate(value[key]);

      propResult.onFail(
        (e) => constraintErrors.add(
          ObjectConstraintsValidationError.propertySchema(key, e),
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
    };
  }
}

final class RequiredPropertyMissingValidator
    extends ConstraintsValidator<MapValue> {
  final Set<String> requiredKeys;
  RequiredPropertyMissingValidator(this.requiredKeys)
      : super(
          type: 'required_property_missing',
          description: 'Properties are required',
        );

  @override
  ConstraintsValidationError? validate(MapValue value) {
    final valueKeys = value.keys.toSet();
    final missingKeys = requiredKeys.difference(valueKeys);
    if (missingKeys.isEmpty) {
      return null;
    }
    return ConstraintsValidationError(
      type: type,
      message: 'Properties are required: ${missingKeys.join(', ')}',
      context: {
        'missingKeys': missingKeys,
      },
    );
  }
}

final class UnallowedAdditionalPropertyValidator
    extends ConstraintsValidator<MapValue> {
  final Set<String> allowedKeys;
  UnallowedAdditionalPropertyValidator(this.allowedKeys)
      : super(
          type: 'unallowed_additional_property',
          description: 'Additional properties are not allowed',
        );

  @override
  ConstraintsValidationError? validate(MapValue value) {
    final valueKeys = value.keys.toSet();
    final allowedKeys = this.allowedKeys;
    final unallowedKeys = valueKeys.difference(allowedKeys);
    if (unallowedKeys.isEmpty) {
      return null;
    }
    return ConstraintsValidationError(
      type: type,
      message:
          'Only the following properties are allowed: ${allowedKeys.join(', ')}',
      context: {
        'unallowedKeys': unallowedKeys,
      },
    );
  }
}

final class ObjectConstraintsValidationError
    extends ConstraintsValidationError {
  const ObjectConstraintsValidationError._({
    required super.type,
    required super.message,
    required super.context,
  });

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
