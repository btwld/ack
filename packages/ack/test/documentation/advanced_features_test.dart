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
        expect(userSchema.safeParse(validData1).isOk, isTrue);

        // Valid - middleName is present with string value
        final validData2 = {'name': 'John', 'middleName': 'Robert'};
        expect(userSchema.safeParse(validData2).isOk, isTrue);

        // Invalid - middleName is missing entirely
        final invalidData = {'name': 'John'};
        expect(userSchema.safeParse(invalidData).isOk, isFalse);
      });

      test('should demonstrate optional field behavior', () {
        final userSchema = Ack.object({
          'name': Ack.string(),
          'age': Ack.integer().min(0).optional(), // Can be missing entirely
        });

        // Valid - age field is omitted
        final validData1 = {'name': 'John'};
        expect(userSchema.safeParse(validData1).isOk, isTrue);

        // Valid - age field is present with value
        final validData2 = {'name': 'John', 'age': 30};
        expect(userSchema.safeParse(validData2).isOk, isTrue);

        // Invalid - age field cannot be null (optional ≠ nullable)
        final invalidData = {'name': 'John', 'age': null};
        expect(userSchema.safeParse(invalidData).isFail, isTrue);
      });

      test('should demonstrate optional and nullable combined', () {
        final userSchema = Ack.object({
          'name': Ack.string(),
          'bio': Ack.string().optional().nullable(), // Can be missing OR null
        });

        // All of these are valid:
        final valid1 = {'name': 'John'}; // bio omitted
        expect(userSchema.safeParse(valid1).isOk, isTrue);

        final valid2 = {'name': 'John', 'bio': null}; // bio is null
        expect(userSchema.safeParse(valid2).isOk, isTrue);

        final valid3 = {
          'name': 'John',
          'bio': 'Software developer',
        }; // bio has value
        expect(userSchema.safeParse(valid3).isOk, isTrue);
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

        expect(strongPasswordSchema.safeParse('Password123!').isOk, isTrue);
        expect(
          strongPasswordSchema.safeParse('password123!').isOk,
          isFalse,
        ); // No uppercase
        expect(
          strongPasswordSchema.safeParse('Password!').isOk,
          isFalse,
        ); // No number
        expect(
          strongPasswordSchema.safeParse('Password123').isOk,
          isFalse,
        ); // No special char
      });
    });

    group('Advanced Transformations', () {
      test('should support type transformation', () {
        final dateSchema = Ack.string()
            .matches(r'^\d{4}-\d{2}-\d{2}$')
            .transform<DateTime>((dateStr) {
              return DateTime.parse(dateStr!);
            });

        final result = dateSchema.safeParse('2024-01-15');
        expect(result.isOk, isTrue);
        final transformedDate = result.getOrThrow() as DateTime;
        expect(transformedDate, isA<DateTime>());
        expect(transformedDate.year, equals(2024));
        expect(transformedDate.month, equals(1));
        expect(transformedDate.day, equals(15));
      });

      test('should support data normalization', () {
        final phoneSchema = Ack.string()
            .matches(r'^[\d\s\-\(\)\+]+$')
            .transform((phone) {
              // Remove all non-digit characters except +
              return phone!.replaceAll(RegExp(r'[^\d\+]'), '');
            });

        final result = phoneSchema.safeParse('+1 (555) 123-4567');
        expect(result.isOk, isTrue);
        expect(result.getOrThrow(), equals('+15551234567'));
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

        expect(adminUserSchema.safeParse(adminData).isOk, isTrue);
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

        expect(publicUserSchema.safeParse(publicData).isOk, isTrue);

        // Should fail if password is included
        final dataWithPassword = {...publicData, 'password': 'secret123'};
        expect(publicUserSchema.safeParse(dataWithPassword).isOk, isFalse);
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

        expect(safeUserSchema.safeParse(safeData).isOk, isTrue);

        // Should fail if password is included
        final dataWithPassword = {...safeData, 'password': 'secret123'};
        expect(safeUserSchema.safeParse(dataWithPassword).isOk, isFalse);
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
        expect(
          partialUserSchema.safeParse(<String, Object?>{}).isOk,
          isTrue,
        ); // Empty object
        expect(
          partialUserSchema.safeParse({'name': 'John'}).isOk,
          isTrue,
        ); // Only name
        expect(
          partialUserSchema.safeParse({
            'email': 'john@example.com',
            'age': 30,
          }).isOk,
          isTrue,
        ); // Subset
      });

      test('should support strict vs passthrough modes', () {
        final baseSchema = Ack.object({
          'id': Ack.string(),
          'name': Ack.string(),
        });

        // Strict: reject additional properties
        final strictSchema = baseSchema.strict();
        final dataWithExtra = {'id': '1', 'name': 'Test', 'extra': 'value'};
        expect(strictSchema.safeParse(dataWithExtra).isOk, isFalse);

        // Passthrough: allow additional properties (default behavior)
        final passthroughSchema = baseSchema.passthrough();
        expect(passthroughSchema.safeParse(dataWithExtra).isOk, isTrue);
      });
    });
  });
}
