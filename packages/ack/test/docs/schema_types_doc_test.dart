import 'dart:convert';

import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('Schema Types Documentation Examples', () {
    group('String Schema', () {
      test('Basic string schema', () {
        final nameSchema = Ack.string;
        expect(nameSchema.validate('John').isOk, isTrue);
        // Note: Ack tries to convert numbers to strings by default
        // This is expected behavior
        expect(nameSchema.validate(123).isOk, isTrue);
      });

      test('String with length constraints', () {
        // Using matches() for full string validation.
        final usernameSchema = Ack.string
            .minLength(3)
            .maxLength(20)
            .matches(r'[a-zA-Z0-9_]+', example: 'user_123');

        expect(usernameSchema.validate('user_123').isOk, isTrue);
        expect(usernameSchema.validate('ab').isOk, isFalse); // Too short.
        expect(usernameSchema.validate('a' * 21).isOk, isFalse); // Too long.
        expect(usernameSchema.validate('user-name').isOk,
            isFalse); // Invalid character.
      });

      test('Email validation', () {
        final emailSchema = Ack.string.isEmail();

        expect(emailSchema.validate('user@example.com').isOk, isTrue);
        expect(emailSchema.validate('invalid-email').isOk, isFalse);
      });

      test('Enum values', () {
        final roleSchema = Ack.string.isEnum(['admin', 'user', 'guest']);

        expect(roleSchema.validate('admin').isOk, isTrue);
        expect(roleSchema.validate('user').isOk, isTrue);
        expect(roleSchema.validate('guest').isOk, isTrue);
        expect(roleSchema.validate('other').isOk, isFalse);
      });
    });

    group('Number Schemas', () {
      test('Integer validation', () {
        final ageSchema = Ack.int.min(0).max(120);

        expect(ageSchema.validate(0).isOk, isTrue);
        expect(ageSchema.validate(120).isOk, isTrue);
        expect(ageSchema.validate(-1).isOk, isFalse);
        expect(ageSchema.validate(121).isOk, isFalse);
      });

      test('Double/decimal validation', () {
        final priceSchema = Ack.double.constrain(ExclusiveMinConstraint(0.0))
            .constrain(MultipleOfConstraint(0.01));

        expect(priceSchema.validate(0.01).isOk, isTrue);
        expect(priceSchema.validate(10.50).isOk, isTrue);
        expect(priceSchema.validate(0.0).isOk, isFalse); // Not greater than 0.
        expect(priceSchema.validate(0.001).isOk,
            isFalse); // Not a multiple of 0.01.
      });
    });

    group('Boolean Schema', () {
      test('Simple true/false validation', () {
        final isActiveSchema = Ack.boolean;

        expect(isActiveSchema.validate(true).isOk, isTrue);
        expect(isActiveSchema.validate(false).isOk, isTrue);
        // Note: Ack tries to convert strings to booleans by default
        // This is expected behavior
        expect(isActiveSchema.validate('true').isOk, isTrue);
      });
    });

    group('List Schema', () {
      test('List of strings', () {
        final tagsSchema = Ack.list(Ack.string);

        expect(tagsSchema.validate(['tag1', 'tag2']).isOk, isTrue);
        // Note: Ack tries to convert numbers to strings by default
        // This is expected behavior
        expect(tagsSchema.validate([1, 2]).isOk, isTrue);
      });

      test('List with constraints', () {
        final itemsSchema =
            Ack.list(Ack.string).minItems(1).maxItems(10).uniqueItems();

        expect(itemsSchema.validate(['item1', 'item2']).isOk, isTrue);
        expect(itemsSchema.validate([]).isOk, isFalse); // Too few items.
        expect(itemsSchema.validate(List.filled(11, 'item')).isOk,
            isFalse); // Too many items.
        expect(itemsSchema.validate(['item', 'item']).isOk,
            isFalse); // Not unique.
      });
    });

    group('Object Schema', () {
      test('Basic object schema', () {
        final userSchema = Ack.object({
          'name': Ack.string.isNotEmpty(), // Ensure name is not empty.
          'age': Ack.int.min(0), // Age must be non-negative.
        });

        final validUser = {'name': 'Alice', 'age': 30};
        final invalidUserAge = {'name': 'Bob', 'age': -5};
        final invalidUserName = {'name': '', 'age': 25};
        final missingAge = {'name': 'Charlie'};

        expect(userSchema.validate(validUser).isOk, isTrue);
        expect(userSchema.validate(invalidUserAge).isOk, isFalse);
        expect(userSchema.validate(invalidUserName).isOk, isFalse);
        expect(
            userSchema.validate(missingAge).isOk, isFalse); // Age is required.
      });

      test('Object Schema with Optional Fields', () {
        final profileSchema = Ack.object({
          'username': Ack.string.minLength(3),
          'bio': Ack.string.maxLength(200).nullable(), // Bio is optional.
        });

        final validProfile = {'username': 'dave', 'bio': 'Loves Dart.'};
        final validProfileNoBio = {
          'username': 'eve'
        }; // Bio is null implicitly.
        final validProfileNullBio = {'username': 'frank', 'bio': null};
        final invalidProfile = {'username': 'g'}; // Username too short.

        expect(profileSchema.validate(validProfile).isOk, isTrue);
        expect(profileSchema.validate(validProfileNoBio).isOk, isTrue);
        expect(profileSchema.validate(validProfileNullBio).isOk, isTrue);
        expect(profileSchema.validate(invalidProfile).isOk, isFalse);
      });

      test('Nested object schema', () {
        final addressSchema = Ack.object({
          'street': Ack.string.isNotEmpty(),
          'city': Ack.string.isNotEmpty(),
          'zip':
              Ack.string.matches(r'^\d{5}$', example: '12345'), // 5-digit zip.
        });

        final userWithAddressSchema = Ack.object({
          'name': Ack.string.isNotEmpty(),
          'address': addressSchema, // Nested schema.
        });

        final validData = {
          'name': 'Hannah',
          'address': {
            'street': '123 Main St',
            'city': 'Anytown',
            'zip': '12345'
          }
        };
        final invalidZip = {
          'name': 'Ian',
          'address': {
            'street': '456 Oak Ave',
            'city': 'Somewhere',
            'zip': 'abc'
          }
        };
        final missingStreet = {
          'name': 'Jane',
          'address': {'city': 'Otherville', 'zip': '54321'}
        };

        expect(userWithAddressSchema.validate(validData).isOk, isTrue);
        expect(userWithAddressSchema.validate(invalidZip).isOk, isFalse);
        expect(userWithAddressSchema.validate(missingStreet).isOk, isFalse);
      });

      test('Nested list of objects', () {
        final itemSchema = Ack.object({
          'id': Ack.int.min(1), // Use min(1) for positive integers.
          'name': Ack.string.isNotEmpty(),
        });

        final orderSchema = Ack.object({
          'orderId': Ack.string.matches(
            // Basic UUID regex (adjust if specific version needed).
            r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
            example: 'f47ac10b-58cc-4372-a567-0e02b2c3d479',
          ),
          'items': Ack.list(itemSchema).minItems(1), // List of item objects.
        });

        final validOrder = {
          'orderId': 'f47ac10b-58cc-4372-a567-0e02b2c3d479',
          'items': [
            {'id': 1, 'name': 'Widget A'},
            {'id': 2, 'name': 'Widget B'},
          ]
        };
        final invalidItemId = {
          'orderId': 'f47ac10b-58cc-4372-a567-0e02b2c3d479',
          'items': [
            {'id': -1, 'name': 'Invalid Widget'} // Negative ID.
          ]
        };
        final emptyItemsList = {
          'orderId': 'f47ac10b-58cc-4372-a567-0e02b2c3d479',
          'items': [] // Must have at least one item.
        };

        expect(orderSchema.validate(validOrder).isOk, isTrue);
        expect(orderSchema.validate(invalidItemId).isOk, isFalse);
        expect(orderSchema.validate(emptyItemsList).isOk, isFalse);
      });
    });

    group('Combining Schemas', () {
      test('Nullable schema', () {
        final nullableString = Ack.string.nullable();

        expect(nullableString.validate('text').isOk, isTrue);
        expect(nullableString.validate(null).isOk, isTrue);
      });

      test('Union types (using custom logic or AnySchema)', () {
        // Ack doesn't have a direct `oneOf` or union type.
        // Option 1: Use custom validation logic outside Ack for specific checks.
        // Option 2: Use a less specific schema like `Ack.dynamic` if the exact
        //           type doesn't need strict enforcement by Ack itself.

        // Example of Option 1: Custom validation logic.
        bool validateStringOrInt(dynamic value) {
          final isString = Ack.string.validate(value).isOk;
          final isInt = Ack.int.validate(value).isOk;
          return isString || isInt;
        }

        // Example demonstrating loose typing (if custom logic isn't used)
        // final looseSchema = Ack.dynamic; // Could allow string, int, bool, etc.
        // expect(looseSchema.validate('hello').isOk, isTrue);
        // expect(looseSchema.validate(123).isOk, isTrue);

        // Testing the custom logic.
        expect(validateStringOrInt('hello'), isTrue);
        expect(validateStringOrInt(123), isTrue);
        expect(validateStringOrInt(true), isFalse); // Custom logic is stricter.
        expect(validateStringOrInt(12.3), isFalse);
      });

      // Note: Ack doesn't have a built-in allOf method, so we'll simulate it.
      test('Multiple constraints (simulating allOf)', () {
        // In a real application, you would chain constraints on a single schema.
        // Using contains() for partial matching.
        final passwordSchema = Ack.string
            .minLength(8)
            .contains(r'[A-Z]', example: 'Password') // Must contain uppercase.
            .contains(r'[0-9]', example: 'password1'); // Must contain digit.

        expect(passwordSchema.validate('Password1').isOk, isTrue);
        expect(passwordSchema.validate('password').isOk,
            isFalse); // No uppercase, no digit.
        expect(passwordSchema.validate('Pass').isOk,
            isFalse); // Too short, no digit.
      });
    });

    group('Making Schemas Nullable', () {
      test('Nullable schemas', () {
        final middleNameSchema = Ack.string.nullable();
        // Note: Ack doesn't have a built-in dateTime schema type.
        // Using matches() for full string validation.
        final optionalDateSchema = Ack.string
            .matches(r'\d{4}-\d{2}-\d{2}', example: '2023-01-01')
            .nullable();

        expect(middleNameSchema.validate(null).isOk, isTrue);
        expect(optionalDateSchema.validate(null).isOk, isTrue);
      });

      test('With default values', () {
        final statusSchema =
            Ack.string.isEnum(['active', 'inactive']).nullable();

        final result = statusSchema.validate(null);
        expect(result.isOk, isTrue);

        final status = result.getOrElse(() => 'active');
        expect(status, equals('active'));
      });
    });

    group('Using with JSON', () {
      test('Parse and validate JSON data', () {
        final userSchema = Ack.object({'name': Ack.string, 'age': Ack.int});

        final jsonData = jsonDecode('{"name": "John", "age": 30}');
        final result = userSchema.validate(jsonData);

        expect(result.isOk, isTrue);
      });
    });
  });
}

// Custom constraint for exclusive minimum
/// Validates if a number is strictly greater than a minimum value.
class ExclusiveMinConstraint<T extends num> extends Constraint<T>
    with Validator<T> {
  /// The exclusive minimum value.
  final T min;

  /// Creates a constraint that checks if a number is strictly greater than [min].
  const ExclusiveMinConstraint(this.min)
      : super(
          constraintKey: 'exclusive_min',
          description: 'Must be greater than $min',
        );

  @override
  bool isValid(T value) => value > min;

  @override
  String buildMessage(T value) => 'Value must be greater than $min.';
}

// Custom constraint for multiple of
/// Validates if a number is a multiple of a given divisor.
class MultipleOfConstraint<T extends num> extends Constraint<T>
    with Validator<T> {
  /// The number that the value must be a multiple of.
  final T divisor;

  /// Creates a constraint that checks if a number is a multiple of [divisor].
  const MultipleOfConstraint(this.divisor)
      : super(
          constraintKey: 'multiple_of',
          description: 'Must be a multiple of $divisor',
        );

  @override
  bool isValid(T value) {
    if (divisor is int) {
      return (value as int) % (divisor as int) == 0;
    } else {
      // For doubles, we need to handle floating point precision issues
      final remainder = value % divisor;
      final epsilon = 1e-10;
      return remainder < epsilon || (divisor - remainder) < epsilon;
    }
  }

  @override
  String buildMessage(T value) => 'Value must be a multiple of $divisor.';
}
