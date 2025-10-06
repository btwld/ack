import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('StringSchemaExtensions', () {
    group('length', () {
      test('minLength should pass if string is long enough', () {
        final schema = StringSchema().minLength(5);
        final result = schema.safeParse('hello');
        expect(result.isOk, isTrue);
      });

      test('minLength should fail if string is too short', () {
        final schema = StringSchema().minLength(5);
        final result = schema.safeParse('hi');
        expect(result.isOk, isFalse);
        expect(
          (result.getError() as SchemaConstraintsError)
              .constraints
              .first
              .message,
          'Too short. Minimum 5 characters, got 2.',
        );
      });

      test('maxLength should pass if string is short enough', () {
        final schema = StringSchema().maxLength(5);
        final result = schema.safeParse('hello');
        expect(result.isOk, isTrue);
      });

      test('maxLength should fail if string is too long', () {
        final schema = StringSchema().maxLength(3);
        final result = schema.safeParse('hello');
        expect(result.isOk, isFalse);
        expect(
          (result.getError() as SchemaConstraintsError)
              .constraints
              .first
              .message,
          'Too long. Maximum 3 characters, got 5.',
        );
      });

      test('length should pass if string is exact length', () {
        final schema = StringSchema().length(5);
        final result = schema.safeParse('hello');
        expect(result.isOk, isTrue);
      });

      test('length should fail if string is not exact length', () {
        final schema = StringSchema().length(5);
        final result = schema.safeParse('hell');
        expect(result.isOk, isFalse);
        expect(
          (result.getError() as SchemaConstraintsError)
              .constraints
              .first
              .message,
          'Must be exactly 5 characters, got 4.',
        );
      });

      test('should chain length constraints', () {
        final schema = StringSchema().minLength(3).maxLength(5);
        expect(schema.safeParse('hi').isOk, isFalse);
        expect(schema.safeParse('hello').isOk, isTrue);
        expect(schema.safeParse('hellos').isOk, isFalse);
      });
    });

    group('format', () {
      test('email should pass for valid email', () {
        final schema = StringSchema().email();
        final result = schema.safeParse('test@example.com');
        expect(result.isOk, isTrue);
      });

      test('email should fail for invalid email', () {
        final schema = StringSchema().email();
        final result = schema.safeParse('not-an-email');
        expect(result.isOk, isFalse);
        expect(
          (result.getError() as SchemaConstraintsError)
              .constraints
              .first
              .message,
          'Invalid email format. Expected format like user@example.com, got "not-an-email".',
        );
      });

      test('url should pass for valid url', () {
        final schema = StringSchema().url();
        final result = schema.safeParse('https://example.com');
        expect(result.isOk, isTrue);
      });

      test('url should fail for invalid url', () {
        final schema = StringSchema().url();
        final result = schema.safeParse('not-a-url');
        expect(result.isOk, isFalse);
        expect(
          (result.getError() as SchemaConstraintsError)
              .constraints
              .first
              .message,
          'Invalid URI format, got "not-a-url".',
        );
      });

      test('uuid should pass for valid uuid', () {
        final schema = StringSchema().uuid();
        final result = schema.safeParse('123e4567-e89b-12d3-a456-426614174000');
        expect(result.isOk, isTrue);
      });

      test('uuid should fail for invalid uuid', () {
        final schema = StringSchema().uuid();
        final result = schema.safeParse('not-a-uuid');
        expect(result.isOk, isFalse);
        expect(
          (result.getError() as SchemaConstraintsError)
              .constraints
              .first
              .message,
          'Invalid UUID format, got "not-a-uuid".',
        );
      });
    });

    test('should chain multiple constraints', () {
      final schema = StringSchema().minLength(10).email();
      final result = schema.safeParse('a@b.com');
      expect(result.isOk, isFalse);
      expect(
        (result.getError() as SchemaConstraintsError).constraints.first.message,
        'Too short. Minimum 10 characters, got 7.',
      );

      final result2 = schema.safeParse('this-is-not-an-email');
      expect(result2.isOk, isFalse);
      expect(
        (result2.getError() as SchemaConstraintsError)
            .constraints
            .first
            .message,
        'Invalid email format. Expected format like user@example.com, got "this-is-not-an-email".',
      );

      final result3 = schema.safeParse('long.email@example.com');
      expect(result3.isOk, isTrue);
    });

    group('literal', () {
      test('should pass for exact string match', () {
        final schema = Ack.string().literal('hello');

        expect(schema.safeParse('hello').isOk, isTrue);
        expect(schema.safeParse('hello').getOrNull(), equals('hello'));
      });

      test('should fail for different string', () {
        final schema = Ack.string().literal('hello');

        final result = schema.safeParse('world');
        expect(result.isOk, isFalse);
        final error = result.getError() as SchemaConstraintsError;
        expect(
          error.constraints.first.message,
          equals('Must be exactly "hello", but got "world".'),
        );
      });

      test('should work with empty string', () {
        final schema = Ack.string().literal('');

        expect(schema.safeParse('').isOk, isTrue);
        expect(schema.safeParse('not empty').isOk, isFalse);
      });

      test('should work chained with other constraints', () {
        final schema = Ack.string().minLength(3).literal('hello');

        expect(schema.safeParse('hello').isOk, isTrue);
        expect(schema.safeParse('hi').isOk, isFalse); // too short
        expect(schema.safeParse('world').isOk, isFalse); // wrong literal
      });

      test('should work with Ack.literal() factory method (like Zod)', () {
        final schema = Ack.literal('hello');

        expect(schema.safeParse('hello').isOk, isTrue);
        expect(schema.safeParse('hello').getOrNull(), equals('hello'));
        expect(schema.safeParse('world').isOk, isFalse);
      });
    });

    group('matches (regex validation)', () {
      test('should throw ArgumentError for invalid regex pattern', () {
        expect(
          () => StringSchema().matches(r'[unclosed'),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('Invalid regular expression pattern'),
            ),
          ),
        );
      });

      test('should throw ArgumentError for invalid regex with context', () {
        expect(
          () => StringSchema().matches(r'(?P<invalid>test)'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should accept valid regex patterns', () {
        final schema = StringSchema().matches(r'^\d{3}-\d{3}-\d{4}$');
        expect(schema.safeParse('555-123-4567').isOk, isTrue);
        expect(schema.safeParse('invalid').isOk, isFalse);
      });
    });
  });
}
