import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  for (final keyword in [r'$ref', r'$dynamicRef']) {
    test('$keyword preserves pointers through retrieval aliases', () {
      final schema = Ack.fromJsonSchema(
        {keyword: r'https://example.test/download.json#/$defs/a~1b'},
        documents: {
          Uri.parse('https://example.test/download.json'): {
            r'$id': 'https://example.test/canonical.json',
            r'$defs': {
              'a/b': {'type': 'string'},
            },
          },
        },
      );
      final restored = Ack.fromJsonSchema(schema.toJsonSchema());
      expect(restored.safeParse('value').isOk, isTrue);
      expect(restored.safeParse(42).isFail, isTrue);
    });
  }

  test('nested resource retains opt-in format assertion after export', () {
    final schema = Ack.fromJsonSchema({
      r'$id': 'https://example.test/root',
      r'$defs': {
        'email': {
          r'$id': 'email',
          r'$schema': 'https://json-schema.org/draft/2020-12/schema',
          'type': 'string',
          'format': 'email',
        },
      },
      r'$ref': 'email',
      'default': {r'$schema': 'https://json-schema.org/draft/2020-12/schema'},
    }, assertFormats: true);
    final exported = schema.toJsonSchema();
    final restored = Ack.fromJsonSchema(exported);
    expect(schema.safeParse('not-an-email').isFail, isTrue);
    expect(restored.safeParse('not-an-email').isFail, isTrue);
    expect(restored.safeParse('user@example.test').isOk, isTrue);
    expect(exported['default'], {
      r'$schema': 'https://json-schema.org/draft/2020-12/schema',
    });
  });

  test('retrieval aliases preserve encoded pointers and annotation data', () {
    final source = {
      r'$ref': 'https://example.test/download.json#/components/a%25b',
      'default': {r'$ref': 'https://example.test/download.json'},
    };
    final schema = Ack.fromJsonSchema(
      source,
      documents: {
        Uri.parse('https://example.test/download.json'): {
          r'$id': 'https://example.test/canonical.json',
          'components': {
            'a%b': {'type': 'integer'},
          },
        },
      },
    );
    final exported = schema.toJsonSchema();
    expect(exported['default'], source['default']);
    final restored = Ack.fromJsonSchema(exported);
    expect(restored.safeParse(1).isOk, isTrue);
    expect(restored.safeParse('1').isFail, isTrue);
  });

  test('nested formats in supplied documents retain assertion behavior', () {
    final schema = Ack.fromJsonSchema(
      {r'$ref': r'https://example.test/download.json#/$defs/email'},
      assertFormats: true,
      documents: {
        Uri.parse('https://example.test/download.json'): {
          r'$id': 'https://example.test/canonical.json',
          r'$defs': {
            'email': {
              r'$id': 'email',
              r'$schema': 'https://json-schema.org/draft/2020-12/schema',
              'type': 'string',
              'format': 'email',
            },
          },
        },
      },
    );
    final restored = Ack.fromJsonSchema(schema.toJsonSchema());
    expect(restored.safeParse('not-an-email').isFail, isTrue);
    expect(restored.safeParse('user@example.test').isOk, isTrue);
  });

  test(
    'export retains dormant malformed references without evaluating them',
    () {
      final schema = Ack.fromJsonSchema({
        'type': 'string',
        r'$defs': {
          'unused': {r'$ref': 'http://['},
        },
      });
      final restored = Ack.fromJsonSchema(schema.toJsonSchema());
      expect(restored.safeParse('ok').isOk, isTrue);
    },
  );
}
