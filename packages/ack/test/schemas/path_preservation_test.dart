import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('Path Preservation in Nested Validations', () {
    group('ListSchema', () {
      test('should preserve path for invalid list items', () {
        final schema = Ack.list(Ack.string().minLength(5));

        final result = schema.safeParse(['valid', 'bad', 'another']);

        expect(result.isFail, isTrue);
        final error = result.getError();
        // Check the actual JSON Pointer path from nested error
        if (error is SchemaNestedError) {
          final nestedErrors = error.errors;
          expect(nestedErrors, isNotEmpty);
          final firstError = nestedErrors.first;
          if (firstError is SchemaConstraintsError) {
            expect(
              firstError.context.path,
              equals('#/1'),
              reason: 'Error should have JSON Pointer path #/1',
            );
          }
        }
      });

      test('should show JSON pointer path for nested list items', () {
        final schema = Ack.object({'items': Ack.list(Ack.integer().min(10))});

        final result = schema.safeParse({
          'items': [15, 5, 20], // 5 is invalid
        });

        expect(result.isFail, isTrue);
        final error = result.getError();
        // Navigate through nested error structure to find the actual validation error
        if (error is SchemaNestedError) {
          final objectErrors = error.errors;
          expect(objectErrors, isNotEmpty);
          // The first error should be for the 'items' property
          final itemsError = objectErrors.first;
          if (itemsError is SchemaNestedError) {
            // Within items, there should be an error for index 1
            final listErrors = itemsError.errors;
            expect(listErrors, isNotEmpty);
            final indexError = listErrors.first;
            if (indexError is SchemaConstraintsError) {
              expect(
                indexError.context.path,
                equals('#/items/1'),
                reason: 'Error should have full JSON Pointer path #/items/1',
              );
            }
          }
        }
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

        final result = schema.safeParse({
          'type': 'bird', // Invalid discriminator
        });

        expect(result.isFail, isTrue);
        final error = result.getError();
        expect(
          error.toString(),
          contains('type'),
          reason: 'Error should mention discriminator field',
        );
        expect(
          error.toString(),
          contains(RegExp(r'cat.*dog')),
          reason: 'Error should list valid options',
        );
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

        final result = schema.safeParse({
          'kind': 'user',
          'email': 'invalid-email', // Bad email
        });

        expect(result.isFail, isTrue);
        final error = result.getError();
        expect(
          error.toString(),
          contains('email'),
          reason: 'Error should show field that failed',
        );
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

        final result = schema.safeParse({
          'value': 3, // Too small for integer, not a string
        });

        expect(result.isFail, isTrue);
        final error = result.getError();
        expect(
          error.toString(),
          contains('value'),
          reason: 'Error should show field path',
        );
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

      final result = transformedSchema.safeParse(null);

      expect(result.isOk, isTrue);
      expect(
        result.getOrNull(),
        equals('DEFAULT_OUTPUT'),
        reason: 'Should use output default, not transformer default',
      );
    });

    test('should apply transformation when input is not null', () {
      final schema = Ack.string()
          .transform((value) => value?.toUpperCase() ?? '')
          .copyWith(defaultValue: 'DEFAULT');

      final result = schema.safeParse('hello');

      expect(result.isOk, isTrue);
      expect(result.getOrNull(), equals('HELLO'));
    });

    test('nullable transformed schema with null input and no default', () {
      final schema = Ack.string().nullable().transform(
        (value) => value?.toUpperCase() ?? '',
      );

      final result = schema.safeParse(null);

      expect(result.isOk, isTrue);
      expect(
        result.getOrNull(),
        equals(''),
        reason: 'Transformer converts null to empty string',
      );
    });
  });

  group('InvalidTypeConstraint Map/List Handling', () {
    test('should accept any Map implementation', () {
      final schema = Ack.object({'name': Ack.string()});

      // Different Map implementations
      final testCases = [
        <String, Object?>{'name': 'test'},
        Map<String, dynamic>.from({'name': 'test'}),
        {'name': 'test'} as Map<String, Object?>,
      ];

      for (final testMap in testCases) {
        final result = schema.safeParse(testMap);
        expect(
          result.isOk,
          isTrue,
          reason: 'Should accept ${testMap.runtimeType}',
        );
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
        final result = schema.safeParse(testList);
        expect(
          result.isOk,
          isTrue,
          reason: 'Should accept ${testList.runtimeType}',
        );
      }
    });
  });

  group('RFC 6901 JSON Pointer Escaping', () {
    test('should escape ~ and / in property names', () {
      final schema = Ack.object({
        'user/name': Ack.string().minLength(5),
        'config~value': Ack.integer().min(10),
      });

      // Test ~ escaping
      final result1 = schema.safeParse({
        'user/name': 'valid',
        'config~value': 5, // Invalid: too small
      });

      expect(result1.isFail, isTrue);
      final error1 = result1.getError();
      if (error1 is SchemaNestedError) {
        final nestedError = error1.errors.first;
        if (nestedError is SchemaConstraintsError) {
          // ~ should be escaped as ~0
          expect(
            nestedError.context.path,
            equals('#/config~0value'),
            reason: 'Tilde ~ should be escaped as ~0 per RFC 6901',
          );
        }
      }

      // Test / escaping
      final result2 = schema.safeParse({
        'user/name': 'bad', // Invalid: too short
        'config~value': 15,
      });

      expect(result2.isFail, isTrue);
      final error2 = result2.getError();
      if (error2 is SchemaNestedError) {
        final nestedError = error2.errors.first;
        if (nestedError is SchemaConstraintsError) {
          // / should be escaped as ~1
          expect(
            nestedError.context.path,
            equals('#/user~1name'),
            reason: 'Forward slash / should be escaped as ~1 per RFC 6901',
          );
        }
      }
    });

    test('should escape both ~ and / when present together', () {
      final schema = Ack.object({'path~/to/file': Ack.string().minLength(5)});

      final result = schema.safeParse({
        'path~/to/file': 'bad', // Invalid: too short
      });

      expect(result.isFail, isTrue);
      final error = result.getError();
      if (error is SchemaNestedError) {
        final nestedError = error.errors.first;
        if (nestedError is SchemaConstraintsError) {
          // ~ first (becomes ~0), then / (becomes ~1)
          expect(
            nestedError.context.path,
            equals('#/path~0~1to~1file'),
            reason: 'Should escape ~ as ~0 and / as ~1 per RFC 6901',
          );
        }
      }
    });

    test('should escape in nested paths', () {
      final schema = Ack.object({
        'level1': Ack.object({'level~/2': Ack.string().minLength(5)}),
      });

      final result = schema.safeParse({
        'level1': {
          'level~/2': 'bad', // Invalid: too short
        },
      });

      expect(result.isFail, isTrue);
      final error = result.getError();
      if (error is SchemaNestedError) {
        // Navigate to the nested error
        final level1Error = error.errors.first;
        if (level1Error is SchemaNestedError) {
          final level2Error = level1Error.errors.first;
          if (level2Error is SchemaConstraintsError) {
            // 'level~/2' becomes 'level~0~12' (~ -> ~0, / -> ~1, 2 stays as 2)
            expect(
              level2Error.context.path,
              equals('#/level1/level~0~12'),
              reason: 'Nested paths should also escape special characters',
            );
          }
        }
      }
    });
  });

  group('JSON Schema Nullability', () {
    test('AnySchema should handle nullable in JSON Schema', () {
      final nullableSchema = Ack.any().nullable();
      final nonNullableSchema = Ack.any();

      final nullableJson = nullableSchema.toJsonSchema();
      final nonNullableJson = nonNullableSchema.toJsonSchema();

      // Nullable AnySchema uses anyOf pattern with null
      expect(nullableJson.containsKey('anyOf'), isTrue);

      // Non-nullable AnySchema uses empty schema {} (no type field)
      // which accepts any type except null
      expect(nonNullableJson.containsKey('type'), isFalse);
      expect(nonNullableJson.containsKey('anyOf'), isFalse);
    });

    test('AnyOfSchema should include null type when nullable', () {
      final schema = Ack.anyOf([Ack.integer(), Ack.string()]).nullable();

      final jsonSchema = schema.toJsonSchema();

      // When nullable, AnyOfSchema wraps in another anyOf with null
      // Structure: anyOf: [ { anyOf: [integer, string] }, { type: 'null' } ]
      expect(jsonSchema['anyOf'], isA<List>());
      final anyOf = jsonSchema['anyOf'] as List;

      expect(anyOf.length, equals(2)); // base anyOf + null
      expect(
        anyOf[1],
        equals({'type': 'null'}),
        reason: 'Last element should be null type',
      );
      expect(anyOf[0], isA<Map>());
      expect((anyOf[0] as Map).containsKey('anyOf'), isTrue);
    });
  });
}
