import 'dart:convert';

import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('Best Practices Examples', () {
    group('Schema Reuse Pattern', () {
      test('should define reusable schemas', () {
        // Best practice: Define reusable schemas
        final emailSchema = Ack.string().email();
        final uuidSchema = Ack.string().uuid();
        final timestampSchema = Ack.string().datetime();

        final userSchema = Ack.object({
          'id': uuidSchema,
          'email': emailSchema,
          'createdAt': timestampSchema,
          'updatedAt': timestampSchema,
        });

        final postSchema = Ack.object({
          'id': uuidSchema,
          'authorId': uuidSchema,
          'title': Ack.string().minLength(1).maxLength(200),
          'createdAt': timestampSchema,
        });

        // Schemas are reusable
        final userData = {
          'id': '550e8400-e29b-41d4-a716-446655440000',
          'email': 'user@example.com',
          'createdAt': '2024-01-01T00:00:00Z',
          'updatedAt': '2024-01-01T00:00:00Z',
        };

        final userResult = userSchema.validate(userData);
        expect(userResult.isOk, isTrue);

        final postData = {
          'id': '550e8400-e29b-41d4-a716-446655440001',
          'authorId': '550e8400-e29b-41d4-a716-446655440000',
          'title': 'Test Post',
          'createdAt': '2024-01-01T00:00:00Z',
        };

        final postResult = postSchema.validate(postData);
        expect(postResult.isOk, isTrue);
      });
    });

    group('Error Handling Pattern', () {
      test('should use structured error handling', () {
        final schema = Ack.object({
          'name': Ack.string().minLength(3),
          'age': Ack.integer().min(18).max(100),
        });

        ValidationResult<Map<String, dynamic>> validateUser(dynamic data) {
          final result = schema.validate(data);
          if (result.isOk) {
            return ValidationResult.valid(result.getOrThrow()!);
          } else {
            final error = result.getError();
            return ValidationResult.invalid(error.message);
          }
        }

        // Valid case
        final validResult = validateUser({'name': 'John', 'age': 25});
        expect(validResult.isValid, isTrue);
        expect(validResult.value, isNotNull);

        // Invalid case
        final invalidResult = validateUser({'name': 'Jo', 'age': 150});
        expect(invalidResult.isValid, isFalse);
        expect(invalidResult.error, isNotNull);
      });
    });

    group('Type-Safe Parsing Pattern', () {
      test('should use type parameters for safety', () {
        T parseConfig<T>(String json, AckSchema schema) {
          final data = jsonDecode(json);
          return schema.parse(data) as T;
        }

        final configSchema = Ack.object({
          'apiUrl': Ack.string().url(),
          'timeout': Ack.integer().positive(),
          'retries': Ack.integer().min(0).max(5),
        });

        final config = parseConfig<Map<String, dynamic>>(
          '{"apiUrl": "https://api.example.com", "timeout": 5000, "retries": 3}',
          configSchema,
        );

        expect(config['apiUrl'], equals('https://api.example.com'));
        expect(config['timeout'], equals(5000));
        expect(config['retries'], equals(3));
      });
    });

    group('Gradual Validation Pattern', () {
      test('should support progressive validation', () {
        // Best practice: Progressive validation
        final basicSchema = Ack.object({
          'email': Ack.string().email(),
        });

        final profileSchema = Ack.object({
          'email': Ack.string().email(),
          'name': Ack.string().minLength(1),
          'bio': Ack.string().maxLength(500).nullable(),
        });

        final completeSchema = Ack.object({
          'email': Ack.string().email(),
          'name': Ack.string().minLength(1),
          'bio': Ack.string().maxLength(500).nullable(),
          'verified': Ack.boolean(),
          'role': Ack.enumString(['user', 'admin']),
        });

        Map<String, dynamic>? validateSignup(dynamic data) {
          return basicSchema.parse(data);
        }

        Map<String, dynamic>? validateProfile(dynamic data) {
          return profileSchema.parse(data);
        }

        Map<String, dynamic>? validateComplete(dynamic data) {
          return completeSchema.parse(data);
        }

        // Start with basic
        final step1 = validateSignup({
          'email': 'user@example.com',
        });
        expect(step1!['email'], equals('user@example.com'));

        // Add profile
        final step2 = validateProfile({
          'email': 'user@example.com',
          'name': 'John Doe',
        });
        expect(step2!['name'], equals('John Doe'));

        // Complete validation
        final step3 = validateComplete({
          'email': 'user@example.com',
          'name': 'John Doe',
          'verified': true,
          'role': 'user',
        });
        expect(step3!['verified'], equals(true));
      });
    });

    group('Composition Pattern', () {
      test('should compose complex schemas from simple ones', () {
        // Base schemas
        final addressSchema = Ack.object({
          'street': Ack.string(),
          'city': Ack.string(),
          'country': Ack.string(),
          'postalCode': Ack.string().matches(r'^\d{5}(-\d{4})?$'),
        });

        final contactSchema = Ack.object({
          'email': Ack.string().email(),
          'phone': Ack.string().nullable(),
        });

        // Composed schema
        final customerSchema = Ack.object({
          'id': Ack.string().uuid(),
          'name': Ack.string(),
          'contact': contactSchema,
          'billingAddress': addressSchema,
          'shippingAddress': addressSchema.nullable(),
        });

        final customerData = {
          'id': '550e8400-e29b-41d4-a716-446655440000',
          'name': 'John Doe',
          'contact': {
            'email': 'john@example.com',
            'phone': '+1-555-0123',
          },
          'billingAddress': {
            'street': '123 Main St',
            'city': 'Anytown',
            'country': 'USA',
            'postalCode': '12345',
          },
        };

        final result = customerSchema.validate(customerData);
        expect(result.isOk, isTrue);
      });
    });

    group('Validation with Fallbacks', () {
      test('should provide fallback values on validation failure', () {
        T parseWithFallback<T>(
          dynamic input,
          AckSchema schema,
          T fallback,
        ) {
          final result = schema.validate(input);
          return result.isOk ? result.getOrThrow() as T : fallback;
        }

        final ageSchema = Ack.integer().min(0).max(150);

        expect(parseWithFallback(25, ageSchema, 0), equals(25));
        expect(parseWithFallback(-5, ageSchema, 0), equals(0));
        expect(parseWithFallback('invalid', ageSchema, 0), equals(0));
      });
    });

    group('Schema Documentation Pattern', () {
      test('should document schemas with descriptions', () {
        final userSchema = Ack.object({
          'id': Ack.string().uuid().withDescription('Unique user identifier'),
          'email': Ack.string().email().withDescription('User email address'),
          'age': Ack.integer()
              .min(13)
              .max(120)
              .withDescription('User age in years'),
          'preferences': Ack.object({
            'theme': Ack.enumString(['light', 'dark'])
                .withDescription('UI theme preference'),
            'notifications':
                Ack.boolean().withDescription('Email notifications enabled'),
          }).withDescription('User preferences'),
        }).withDescription('User profile data');

        final userData = {
          'id': '550e8400-e29b-41d4-a716-446655440000',
          'email': 'user@example.com',
          'age': 25,
          'preferences': {
            'theme': 'dark',
            'notifications': true,
          },
        };

        final result = userSchema.validate(userData);
        expect(result.isOk, isTrue);

        // Verify descriptions are set
        expect(userSchema.description, equals('User profile data'));
      });
    });

    group('Performance Best Practices', () {
      test('should reuse schema instances for performance', () {
        // Good: Reuse schema instances
        final emailSchema = Ack.string().email();
        final userSchema = Ack.object({
          'primaryEmail': emailSchema,
          'secondaryEmail': emailSchema.nullable(),
        });

        // Validate multiple times with same schema
        final users = [
          {'primaryEmail': 'user1@example.com'},
          {
            'primaryEmail': 'user2@example.com',
            'secondaryEmail': 'alt2@example.com'
          },
          {'primaryEmail': 'user3@example.com'},
        ];

        for (final userData in users) {
          final result = userSchema.validate(userData);
          expect(result.isOk, isTrue);
        }
      });
    });
  });
}

class ValidationResult<T> {
  final bool isValid;
  final T? value;
  final String? error;

  ValidationResult.valid(this.value)
      : isValid = true,
        error = null;
  ValidationResult.invalid(this.error)
      : isValid = false,
        value = null;
}
