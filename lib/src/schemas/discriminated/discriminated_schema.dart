part of '../../ack_base.dart';

final class DiscriminatedObjectSchema extends Schema<MapValue>
    with SchemaFluentMethods<DiscriminatedObjectSchema, MapValue> {
  final String _discriminatorKey;
  late final Map<String, ObjectSchema> _schemas;

  DiscriminatedObjectSchema({
    super.nullable,
    super.strict,
    required String discriminatorKey,
    required Map<String, ObjectSchema> schemas,
    super.constraints,
    super.description,
  }) : _discriminatorKey = discriminatorKey {
    _schemas = _strict ? _applyStrictToSchemas(schemas) : schemas;
  }
  Map<String, ObjectSchema> _applyStrictToSchemas(
    Map<String, ObjectSchema> schemas,
  ) {
    return {
      for (final entry in schemas.entries)
        entry.key: entry.value.copyWith(strict: true),
    };
  }

  String? getDiscriminatorValue(MapValue value) {
    final discriminatorValue = value[_discriminatorKey];

    return discriminatorValue != null ? discriminatorValue as String : null;
  }

  @override
  DiscriminatedObjectSchema copyWith({
    List<ConstraintValidator<MapValue>>? constraints,
    String? discriminatorKey,
    Map<String, ObjectSchema>? schemas,
    bool? nullable,
    bool? strict,
    String? description,
  }) {
    return DiscriminatedObjectSchema(
      nullable: nullable ?? _nullable,
      strict: strict ?? _strict,
      discriminatorKey: discriminatorKey ?? _discriminatorKey,
      schemas: schemas ?? _schemas,
      constraints: constraints ?? _constraints,
      description: description ?? _description,
    );
  }

  @override
  Map<String, Object?> toMap() {
    return {
      'type': 'discriminated',
      'discriminatorKey': _discriminatorKey,
      'schemas': _schemas.map((key, value) => MapEntry(key, value.toMap())),
      'nullable': _nullable,
      'strict': _strict,
    };
  }

  @override
  List<SchemaError> validateAsType(MapValue value) {
    final discriminatorValue = getDiscriminatorValue(value);

    if (discriminatorValue == null) {
      return [
        DiscriminatedValidationError.missingDiscriminatorKeyInValue(
          _discriminatorKey,
          value,
        ),
      ];
    }
    final (errors, discriminatedSchema) = _validateDiscriminatedSchemas(
      schemas: _schemas,
      discriminatorKey: _discriminatorKey,
      discriminatorValue: discriminatorValue,
    );

    if (discriminatedSchema == null) {
      return errors;
    }

    final result = discriminatedSchema.checkResult(value);

    final schemaErrors = <SchemaError>[];
    result.onFail((errors) {
      schemaErrors.addAll(
        SchemaError.pathSchemas(
          path: discriminatorValue,
          message: 'Schema for $discriminatorValue validation failed',
          errors: errors,
          schema: this,
        ),
      );
    });

    return schemaErrors;
  }
}

(List<DiscriminatedValidationError>, ObjectSchema?)
    _validateDiscriminatedSchemas({
  required Map<String, ObjectSchema> schemas,
  required String discriminatorKey,
  required String discriminatorValue,
}) {
  final errors = <DiscriminatedValidationError>[];

  // Check if schema exists for the discriminator value
  if (!schemas.containsKey(discriminatorValue)) {
    errors.add(
      DiscriminatedValidationError.noSchemaForDiscriminatorValue(
        discriminatorKey,
        discriminatorValue,
      ),
    );

    return (errors, null);
  }

  // Validate the schema configuration
  for (final MapEntry(:key, value: schema) in schemas.entries) {
    final keyIsRequired = schema.required.contains(discriminatorKey);
    final propertyExists = schema._properties.containsKey(discriminatorKey);

    if (!propertyExists) {
      errors.add(
        DiscriminatedValidationError.missingDiscriminatorKeyInSchema(
          discriminatorKey,
          key,
        ),
      );
    }

    if (!keyIsRequired) {
      errors.add(
        DiscriminatedValidationError.keyMustBeRequiredInSchema(
          discriminatorKey,
          schema,
        ),
      );
    }
  }

  return errors.isEmpty
      ? (errors, schemas[discriminatorValue])
      : (errors, null);
}
