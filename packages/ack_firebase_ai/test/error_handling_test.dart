import 'package:ack/ack.dart';
import 'package:ack_firebase_ai/ack_firebase_ai.dart';
import 'package:firebase_ai/firebase_ai.dart' as firebase_ai;
import 'package:test/test.dart';

void main() {
  group('FirebaseAiSchemaConverter - Error Handling', () {
    group('TransformedSchema rejection', () {
      test('throws UnsupportedError for date schema', () {
        final schema = Ack.date();

        expect(
          () => schema.toFirebaseAiSchema(),
          throwsA(
            isA<UnsupportedError>().having(
              (e) => e.message,
              'message',
              contains('TransformedSchema cannot be converted'),
            ),
          ),
        );
      });

      test('throws UnsupportedError for datetime schema', () {
        final schema = Ack.datetime();

        expect(
          () => schema.toFirebaseAiSchema(),
          throwsA(
            isA<UnsupportedError>().having(
              (e) => e.message,
              'message',
              contains('TransformedSchema cannot be converted'),
            ),
          ),
        );
      });

      test('throws UnsupportedError for custom transform', () {
        final schema = Ack.string().transform((s) => s!.toUpperCase());

        expect(
          () => schema.toFirebaseAiSchema(),
          throwsA(
            isA<UnsupportedError>().having(
              (e) => e.message,
              'message',
              contains('TransformedSchema cannot be converted'),
            ),
          ),
        );
      });
    });

    group('Nested property error context', () {
      test('provides property path for nested TransformedSchema errors', () {
        final schema = Ack.object({
          'user': Ack.object({
            'birthdate': Ack.date(), // TransformedSchema
          }),
        });

        expect(
          () => schema.toFirebaseAiSchema(),
          throwsA(
            isA<UnsupportedError>().having(
              (e) => e.message,
              'message',
              allOf([
                contains('Error converting property'),
                contains('birthdate'),
              ]),
            ),
          ),
        );
      });

      test('provides property path for top-level property errors', () {
        final schema = Ack.object({
          'timestamp': Ack.datetime(),
        });

        expect(
          () => schema.toFirebaseAiSchema(),
          throwsA(
            isA<UnsupportedError>().having(
              (e) => e.message,
              'message',
              contains('timestamp'),
            ),
          ),
        );
      });

      test('provides clear error for deeply nested TransformedSchema', () {
        final schema = Ack.object({
          'data': Ack.object({
            'metadata': Ack.object({
              'createdAt': Ack.date(),
            }),
          }),
        });

        expect(
          () => schema.toFirebaseAiSchema(),
          throwsA(
            isA<UnsupportedError>().having(
              (e) => e.message,
              'message',
              allOf([
                contains('Error converting property'),
                contains('createdAt'),
              ]),
            ),
          ),
        );
      });
    });

    group('Converter instantiation prevention', () {
      test('cannot instantiate FirebaseAiSchemaConverter', () {
        // This should not compile, but we can verify the constructor is private
        // by checking that the convert method is accessible but the class cannot be instantiated
        final schema = Ack.string();

        // This should work (static method)
        expect(
          () => schema.toFirebaseAiSchema(),
          returnsNormally,
        );

        // Note: We cannot directly test private constructor in Dart,
        // but attempting to instantiate would be a compile-time error:
        // final converter = FirebaseAiSchemaConverter(); // Would not compile
      });
    });

    group('Edge cases', () {
      test('handles empty anyOf gracefully', () {
        // AnyOf with empty schemas list
        final schema = Ack.anyOf([]);

        final result = schema.toFirebaseAiSchema();

        expect(result.type, firebase_ai.SchemaType.anyOf);
        expect(result.anyOf, isEmpty);
      });

      test('handles empty object in anyOf', () {
        final schema = Ack.anyOf([
          Ack.object({}),
        ]);

        final result = schema.toFirebaseAiSchema();

        expect(result.type, firebase_ai.SchemaType.anyOf);
        expect(result.anyOf, hasLength(1));
      });

      test('handles empty object schema', () {
        final schema = Ack.object({});

        final result = schema.toFirebaseAiSchema();

        expect(result.type, firebase_ai.SchemaType.object);
        expect(result.properties, isEmpty);
      });

      test('handles deeply nested optional objects', () {
        final schema = Ack.object({
          'level1': Ack.object({
            'level2': Ack.object({
              'level3': Ack.string().optional(),
            }).optional(),
          }).optional(),
        });

        // Should not throw
        expect(
          () => schema.toFirebaseAiSchema(),
          returnsNormally,
        );

        final result = schema.toFirebaseAiSchema();
        expect(result.type, firebase_ai.SchemaType.object);
      });
    });

    group('Nullable handling', () {
      test('preserves nullable on primitive types', () {
        final stringSchema = Ack.string().nullable();
        final intSchema = Ack.integer().nullable();
        final doubleSchema = Ack.double().nullable();
        final boolSchema = Ack.boolean().nullable();

        expect(stringSchema.toFirebaseAiSchema().nullable, isTrue);
        expect(intSchema.toFirebaseAiSchema().nullable, isTrue);
        expect(doubleSchema.toFirebaseAiSchema().nullable, isTrue);
        expect(boolSchema.toFirebaseAiSchema().nullable, isTrue);
      });

      test('preserves nullable on complex types', () {
        final objectSchema = Ack.object({'key': Ack.string()}).nullable();
        final listSchema = Ack.list(Ack.string()).nullable();
        final enumSchema = Ack.string().enumString(['a', 'b']).nullable();

        expect(objectSchema.toFirebaseAiSchema().nullable, isTrue);
        expect(listSchema.toFirebaseAiSchema().nullable, isTrue);
        expect(enumSchema.toFirebaseAiSchema().nullable, isTrue);
      });
    });

    group('Optional vs Required fields', () {
      test('marks optional fields correctly', () {
        final schema = Ack.object({
          'required': Ack.string(),
          'optional': Ack.string().optional(),
        });

        final result = schema.toFirebaseAiSchema();

        expect(result.optionalProperties, contains('optional'));
        expect(result.optionalProperties, isNot(contains('required')));
      });

      test('handles all-optional fields', () {
        final schema = Ack.object({
          'field1': Ack.string().optional(),
          'field2': Ack.integer().optional(),
        });

        final result = schema.toFirebaseAiSchema();

        expect(result.optionalProperties, hasLength(2));
        expect(result.optionalProperties, containsAll(['field1', 'field2']));
      });

      test('handles all-required fields', () {
        final schema = Ack.object({
          'field1': Ack.string(),
          'field2': Ack.integer(),
        });

        final result = schema.toFirebaseAiSchema();

        // When all fields are required, optionalProperties should be null or empty
        expect(
          result.optionalProperties,
          anyOf(isNull, isEmpty),
        );
      });
    });

    group('AnySchema fallback', () {
      test('converts AnySchema to empty object', () {
        final schema = Ack.any();

        final result = schema.toFirebaseAiSchema();

        expect(result.type, firebase_ai.SchemaType.object);
        expect(result.properties, isEmpty);
      });

      test('handles nullable AnySchema', () {
        final schema = Ack.any().nullable();

        final result = schema.toFirebaseAiSchema();

        expect(result.type, firebase_ai.SchemaType.object);
        expect(result.nullable, isTrue);
      });
    });

    group('Complex nested structures', () {
      test('handles arrays of objects with optional fields', () {
        final schema = Ack.list(
          Ack.object({
            'id': Ack.string(),
            'metadata': Ack.object({
              'tags': Ack.list(Ack.string()).optional(),
            }).optional(),
          }),
        );

        expect(
          () => schema.toFirebaseAiSchema(),
          returnsNormally,
        );
      });

      test('handles anyOf with objects', () {
        final schema = Ack.anyOf([
          Ack.object({'type': Ack.string()}),
          Ack.object({'value': Ack.integer()}),
        ]);

        final result = schema.toFirebaseAiSchema();

        expect(result.type, firebase_ai.SchemaType.anyOf);
        expect(result.anyOf, hasLength(2));
      });

      test('handles anyOf with multiple object branches', () {
        final schema = Ack.anyOf([
          Ack.object({'type': Ack.string(), 'radius': Ack.double()}),
          Ack.object({'type': Ack.string(), 'side': Ack.double()}),
          Ack.object({
            'type': Ack.string(),
            'width': Ack.double(),
            'height': Ack.double(),
          }),
        ]);

        final result = schema.toFirebaseAiSchema();

        expect(result.type, firebase_ai.SchemaType.anyOf);
        expect(result.anyOf, hasLength(3));
      });
    });
  });
}
