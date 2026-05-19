import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('AnySchema', () {
    test('should accept any non-null JSON-safe value', () {
      final schema = Ack.any();

      // Test various types
      expect(schema.safeParse(42).getOrThrow(), equals(42));
      expect(schema.safeParse("hello").getOrThrow(), equals("hello"));
      expect(schema.safeParse([1, 2, 3]).getOrThrow(), equals([1, 2, 3]));
      expect(schema.safeParse({"a": 1}).getOrThrow(), equals({"a": 1}));
      expect(schema.safeParse(true).getOrThrow(), equals(true));
      expect(schema.safeParse(3.14).getOrThrow(), equals(3.14));
    });

    test('should reject non-JSON-safe values', () {
      final schema = Ack.any();

      expect(schema.safeParse(DateTime(2026, 1, 1)).isFail, isTrue);
      expect(schema.safeParse(double.nan).isFail, isTrue);
      expect(schema.safeParse({1: 'one'}).isFail, isTrue);
      expect(schema.safeParse([DateTime(2026, 1, 1)]).isFail, isTrue);
      expect(
        schema.safeParse({
          'nested': {'createdAt': DateTime(2026, 1, 1)},
        }).isFail,
        isTrue,
      );
      expect(schema.safeEncode(DateTime(2026, 1, 1)).isFail, isTrue);
    });

    test('should accept nested JSON-safe values', () {
      final schema = Ack.any();
      final value = {
        'items': [
          {'name': 'one', 'count': 1, 'enabled': true},
          ['nested', null],
        ],
      };

      expect(schema.safeParse(value).getOrThrow(), equals(value));
      expect(schema.safeEncode(value).getOrThrow(), equals(value));
    });

    test('should reject null by default', () {
      final schema = Ack.any();
      final result = schema.safeParse(null);

      expect(result.isFail, isTrue);
    });

    test('should accept null when nullable', () {
      final schema = Ack.any().nullable();
      final result = schema.safeParse(null);

      expect(result.isOk, isTrue);
      expect(result.getOrThrow(), isNull);
    });

    test('should use default value when provided', () {
      final schema = Ack.any().withDefault("default");
      final result = schema.safeParse(null);

      expect(result.isOk, isTrue);
      expect(result.getOrThrow(), equals("default"));
    });

    test('should support refinements on Object type', () {
      final schema = Ack.any().refine(
        (value) => value.toString().length > 5,
        message:
            "Value must have string representation longer than 5 characters",
      );

      expect(schema.safeParse("hello world").isOk, isTrue);
      expect(schema.safeParse("hi").isFail, isTrue);
      expect(schema.safeParse(123456).isOk, isTrue);
      expect(schema.safeParse(123).isFail, isTrue);
    });

    test('should generate correct JSON schema', () {
      final schema = Ack.any()
          .describe("Accepts any value")
          .withDefault("fallback");

      final jsonSchema = schema.toJsonSchema();

      expect(jsonSchema['description'], equals('Accepts any value'));
      expect(jsonSchema['default'], equals('fallback'));
      expect(jsonSchema['anyOf'], isA<List>());
      expect(jsonSchema.containsKey('type'), isFalse);
    });

    test('should work with copyWith', () {
      final original = Ack.any().describe("Original");
      final copied = original.copyWith(description: "Modified");

      expect(original.description, equals("Original"));
      expect(copied.description, equals("Modified"));
    });
  });
}
