import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('Uri Validation', () {
    group('Format validation', () {
      test('accepts valid https URI with path, query, and fragment', () {
        final schema = Ack.uri();
        final result = schema.safeParse('https://example.com/path?x=1#section');

        expect(result.isOk, isTrue);
      });

      test('accepts valid http URI', () {
        final schema = Ack.uri();
        final result = schema.safeParse('http://example.com');

        expect(result.isOk, isTrue);
      });

      test('accepts valid ftp URI', () {
        final schema = Ack.uri();
        final result = schema.safeParse('ftp://files.example.com/resource.txt');

        expect(result.isOk, isTrue);
      });

      test('rejects non-URI string', () {
        final schema = Ack.uri();
        final result = schema.safeParse('not a uri');

        expect(result.isFail, isTrue);
        final error = result.getError() as SchemaConstraintsError;
        expect(error.constraints.first.message, contains('Invalid URI format'));
      });

      test('rejects empty string', () {
        final schema = Ack.uri();
        final result = schema.safeParse('');

        expect(result.isFail, isTrue);
      });
    });

    group('Type output', () {
      test('returns Uri type with accessible properties', () {
        final schema = Ack.uri();
        final result = schema.parse('https://example.com/path?x=1#section')!;

        expect(result, isA<Uri>());
        expect(result.scheme, 'https');
        expect(result.host, 'example.com');
        expect(result.path, '/path');
        expect(result.query, 'x=1');
        expect(result.fragment, 'section');
      });
    });

    group('Composition', () {
      test('works with optional() in object schema', () {
        final objSchema = Ack.object({'website': Ack.uri().optional()});

        expect(objSchema.safeParse({}).isOk, isTrue);
        expect(
          objSchema.safeParse({'website': 'https://example.com'}).isOk,
          isTrue,
        );
      });

      test('works with nullable()', () {
        final nullOnly = Ack.any().nullable().refine(
          (_) => false,
          message: 'Expected null',
        );
        final schema = Ack.anyOf([Ack.uri(), nullOnly]);

        expect(schema.safeParse(null).isOk, isTrue);
        expect(schema.safeParse('https://example.com').isOk, isTrue);
        expect(schema.safeParse('not a uri').isFail, isTrue);
      });
    });

    group('JSON Schema', () {
      test('emits type string, format uri, and x-transformed', () {
        final schema = Ack.uri();
        final jsonSchema = schema.toJsonSchema();

        expect(jsonSchema['type'], 'string');
        expect(jsonSchema['format'], 'uri');
        expect(jsonSchema['x-transformed'], isTrue);
      });
    });
  });
}
