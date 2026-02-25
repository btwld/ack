import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('Error Message Catalog', () {
    test('type validation errors', () {
      final examples = <ErrorExample>[];

      // String type error - use an object which can't be converted to string
      examples.add(
        ErrorExample(
          schema: Ack.string(),
          input: {'not': 'a string'},
          description: 'Object provided to string schema',
        ),
      );

      // Number type error - use an object which can't be converted to number
      examples.add(
        ErrorExample(
          schema: Ack.integer(),
          input: {'not': 'a number'},
          description: 'Object instead of integer',
        ),
      );

      // Boolean type error - use an object which can't be converted to boolean
      examples.add(
        ErrorExample(
          schema: Ack.boolean(),
          input: {'not': 'a boolean'},
          description: 'Object instead of boolean',
        ),
      );

      // Object type error
      examples.add(
        ErrorExample(
          schema: Ack.object({'id': Ack.string()}),
          input: 'not an object',
          description: 'Non-object value',
        ),
      );

      // List type error
      examples.add(
        ErrorExample(
          schema: Ack.list(Ack.string()),
          input: 'not a list',
          description: 'Non-list value',
        ),
      );

      // Verify all examples
      for (final example in examples) {
        final result = example.schema.safeParse(example.input);
        expect(
          result.isFail,
          isTrue,
          reason: 'Should fail for: ${example.description}',
        );

        final error = result.getError();
        expect(
          error,
          isA<SchemaError>(),
          reason: 'Should return SchemaError for: ${example.description}',
        );
      }
    });

    test('constraint validation errors', () {
      final examples = <ErrorExample>[];

      // String length constraints
      examples.add(
        ErrorExample(
          schema: Ack.string().minLength(5),
          input: 'hi',
          description: 'String too short',
        ),
      );

      examples.add(
        ErrorExample(
          schema: Ack.string().maxLength(3),
          input: 'hello',
          description: 'String too long',
        ),
      );

      examples.add(
        ErrorExample(
          schema: Ack.string().length(5),
          input: 'hi',
          description: 'String wrong exact length',
        ),
      );

      // Number range constraints
      examples.add(
        ErrorExample(
          schema: Ack.integer().min(0),
          input: -5,
          description: 'Number below minimum',
        ),
      );

      examples.add(
        ErrorExample(
          schema: Ack.integer().max(100),
          input: 150,
          description: 'Number above maximum',
        ),
      );

      examples.add(
        ErrorExample(
          schema: Ack.integer().positive(),
          input: -1,
          description: 'Number not positive',
        ),
      );

      examples.add(
        ErrorExample(
          schema: Ack.integer().negative(),
          input: 1,
          description: 'Number not negative',
        ),
      );

      // String format constraints
      examples.add(
        ErrorExample(
          schema: Ack.string().email(),
          input: 'not-an-email',
          description: 'Invalid email format',
        ),
      );

      examples.add(
        ErrorExample(
          schema: Ack.string().url(),
          input: 'not-a-url',
          description: 'Invalid URL format',
        ),
      );

      examples.add(
        ErrorExample(
          schema: Ack.string().uuid(),
          input: 'not-a-uuid',
          description: 'Invalid UUID format',
        ),
      );

      // List constraints
      examples.add(
        ErrorExample(
          schema: Ack.list(Ack.string()).minItems(2),
          input: ['one'],
          description: 'List too few items',
        ),
      );

      examples.add(
        ErrorExample(
          schema: Ack.list(Ack.string()).maxItems(2),
          input: ['one', 'two', 'three'],
          description: 'List too many items',
        ),
      );

      for (final example in examples) {
        final result = example.schema.safeParse(example.input);
        expect(
          result.isFail,
          isTrue,
          reason: 'Should fail for: ${example.description}',
        );
      }
    });

    test('complex validation errors', () {
      final examples = <ErrorExample>[];

      // Missing required field
      examples.add(
        ErrorExample(
          schema: Ack.object({'id': Ack.string(), 'name': Ack.string()}),
          input: {'id': '123'},
          description: 'Missing required field',
        ),
      );

      // Nested validation errors
      examples.add(
        ErrorExample(
          schema: Ack.object({
            'user': Ack.object({'email': Ack.string().email()}),
          }),
          input: {
            'user': {'email': 'invalid-email'},
          },
          description: 'Nested object validation failure',
        ),
      );

      // List item validation errors
      examples.add(
        ErrorExample(
          schema: Ack.list(Ack.string().email()),
          input: ['valid@example.com', 'invalid-email'],
          description: 'List item validation failure',
        ),
      );

      // Discriminated union errors
      examples.add(
        ErrorExample(
          schema: Ack.discriminated(
            discriminatorKey: 'type',
            schemas: {
              'a': Ack.object({'type': Ack.literal('a')}),
              'b': Ack.object({'type': Ack.literal('b')}),
            },
          ),
          input: {'type': 'c'},
          description: 'Invalid discriminator value',
        ),
      );

      // Enum validation errors
      examples.add(
        ErrorExample(
          schema: Ack.enumString(['red', 'green', 'blue']),
          input: 'yellow',
          description: 'Invalid enum value',
        ),
      );

      for (final example in examples) {
        final result = example.schema.safeParse(example.input);
        expect(
          result.isFail,
          isTrue,
          reason: 'Should fail for: ${example.description}',
        );
      }
    });

    test('null and undefined errors', () {
      final examples = <ErrorExample>[];

      // Non-nullable schema with null
      examples.add(
        ErrorExample(
          schema: Ack.string(),
          input: null,
          description: 'Null value for non-nullable schema',
        ),
      );

      // Required field missing (null/undefined)
      examples.add(
        ErrorExample(
          schema: Ack.object({'required': Ack.string()}),
          input: {},
          description: 'Required field missing',
        ),
      );

      for (final example in examples) {
        final result = example.schema.safeParse(example.input);
        expect(
          result.isFail,
          isTrue,
          reason: 'Should fail for: ${example.description}',
        );
      }
    });

    test('error message consistency', () {
      // Test that similar errors have consistent message patterns
      final stringLengthErrors = [
        Ack.string().minLength(5).safeParse('hi'),
        Ack.string().maxLength(3).safeParse('hello'),
        Ack.string().length(5).safeParse('hi'),
      ];

      for (final result in stringLengthErrors) {
        expect(result.isFail, isTrue);
        final error = result.getError();
        // All string length errors should be constraint errors
        expect(error, isA<SchemaError>());
      }

      final numberRangeErrors = [
        Ack.integer().min(0).safeParse(-1),
        Ack.integer().max(100).safeParse(101),
        Ack.double().positive().safeParse(-1.5),
      ];

      for (final result in numberRangeErrors) {
        expect(result.isFail, isTrue);
        final error = result.getError();
        expect(error, isA<SchemaError>());
      }
    });
  });
}

class ErrorExample {
  final AckSchema schema;
  final dynamic input;
  final String description;

  ErrorExample({
    required this.schema,
    required this.input,
    required this.description,
  });
}
