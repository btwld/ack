import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('StringSchemaExtensions - Transformers', () {
    group('trim()', () {
      test('should remove leading and trailing whitespace', () {
        final schema = Ack.string().trim();

        expect(schema.parse('  hello  '), equals('hello'));
        expect(schema.parse('\n\thello\t\n'), equals('hello'));
        expect(schema.parse('hello'), equals('hello'));
      });

      test('should handle empty string after trimming', () {
        final schema = Ack.string().trim();

        expect(schema.parse('   '), equals(''));
        expect(schema.parse('\t\n'), equals(''));
      });

      test('should handle null input with nullable schema', () {
        final schema = Ack.string().nullable().trim();

        final result = schema.safeParse(null);
        expect(result.isOk, isTrue);
        // Null passes through without calling transformer
        expect(result.getOrNull(), isNull);
      });

      test('should validate before transforming', () {
        final schema = Ack.string().email().trim();

        // Invalid email fails before trim is applied
        final result = schema.safeParse('not-an-email');
        expect(result.isFail, isTrue);
        expect(result.getError(), isA<SchemaConstraintsError>());
      });
    });

    group('toLowerCase()', () {
      test('should convert string to lowercase', () {
        final schema = Ack.string().toLowerCase();

        expect(schema.parse('HELLO'), equals('hello'));
        expect(schema.parse('HeLLo'), equals('hello'));
        expect(schema.parse('hello'), equals('hello'));
      });

      test('should handle empty string', () {
        final schema = Ack.string().toLowerCase();

        expect(schema.parse(''), equals(''));
      });

      test('should handle special characters and numbers', () {
        final schema = Ack.string().toLowerCase();

        expect(schema.parse('HELLO123!@#'), equals('hello123!@#'));
        expect(schema.parse('CamelCase'), equals('camelcase'));
      });

      test('should handle null input with nullable schema', () {
        final schema = Ack.string().nullable().toLowerCase();

        final result = schema.safeParse(null);
        expect(result.isOk, isTrue);
        // Null passes through without calling transformer
        expect(result.getOrNull(), isNull);
      });

      test('should validate before transforming', () {
        final schema = Ack.string().minLength(10).toLowerCase();

        // Too short fails before toLowerCase is applied
        final result = schema.safeParse('SHORT');
        expect(result.isFail, isTrue);
        expect(result.getError(), isA<SchemaConstraintsError>());
      });
    });

    group('toUpperCase()', () {
      test('should convert string to uppercase', () {
        final schema = Ack.string().toUpperCase();

        expect(schema.parse('hello'), equals('HELLO'));
        expect(schema.parse('HeLLo'), equals('HELLO'));
        expect(schema.parse('HELLO'), equals('HELLO'));
      });

      test('should handle empty string', () {
        final schema = Ack.string().toUpperCase();

        expect(schema.parse(''), equals(''));
      });

      test('should handle special characters and numbers', () {
        final schema = Ack.string().toUpperCase();

        expect(schema.parse('hello123!@#'), equals('HELLO123!@#'));
        expect(schema.parse('camelCase'), equals('CAMELCASE'));
      });

      test('should handle null input with nullable schema', () {
        final schema = Ack.string().nullable().toUpperCase();

        final result = schema.safeParse(null);
        expect(result.isOk, isTrue);
        // Null passes through without calling transformer
        expect(result.getOrNull(), isNull);
      });

      test('should validate before transforming', () {
        final schema = Ack.string().email().toUpperCase();

        // Invalid email fails before toUpperCase is applied
        final result = schema.safeParse('not-an-email');
        expect(result.isFail, isTrue);
        expect(result.getError(), isA<SchemaConstraintsError>());
      });
    });

    group('Combining transformers with transform()', () {
      test('should combine trim and toLowerCase using transform', () {
        final schema = Ack.string().transform((s) => s.trim().toLowerCase());

        expect(schema.parse('  HELLO  '), equals('hello'));
        expect(schema.parse('\tHeLLo\n'), equals('hello'));
      });

      test('should combine trim and toUpperCase using transform', () {
        final schema = Ack.string().transform((s) => s.trim().toUpperCase());

        expect(schema.parse('  hello  '), equals('HELLO'));
        expect(schema.parse('\theLLo\n'), equals('HELLO'));
      });

      test('should combine all transformations', () {
        // Trim, then lowercase, then uppercase (last wins)
        final schema = Ack.string().transform((s) {
          return s.trim().toLowerCase().toUpperCase();
        });

        expect(schema.parse('  hello  '), equals('HELLO'));
      });

      test('should validate constraints before transformation', () {
        final schema = Ack.string().email().transform(
          (s) => s.trim().toLowerCase(),
        );

        // Email validation happens first - spaces cause validation to fail
        final result = schema.safeParse('  not-an-email  ');
        expect(result.isFail, isTrue);
        expect(result.getError(), isA<SchemaConstraintsError>());

        // Valid email (without leading/trailing spaces) gets lowercased
        final validResult = schema.safeParse('TEST@EXAMPLE.COM');
        expect(validResult.isOk, isTrue);
        expect(validResult.getOrThrow(), equals('test@example.com'));
      });
    });

    group('Transformers with optional/nullable', () {
      test('should work with optional schema', () {
        final schema = Ack.string().optional().trim();

        expect(schema.isOptional, isTrue);
        expect(schema.parse('  hello  '), equals('hello'));
      });

      test('should work with nullable schema', () {
        final schema = Ack.string().nullable().trim();

        expect(schema.isNullable, isTrue);
        // Null passes through without calling transformer
        expect(schema.parse(null), isNull);
        expect(schema.parse('  hello  '), equals('hello'));
      });

      test('should work with optional and nullable', () {
        final schema = Ack.string().optional().nullable().toLowerCase();

        expect(schema.isOptional, isTrue);
        expect(schema.isNullable, isTrue);
        // Null passes through without calling transformer
        expect(schema.parse(null), isNull);
        expect(schema.parse('HELLO'), equals('hello'));
      });
    });

    group('Real-world use cases', () {
      test('should normalize usernames', () {
        final usernameSchema = Ack.string()
            .minLength(3)
            .maxLength(20)
            .transform((s) => s.trim().toLowerCase());

        final result = usernameSchema.safeParse('  JohnDoe123  ');
        expect(result.isOk, isTrue);
        expect(result.getOrThrow(), equals('johndoe123'));
      });
    });
  });
}
