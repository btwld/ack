import 'package:ack/ack.dart';
import 'package:test/test.dart';

import '../../test_helpers.dart';

void main() {
  group('DiscriminatedMapSchema', () {
    // A valid ObjectSchema for discriminator "a": it does NOT declare the discriminator key
    // in its properties but requires it in its required list.
    final validSchemaA = ObjectSchema(
      {
        'value': IntSchema(),
      },
      additionalProperties: true,
      required: ['type'],
    );

    // Another valid ObjectSchema for discriminator "b".
    final validSchemaB = ObjectSchema(
      {
        'name': StringSchema(),
      },
      additionalProperties: true,
      required: ['type'],
    );

    // A DiscriminatedMapSchema with discriminator key 'type'
    // mapping discriminator values to their corresponding schemas.
    final discriminatedSchema = DiscriminatedMapSchema(
      discriminatorKey: 'type',
      schemas: {
        'a': validSchemaA,
        'b': validSchemaB,
      },
      nullable: false,
    );

    test('copyWith returns a new instance with updated fields', () {
      final newSchema = discriminatedSchema.copyWith(
        discriminatorKey: 'newType',
        schemas: {'x': validSchemaA},
        nullable: true,
      );
      expect(newSchema, isNot(same(discriminatedSchema)));
      // We don't perform a full validation here; just verify the instance type.
      expect(newSchema, isA<DiscriminatedMapSchema>());
    });

    test('Non-nullable schema fails on null', () {
      final result = discriminatedSchema.validate(null);
      expect(result, isA<Fail>());
      expect(
          TestHelpers.isFail(result).error.type, equals('non_nullable_value'));
    });

    test('Nullable schema passes on null', () {
      final nullableSchema = discriminatedSchema.copyWith(nullable: true);
      final result = nullableSchema.validate(null);
      expect(result, isA<Ok>());
    });

    test('Invalid type returns invalid type error', () {
      final result = discriminatedSchema.validate('not a map');
      expect(result, isA<Fail>());
      expect(TestHelpers.isFail(result).error.type, equals('invalid_type'));
    });

    test('Valid discriminated object passes validation', () {
      // For discriminator 'a', validSchemaA is used.
      final result = discriminatedSchema.validate({'type': 'a', 'value': 42});
      expect(result, isA<Ok>());
      expect(
          TestHelpers.isOk(result).value, equals({'type': 'a', 'value': 42}));
    });

    test('Fails when discriminator key is missing from the value', () {
      // Missing the 'type' key means no matching schema can be found.
      final result = discriminatedSchema.validate({'value': 42});
      expect(result, isA<Fail>());
      final error = TestHelpers.isConstraintError(result);
      expect(error.getError('no_schema_for_discriminator_key'),
          isA<ConstraintsValidationError>());
    });

    test('Fails when no schema is found for the discriminator value', () {
      // 'nonexistent' is not in the provided schemas map.
      final result =
          discriminatedSchema.validate({'type': 'nonexistent', 'value': 42});
      expect(result, isA<Fail>());
      final error = TestHelpers.isConstraintError(result);
      expect(error.getError('no_schema_for_discriminator_key'),
          isA<ConstraintsValidationError>());
    });

    test('Fails when discriminator key is not required in the selected schema',
        () {
      // Create a schema for 'a' that does NOT require the discriminator key.
      final schemaWithoutRequired = ObjectSchema(
        {
          'value': IntSchema(),
        },
        additionalProperties: true,
        required: [],
      );
      final discriminatedSchema2 = DiscriminatedMapSchema(
        discriminatorKey: 'type',
        schemas: {'a': schemaWithoutRequired},
      );

      final result = discriminatedSchema2.validate({'type': 'a', 'value': 42});
      expect(result, isA<Fail>());
      final error = TestHelpers.isConstraintError(result);
      expect(error.getError('discriminator_key_is_required_in_schema'),
          isA<ConstraintsValidationError>());
    });

    test(
        'Fails when discriminator key is defined as a property in the selected schema',
        () {
      // Create a schema for 'a' that mistakenly includes the discriminator key in its properties.
      final schemaWithDiscriminatorProperty = ObjectSchema(
        {
          'type': StringSchema(),
          'value': IntSchema(),
        },
        additionalProperties: true,
        required: ['type'],
      );
      final discriminatedSchema3 = DiscriminatedMapSchema(
        discriminatorKey: 'type',
        schemas: {'a': schemaWithDiscriminatorProperty},
      );

      final result = discriminatedSchema3.validate({'type': 'a', 'value': 42});
      expect(result, isA<Fail>());
      final error = TestHelpers.isConstraintError(result);
      expect(error.getError('missing_discriminator_key'),
          isA<ConstraintsValidationError>());
    });

    test('Fails when underlying schema validation fails', () {
      // For discriminator 'a', validSchemaA expects 'value' to be an int.
      final result =
          discriminatedSchema.validate({'type': 'a', 'value': 'not an int'});
      expect(result, isA<Fail>());
      final error = TestHelpers.isConstraintError(result);
      expect(error.getError('schema_error'), isA<ConstraintsValidationError>());
    });
  });
}
