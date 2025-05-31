import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('Form Validation Documentation Examples', () {
    group('Basic Form Validation', () {
      test('Validate form fields', () {
        // Define schemas
        final usernameSchema = Ack.string
            .minLength(3)
            .maxLength(20)
            .matches(r'[a-zA-Z0-9_]+', example: 'john_doe123')
            .notEmpty();

        final emailSchema = Ack.string.email().notEmpty();

        final passwordSchema = Ack.string
            .minLength(8)
            .contains(r'[A-Z]') // Must contain uppercase
            .contains(r'[a-z]') // Must contain lowercase
            .contains(r'[0-9]') // Must contain digit
            .notEmpty();

        // Test valid values
        expect(usernameSchema.validate('john_doe123').isOk, isTrue);
        expect(emailSchema.validate('john@example.com').isOk, isTrue);
        expect(passwordSchema.validate('Password123').isOk, isTrue);

        // Test invalid values
        expect(usernameSchema.validate('jo').isOk, isFalse); // Too short
        expect(emailSchema.validate('not-an-email').isOk,
            isFalse); // Invalid email
        expect(passwordSchema.validate('password').isOk,
            isFalse); // No uppercase or digit
      });
    });

    group('Real-time Validation', () {
      test('Validate as user types', () {
        final emailSchema = Ack.string.email();

        // Empty string should be valid (user hasn't typed anything yet)
        expect(emailSchema.validate('').isOk, isFalse);

        // Partial email should be invalid
        expect(emailSchema.validate('john@').isOk, isFalse);

        // Complete email should be valid
        expect(emailSchema.validate('john@example.com').isOk, isTrue);
      });
    });

    group('Form Submission', () {
      test('Validate all fields at once', () {
        // Define schemas
        final usernameSchema = Ack.string.minLength(3);
        final emailSchema = Ack.string.email();
        final passwordSchema = Ack.string.minLength(8);

        // Test all fields valid
        final usernameResult = usernameSchema.validate('john');
        final emailResult = emailSchema.validate('john@example.com');
        final passwordResult = passwordSchema.validate('password123');

        expect(usernameResult.isOk && emailResult.isOk && passwordResult.isOk,
            isTrue);

        // Test one field invalid
        final invalidEmailResult = emailSchema.validate('not-an-email');
        expect(
            usernameResult.isOk &&
                invalidEmailResult.isOk &&
                passwordResult.isOk,
            isFalse);
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
