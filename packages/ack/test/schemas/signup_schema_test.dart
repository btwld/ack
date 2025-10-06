import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('Signup Schema with Password Confirmation', () {
    late AckSchema signupSchema;

    setUp(() {
      signupSchema =
          Ack.object({
            'email': Ack.string().email(),
            'password': Ack.string().minLength(8),
            'confirmPassword': Ack.string().minLength(8),
          }).refine(
            (data) => data['password'] == data['confirmPassword'],
            message: '❌ Passwords do not match!',
          );
    });

    group('Valid signup data', () {
      test('should succeed with matching passwords and valid email', () {
        final result = signupSchema.safeParse({
          'email': 'user@example.com',
          'password': 'securePassword123',
          'confirmPassword': 'securePassword123',
        });

        expect(result.isOk, isTrue);
        expect(result.getOrNull(), {
          'email': 'user@example.com',
          'password': 'securePassword123',
          'confirmPassword': 'securePassword123',
        });
      });

      test('should succeed with different valid email formats', () {
        final testCases = [
          'john.doe@company.com',
          'alice+test@subdomain.example.org',
          'bob123@email.co.uk',
          'test_user@example-domain.com',
        ];

        for (final email in testCases) {
          final result = signupSchema.safeParse({
            'email': email,
            'password': 'validPassword123',
            'confirmPassword': 'validPassword123',
          });

          expect(
            result.isOk,
            isTrue,
            reason: 'Should accept valid email: $email',
          );
        }
      });

      test('should succeed with exactly 8 character passwords', () {
        final result = signupSchema.safeParse({
          'email': 'test@example.com',
          'password': '12345678',
          'confirmPassword': '12345678',
        });

        expect(result.isOk, isTrue);
      });
    });

    group('Password mismatch', () {
      test(
        'should fail with emoji error message when passwords do not match',
        () {
          final result = signupSchema.safeParse({
            'email': 'user@example.com',
            'password': 'password123',
            'confirmPassword': 'differentPassword123',
          });

          expect(result.isFail, isTrue);
          expect(
            (result.getError() as SchemaValidationError).message,
            '❌ Passwords do not match!',
          );
        },
      );

      test('should fail even when both passwords meet length requirements', () {
        final result = signupSchema.safeParse({
          'email': 'valid@email.com',
          'password': 'longEnoughPassword1',
          'confirmPassword': 'longEnoughPassword2',
        });

        expect(result.isFail, isTrue);
        expect(
          (result.getError() as SchemaValidationError).message,
          contains('❌'),
        );
      });

      test('should fail with case-sensitive password mismatch', () {
        final result = signupSchema.safeParse({
          'email': 'test@example.com',
          'password': 'Password123',
          'confirmPassword': 'password123',
        });

        expect(result.isFail, isTrue);
        expect(
          (result.getError() as SchemaValidationError).message,
          '❌ Passwords do not match!',
        );
      });
    });

    group('Invalid email formats', () {
      test('should fail with invalid email formats', () {
        final invalidEmails = [
          'notanemail',
          '@example.com',
          'user@',
          'user space@example.com',
          'user@.com',
          'user@example',
          'user..name@example.com',
          'user@example..com',
        ];

        for (final email in invalidEmails) {
          final result = signupSchema.safeParse({
            'email': email,
            'password': 'validPassword123',
            'confirmPassword': 'validPassword123',
          });

          expect(
            result.isFail,
            isTrue,
            reason: 'Should reject invalid email: $email',
          );

          final error = result.getError();
          if (error is SchemaConstraintsError) {
            expect(
              error.constraints.any((c) => c.message.contains('email')),
              isTrue,
              reason: 'Should have email validation error for: $email',
            );
          }
        }
      });

      test(
        'should fail before checking password match if email is invalid',
        () {
          final result = signupSchema.safeParse({
            'email': 'invalid-email',
            'password': 'password123',
            'confirmPassword': 'differentPassword',
          });

          expect(result.isFail, isTrue);
          final error = result.getError();
          if (error is SchemaConstraintsError) {
            expect(
              error.constraints.any((c) => c.message.contains('email')),
              isTrue,
            );
          }
        },
      );
    });

    group('Password length validation', () {
      test('should fail when password is too short', () {
        final result = signupSchema.safeParse({
          'email': 'user@example.com',
          'password': '1234567',
          'confirmPassword': '1234567',
        });

        expect(result.isFail, isTrue);
        final error = result.getError();
        if (error is SchemaConstraintsError) {
          expect(
            error.constraints.any((c) => c.message.contains('Minimum 8')),
            isTrue,
          );
        }
      });

      test('should fail when confirmPassword is too short', () {
        final result = signupSchema.safeParse({
          'email': 'user@example.com',
          'password': 'validPassword123',
          'confirmPassword': '1234567',
        });

        expect(result.isFail, isTrue);
        final error = result.getError();
        if (error is SchemaConstraintsError) {
          expect(
            error.constraints.any((c) => c.message.contains('Minimum 8')),
            isTrue,
          );
        }
      });

      test('should validate base constraints before refinement', () {
        final result = signupSchema.safeParse({
          'email': 'user@example.com',
          'password': 'short',
          'confirmPassword': 'different',
        });

        expect(result.isFail, isTrue);
        final error = result.getError();

        // Object validation returns SchemaNestedError for field errors
        expect(error, isA<SchemaNestedError>());

        // Check nested errors for the password field constraint error
        final nestedError = error as SchemaNestedError;
        final passwordError = nestedError.errors.firstWhere(
          (e) => e.toString().contains('password'),
        );

        expect(passwordError, isA<SchemaConstraintsError>());
        final constraintsError = passwordError as SchemaConstraintsError;

        // Check that constraint error message contains minimum length info
        final constraintMessage = constraintsError.constraints.first.message;
        expect(
          constraintMessage.toLowerCase().contains('minimum'),
          isTrue,
          reason: 'Should contain minimum length constraint error',
        );

        // Should not contain the password mismatch message since constraint fails first
        expect(
          error.toString().contains('❌'),
          isFalse,
          reason: 'Should not contain password mismatch emoji',
        );
      });
    });

    group('Edge cases', () {
      test('should handle empty passwords', () {
        final result = signupSchema.safeParse({
          'email': 'user@example.com',
          'password': '',
          'confirmPassword': '',
        });

        expect(result.isFail, isTrue);
        final error = result.getError();
        if (error is SchemaConstraintsError) {
          expect(
            error.constraints.any((c) => c.message.contains('Minimum 8')),
            isTrue,
          );
        }
      });

      test('should handle missing fields', () {
        final result = signupSchema.safeParse({'email': 'user@example.com'});

        expect(result.isFail, isTrue);
        final error = result.getError();
        if (error is SchemaConstraintsError) {
          expect(
            error.constraints.any((c) => c.message.contains('required')),
            isTrue,
          );
        }
      });

      test('should handle null values', () {
        final result = signupSchema.safeParse({
          'email': 'user@example.com',
          'password': null,
          'confirmPassword': null,
        });

        expect(result.isFail, isTrue);
      });

      test('should handle special characters in passwords', () {
        final specialPassword = r'P@$$w0rd!#$%^&*()';
        final result = signupSchema.safeParse({
          'email': 'user@example.com',
          'password': specialPassword,
          'confirmPassword': specialPassword,
        });

        expect(result.isOk, isTrue);
      });

      test('should handle unicode characters in passwords', () {
        final unicodePassword = 'пароль123😊';
        final result = signupSchema.safeParse({
          'email': 'user@example.com',
          'password': unicodePassword,
          'confirmPassword': unicodePassword,
        });

        expect(result.isOk, isTrue);
      });
    });
  });
}
