import 'package:ack/ack.dart';
import 'package:test/test.dart';

import '../../test_helpers.dart';

void main() {
  group('DiscriminatedMapSchema', () {
    test('copyWith returns a new instance with updated fields', () {
      final validSchemaA = ObjectSchema(
        {
          'value': IntSchema(),
          'type': StringSchema(),
        },
        additionalProperties: true,
        required: ['type'],
      );

      final discriminatedSchema = DiscriminatedObjectSchema(
        discriminatorKey: 'type',
        schemas: {'a': validSchemaA},
      );

      final newSchema = discriminatedSchema.copyWith(
        discriminatorKey: 'newType',
        schemas: {'x': validSchemaA},
        nullable: true,
      );
      expect(
          newSchema,
          isNot(
            same(discriminatedSchema),
          ));
      expect(
        newSchema,
        isA<DiscriminatedObjectSchema>(),
      );
    });

    test('Non-nullable schema fails on null', () {
      final discriminatedSchema = DiscriminatedObjectSchema(
        discriminatorKey: 'type',
        schemas: {
          'a': ObjectSchema(
            {'value': IntSchema()},
            required: ['type'],
          ),
        },
      );
      final result = discriminatedSchema.validate(null);
      expect(
        result,
        hasOneSchemaError(
          'non_nullable_value',
        ),
      );
    });

    test('Nullable schema passes on null', () {
      final discriminatedSchema = DiscriminatedObjectSchema(
        discriminatorKey: 'type',
        schemas: {
          'a': ObjectSchema(
            {'value': IntSchema()},
            required: ['type'],
          ),
        },
      );
      final nullableSchema = discriminatedSchema.copyWith(nullable: true);
      final result = nullableSchema.validate(null);
      expect(
        result.isOk,
        isTrue,
      );
    });

    test('Invalid type returns invalid type error', () {
      final discriminatedSchema = DiscriminatedObjectSchema(
        discriminatorKey: 'type',
        schemas: {
          'a': ObjectSchema(
            {'value': IntSchema()},
            required: ['type'],
          ),
        },
      );
      final result = discriminatedSchema.validate('not a map');
      expect(
        result,
        hasOneSchemaError(
          'invalid_type',
        ),
      );
    });

    test('Valid discriminated object passes validation', () {
      final discriminatedSchema = DiscriminatedObjectSchema(
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
      final result = discriminatedSchema.validate({'type': 'a', 'value': 42});
      expect(
        result.isOk,
        isTrue,
      );
    });

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

      final failResult = result;
      final nestedSchemaError = failResult.nestedSchemaErrors.first;
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
