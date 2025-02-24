part of '../../ack_base.dart';

final class DiscriminatedObjectSchema extends Schema<MapValue> {
  final String _discriminatorKey;
  final Map<String, ObjectSchema> _schemas;

  const DiscriminatedObjectSchema({
    super.nullable,
    super.strict,
    required String discriminatorKey,
    required Map<String, ObjectSchema> schemas,
    super.constraints,
  })  : _discriminatorKey = discriminatorKey,
        _schemas = schemas;

  @override
  DiscriminatedObjectSchema copyWith({
    List<ConstraintValidator<MapValue>>? constraints,
    String? discriminatorKey,
    Map<String, ObjectSchema>? schemas,
    bool? nullable,
    bool? strict,
  }) {
    return DiscriminatedObjectSchema(
      discriminatorKey: discriminatorKey ?? _discriminatorKey,
      schemas: schemas ?? _schemas,
      constraints: constraints ?? _constraints,
      nullable: nullable ?? _nullable,
      strict: strict ?? _strict,
    );
  }

  String? _getDiscriminatorValue(MapValue value) {
    final discriminatorValue = value[_discriminatorKey];
    return discriminatorValue != null ? discriminatorValue as String : null;
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
    final discriminatorValue = _getDiscriminatorValue(value);

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

    final result = discriminatedSchema.validate(value);

    final schemaErrors = <SchemaError>[];
    result.onFail(
      (errors) {
        schemaErrors.addAll(
          SchemaError.pathSchemas(
            path: discriminatorValue,
            errors: errors,
            message: 'Schema for $discriminatorValue validation failed',
            schema: this,
          ),
        );
      },
    );

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
  for (final MapEntry(key: key, value: schema) in schemas.entries) {
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
