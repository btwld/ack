import 'package:ack/ack.dart';
import 'package:test/test.dart';

// TODO: Add tests based on docs/custom-validation.mdx examples

void main() {
  group('Custom Validation Documentation Examples', () {
    test('Option 1: Combine Built-in Validators', () {
      // Username validation: 3-20 characters, alphanumeric, starts with a letter
      final usernameSchema = Ack.string.minLength(3).maxLength(20).constrain(
          StringRegexConstraint(
              patternName: 'starts_with_letter_alphanumeric',
              pattern: r'^[a-zA-Z][a-zA-Z0-9_]*$',
              example: 'Starts with letter, alphanumeric or underscore'));

      // Valid cases
      expect(usernameSchema.validate('user123').isOk, isTrue);
      expect(usernameSchema.validate('AnotherUser').isOk, isTrue);
      expect(usernameSchema.validate('aBc').isOk, isTrue);

      // Invalid cases
      expect(usernameSchema.validate('us').isOk, isFalse); // Too short
      expect(
          usernameSchema.validate('1user').isOk, isFalse); // Starts with number
      expect(
          usernameSchema.validate('user name').isOk, isFalse); // Contains space
      expect(usernameSchema.validate('toolongusernameexample123').isOk,
          isFalse); // Too long
      expect(
          usernameSchema.validate('user@').isOk, isFalse); // Invalid character
    });

    test('Option 2: Use .constrain() for one-off rules', () {
      // Define the custom validation logic within a Constraint class
      final validMarketPriceConstraint = CustomConstraint<double>(
        constraintKey: 'validMarketPrice',
        description: 'Price must be positive and end in .00 or .50',
        validationLogic: (value) => value > 0 && (value * 100).toInt() % 5 == 0,
        messageBuilder: (value) =>
            'Price must be positive and end in .00 or .50',
      );

      // Apply the constraint using .constrain()
      final priceSchema = Ack.double.constrain(validMarketPriceConstraint);

      // Test the schema
      expect(priceSchema.validate(24.50).isOk, isTrue); // Valid
      expect(priceSchema.validate(10.00).isOk, isTrue); // Valid
      expect(priceSchema.validate(0.50).isOk, isTrue); // Valid

      expect(priceSchema.validate(24.37).isOk, isFalse); // Invalid
      expect(
          priceSchema.validate(0.00).isOk, isFalse); // Invalid (not positive)
      expect(priceSchema.validate(-5.50).isOk, isFalse); // Invalid (negative)

      // Check error message
      final invalidResult = priceSchema.validate(24.37);
      expect(invalidResult.isOk, isFalse);
      final error = invalidResult.getError();
      // Check if the error is of the expected type and has the constraint
      expect(error, isA<SchemaConstraintsError>());
      expect((error as SchemaConstraintsError).constraints.first.constraint,
          equals(validMarketPriceConstraint));
      expect(error.constraints.first.message,
          equals('Price must be positive and end in .00 or .50'));
    });

    test('Option 3: Create Reusable Validators (Credit Card)', () {
      // Usage
      final schema = Ack.string.isCreditCard();

      // Valid Credit Card Numbers (Examples - using known valid Luhn numbers)
      expect(schema.validate('5100111111111111').isOk, isTrue,
          reason: 'Known valid 16-digit Luhn number');

      // Invalid Credit Card Numbers
      expect(schema.validate('1234-5678-9012-3456').isOk, isFalse,
          reason: 'Invalid Luhn check');
      expect(schema.validate('5100111111111110').isOk, isFalse,
          reason: 'Incorrect checksum digit'); // Checksum should be 1
      expect(schema.validate('1234').isOk, isFalse, reason: 'Too short');
      expect(schema.validate('abcd-efgh-ijkl-mnop').isOk, isFalse,
          reason: 'Non-numeric characters');
      expect(schema.validate(null).isOk, isFalse, reason: 'Null value');

      // Check error message
      final invalidResult = schema.validate('12345');
      expect(invalidResult.isOk, isFalse);
      final error = invalidResult.getError();
      expect(error, isA<SchemaConstraintsError>());
      expect((error as SchemaConstraintsError).constraints.first.message,
          equals('Must be a valid credit card number'));
    });

    test('Option 3: Create Custom Constraints', () {
      // Using the custom constraint for even numbers
      final evenNumberSchema =
          Ack.int.constrain(OnlyEvenConstraint()).min(0).max(100);

      // Test valid values
      expect(evenNumberSchema.validate(2).isOk, isTrue);
      expect(evenNumberSchema.validate(4).isOk, isTrue);
      expect(evenNumberSchema.validate(100).isOk, isTrue);

      // Test invalid values
      expect(evenNumberSchema.validate(3).isOk, isFalse); // Not even
      expect(evenNumberSchema.validate(-2).isOk, isFalse); // Less than min
      expect(evenNumberSchema.validate(102).isOk, isFalse); // Greater than max
    });

    test('Advanced Custom Constraints: Regex Pattern Matching', () {
      // Using the StringRegexConstraint
      final nameSchema = Ack.string.constrain(StringRegexConstraint(
          patternName: 'letters_and_spaces',
          pattern: r'^[A-Za-z\s]+$',
          example: 'John Doe'));

      // Test valid values
      expect(nameSchema.validate('John Doe').isOk, isTrue);
      expect(nameSchema.validate('Mary').isOk, isTrue);

      // Test invalid values
      expect(nameSchema.validate('John123').isOk, isFalse); // Contains digits
      expect(nameSchema.validate('John@Doe').isOk,
          isFalse); // Contains special character
    });

    test('Advanced Custom Constraints: Email with Preprocessing', () {
      // Using the TrimmedEmailConstraint
      final emailSchema = Ack.string.constrain(TrimmedEmailConstraint());

      // Test valid values (with whitespace that gets trimmed)
      expect(emailSchema.validate('  john@example.com  ').isOk, isTrue);
      expect(emailSchema.validate('john@example.com').isOk, isTrue);

      // Test invalid values
      expect(emailSchema.validate('not-an-email').isOk, isFalse);
      expect(emailSchema.validate('  still-not-an-email  ').isOk, isFalse);
    });

    test('Advanced Custom Constraints: With Parameters', () {
      // Using the AgeConstraint with a parameter
      final ageSchema = Ack.int.constrain(AgeConstraint(18));

      // Test valid values
      expect(ageSchema.validate(18).isOk, isTrue);
      expect(ageSchema.validate(21).isOk, isTrue);

      // Test invalid values
      expect(ageSchema.validate(17).isOk, isFalse);

      // Check error message
      final invalidResult = ageSchema.validate(16);
      expect(invalidResult.isOk, isFalse);
      final error = invalidResult.getError();
      expect(error, isA<SchemaConstraintsError>());
      expect((error as SchemaConstraintsError).constraints.first.message,
          equals('You must be at least 18 years old'));
    });
  });
}

// Helper class for Option 2 test
class CustomConstraint<T extends Object> extends Constraint<T>
    with Validator<T> {
  final bool Function(T value) validationLogic;
  final String Function(T value) messageBuilder;

  const CustomConstraint({
    required super.constraintKey,
    required super.description,
    required this.validationLogic,
    required this.messageBuilder,
  });

  @override
  bool isValid(T value) => validationLogic(value);

  @override
  String buildMessage(T value) => messageBuilder(value);
}

// Custom constraint for even numbers
class OnlyEvenConstraint extends Constraint<int> with Validator<int> {
  const OnlyEvenConstraint()
      : super(
          constraintKey: 'only_even',
          description: 'Must be an even number',
        );

  @override
  bool isValid(int value) => value % 2 == 0;

  @override
  String buildMessage(int value) => 'Value must be an even number.';
}

// Custom constraint for email validation with preprocessing
class TrimmedEmailConstraint extends Constraint<String> with Validator<String> {
  const TrimmedEmailConstraint()
      : super(
          constraintKey: 'trimmed_email',
          description: 'Must be a valid email address',
        );

  @override
  bool isValid(String value) {
    // Trim the value before validation
    final trimmed = value.trim();
    // Simple email validation regex
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return regex.hasMatch(trimmed);
  }

  @override
  String buildMessage(String value) => 'Value must be a valid email address';
}

// Custom constraint with parameters
class AgeConstraint extends Constraint<int> with Validator<int> {
  final int minAge;

  const AgeConstraint(this.minAge)
      : super(
          constraintKey: 'min_age',
          description: 'Must be at least $minAge years old',
        );

  @override
  bool isValid(int value) => value >= minAge;

  @override
  String buildMessage(int value) => 'You must be at least $minAge years old';
}

// Extension for Option 3 test
extension CreditCardValidator on StringSchema {
  StringSchema isCreditCard() {
    // Use constrain to add the custom logic
    return constrain(const _CreditCardConstraint());
  }
}

// Constraint implementation for Credit Card Validation
class _CreditCardConstraint extends Constraint<String> with Validator<String> {
  const _CreditCardConstraint()
      : super(
          constraintKey: 'isCreditCard',
          description: 'Must be a valid credit card number',
        );

  @override
  bool isValid(String value) => _validateCreditCard(value);

  @override
  String buildMessage(String value) => 'Must be a valid credit card number';

  // Luhn algorithm implementation
  bool _validateCreditCard(String? value) {
    if (value == null) return false;

    // Remove spaces and dashes
    final sanitized = value.replaceAll(RegExp(r'[\s-]'), '');

    // Basic format check (allow common lengths)
    if (!RegExp(r'^[0-9]{13,19}$').hasMatch(sanitized)) {
      return false;
    }

    // Luhn algorithm check
    int sum = 0;
    bool alternate = false;
    for (int i = sanitized.length - 1; i >= 0; i--) {
      int digit = int.parse(sanitized[i]);
      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit -= 9;
        }
      }
      sum += digit;
      alternate = !alternate;
    }
    final isValid = sum % 10 == 0;
    return isValid;
  }
}
