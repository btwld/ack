import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('Advanced Features Documentation Examples', () {
    group('Optional vs Nullable Patterns', () {
      test('should demonstrate nullable field behavior', () {
        final userSchema = Ack.object({
          'name': Ack.string(),
          'middleName': Ack.string().nullable(), // Must be present, can be null
        });

        // Valid - middleName is present with null value
        final validData1 = {'name': 'John', 'middleName': null};
        expect(userSchema.validate(validData1).isOk, isTrue);

        // Valid - middleName is present with string value
        final validData2 = {'name': 'John', 'middleName': 'Robert'};
        expect(userSchema.validate(validData2).isOk, isTrue);

        // Invalid - middleName is missing entirely
        final invalidData = {'name': 'John'};
        expect(userSchema.validate(invalidData).isOk, isFalse);
      });

      test('should demonstrate optional field behavior', () {
        final userSchema = Ack.object({
          'name': Ack.string(),
          'age': Ack.integer().min(0).optional(), // Can be missing entirely
        });

        // Valid - age field is omitted
        final validData1 = {'name': 'John'};
        expect(userSchema.validate(validData1).isOk, isTrue);

        // Valid - age field is present with value
        final validData2 = {'name': 'John', 'age': 30};
        expect(userSchema.validate(validData2).isOk, isTrue);

        // Invalid - age field cannot be null (use .optional().nullable() for that)
        final invalidData = {'name': 'John', 'age': null};
        expect(userSchema.validate(invalidData).isOk, isFalse);
      });

      test('should demonstrate optional and nullable combined', () {
        final userSchema = Ack.object({
          'name': Ack.string(),
          'bio': Ack.string().optional().nullable(), // Can be missing OR null
        });

        // All of these are valid:
        final valid1 = {'name': 'John'}; // bio omitted
        expect(userSchema.validate(valid1).isOk, isTrue);

        final valid2 = {'name': 'John', 'bio': null}; // bio is null
        expect(userSchema.validate(valid2).isOk, isTrue);

        final valid3 = {
          'name': 'John',
          'bio': 'Software developer'
        }; // bio has value
        expect(userSchema.validate(valid3).isOk, isTrue);
      });
    });

    group('Advanced Refinements', () {
      test('should support multiple chained refinements', () {
        final strongPasswordSchema = Ack.string()
            .minLength(8)
            .refine(
              (password) => password.contains(RegExp(r'[A-Z]')),
              message: 'Password must contain at least one uppercase letter',
            )
            .refine(
              (password) => password.contains(RegExp(r'[0-9]')),
              message: 'Password must contain at least one number',
            )
            .refine(
              (password) =>
                  password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
              message: 'Password must contain at least one special character',
            );

        expect(strongPasswordSchema.validate('Password123!').isOk, isTrue);
        expect(strongPasswordSchema.validate('password123!').isOk,
            isFalse); // No uppercase
        expect(strongPasswordSchema.validate('Password!').isOk,
            isFalse); // No number
        expect(strongPasswordSchema.validate('Password123').isOk,
            isFalse); // No special char
      });

      test('should support business logic validation', () {
        final orderSchema = Ack.object({
          'items': Ack.list(Ack.object({
            'price': Ack.double().positive(),
            'quantity': Ack.integer().positive(),
          })),
          'discount': Ack.double().min(0).max(1),
          'total': Ack.double().positive(),
        }).refine(
          (order) {
            final items = order['items'] as List;
            final discount = order['discount'] as double;
            final total = order['total'] as double;

            final subtotal = items.fold<double>(0, (sum, item) {
              final itemMap = item as Map<String, Object?>;
              final price = itemMap['price'] as double;
              final quantity = itemMap['quantity'] as int;
              return sum + (price * quantity);
            });

            final expectedTotal = subtotal * (1 - discount);
            return (expectedTotal - total).abs() < 0.01; // Allow for rounding
          },
          message: 'Total must match calculated amount after discount',
        );

        final validOrder = {
          'items': [
            {'price': 10.0, 'quantity': 2}, // 20.0
            {'price': 5.0, 'quantity': 1}, // 5.0
          ], // subtotal: 25.0
          'discount': 0.1, // 10% discount
          'total': 22.5, // 25.0 * 0.9 = 22.5
        };

        expect(orderSchema.validate(validOrder).isOk, isTrue);

        final invalidOrder = {
          'items': [
            {'price': 10.0, 'quantity': 2},
          ],
          'discount': 0.1,
          'total': 25.0, // Should be 18.0 (20.0 * 0.9)
        };

        expect(orderSchema.validate(invalidOrder).isOk, isFalse);
      });
    });

    group('Advanced Transformations', () {
      test('should support type transformation', () {
        final dateSchema = Ack.string()
            .matches(r'^\d{4}-\d{2}-\d{2}$')
            .transform<DateTime>((dateStr) {
          return DateTime.parse(dateStr!);
        });

        final result = dateSchema.validate('2024-01-15');
        expect(result.isOk, isTrue);
        final transformedDate = result.getOrThrow();
        expect(transformedDate, isA<DateTime>());
        expect(transformedDate.year, equals(2024));
        expect(transformedDate.month, equals(1));
        expect(transformedDate.day, equals(15));
      });

      test('should support data normalization', () {
        final phoneSchema =
            Ack.string().matches(r'^[\d\s\-\(\)\+]+$').transform((phone) {
          // Remove all non-digit characters except +
          return phone!.replaceAll(RegExp(r'[^\d\+]'), '');
        });

        final result = phoneSchema.validate('+1 (555) 123-4567');
        expect(result.isOk, isTrue);
        expect(result.getOrThrow(), equals('+15551234567'));
      });

      test('should support complex object transformation', () {
        final apiResponseSchema = Ack.object({
          'user_id': Ack.integer(),
          'first_name': Ack.string(),
          'last_name': Ack.string(),
          'email_address': Ack.string().email(),
          'created_at': Ack.string().datetime(),
        }).transform<Map<String, Object?>>((apiData) {
          // Transform API response to internal format
          return {
            'id': apiData!['user_id'],
            'fullName': '${apiData['first_name']} ${apiData['last_name']}',
            'email': apiData['email_address'],
            'createdAt': DateTime.parse(apiData['created_at'] as String),
            'isActive': true, // Default value
          };
        });

        final apiData = {
          'user_id': 123,
          'first_name': 'John',
          'last_name': 'Doe',
          'email_address': 'john@example.com',
          'created_at': '2024-01-15T10:30:00Z',
        };

        final result = apiResponseSchema.validate(apiData);
        expect(result.isOk, isTrue);

        final transformed = result.getOrThrow();
        expect(transformed['id'], equals(123));
        expect(transformed['fullName'], equals('John Doe'));
        expect(transformed['email'], equals('john@example.com'));
        expect(transformed['createdAt'], isA<DateTime>());
        expect(transformed['isActive'], equals(true));
      });
    });

    group('Schema Composition Patterns', () {
      test('should support schema extension', () {
        final baseUserSchema = Ack.object({
          'id': Ack.string().uuid(),
          'name': Ack.string(),
          'email': Ack.string().email(),
        });

        // Extend with additional properties
        final adminUserSchema = baseUserSchema.extend({
          'role': Ack.literal('admin'),
          'permissions': Ack.list(Ack.string()),
          'lastLogin': Ack.string().datetime().optional(),
        });

        final adminData = {
          'id': '550e8400-e29b-41d4-a716-446655440000',
          'name': 'Admin User',
          'email': 'admin@example.com',
          'role': 'admin',
          'permissions': ['read', 'write', 'delete'],
          'lastLogin': '2024-01-15T10:30:00Z',
        };

        expect(adminUserSchema.validate(adminData).isOk, isTrue);
      });

      test('should support property picking', () {
        final fullUserSchema = Ack.object({
          'id': Ack.string().uuid(),
          'name': Ack.string(),
          'email': Ack.string().email(),
          'password': Ack.string().minLength(8),
          'createdAt': Ack.string().datetime(),
          'updatedAt': Ack.string().datetime(),
        });

        // Pick only specific fields for public API
        final publicUserSchema = fullUserSchema.pick(['id', 'name', 'email']);

        final publicData = {
          'id': '550e8400-e29b-41d4-a716-446655440000',
          'name': 'John Doe',
          'email': 'john@example.com',
        };

        expect(publicUserSchema.validate(publicData).isOk, isTrue);

        // Should fail if password is included
        final dataWithPassword = {
          ...publicData,
          'password': 'secret123',
        };
        expect(publicUserSchema.validate(dataWithPassword).isOk, isFalse);
      });

      test('should support property omission', () {
        final fullUserSchema = Ack.object({
          'id': Ack.string().uuid(),
          'name': Ack.string(),
          'email': Ack.string().email(),
          'password': Ack.string().minLength(8),
        });

        // Omit sensitive fields
        final safeUserSchema = fullUserSchema.omit(['password']);

        final safeData = {
          'id': '550e8400-e29b-41d4-a716-446655440000',
          'name': 'John Doe',
          'email': 'john@example.com',
        };

        expect(safeUserSchema.validate(safeData).isOk, isTrue);

        // Should fail if password is included
        final dataWithPassword = {
          ...safeData,
          'password': 'secret123',
        };
        expect(safeUserSchema.validate(dataWithPassword).isOk, isFalse);
      });

      test('should support partial schemas', () {
        final userSchema = Ack.object({
          'name': Ack.string(),
          'email': Ack.string().email(),
          'age': Ack.integer().min(0),
        });

        // All fields become optional
        final partialUserSchema = userSchema.partial();

        // All these should be valid:
        expect(partialUserSchema.validate({}).isOk, isTrue); // Empty object
        expect(partialUserSchema.validate({'name': 'John'}).isOk,
            isTrue); // Only name
        expect(
            partialUserSchema
                .validate({'email': 'john@example.com', 'age': 30}).isOk,
            isTrue); // Subset
      });

      test('should support strict vs passthrough modes', () {
        final baseSchema = Ack.object({
          'id': Ack.string(),
          'name': Ack.string(),
        });

        // Strict: reject additional properties
        final strictSchema = baseSchema.strict();
        final dataWithExtra = {'id': '1', 'name': 'Test', 'extra': 'value'};
        expect(strictSchema.validate(dataWithExtra).isOk, isFalse);

        // Passthrough: allow additional properties (default behavior)
        final passthroughSchema = baseSchema.passthrough();
        expect(passthroughSchema.validate(dataWithExtra).isOk, isTrue);
      });
    });
  });
}
