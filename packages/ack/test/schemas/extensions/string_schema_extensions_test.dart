import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('StringSchemaExtensions', () {
    group('length', () {
      test('minLength should pass if string is long enough', () {
        final schema = StringSchema().minLength(5);
        final result = schema.validate('hello');
        expect(result.isOk, isTrue);
      });

      test('minLength should fail if string is too short', () {
        final schema = StringSchema().minLength(5);
        final result = schema.validate('hi');
        expect(result.isOk, isFalse);
        expect(
            (result.getError() as SchemaConstraintsError)
                .constraints
                .first
                .message,
            'Value must be at least 5 characters long, but was 2.');
      });

      test('maxLength should pass if string is short enough', () {
        final schema = StringSchema().maxLength(5);
        final result = schema.validate('hello');
        expect(result.isOk, isTrue);
      });

      test('maxLength should fail if string is too long', () {
        final schema = StringSchema().maxLength(3);
        final result = schema.validate('hello');
        expect(result.isOk, isFalse);
        expect(
            (result.getError() as SchemaConstraintsError)
                .constraints
                .first
                .message,
            'Value must be no more than 3 characters long, but was 5.');
      });

      test('length should pass if string is exact length', () {
        final schema = StringSchema().length(5);
        final result = schema.validate('hello');
        expect(result.isOk, isTrue);
      });

      test('length should fail if string is not exact length', () {
        final schema = StringSchema().length(5);
        final result = schema.validate('hell');
        expect(result.isOk, isFalse);
        expect(
            (result.getError() as SchemaConstraintsError)
                .constraints
                .first
                .message,
            'Value must be exactly 5 characters long, but was 4.');
      });

      test('should chain length constraints', () {
        final schema = StringSchema().minLength(3).maxLength(5);
        expect(schema.validate('hi').isOk, isFalse);
        expect(schema.validate('hello').isOk, isTrue);
        expect(schema.validate('hellos').isOk, isFalse);
      });
    });

    group('format', () {
      test('email should pass for valid email', () {
        final schema = StringSchema().email();
        final result = schema.validate('test@example.com');
        expect(result.isOk, isTrue);
      });

      test('email should fail for invalid email', () {
        final schema = StringSchema().email();
        final result = schema.validate('not-an-email');
        expect(result.isOk, isFalse);
        expect(
            (result.getError() as SchemaConstraintsError)
                .constraints
                .first
                .message,
            '"not-an-email" is not a valid email address.');
      });

      test('url should pass for valid url', () {
        final schema = StringSchema().url();
        final result = schema.validate('https://example.com');
        expect(result.isOk, isTrue);
      });

      test('url should fail for invalid url', () {
        final schema = StringSchema().url();
        final result = schema.validate('not-a-url');
        expect(result.isOk, isFalse);
        expect(
            (result.getError() as SchemaConstraintsError)
                .constraints
                .first
                .message,
            '"not-a-url" is not a valid URL.');
      });

      test('uuid should pass for valid uuid', () {
        final schema = StringSchema().uuid();
        final result = schema.validate('123e4567-e89b-12d3-a456-426614174000');
        expect(result.isOk, isTrue);
      });

      test('uuid should fail for invalid uuid', () {
        final schema = StringSchema().uuid();
        final result = schema.validate('not-a-uuid');
        expect(result.isOk, isFalse);
        expect(
            (result.getError() as SchemaConstraintsError)
                .constraints
                .first
                .message,
            '"not-a-uuid" is not a valid UUID.');
      });
    });

    test('should chain multiple constraints', () {
      final schema = StringSchema().minLength(10).email();
      final result = schema.validate('a@b.com');
      expect(result.isOk, isFalse);
      expect(
          (result.getError() as SchemaConstraintsError)
              .constraints
              .first
              .message,
          'Value must be at least 10 characters long, but was 7.');

      final result2 = schema.validate('this-is-not-an-email');
      expect(result2.isOk, isFalse);
      expect(
          (result2.getError() as SchemaConstraintsError)
              .constraints
              .first
              .message,
          '"this-is-not-an-email" is not a valid email address.');

      final result3 = schema.validate('long.email@example.com');
      expect(result3.isOk, isTrue);
    });
  });
}
