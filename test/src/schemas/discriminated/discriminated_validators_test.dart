import 'package:ack/ack.dart';
import 'package:test/test.dart';

import '../../../test_helpers.dart';

void main() {
  group('Discriminated Validators', () {
    test('Fails when discriminator key is missing from the value', () {
      final discriminatedSchema = DiscriminatedObjectSchema(
        discriminatorKey: 'type',
        schemas: {
          'a': ObjectSchema(
            {'value': IntSchema()},
            required: ['type'],
          ),
        },
      );
      final result = discriminatedSchema.validate({'value': 42});
      expect(
        result.isFail,
        isTrue,
      );
      expect(
        result,
        hasOneConstraintError(
          'discriminated_missing_discriminator_key',
        ),
      );
    });

    test('Fails when no schema is found for the discriminator value', () {
      final schema = DiscriminatedObjectSchema(
        discriminatorKey: 'type',
        schemas: {
          'a': ObjectSchema(
            {
              'type': StringSchema(),
              'value': IntSchema(),
            },
            required: ['type'],
          ),
        },
      );
      final result = schema.validate({'type': 'nonexistent', 'value': 42});
      expect(
        result.isFail,
        isTrue,
      );
      expect(
        result,
        hasOneConstraintError(
          'discriminated_no_schema_for_discriminator_value',
        ),
      );
    });

    test('Fails when discriminator key is not required in the selected schema',
        () {
      final schemaWithoutRequired = ObjectSchema(
        {
          'type': StringSchema(),
          'value': IntSchema(),
        },
        additionalProperties: true,
        required: [],
      );
      final discriminatedSchema = DiscriminatedObjectSchema(
        discriminatorKey: 'type',
        schemas: {'a': schemaWithoutRequired},
      );

      final result = discriminatedSchema.validate({'type': 'a', 'value': 42});
      expect(
        result.isFail,
        isTrue,
      );
      expect(
        result,
        hasOneConstraintError(
          'discriminated_key_must_be_required_in_schema',
        ),
      );
    });

    test(
        'Fails when discriminator key is defined as a property in the selected schema',
        () {
      final schemaWithDiscriminatorProperty = ObjectSchema(
        {
          'value': IntSchema(),
        },
        additionalProperties: true,
        required: ['type'],
      );
      final discriminatedSchema = DiscriminatedObjectSchema(
        discriminatorKey: 'type',
        schemas: {'a': schemaWithDiscriminatorProperty},
      );

      final result = discriminatedSchema.validate({'type': 'a', 'value': 42});
      expect(
        result.isFail,
        isTrue,
      );
      expect(
        result,
        hasOneConstraintError(
          'discriminated_missing_discriminator_key_in_schema',
        ),
      );
    });

    test('Fails when underlying schema validation fails', () {
      final discriminatedSchema = DiscriminatedObjectSchema(
        discriminatorKey: 'type',
        schemas: {
          'a': ObjectSchema(
            {
              'value': IntSchema(),
              'type': StringSchema(),
            },
            required: ['type'],
          ),
        },
      );
      final result =
          discriminatedSchema.validate({'type': 'a', 'value': 'not an int'});

      expect(
        (result as Fail).errors,
        hasOneSchemaError(PathSchemaError.key),
      );

      final nestedSchemaError = (result as Fail).pathSchemaError.first;
      expect(nestedSchemaError.path, 'a.value');

      expect(
        nestedSchemaError.errors,
        hasOneSchemaError(
          'invalid_type',
        ),
      );
    });
  });
}
