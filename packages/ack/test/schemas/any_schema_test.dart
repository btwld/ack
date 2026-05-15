import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('AnySchema', () {
    test('should accept any non-null value', () {
      final schema = Ack.any();

      // Test various types
      expect(schema.safeParse(42).getOrThrow(), equals(42));
      expect(schema.safeParse("hello").getOrThrow(), equals("hello"));
      expect(schema.safeParse([1, 2, 3]).getOrThrow(), equals([1, 2, 3]));
      expect(schema.safeParse({"a": 1}).getOrThrow(), equals({"a": 1}));
      expect(schema.safeParse(true).getOrThrow(), equals(true));
      expect(schema.safeParse(3.14).getOrThrow(), equals(3.14));
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

      // AnySchema emits explicit non-null JSON types because an empty schema {}
      // would also permit null.
      expect(jsonSchema['description'], equals('Accepts any value'));
      expect(jsonSchema['default'], equals('fallback'));
      expect(jsonSchema['anyOf'], [
        {'type': 'string'},
        {'type': 'number'},
        {'type': 'integer'},
        {'type': 'boolean'},
        {'type': 'object'},
        {'type': 'array'},
      ]);
    });

    test('JSON schema includes null only when nullable', () {
      final nonNullableJson = Ack.any().toJsonSchema();
      final nullableJson = Ack.any().nullable().toJsonSchema();

      final nonNullableAnyOf = nonNullableJson['anyOf'] as List<Object?>;
      final nullableAnyOf = nullableJson['anyOf'] as List<Object?>;

      expect(nonNullableAnyOf, isNot(anyElement(equals({'type': 'null'}))));
      expect(nullableAnyOf, anyElement(equals({'type': 'null'})));
    });

    test('should support fluent API', () {
      final schema = Ack.any()
          .nullable()
          .describe("Any value or null")
          .withDefault("default");

      expect(schema.isNullable, isTrue);
      expect(schema.description, equals("Any value or null"));
      expect(schema.defaultValue, equals("default"));
    });

    test('should work with copyWith', () {
      final original = Ack.any().describe("Original");
      final copied = original.copyWith(description: "Modified");

      expect(original.description, equals("Original"));
      expect(copied.description, equals("Modified"));
    });
  });
}
