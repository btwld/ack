part of '../../ack_base.dart';

typedef MapValue = Map<String, Object?>;

final class ObjectSchema extends Schema<MapValue>
    with SchemaFluentMethods<ObjectSchema, MapValue> {
  final bool additionalProperties;
  final List<String> required;
  final Map<String, Schema> _properties;

  ObjectSchema(
    this._properties, {
    this.additionalProperties = false,
    super.constraints,
    super.description,
    this.required = const [],
    super.nullable,
    super.strict,
  });

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
          required: required,
          constraints: constraints,
        );
      } else {
        mergedProperties[key] = prop;
      }
    }

    final requiredProperties =
        <String>{...this.required, ...?required}.toList();

    return copyWith(
      additionalProperties: additionalProperties,
      required: requiredProperties,
      properties: mergedProperties,
      constraints: [..._constraints, ...?constraints],
    );
  }

  @override
  ObjectSchema copyWith({
    bool? additionalProperties,
    List<String>? required,
    Map<String, Schema>? properties,
    List<ConstraintValidator<MapValue>>? constraints,
    bool? nullable,
    bool? strict,
    String? description,
  }) {
    return ObjectSchema(
      properties ?? _properties,
      additionalProperties: additionalProperties ?? this.additionalProperties,
      constraints: constraints ?? _constraints,
      description: description ?? _description,
      required: required ?? this.required,
      nullable: nullable ?? _nullable,
      strict: strict ?? _strict,
    );
  }

  @override
  List<SchemaError> validateAsType(MapValue value) {
    final constraintErrors = super.validateAsType(value);

    constraintErrors.addAll([
      ..._validateRequiredProperties(value, required),
      if (!additionalProperties)
        ..._validateUnallowedProperties(value, _properties.keys),
    ]);

    // Validate properties
    for (final key in _properties.keys) {
      final schemaProp = _properties[key]!;
      final propResult = schemaProp.checkResult(value[key]);

      propResult.onFail(
        (errors) => constraintErrors.addAll(
          SchemaError.pathSchemas(
            path: key,
            message: 'Property $key schema validation failed',
            errors: errors,
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
