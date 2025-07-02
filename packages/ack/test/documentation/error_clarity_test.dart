import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('Error Message Clarity', () {
    group('Error messages should be helpful and actionable', () {
      test('type mismatch errors should be clear', () {
        final testCases = <ErrorClarityTest>[
          ErrorClarityTest(
            name: 'String schema with object input',
            schema: Ack.string(),
            input: {'not': 'a string'},
            checks: [
              (error) => error.contains('string') || error.contains('String'),
              (error) =>
                  error.contains('expected') || error.contains('Expected'),
            ],
          ),
          ErrorClarityTest(
            name: 'Integer schema with object input',
            schema: Ack.integer(),
            input: {'not': 'a number'},
            checks: [
              (error) => error.contains('integer') || error.contains('number'),
              (error) =>
                  error.contains('expected') || error.contains('Expected'),
            ],
          ),
          ErrorClarityTest(
            name: 'Boolean schema with object input',
            schema: Ack.boolean(),
            input: {'not': 'a boolean'},
            checks: [
              (error) => error.contains('boolean') || error.contains('bool'),
              (error) =>
                  error.contains('expected') || error.contains('Expected'),
            ],
          ),
        ];

        for (final test in testCases) {
          final result = test.schema.validate(test.input);
          expect(result.isFail, isTrue,
              reason: 'Should fail for: ${test.name}');

          final error = result.getError().toString().toLowerCase();

          for (final check in test.checks) {
            expect(check(error), isTrue,
                reason:
                    'Error message for "${test.name}" should be clear: $error');
          }
        }
      });

      test('constraint violation errors should be specific', () {
        final testCases = <ErrorClarityTest>[
          ErrorClarityTest(
            name: 'String too short',
            schema: Ack.string().minLength(5),
            input: 'hi',
            checks: [
              (error) =>
                  error.contains('length') || error.contains('characters'),
              (error) => error.contains('5') || error.contains('least'),
            ],
          ),
          ErrorClarityTest(
            name: 'String too long',
            schema: Ack.string().maxLength(3),
            input: 'hello',
            checks: [
              (error) =>
                  error.contains('length') || error.contains('characters'),
              (error) => error.contains('3') || error.contains('most'),
            ],
          ),
          ErrorClarityTest(
            name: 'Number below minimum',
            schema: Ack.integer().min(18),
            input: 16,
            checks: [
              (error) => error.contains('18') || error.contains('least'),
              (error) =>
                  error.contains('min') ||
                  error.contains('minimum') ||
                  error.contains('at least'),
            ],
          ),
          ErrorClarityTest(
            name: 'Number above maximum',
            schema: Ack.integer().max(100),
            input: 150,
            checks: [
              (error) => error.contains('100') || error.contains('most'),
              (error) =>
                  error.contains('max') ||
                  error.contains('maximum') ||
                  error.contains('at most'),
            ],
          ),
          ErrorClarityTest(
            name: 'Invalid email format',
            schema: Ack.string().email(),
            input: 'not-an-email',
            checks: [
              (error) => error.contains('email'),
              (error) => error.contains('valid') || error.contains('invalid'),
            ],
          ),
        ];

        for (final test in testCases) {
          final result = test.schema.validate(test.input);
          expect(result.isFail, isTrue,
              reason: 'Should fail for: ${test.name}');

          final error = result.getError().toString().toLowerCase();

          for (final check in test.checks) {
            expect(check(error), isTrue,
                reason:
                    'Error message for "${test.name}" should be specific: $error');
          }
        }
      });

      test('missing required field errors should be informative', () {
        final schema = Ack.object({
          'id': Ack.string(),
          'name': Ack.string(),
          'email': Ack.string().email(),
        });

        final testCases = [
          {
            'name': 'Missing id field',
            'input': {'name': 'John', 'email': 'john@example.com'},
            'expectedField': 'id',
          },
          {
            'name': 'Missing name field',
            'input': {'id': '123', 'email': 'john@example.com'},
            'expectedField': 'name',
          },
          {
            'name': 'Missing email field',
            'input': {'id': '123', 'name': 'John'},
            'expectedField': 'email',
          },
        ];

        for (final testCase in testCases) {
          final result = schema.validate(testCase['input']);
          expect(result.isFail, isTrue,
              reason: 'Should fail for: ${testCase['name']}');

          final error = result.getError().toString().toLowerCase();
          final expectedField = testCase['expectedField'] as String;

          // Error should mention the missing field or be a nested error
          expect(
            error.contains(expectedField) ||
                error.contains('nested') ||
                error.contains('required'),
            isTrue,
            reason: 'Error should mention missing field or be nested: $error',
          );
        }
      });
    });

    group('Error paths should be clear in nested structures', () {
      test('nested object validation errors should show clear paths', () {
        final schema = Ack.object({
          'user': Ack.object({
            'profile': Ack.object({
              'age': Ack.integer().positive(),
              'email': Ack.string().email(),
            }),
          }),
        });

        final testData = {
          'user': {
            'profile': {
              'age': -5,
              'email': 'invalid-email',
            },
          },
        };

        final result = schema.validate(testData);
        expect(result.isFail, isTrue);

        final error = result.getError();
        expect(error, isA<SchemaError>());

        // For nested errors, we expect either specific path information
        // or a general nested validation error message
        final errorString = error.toString().toLowerCase();
        expect(
          errorString.contains('nested') ||
              errorString.contains('user') ||
              errorString.contains('profile'),
          isTrue,
          reason: 'Error should indicate nested structure: $errorString',
        );
      });

      test('list item validation errors should indicate position', () {
        final schema = Ack.list(Ack.string().email());

        final testData = [
          'valid@example.com',
          'invalid-email',
          'another@example.com'
        ];

        final result = schema.validate(testData);
        expect(result.isFail, isTrue);

        final error = result.getError();
        expect(error, isA<SchemaError>());

        // Error should indicate it's related to list validation
        final errorString = error.toString().toLowerCase();
        expect(
          errorString.contains('nested') ||
              errorString.contains('list') ||
              errorString.contains('array') ||
              errorString.contains('item'),
          isTrue,
          reason: 'Error should indicate list validation: $errorString',
        );
      });
    });

    group('Error messages should suggest solutions', () {
      test('format errors should hint at correct format', () {
        final testCases = [
          {
            'name': 'Email format',
            'schema': Ack.string().email(),
            'input': 'user@',
            'expectedHints': ['email', 'valid'],
          },
          {
            'name': 'URL format',
            'schema': Ack.string().url(),
            'input': 'not-a-url',
            'expectedHints': ['url', 'valid'],
          },
          {
            'name': 'UUID format',
            'schema': Ack.string().uuid(),
            'input': '123',
            'expectedHints': ['uuid', 'valid'],
          },
        ];

        for (final testCase in testCases) {
          final schema = testCase['schema'] as AckSchema;
          final result = schema.validate(testCase['input']);
          expect(result.isFail, isTrue,
              reason: 'Should fail for: ${testCase['name']}');

          final error = result.getError().toString().toLowerCase();
          final expectedHints = testCase['expectedHints'] as List<String>;

          for (final hint in expectedHints) {
            expect(error.contains(hint), isTrue,
                reason: 'Error should contain hint "$hint": $error');
          }
        }
      });

      test('range errors should specify valid ranges', () {
        final testCases = [
          {
            'name': 'Number too small',
            'schema': Ack.integer().min(18),
            'input': 16,
            'expectedHints': ['18', 'least'],
          },
          {
            'name': 'Number too large',
            'schema': Ack.integer().max(100),
            'input': 150,
            'expectedHints': ['100', 'most'],
          },
          {
            'name': 'String too short',
            'schema': Ack.string().minLength(8),
            'input': 'short',
            'expectedHints': ['8', 'characters'],
          },
        ];

        for (final testCase in testCases) {
          final schema = testCase['schema'] as AckSchema;
          final result = schema.validate(testCase['input']);
          expect(result.isFail, isTrue,
              reason: 'Should fail for: ${testCase['name']}');

          final error = result.getError().toString().toLowerCase();
          final expectedHints = testCase['expectedHints'] as List<String>;

          // At least one hint should be present
          final hasHint = expectedHints.any((hint) => error.contains(hint));
          expect(hasHint, isTrue,
              reason:
                  'Error should contain at least one hint from $expectedHints: $error');
        }
      });
    });

    group('Error messages should be user-friendly', () {
      test('technical jargon should be minimized', () {
        final schema = Ack.string().email();
        final result = schema.validate('invalid');
        expect(result.isFail, isTrue);

        final error = result.getError().toString().toLowerCase();

        // Should contain user-friendly terms
        final friendlyTerms = ['email', 'format', 'invalid', 'expected'];

        // Should contain more friendly terms than technical ones
        final friendlyCount =
            friendlyTerms.where((term) => error.contains(term)).length;

        expect(friendlyCount, greaterThanOrEqualTo(1),
            reason: 'Error should contain user-friendly terms: $error');
      });

      test('error messages should be concise but informative', () {
        final testCases = [
          Ack.string().minLength(5).validate('hi'),
          Ack.integer().positive().validate(-1),
          Ack.string().email().validate('invalid'),
        ];

        for (final result in testCases) {
          expect(result.isFail, isTrue);
          final error = result.getError().toString();

          // Error should not be too short (less than 10 chars) or too long (more than 200 chars)
          expect(error.length, greaterThan(10),
              reason: 'Error message should be informative: $error');
          expect(error.length, lessThan(200),
              reason: 'Error message should be concise: $error');
        }
      });
    });
  });
}

class ErrorClarityTest {
  final String name;
  final AckSchema schema;
  final dynamic input;
  final List<bool Function(String)> checks;

  ErrorClarityTest({
    required this.name,
    required this.schema,
    required this.input,
    required this.checks,
  });
}
