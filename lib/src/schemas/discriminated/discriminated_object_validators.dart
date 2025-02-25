part of '../../ack.dart';

final class DiscriminatedObjectSchemaError extends ConstraintError {
  const DiscriminatedObjectSchemaError._({
    required String name,
    required super.message,
    required super.context,
  }) : super(name: 'discriminated_$name');

  factory DiscriminatedObjectSchemaError.missingDiscriminatorKeyInSchema(
    String discriminatorKey,
    String discriminatorValue,
  ) {
    return DiscriminatedObjectSchemaError._(
      name: 'missing_discriminator_key_in_schema',
      message:
          'Missing discriminator key: $discriminatorKey in schema: $discriminatorValue',
      context: {
        'discriminatorKey': discriminatorKey,
        'discriminatorValue': discriminatorValue,
      },
    );
  }

  factory DiscriminatedObjectSchemaError.noSchemaForDiscriminatorValue(
    String discriminatorKey,
    String discriminatorValue,
  ) {
    return DiscriminatedObjectSchemaError._(
      name: 'no_schema_for_discriminator_value',
      message:
          'No schema found for discriminator value: $discriminatorValue for discriminator key: $discriminatorKey',
      context: {
        'discriminatorKey': discriminatorKey,
        'discriminatorValue': discriminatorValue,
      },
    );
  }

  factory DiscriminatedObjectSchemaError.keyMustBeRequiredInSchema(
    String discriminatorKey,
    ObjectSchema schema,
  ) {
    return DiscriminatedObjectSchemaError._(
      name: 'key_must_be_required_in_schema',
      message:
          'Key is required in schema: $discriminatorKey for schema: $schema',
      context: {'discriminatorKey': discriminatorKey, 'schema': schema},
    );
  }

  factory DiscriminatedObjectSchemaError.missingDiscriminatorKeyInValue(
    String discriminatorKey,
    MapValue value,
  ) {
    return DiscriminatedObjectSchemaError._(
      name: 'missing_discriminator_key',
      message: 'Missing discriminator key: $discriminatorKey in value: $value',
      context: {'discriminatorKey': discriminatorKey, 'value': value},
    );
  }
}
