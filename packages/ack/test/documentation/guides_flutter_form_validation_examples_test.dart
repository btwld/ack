import 'package:ack/ack.dart';
import 'package:test/test.dart';

/// Tests for the schema logic shown in docs/guides/flutter-form-validation.mdx.
void main() {
  group('Docs /guides/flutter-form-validation.mdx', () {
    final usernameSchema = Ack.string()
        .minLength(3)
        .maxLength(20)
        .matches(r'^[a-zA-Z0-9_]+$')
        .notEmpty();

    final emailSchema = Ack.string().email().notEmpty();

    final passwordSchema = Ack.string()
        .minLength(8)
        .matches(r'.*[A-Z].*')
        .matches(r'.*[a-z].*')
        .matches(r'.*[0-9].*')
        .notEmpty();

    String? runValidator(AckSchema<String> schema, String? value) {
      final result = schema.safeParse(value);
      return result.isFail ? result.getError().toString() : null;
    }

    test('username schema enforces pattern and length', () {
      expect(runValidator(usernameSchema, 'user_name'), isNull);
      expect(runValidator(usernameSchema, 'ab'), isNotNull);
      expect(runValidator(usernameSchema, 'user-name'), isNotNull);
    });

    test('email schema validates address format', () {
      expect(runValidator(emailSchema, 'user@example.com'), isNull);
      expect(runValidator(emailSchema, 'bad-email'), isNotNull);
    });

    test('password schema enforces complexity', () {
      expect(runValidator(passwordSchema, 'Password123'), isNull);
      expect(runValidator(passwordSchema, 'password123'), isNotNull);
      expect(runValidator(passwordSchema, 'PASSWORD123'), isNotNull);
      expect(runValidator(passwordSchema, 'Password'), isNotNull);
    });
  });
}
