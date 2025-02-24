part of '../../ack_base.dart';

final class DiscriminatedValidationError extends ConstraintError {
  const DiscriminatedValidationError._({
    required String name,
    required super.message,
    required super.context,
  }) : super(name: 'discriminated_$name');

  factory DiscriminatedValidationError.missingDiscriminatorKeyInSchema(
      String discriminatorKey, String discriminatorValue) {
    return DiscriminatedValidationError._(
      name: 'missing_discriminator_key_in_schema',
      message:
          'Missing discriminator key: $discriminatorKey in schema: $discriminatorValue',
      context: {
        'discriminatorKey': discriminatorKey,
        'discriminatorValue': discriminatorValue,
      },
    );
  }

  factory DiscriminatedValidationError.noSchemaForDiscriminatorValue(
      String discriminatorKey, String discriminatorValue) {
    return DiscriminatedValidationError._(
      name: 'no_schema_for_discriminator_value',
      message:
          'No schema found for discriminator value: $discriminatorValue for discriminator key: $discriminatorKey',
      context: {
        'discriminatorKey': discriminatorKey,
        'discriminatorValue': discriminatorValue,
      },
    );
  }

  factory DiscriminatedValidationError.keyMustBeRequiredInSchema(
    String discriminatorKey,
    ObjectSchema schema,
  ) {
    return DiscriminatedValidationError._(
      name: 'key_must_be_required_in_schema',
      message:
          'Key is required in schema: $discriminatorKey for schema: $schema',
      context: {
        'discriminatorKey': discriminatorKey,
        'schema': schema,
      },
    );
  }

  factory DiscriminatedValidationError.missingDiscriminatorKeyInValue(
    String discriminatorKey,
    MapValue value,
  ) {
    return DiscriminatedValidationError._(
      name: 'missing_discriminator_key',
      message: 'Missing discriminator key: $discriminatorKey in value: $value',
      context: {
        'discriminatorKey': discriminatorKey,
        'value': value,
      },
    );
  }
}
