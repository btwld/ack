import 'package:ack/ack.dart';
import 'package:test/test.dart';

/// Tests for code snippets in docs/core-concepts/validation.mdx.
void main() {
  group('Docs /core-concepts/validation.mdx', () {
    test('nullable allows null values', () {
      final optionalName = Ack.string().nullable();
      final optionalAge = Ack.integer().nullable();

      expect(optionalName.safeParse(null).isOk, isTrue);
      expect(optionalName.safeParse('Marie').isOk, isTrue);
      expect(optionalAge.safeParse(null).isOk, isTrue);
      expect(optionalAge.safeParse(30).isOk, isTrue);
    });

    group('String constraints', () {
      test('length and emptiness', () {
        final minSchema = Ack.string().minLength(5);
        expect(minSchema.safeParse('hello').isOk, isTrue);
        expect(minSchema.safeParse('hi').isFail, isTrue);

        final maxSchema = Ack.string().maxLength(3);
        expect(maxSchema.safeParse('abc').isOk, isTrue);
        expect(maxSchema.safeParse('abcd').isFail, isTrue);

        final exactSchema = Ack.string().minLength(10).maxLength(10);
        expect(exactSchema.safeParse('0123456789').isOk, isTrue);
        expect(exactSchema.safeParse('short').isFail, isTrue);

        final notEmptySchema = Ack.string().notEmpty();
        expect(notEmptySchema.safeParse('a').isOk, isTrue);
        expect(notEmptySchema.safeParse('').isFail, isTrue);
      });

      test('patterns and contains', () {
        final alnumSchema = Ack.string().matches(r'^[a-zA-Z0-9]+$');
        expect(alnumSchema.safeParse('User42').isOk, isTrue);
        expect(alnumSchema.safeParse('User 42').isFail, isTrue);

        final uuidSchema = Ack.string().matches(
          r'^[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}$',
        );
        expect(
          uuidSchema.safeParse('550e8400-e29b-41d4-a716-446655440000').isOk,
          isTrue,
        );

        final uppercaseRequirement = Ack.string().contains(r'[A-Z]');
        expect(uppercaseRequirement.safeParse('Password').isOk, isTrue);
        expect(uppercaseRequirement.safeParse('password').isFail, isTrue);

        final digitRequirement = Ack.string().contains(r'[0-9]');
        expect(digitRequirement.safeParse('abc1').isOk, isTrue);
        expect(digitRequirement.safeParse('abcd').isFail, isTrue);
      });

      test('format helpers', () {
        expect(Ack.string().email().safeParse('user@example.com').isOk, isTrue);
        expect(Ack.string().email().safeParse('invalid').isFail, isTrue);

        expect(Ack.string().date().safeParse('2024-01-01').isOk, isTrue);
        expect(Ack.string().date().safeParse('01/01/2024').isFail, isTrue);

        expect(
          Ack.string().datetime().safeParse('2024-01-01T12:00:00Z').isOk,
          isTrue,
        );
        expect(Ack.string().time().safeParse('12:30:45').isOk, isTrue);
        expect(
          Ack.string().uri().safeParse('https://example.com').isOk,
          isTrue,
        );
        expect(
          Ack.string()
              .uuid()
              .safeParse('550e8400-e29b-41d4-a716-446655440000')
              .isOk,
          isTrue,
        );
        expect(Ack.string().ipv4().safeParse('192.168.0.1').isOk, isTrue);
        expect(
          Ack.string()
              .ipv6()
              .safeParse('2001:0db8:85a3:0000:0000:8a2e:0370:7334')
              .isOk,
          isTrue,
        );

        final statusSchema = Ack.enumString(['active', 'inactive', 'pending']);
        expect(statusSchema.safeParse('active').isOk, isTrue);
        expect(statusSchema.safeParse('invalid').isFail, isTrue);
      });
    });

    group('Number constraints', () {
      test('min, max, multipleOf, positivity', () {
        expect(Ack.integer().min(0).safeParse(-1).isFail, isTrue);
        expect(Ack.double().min(0.0).safeParse(0.5).isOk, isTrue);

        expect(Ack.integer().max(100).safeParse(120).isFail, isTrue);
        expect(Ack.double().max(100.0).safeParse(80.0).isOk, isTrue);

        expect(Ack.integer().multipleOf(5).safeParse(15).isOk, isTrue);
        expect(Ack.integer().multipleOf(5).safeParse(16).isFail, isTrue);

        expect(Ack.double().multipleOf(0.5).safeParse(12.5).isOk, isTrue);

        expect(Ack.integer().positive().safeParse(1).isOk, isTrue);
        expect(Ack.integer().positive().safeParse(0).isFail, isTrue);

        expect(Ack.double().negative().safeParse(-0.5).isOk, isTrue);
        expect(Ack.double().negative().safeParse(0.5).isFail, isTrue);
      });
    });

    group('List constraints', () {
      test('length and uniqueness', () {
        expect(
          Ack.list(Ack.string()).minLength(1).safeParse([]).isFail,
          isTrue,
        );
        expect(
          Ack.list(Ack.string()).minLength(1).safeParse(['item']).isOk,
          isTrue,
        );

        expect(
          Ack.list(Ack.integer()).maxLength(2).safeParse([1, 2, 3]).isFail,
          isTrue,
        );
        expect(
          Ack.list(Ack.boolean()).length(2).safeParse([true, false]).isOk,
          isTrue,
        );
        expect(
          Ack.list(Ack.object({})).notEmpty().safeParse([]).isFail,
          isTrue,
        );

        expect(
          Ack.list(Ack.string()).unique().safeParse(['a', 'b']).isOk,
          isTrue,
        );
        expect(
          Ack.list(Ack.string()).unique().safeParse(['dup', 'dup']).isFail,
          isTrue,
        );
      });
    });

    group('Combining constraints', () {
      test('string constraint chaining', () {
        final usernameSchema = Ack.string()
            .minLength(3)
            .maxLength(20)
            .matches(r'[a-z0-9_]+')
            .notEmpty();

        expect(usernameSchema.safeParse('user_name').isOk, isTrue);
        expect(usernameSchema.safeParse('UPPER').isFail, isTrue);
      });

      test('numeric constraint chaining', () {
        final quantitySchema = Ack.integer().min(1).max(100).multipleOf(1);

        expect(quantitySchema.safeParse(50).isOk, isTrue);
        expect(quantitySchema.safeParse(0).isFail, isTrue);
        expect(quantitySchema.safeParse(101).isFail, isTrue);
      });
    });
  });
}
