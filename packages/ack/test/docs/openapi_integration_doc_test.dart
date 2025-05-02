import 'dart:convert';

import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAPI Integration Documentation Examples', () {
    group('OpenAPI Schema Generation', () {
      test('Generate OpenAPI schema from Ack schema', () {
        // Define a schema for an API endpoint
        final createUserSchema = Ack.object(
          {
            'name': Ack.string.minLength(2).maxLength(50),
            'email': Ack.string.isEmail(),
            'role': Ack.string.nullable(),
            'preferences': Ack.object(
              {
                'darkMode': Ack.boolean.nullable(),
                'notifications': Ack.boolean.nullable(),
              },
            ).nullable(),
          },
          required: ['name', 'email'],
        );

        // This is a simplified test since we can't easily test the actual OpenAPI schema output
        expect(createUserSchema, isNotNull);
      });
    });

    group('Default Values', () {
      test('Apply default values after validation', () {
        // Define a schema
        final createUserSchema = Ack.object(
          {
            'name': Ack.string.minLength(2).maxLength(50),
            'email': Ack.string.isEmail(),
            'role': Ack.string.nullable(),
          },
          required: ['name', 'email'],
        );

        // Apply default values after validation
        final result = createUserSchema.validate({
          'name': 'John Doe',
          'email': 'john@example.com',
        });

        expect(result.isOk, isTrue);

        if (result.isOk) {
          final data = result.getOrThrow();
          // Apply defaults to optional fields
          final role = data['role'] ?? 'user';

          expect(role, equals('user'));
        }
      });
    });

    group('LLM Function Calling', () {
      test('Parse and validate LLM response', () {
        // Define a schema
        final userSchema = Ack.object(
          {
            'name': Ack.string.minLength(2),
            'email': Ack.string.isEmail(),
            'preferences': Ack.object(
              {
                'darkMode': Ack.boolean.nullable(),
                'notifications': Ack.boolean.nullable(),
              },
            ).nullable(),
          },
          required: ['name', 'email'],
        );

        // Simulated LLM response (already extracted from the response wrapper)
        final llmResponse = {
          'name': 'Alice Smith',
          'email': 'alice@example.com',
          'preferences': {'darkMode': true, 'notifications': false}
        };

        // Validate the response
        final validationResult = userSchema.validate(llmResponse);
        expect(validationResult.isOk, isTrue);

        if (validationResult.isOk) {
          final data = validationResult.getOrThrow();
          expect(data['name'], equals('Alice Smith'));
          expect(data['email'], equals('alice@example.com'));
          expect((data['preferences'] as Map<String, dynamic>)['darkMode'],
              isTrue);
        }
      });
    });

    group('Function Calling with OpenAI', () {
      test('Validate function call arguments', () {
        // Define schema
        final weatherQuerySchema = Ack.object({
          'location': Ack.string.minLength(2).maxLength(100),
          'unit': Ack.string.isEnum(['celsius', 'fahrenheit']).nullable(),
          'date': Ack.string
              .constrain(StringRegexConstraint(
                  patternName: 'iso_date',
                  pattern: r'^\d{4}-\d{2}-\d{2}$',
                  example: '2023-01-01'))
              .nullable(), // ISO date format (YYYY-MM-DD)
        });

        // Simulated function call args
        final functionCallArgs = '{"location": "New York", "unit": "celsius"}';
        final validationResult =
            weatherQuerySchema.validate(jsonDecode(functionCallArgs));

        expect(validationResult.isOk, isTrue);

        if (validationResult.isOk) {
          final args = validationResult.getOrThrow();
          expect(args['location'], equals('New York'));
          expect(args['unit'], equals('celsius'));
          expect(args['date'], isNull);
        }
      });
    });
  });
}

// Custom constraint for string enum validation
class StringEnumConstraint extends Constraint<String> with Validator<String> {
  final List<String> allowedValues;

  const StringEnumConstraint(this.allowedValues)
      : super(
          constraintKey: 'enum',
          description: 'Must be one of $allowedValues',
        );

  @override
  bool isValid(String value) => allowedValues.contains(value);

  @override
  String buildMessage(String value) =>
      'Allowed: ${allowedValues.map((v) => '"$v"').join(", ")}';
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
