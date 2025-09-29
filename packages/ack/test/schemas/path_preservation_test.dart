import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('Path Preservation in Nested Validations', () {
    group('ListSchema', () {
      test('should preserve path for invalid list items', () {
        final schema = Ack.list(Ack.string().minLength(5));

        final result = schema.validate(['valid', 'bad', 'another']);

        expect(result.isFail, isTrue);
        final error = result.getError();
        expect(error.toString(), contains('[1]'),
            reason: 'Error should contain index of bad item');
      });

      test('should show JSON pointer path for nested list items', () {
        final schema = Ack.object({
          'items': Ack.list(Ack.integer().min(10)),
        });

        final result = schema.validate({
          'items': [15, 5, 20], // 5 is invalid
        });

        expect(result.isFail, isTrue);
        final error = result.getError();
        expect(error.toString(), contains('items'),
            reason: 'Error should show parent field');
        expect(error.toString(), contains('[1]'),
            reason: 'Error should show array index');
      });
    });

    group('DiscriminatedObjectSchema', () {
      test('should preserve path for invalid discriminator value', () {
        final schema = DiscriminatedObjectSchema(
          discriminatorKey: 'type',
          schemas: {
            'cat': Ack.object({
              'type': Ack.literal('cat'),
              'meow': Ack.boolean(),
            }),
            'dog': Ack.object({
              'type': Ack.literal('dog'),
              'bark': Ack.boolean(),
            }),
          },
        );

        final result = schema.validate({
          'type': 'bird', // Invalid discriminator
        });

        expect(result.isFail, isTrue);
        final error = result.getError();
        expect(error.toString(), contains('type'),
            reason: 'Error should mention discriminator field');
        expect(error.toString(), contains(RegExp(r'cat.*dog')),
            reason: 'Error should list valid options');
      });

      test('should preserve path for nested validation in selected branch', () {
        final schema = DiscriminatedObjectSchema(
          discriminatorKey: 'kind',
          schemas: {
            'user': Ack.object({
              'kind': Ack.literal('user'),
              'email': Ack.string().email(),
            }),
          },
        );

        final result = schema.validate({
          'kind': 'user',
          'email': 'invalid-email', // Bad email
        });

        expect(result.isFail, isTrue);
        final error = result.getError();
        expect(error.toString(), contains('email'),
            reason: 'Error should show field that failed');
      });
    });

    group('AnyOfSchema', () {
      test('should preserve context through anyOf branches', () {
        final schema = Ack.object({
          'value': Ack.anyOf([
            Ack.integer().min(10),
            Ack.string().minLength(5),
          ]),
        });

        final result = schema.validate({
          'value': 3, // Too small for integer, not a string
        });

        expect(result.isFail, isTrue);
        final error = result.getError();
        expect(error.toString(), contains('value'),
            reason: 'Error should show field path');
      });
    });
  });

  group('TransformedSchema Default Values', () {
    test('should apply output default when input is null', () {
      // Create a TransformedSchema with a default value
      final baseSchema = Ack.string();
      final transformedSchema = TransformedSchema<String, String>(
        baseSchema,
        (value) => value?.toUpperCase() ?? 'TRANSFORMED',
        defaultValue: 'DEFAULT_OUTPUT',
      );

      final result = transformedSchema.validate(null);

      expect(result.isOk, isTrue);
      expect(result.getOrNull(), equals('DEFAULT_OUTPUT'),
          reason: 'Should use output default, not transformer default');
    });

    test('should apply transformation when input is not null', () {
      final schema = Ack.string()
          .transform((value) => value?.toUpperCase() ?? '')
          .copyWith(defaultValue: 'DEFAULT');

      final result = schema.validate('hello');

      expect(result.isOk, isTrue);
      expect(result.getOrNull(), equals('HELLO'));
    });

    test('nullable transformed schema with null input and no default', () {
      final schema = Ack.string()
          .nullable()
          .transform((value) => value?.toUpperCase() ?? '');

      final result = schema.validate(null);

      expect(result.isOk, isTrue);
      expect(result.getOrNull(), equals(''),
          reason: 'Transformer converts null to empty string');
    });
  });

  group('InvalidTypeConstraint Map/List Handling', () {
    test('should accept any Map implementation', () {
      final schema = Ack.object({
        'name': Ack.string(),
      });

      // Different Map implementations
      final testCases = [
        <String, Object?>{'name': 'test'},
        Map<String, dynamic>.from({'name': 'test'}),
        {'name': 'test'} as Map<String, Object?>,
      ];

      for (final testMap in testCases) {
        final result = schema.validate(testMap);
        expect(result.isOk, isTrue,
            reason: 'Should accept ${testMap.runtimeType}');
      }
    });

    test('should accept any List implementation', () {
      final schema = Ack.list(Ack.string());

      // Different List implementations
      final testCases = [
        <String>['test'],
        List<dynamic>.from(['test']),
        ['test'] as List<Object?>,
      ];

      for (final testList in testCases) {
        final result = schema.validate(testList);
        expect(result.isOk, isTrue,
            reason: 'Should accept ${testList.runtimeType}');
      }
    });
  });

  group('JSON Schema Nullability', () {
    test('AnySchema should handle nullable in JSON Schema', () {
      final nullableSchema = Ack.any().nullable();
      final nonNullableSchema = Ack.any();

      final nullableJson = nullableSchema.toJsonSchema();
      final nonNullableJson = nonNullableSchema.toJsonSchema();

      // Nullable should not restrict null
      expect(nullableJson.containsKey('not'), isFalse);

      // Non-nullable should restrict null
      expect(nonNullableJson['not'], equals({'type': 'null'}));
    });

    test('AnyOfSchema should include null type when nullable', () {
      final schema = Ack.anyOf([
        Ack.integer(),
        Ack.string(),
      ]).nullable();

      final jsonSchema = schema.toJsonSchema();

      // When nullable, AnyOfSchema wraps in oneOf with null type
      expect(jsonSchema['oneOf'], isA<List>());
      final oneOf = jsonSchema['oneOf'] as List;

      // First element should be the null type
      expect(oneOf[0], equals({'type': 'null'}));

      // Second element should contain the anyOf schemas
      expect(oneOf[1], isA<Map>());
      final innerSchema = oneOf[1] as Map;
      expect(innerSchema['anyOf'], isA<List>());
    });
  });
}