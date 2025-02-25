part of '../../ack.dart';

typedef MapValue = Map<String, Object?>;

final class ObjectSchema extends Schema<MapValue>
    with SchemaFluentMethods<ObjectSchema, MapValue> {
  final bool _additionalProperties;
  final List<String> _required;
  final Map<String, Schema> _properties;

  ObjectSchema(
    this._properties, {
    bool additionalProperties = false,
    super.constraints,
    super.description,
    List<String> required = const [],
    super.nullable,
    super.defaultValue,
  })  : _additionalProperties = additionalProperties,
        _required = required,
        super(type: SchemaType.object) {
    if (!_properties.keys.containsAll(required)) {
      throw ArgumentError(
        'Required properties must be present in the properties map [${_properties.keys.getNonContainedValues(required).join(', ')}]',
      );
    }

    // Check if properties has a key called 'type'
    if (_properties.containsKey('type')) {
      log('Warning: Property name "type" is reserved for OpenAPI schema');
    }

    if (_required.areNotUnique) {
      throw ArgumentError('Required properties must be unique');
    }
  }

  @override
  List<SchemaError> _validateAsType(MapValue value) {
    final constraintErrors = super._validateAsType(value);

    constraintErrors.addAll([
      ..._validateRequiredProperties(value, _required),
      if (!_additionalProperties)
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

  ObjectSchema extend(
    Map<String, Schema> properties, {
    bool? additionalProperties,
    List<String>? required,
    bool? nullable,
    String? description,
    List<ConstraintValidator<MapValue>>? constraints,
    MapValue? defaultValue,
  }) {
    // if property SchemaValue is of SchemaMap, we need to merge them
    final mergedProperties = {..._properties};

    for (final entry in properties.entries) {
      final key = entry.key;
      final prop = entry.value;

      final existingProp = mergedProperties[key];

      if (existingProp is ObjectSchema && prop is ObjectSchema) {
        mergedProperties[key] = existingProp.extend(
          prop._properties,
          additionalProperties: prop._additionalProperties,
          required: prop._required,
          constraints: prop._constraints,
        );
      } else {
        mergedProperties[key] = prop;
      }
    }

    final requiredProperties = <String>{..._required, ...?required}.toList();

    return copyWith(
      additionalProperties: additionalProperties,
      required: requiredProperties,
      properties: mergedProperties,
      constraints: [..._constraints, ...?constraints],
      nullable: nullable,
      description: description,
      defaultValue: defaultValue,
    );
  }

  List<String> getRequiredProperties() => _required;

  Map<String, Schema> getProperties() => _properties;

  bool getAllowsAdditionalProperties() => _additionalProperties;

  /// Will extend the ObjectSchema with the values passed into call method
  ///
  /// This method is intended to be used to extend the schema with additional
  /// properties, required properties, nullable, strict, description, and constraints.
  ///
  /// Example:
  /// ```dart
  /// final schema = Ack.object({
  ///   'name': Ack.string,
  /// })(additionalProperties: true);
  /// ```
  @override
  ObjectSchema call({
    bool? nullable,
    String? description,
    bool? additionalProperties,
    List<String>? required,
    Map<String, Schema>? properties,
    List<ConstraintValidator<MapValue>>? constraints,
  }) {
    return extend(
      properties ?? _properties,
      additionalProperties: additionalProperties,
      required: required,
      nullable: nullable,
      description: description,
      constraints: constraints,
    );
  }

  @override
  ObjectSchema copyWith({
    bool? additionalProperties,
    List<String>? required,
    Map<String, Schema>? properties,
    List<ConstraintValidator<MapValue>>? constraints,
    bool? nullable,
    String? description,
    MapValue? defaultValue,
  }) {
    return ObjectSchema(
      properties ?? _properties,
      additionalProperties: additionalProperties ?? _additionalProperties,
      constraints: constraints ?? _constraints,
      description: description ?? _description,
      required: required ?? _required,
      nullable: nullable ?? _nullable,
      defaultValue: defaultValue ?? _defaultValue,
    );
  }

  @override
  Map<String, Object?> toMap() {
    return {
      ...super.toMap(),
      'properties':
          _properties.map((key, value) => MapEntry(key, value.toMap())),
      'additionalProperties': _additionalProperties,
      'required': _required,
    };
  }
}
