import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('Examples Documentation Tests', () {
    group('Basic Validation Examples', () {
      group('String Validation', () {
        test('Username and email validation', () {
          final usernameSchema = Ack.string
              .minLength(3)
              .maxLength(20)
              .constrain(
                StringRegexConstraint(
                  patternName: 'alphanumeric_underscore',
                  pattern: r'^[a-zA-Z0-9_]+$',
                  example: 'john_doe123',
                ),
              )
              .isNotEmpty();

          final emailSchema = Ack.string.isEmail().isNotEmpty();

          // Valid username
          final validUsername = usernameSchema.validate('john_doe123');
          expect(validUsername.isOk, isTrue);

          // Invalid username (too short)
          final invalidUsername = usernameSchema.validate('jo');
          expect(invalidUsername.isOk, isFalse);

          // Valid email
          final validEmail = emailSchema.validate('john@example.com');
          expect(validEmail.isOk, isTrue);

          // Invalid email
          final invalidEmail = emailSchema.validate('not-an-email');
          expect(invalidEmail.isOk, isFalse);
        });
      });

      group('Number Validation', () {
        test('Age and price validation', () {
          final ageSchema = Ack.int.min(0).max(120);

          final priceSchema =
              Ack.double.min(0.0).constrain(PositiveConstraint<double>());

          // Valid age
          final validAge = ageSchema.validate(25);
          expect(validAge.isOk, isTrue);

          // Invalid age (negative)
          final invalidAge = ageSchema.validate(-5);
          expect(invalidAge.isOk, isFalse);

          // Valid price
          final validPrice = priceSchema.validate(19.99);
          expect(validPrice.isOk, isTrue);

          // Invalid price (negative)
          final invalidPrice = priceSchema.validate(-10.50);
          expect(invalidPrice.isOk, isFalse);
        });
      });
    });

    group('Object Validation', () {
      test('Validating complex objects with nested properties', () {
        // Define the schema for a user object
        final userSchema = Ack.object(
          {
            'id': Ack.string.constrain(StringRegexConstraint(
              patternName: 'uuid',
              pattern:
                  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
              example: '123e4567-e89b-12d3-a456-426614174000',
            )), // UUID format
            'name': Ack.string.minLength(2).maxLength(50),
            'email': Ack.string.isEmail(),
            'age': Ack.int.min(18).nullable(),
            'address': Ack.object(
              {
                'street': Ack.string,
                'city': Ack.string,
                'zipCode': Ack.string
                    .constrain(StringRegexConstraint(
                        patternName: 'zipcode',
                        pattern: r'^\d{5}(-\d{4})?$',
                        example: '12345'))
                    .nullable(), // US ZIP code format
                'country': Ack.string,
              },
              required: ['street', 'city', 'country'],
            ),
            'tags': Ack.list(Ack.string).uniqueItems(),
          },
          required: ['id', 'name', 'email'],
        );

        // Valid user
        final validUser = {
          'id': '123e4567-e89b-12d3-a456-426614174000',
          'name': 'John Doe',
          'email': 'john@example.com',
          'age': 30,
          'address': {
            'street': '123 Main St',
            'city': 'New York',
            'zipCode': '10001',
            'country': 'USA',
          },
          'tags': ['developer', 'dart', 'flutter'],
        };

        final result = userSchema.validate(validUser);
        expect(result.isOk, isTrue);
      });
    });

    // Next Steps section in examples.mdx now refers to other documentation pages
    // for more specific examples
  });
}

// Phone number validation is now in the custom-validation.mdx page

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

// Custom constraint for positive numbers
class PositiveConstraint<T extends num> extends Constraint<T>
    with Validator<T> {
  const PositiveConstraint()
      : super(
          constraintKey: 'positive',
          description: 'Must be positive',
        );

  @override
  bool isValid(T value) => value > 0;

  @override
  String buildMessage(T value) => 'Value must be positive';
}
