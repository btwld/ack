part of '../ack_base.dart';

final class DiscriminatedMapSchema
    extends Schema<DiscriminatedMapSchema, MapValue> {
  final String _discriminatorKey;
  final Map<String, ObjectSchema> _schemas;

  const DiscriminatedMapSchema({
    super.nullable,
    required String discriminatorKey,
    required Map<String, ObjectSchema> schemas,
    super.constraints,
  })  : _discriminatorKey = discriminatorKey,
        _schemas = schemas;

  @override
  DiscriminatedMapSchema copyWith({
    List<ConstraintsValidator<MapValue>>? constraints,
    String? discriminatorKey,
    Map<String, ObjectSchema>? schemas,
    bool? nullable,
  }) {
    return DiscriminatedMapSchema(
      discriminatorKey: discriminatorKey ?? _discriminatorKey,
      schemas: schemas ?? _schemas,
      constraints: constraints ?? _constraints,
      nullable: nullable ?? _nullable,
    );
  }

  @override
  MapValue? _tryParse(Object value) {
    return value is MapValue ? value : null;
  }

  ObjectSchema? _getDiscriminatedKeyValue(MapValue value) {
    final discriminatorValue = value[_discriminatorKey];
    return discriminatorValue != null ? _schemas[discriminatorValue] : null;
  }

  @override
  List<DiscriminatedValidationError> _validateParsed(MapValue value) {
    final discriminatedSchema = _getDiscriminatedKeyValue(value);
    if (discriminatedSchema == null) {
      return [
        DiscriminatedValidationError.noSchema(_discriminatorKey),
      ];
    } else {
      final errors = <DiscriminatedValidationError>{};
      if (!discriminatedSchema.required.contains(_discriminatorKey)) {
        errors.add(DiscriminatedValidationError.keyMustBeRequiredInSchema(
          _discriminatorKey,
          discriminatedSchema,
        ));
      }
      if (discriminatedSchema._properties.containsKey(_discriminatorKey)) {
        errors.add(DiscriminatedValidationError.missing(_discriminatorKey));
      }

      final result = discriminatedSchema.validate(value);

      result.onFail((error) {
        errors.add(DiscriminatedValidationError.schemaError(
          _discriminatorKey,
          error,
        ));
      });

      return errors.toList();
    }
  }
}

final class DiscriminatedValidationError extends ConstraintsValidationError {
  const DiscriminatedValidationError._({
    required super.type,
    required super.message,
    required super.context,
  });

  // schema error
  factory DiscriminatedValidationError.schemaError(
    String discriminatorKey,
    SchemaValidationError error,
  ) {
    return DiscriminatedValidationError._(
      type: 'schema_error',
      message: 'Schema error: ${error.message}',
      context: {
        'discriminatorKey': discriminatorKey,
        'error': error.toMap(),
      },
    );
  }

  factory DiscriminatedValidationError.missing(String discriminatorKey) {
    return DiscriminatedValidationError._(
      type: 'missing_discriminator_key',
      message: 'Missing discriminator key: $discriminatorKey',
      context: {
        'discriminatorKey': discriminatorKey,
      },
    );
  }

  factory DiscriminatedValidationError.noSchema(String discriminatorKey) {
    return DiscriminatedValidationError._(
      type: 'no_schema_for_discriminator_key',
      message: 'No schema found for discriminator key: $discriminatorKey',
      context: {
        'discriminatorKey': discriminatorKey,
      },
    );
  }

  factory DiscriminatedValidationError.keyMustBeRequiredInSchema(
    String discriminatorKey,
    ObjectSchema schema,
  ) {
    return DiscriminatedValidationError._(
      type: 'discriminator_key_is_required_in_schema',
      message:
          'Discriminator key is required in schema: $discriminatorKey for schema: $schema',
      context: {
        'discriminatorKey': discriminatorKey,
        'schema': schema,
      },
    );
  }
}
