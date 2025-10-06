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

      test('should work with notEmpty constraint (validates after trim)', () {
        final schema = Ack.string().trim().refine(
          (s) => s.isNotEmpty,
          message: 'String cannot be empty after trimming',
        );

        final result = schema.safeParse('  hello  ');
        expect(result.isOk, isTrue);
        expect(result.getOrThrow(), equals('hello'));

        final emptyResult = schema.safeParse('   ');
        expect(emptyResult.isFail, isTrue);
        expect(
          emptyResult.getError().message,
          contains('String cannot be empty after trimming'),
        );
      });

      test('should handle null input with nullable schema', () {
        final schema = Ack.string().nullable().trim();

        final result = schema.safeParse(null);
        expect(result.isOk, isTrue);
        expect(result.getOrThrow(), equals(''));
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

      test('should work with pattern matching after transformation', () {
        final schema = Ack.string().toLowerCase().refine(
          (s) => s.startsWith('hello'),
          message: 'Must start with hello (lowercase)',
        );

        expect(schema.parse('HELLO WORLD'), equals('hello world'));
        expect(schema.parse('Hello World'), equals('hello world'));

        final result = schema.safeParse('GOODBYE');
        expect(result.isFail, isTrue);
        expect(
          result.getError().message,
          contains('Must start with hello (lowercase)'),
        );
      });

      test('should handle null input with nullable schema', () {
        final schema = Ack.string().nullable().toLowerCase();

        final result = schema.safeParse(null);
        expect(result.isOk, isTrue);
        expect(result.getOrThrow(), equals(''));
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

      test('should work with pattern matching after transformation', () {
        final schema = Ack.string().toUpperCase().refine(
          (s) => s.startsWith('HELLO'),
          message: 'Must start with HELLO (uppercase)',
        );

        expect(schema.parse('hello world'), equals('HELLO WORLD'));
        expect(schema.parse('Hello World'), equals('HELLO WORLD'));

        final result = schema.safeParse('goodbye');
        expect(result.isFail, isTrue);
        expect(
          result.getError().message,
          contains('Must start with HELLO (uppercase)'),
        );
      });

      test('should handle null input with nullable schema', () {
        final schema = Ack.string().nullable().toUpperCase();

        final result = schema.safeParse(null);
        expect(result.isOk, isTrue);
        expect(result.getOrThrow(), equals(''));
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
        final schema = Ack.string().transform(
          (s) => s?.trim().toLowerCase() ?? '',
        );

        expect(schema.parse('  HELLO  '), equals('hello'));
        expect(schema.parse('\tHeLLo\n'), equals('hello'));
      });

      test('should combine trim and toUpperCase using transform', () {
        final schema = Ack.string().transform(
          (s) => s?.trim().toUpperCase() ?? '',
        );

        expect(schema.parse('  hello  '), equals('HELLO'));
        expect(schema.parse('\theLLo\n'), equals('HELLO'));
      });

      test('should combine all transformations', () {
        // Trim, then lowercase, then uppercase (last wins)
        final schema = Ack.string().transform((s) {
          if (s == null) return '';
          return s.trim().toLowerCase().toUpperCase();
        });

        expect(schema.parse('  hello  '), equals('HELLO'));
      });

      test('should apply transformation and then refinements', () {
        final schema = Ack.string()
            .transform((s) => s?.trim().toLowerCase() ?? '')
            .refine(
              (s) => s == 'hello',
              message: 'Must be "hello" after normalization',
            );

        expect(schema.parse('  HELLO  '), equals('hello'));
        expect(schema.parse('  HeLLo  '), equals('hello'));

        final result = schema.safeParse('  WORLD  ');
        expect(result.isFail, isTrue);
        expect(
          result.getError().message,
          contains('Must be "hello" after normalization'),
        );
      });

      test('should validate constraints before transformation', () {
        final schema = Ack.string().email().transform(
          (s) => s?.trim().toLowerCase() ?? '',
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
        expect(schema.parse(null), equals(''));
        expect(schema.parse('  hello  '), equals('hello'));
      });

      test('should work with optional and nullable', () {
        final schema = Ack.string().optional().nullable().toLowerCase();

        expect(schema.isOptional, isTrue);
        expect(schema.isNullable, isTrue);
        expect(schema.parse(null), equals(''));
        expect(schema.parse('HELLO'), equals('hello'));
      });
    });

    group('Real-world use cases', () {
      test('should normalize email addresses', () {
        // Transform first (trim + lowercase), then validate email
        final emailSchema = Ack.string()
            .transform((s) => s?.trim().toLowerCase() ?? '')
            .refine(
              (s) => RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(s),
              message: 'Invalid email',
            );

        final result = emailSchema.safeParse('  Test@Example.COM  ');
        expect(result.isOk, isTrue);
        expect(result.getOrThrow(), equals('test@example.com'));
      });

      test('should normalize usernames', () {
        final usernameSchema = Ack.string()
            .minLength(3)
            .maxLength(20)
            .transform((s) => s?.trim().toLowerCase() ?? '');

        final result = usernameSchema.safeParse('  JohnDoe123  ');
        expect(result.isOk, isTrue);
        expect(result.getOrThrow(), equals('johndoe123'));
      });

      test('should normalize tags', () {
        final tagSchema = Ack.string()
            .transform((s) => s?.trim().toLowerCase() ?? '')
            .refine((s) => s.isNotEmpty, message: 'Tag cannot be empty');

        expect(tagSchema.parse('  JavaScript  '), equals('javascript'));
        expect(tagSchema.parse('DART'), equals('dart'));

        final emptyResult = tagSchema.safeParse('   ');
        expect(emptyResult.isFail, isTrue);
      });

      test('should handle form input normalization', () {
        final formSchema = Ack.object({
          'email': Ack.string()
              .transform((s) => s?.trim().toLowerCase() ?? '')
              .refine(
                (s) => RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(s),
                message: 'Invalid email',
              ),
          'name': Ack.string().trim(),
          'username': Ack.string()
              .minLength(3)
              .transform((s) => s?.trim().toLowerCase() ?? ''),
        });

        final result = formSchema.safeParse({
          'email': '  John@Example.COM  ',
          'name': '  John Doe  ',
          'username': '  JohnDoe  ',
        });

        expect(result.isOk, isTrue);
        final data = result.getOrThrow()!;
        expect(data['email'], equals('john@example.com'));
        expect(data['name'], equals('John Doe'));
        expect(data['username'], equals('johndoe'));
      });
    });
  });
}
