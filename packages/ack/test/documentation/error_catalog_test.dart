import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('Error Message Catalog', () {
    final errorCatalog = <String, List<ErrorExample>>{};

    test('type validation errors', () {
      final examples = <ErrorExample>[];

      // String type error - use an object which can't be converted to string
      examples.add(ErrorExample(
        schema: Ack.string(),
        input: {'not': 'a string'},
        expectedErrorType: 'type',
        description: 'Object provided to string schema',
      ));

      // Number type error - use an object which can't be converted to number
      examples.add(ErrorExample(
        schema: Ack.integer(),
        input: {'not': 'a number'},
        expectedErrorType: 'type',
        description: 'Object instead of integer',
      ));

      // Boolean type error - use an object which can't be converted to boolean
      examples.add(ErrorExample(
        schema: Ack.boolean(),
        input: {'not': 'a boolean'},
        expectedErrorType: 'type',
        description: 'Object instead of boolean',
      ));

      // Object type error
      examples.add(ErrorExample(
        schema: Ack.object({'id': Ack.string()}),
        input: 'not an object',
        expectedErrorType: 'type',
        description: 'Non-object value',
      ));

      // List type error
      examples.add(ErrorExample(
        schema: Ack.list(Ack.string()),
        input: 'not a list',
        expectedErrorType: 'type',
        description: 'Non-list value',
      ));

      errorCatalog['Type Validation'] = examples;

      // Verify all examples
      for (final example in examples) {
        final result = example.schema.validate(example.input);
        expect(result.isFail, isTrue,
            reason: 'Should fail for: ${example.description}');

        final error = result.getError();
        expect(error, isA<SchemaError>(),
            reason: 'Should return SchemaError for: ${example.description}');
      }
    });

    test('constraint validation errors', () {
      final examples = <ErrorExample>[];

      // String length constraints
      examples.add(ErrorExample(
        schema: Ack.string().minLength(5),
        input: 'hi',
        expectedErrorType: 'constraint',
        description: 'String too short',
      ));

      examples.add(ErrorExample(
        schema: Ack.string().maxLength(3),
        input: 'hello',
        expectedErrorType: 'constraint',
        description: 'String too long',
      ));

      examples.add(ErrorExample(
        schema: Ack.string().length(5),
        input: 'hi',
        expectedErrorType: 'constraint',
        description: 'String wrong exact length',
      ));

      // Number range constraints
      examples.add(ErrorExample(
        schema: Ack.integer().min(0),
        input: -5,
        expectedErrorType: 'constraint',
        description: 'Number below minimum',
      ));

      examples.add(ErrorExample(
        schema: Ack.integer().max(100),
        input: 150,
        expectedErrorType: 'constraint',
        description: 'Number above maximum',
      ));

      examples.add(ErrorExample(
        schema: Ack.integer().positive(),
        input: -1,
        expectedErrorType: 'constraint',
        description: 'Number not positive',
      ));

      examples.add(ErrorExample(
        schema: Ack.integer().negative(),
        input: 1,
        expectedErrorType: 'constraint',
        description: 'Number not negative',
      ));

      // String format constraints
      examples.add(ErrorExample(
        schema: Ack.string().email(),
        input: 'not-an-email',
        expectedErrorType: 'constraint',
        description: 'Invalid email format',
      ));

      examples.add(ErrorExample(
        schema: Ack.string().url(),
        input: 'not-a-url',
        expectedErrorType: 'constraint',
        description: 'Invalid URL format',
      ));

      examples.add(ErrorExample(
        schema: Ack.string().uuid(),
        input: 'not-a-uuid',
        expectedErrorType: 'constraint',
        description: 'Invalid UUID format',
      ));

      // List constraints
      examples.add(ErrorExample(
        schema: Ack.list(Ack.string()).minItems(2),
        input: ['one'],
        expectedErrorType: 'constraint',
        description: 'List too few items',
      ));

      examples.add(ErrorExample(
        schema: Ack.list(Ack.string()).maxItems(2),
        input: ['one', 'two', 'three'],
        expectedErrorType: 'constraint',
        description: 'List too many items',
      ));

      errorCatalog['Constraint Validation'] = examples;

      for (final example in examples) {
        final result = example.schema.validate(example.input);
        expect(result.isFail, isTrue,
            reason: 'Should fail for: ${example.description}');
      }
    });

    test('complex validation errors', () {
      final examples = <ErrorExample>[];

      // Missing required field
      examples.add(ErrorExample(
        schema: Ack.object({
          'id': Ack.string(),
          'name': Ack.string(),
        }, required: [
          'id',
          'name'
        ]),
        input: {'id': '123'},
        expectedErrorType: 'nested',
        description: 'Missing required field',
      ));

      // Nested validation errors
      examples.add(ErrorExample(
        schema: Ack.object({
          'user': Ack.object({
            'email': Ack.string().email(),
          }),
        }),
        input: {
          'user': {'email': 'invalid-email'}
        },
        expectedErrorType: 'nested',
        description: 'Nested object validation failure',
      ));

      // List item validation errors
      examples.add(ErrorExample(
        schema: Ack.list(Ack.string().email()),
        input: ['valid@example.com', 'invalid-email'],
        expectedErrorType: 'nested',
        description: 'List item validation failure',
      ));

      // Discriminated union errors
      examples.add(ErrorExample(
        schema: Ack.discriminated(
          discriminatorKey: 'type',
          schemas: {
            'a': Ack.object({'type': Ack.literal('a')}),
            'b': Ack.object({'type': Ack.literal('b')}),
          },
        ),
        input: {'type': 'c'},
        expectedErrorType: 'discriminated',
        description: 'Invalid discriminator value',
      ));

      // Enum validation errors
      examples.add(ErrorExample(
        schema: Ack.enumString(['red', 'green', 'blue']),
        input: 'yellow',
        expectedErrorType: 'constraint',
        description: 'Invalid enum value',
      ));

      errorCatalog['Complex Validation'] = examples;

      for (final example in examples) {
        final result = example.schema.validate(example.input);
        expect(result.isFail, isTrue,
            reason: 'Should fail for: ${example.description}');
      }
    });

    test('null and undefined errors', () {
      final examples = <ErrorExample>[];

      // Non-nullable schema with null
      examples.add(ErrorExample(
        schema: Ack.string(),
        input: null,
        expectedErrorType: 'constraint',
        description: 'Null value for non-nullable schema',
      ));

      // Required field missing (null/undefined)
      examples.add(ErrorExample(
        schema: Ack.object({
          'required': Ack.string(),
        }, required: [
          'required'
        ]),
        input: {},
        expectedErrorType: 'nested',
        description: 'Required field missing',
      ));

      errorCatalog['Null and Undefined'] = examples;

      for (final example in examples) {
        final result = example.schema.validate(example.input);
        expect(result.isFail, isTrue,
            reason: 'Should fail for: ${example.description}');
      }
    });

    test('error message consistency', () {
      // Test that similar errors have consistent message patterns
      final stringLengthErrors = [
        Ack.string().minLength(5).validate('hi'),
        Ack.string().maxLength(3).validate('hello'),
        Ack.string().length(5).validate('hi'),
      ];

      for (final result in stringLengthErrors) {
        expect(result.isFail, isTrue);
        final error = result.getError();
        // All string length errors should be constraint errors
        expect(error, isA<SchemaError>());
      }

      final numberRangeErrors = [
        Ack.integer().min(0).validate(-1),
        Ack.integer().max(100).validate(101),
        Ack.double().positive().validate(-1.5),
      ];

      for (final result in numberRangeErrors) {
        expect(result.isFail, isTrue);
        final error = result.getError();
        expect(error, isA<SchemaError>());
      }
    });

    test('generate error documentation', () {
      // This test demonstrates how to generate documentation from the error catalog
      final doc = StringBuffer();
      doc.writeln('# Ack Validation Error Catalog\n');
      doc.writeln('This document lists all possible validation errors.\n');

      for (final category in errorCatalog.entries) {
        doc.writeln('## ${category.key}\n');

        for (final example in category.value) {
          doc.writeln('### ${example.description}');
          doc.writeln('**Input:** `${example.input}`');
          doc.writeln('**Expected Error Type:** ${example.expectedErrorType}');
          doc.writeln('');
        }
      }

      // Verify documentation was generated
      expect(doc.toString(), contains('Error Catalog'));
      expect(doc.toString(), contains('Type Validation'));
      expect(doc.toString(), contains('Constraint Validation'));
    });
  });
}

class ErrorExample {
  final AckSchema schema;
  final dynamic input;
  final String expectedErrorType;
  final String description;

  ErrorExample({
    required this.schema,
    required this.input,
    required this.expectedErrorType,
    required this.description,
  });
}
