import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('AnySchema', () {
    test('should accept any non-null value', () {
      final schema = Ack.any();

      // Test various types
      expect(schema.validate(42).getOrThrow(), equals(42));
      expect(schema.validate("hello").getOrThrow(), equals("hello"));
      expect(schema.validate([1, 2, 3]).getOrThrow(), equals([1, 2, 3]));
      expect(schema.validate({"a": 1}).getOrThrow(), equals({"a": 1}));
      expect(schema.validate(true).getOrThrow(), equals(true));
      expect(schema.validate(3.14).getOrThrow(), equals(3.14));
    });

    test('should reject null by default', () {
      final schema = Ack.any();
      final result = schema.validate(null);

      expect(result.isFail, isTrue);
    });

    test('should accept null when nullable', () {
      final schema = Ack.any().nullable();
      final result = schema.validate(null);

      expect(result.isOk, isTrue);
      expect(result.getOrThrow(), isNull);
    });

    test('should use default value when provided', () {
      final schema = Ack.any().withDefault("default");
      final result = schema.validate(null);

      expect(result.isOk, isTrue);
      expect(result.getOrThrow(), equals("default"));
    });

    test('should support refinements on Object type', () {
      final schema = Ack.any().refine((value) => value.toString().length > 5,
          message:
              "Value must have string representation longer than 5 characters");

      expect(schema.validate("hello world").isOk, isTrue);
      expect(schema.validate("hi").isFail, isTrue);
      expect(schema.validate(123456).isOk, isTrue);
      expect(schema.validate(123).isFail, isTrue);
    });

    test('should generate correct JSON schema', () {
      final schema = Ack.any()
          .withDescription("Accepts any value")
          .withDefault("fallback");

      final jsonSchema = schema.toJsonSchema();

      expect(
          jsonSchema,
          equals({
            'not': {'type': 'null'}, // Non-nullable AnySchema rejects null
            'description': 'Accepts any value',
            'default': 'fallback',
          }));
    });

    test('should support fluent API', () {
      final schema = Ack.any()
          .nullable()
          .withDescription("Any value or null")
          .withDefault("default");

      expect(schema.isNullable, isTrue);
      expect(schema.description, equals("Any value or null"));
      expect(schema.defaultValue, equals("default"));
    });

    test('should work with copyWith', () {
      final original = Ack.any().withDescription("Original");
      final copied = original.copyWith(description: "Modified");

      expect(original.description, equals("Original"));
      expect(copied.description, equals("Modified"));
    });
  });
}
