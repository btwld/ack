import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('Error Handling Documentation Examples', () {
    group('Validation Results', () {
      test('Basic validation result handling', () {
        final schema = Ack.string.minLength(3);
        final result = schema.validate('ab'); // Too short

        expect(result.isOk, isFalse);

        if (result.isOk) {
          // This won't execute
          final validData = result.getOrThrow();
          expect(validData, equals('ab'));
        } else {
          // This will execute
          final error = result.getError() as SchemaConstraintsError;
          expect(error, isNotNull);
          expect(error.constraints.first.message, contains('Too short'));
        }
      });
    });

    group('Handling Basic Errors', () {
      test('Email validation error', () {
        final schema = Ack.string.minLength(3).isEmail();
        final result = schema.validate('a');

        expect(result.isOk, isFalse);

        if (result.isFail) {
          final error = result.getError() as SchemaConstraintsError;
          expect(error.constraints.first.message, isNotEmpty);

          // In a real application, you would print the error message
          // print('${error.path}: ${error.message}');
        }
      });
    });

    group('Handling Nested Errors', () {
      test('Complex object validation errors', () {
        final userSchema = Ack.object({
          'name': Ack.string.minLength(2),
          'address': Ack.object({
            'city': Ack.string.minLength(2),
            'zipCode': Ack.string.constrain(StringRegexConstraint(
                patternName: 'zipcode', pattern: r'^\d{5}$', example: '12345')),
          })
        });

        final result = userSchema.validate({
          'name': 'J', // Too short
          'address': {
            'city': '', // Too short
            'zipCode': 'ABC' // Invalid format
          }
        });

        expect(result.isOk, isFalse);

        // Helper function to format nested errors (simplified for testing)
        void checkError(SchemaError error) {
          if (error is SchemaConstraintsError) {
            expect(error.constraints.first.message, isNotEmpty);
          }

          // In a real application, you would recursively process nested errors
          // if (error is SchemaNestedError) {
          //   for (final nestedError in error.errors) {
          //     checkError(nestedError);
          //   }
          // }
        }

        checkError(result.getError());
      });
    });

    group('Form Validation', () {
      test('Form field validation', () {
        // Simulate a form field validator
        String? validator(String? value) {
          final result = Ack.string.isEmail().validate(value ?? '');
          if (result.isFail) {
            final error = result.getError() as SchemaConstraintsError;
            return error.constraints.first.message;
          }
          return null; // Validation passed
        }

        // Valid email
        expect(validator('user@example.com'), isNull);

        // Invalid email
        expect(validator('not-an-email'), isNotNull);
      });
    });
  });
}

// Custom constraint for regex pattern matching
class StringRegexConstraint extends Constraint<String> with Validator<String> {
  final String patternName;
  final String pattern;
  final String example;
  late final RegExp _regex;

  StringRegexConstraint({
    required this.patternName,
    required this.pattern,
    required this.example,
  }) : super(
          constraintKey: 'regex_$patternName',
          description: 'Must match pattern: $pattern',
        ) {
    _regex = RegExp(pattern);
  }

  @override
  bool isValid(String value) => _regex.hasMatch(value);

  @override
  String buildMessage(String value) =>
      'Value must match $patternName pattern (e.g., $example)';
}
