import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('Discriminated Validators', () {
    test('Fails when discriminator key is missing from the value', () {
      final discriminatedSchema = DiscriminatedObjectSchema(
        discriminatorKey: 'key',
        schemas: {
          'a': ObjectSchema(
            {
              'key': StringSchema(),
              'value': IntegerSchema(),
            },
            required: ['key'],
          ),
        },
      );
      final result = discriminatedSchema.validate({'value': 42});
      expect(
        result.isFail,
        isTrue,
      );
      final error = (result as Fail).error as SchemaConstraintsError;
      expect(
        error.getConstraint<ObjectDiscriminatorValueConstraint>(),
        isNotNull,
      );
    });

    test('Fails when no schema is found for the discriminator value', () {
      final schema = DiscriminatedObjectSchema(
        discriminatorKey: 'key',
        schemas: {
          'a': ObjectSchema(
            {
              'key': StringSchema(),
              'value': IntegerSchema(),
            },
            required: ['key'],
          ),
        },
      );
      final result = schema.validate({'key': 'nonexistent', 'value': 42});
      expect(
        result.isFail,
        isTrue,
      );

      expect((result as Fail).error, isA<SchemaConstraintsError>());

      final error = (result as Fail).error as SchemaConstraintsError;
      expect(
        error.getConstraint<ObjectDiscriminatorValueConstraint>(),
        isNotNull,
      );
    });

    test('Fails when discriminator key is not required in the selected schema',
        () {
      final schemaWithoutRequired = ObjectSchema(
        {
          'key': StringSchema(),
          'value': IntegerSchema(),
        },
        additionalProperties: true,
        required: [],
      );
      final discriminatedSchema = DiscriminatedObjectSchema(
        discriminatorKey: 'key',
        schemas: {'a': schemaWithoutRequired},
      );

      final result = discriminatedSchema.validate({'key': 'a', 'value': 42});
      expect(
        result.isFail,
        isTrue,
      );
      final error = (result as Fail).error as SchemaConstraintsError;
      expect(
        error.getConstraint<ObjectDiscriminatorStructureConstraint>(),
        isNotNull,
      );
    });

    test('Fails when underlying schema validation fails', () {
      final discriminatedSchema = DiscriminatedObjectSchema(
        discriminatorKey: 'key',
        schemas: {
          'a': ObjectSchema(
            {
              'value': IntegerSchema(),
              'key': StringSchema(),
            },
            required: ['key'],
          ),
        },
      );
      final result =
          discriminatedSchema.validate({'key': 'a', 'value': 'not an int'});

      expect(
        (result as Fail).error,
        isA<SchemaNestedError>(),
      );

      final resultError = (result as Fail).error as SchemaNestedError;

      final constraintsError =
          resultError.getSchemaError<SchemaConstraintsError>();

      // Check that the 'value' property has an error
      expect(constraintsError, isNotNull);

      // Check that it's an invalid type error
      final valueError =
          constraintsError!.getConstraint<InvalidTypeConstraint>();
      expect(valueError, isNotNull);
    });
  });
}
