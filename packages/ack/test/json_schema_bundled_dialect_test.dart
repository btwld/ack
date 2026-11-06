import 'package:ack/ack.dart';
import 'package:test/test.dart';

const _standardDialect = 'https://json-schema.org/draft/2020-12/schema';
const _vocabularyPrefix = 'https://json-schema.org/draft/2020-12/vocab/';
const _customDialect = 'https://example.test/meta/custom';

Map<String, Object?> _dialect({bool applicator = true}) => {
  r'$id': _customDialect,
  r'$schema': _standardDialect,
  r'$vocabulary': {
    '${_vocabularyPrefix}core': true,
    if (applicator) '${_vocabularyPrefix}applicator': true,
    '${_vocabularyPrefix}validation': true,
  },
};

void _expectStringRoundTrip(Map<String, Object?> document) {
  final schema = Ack.fromJsonSchema(document);
  final exported = schema.toJsonSchema();
  final restored = Ack.fromJsonSchema(exported);
  for (final candidate in [schema, restored]) {
    expect(candidate.safeParse('ok').isOk, isTrue);
    expect(candidate.safeParse(1).isFail, isTrue);
    expect(candidate.safeParse(null).isFail, isTrue);
  }
  expect(schema.toJsonSchema(), exported);
}

void main() {
  for (final container in ['allOf', 'properties', 'items']) {
    test('discovers a selected dialect bundled under $container', () {
      _expectStringRoundTrip({
        r'$schema': _customDialect,
        'type': 'string',
        container: switch (container) {
          'allOf' => [_dialect()],
          'properties' => {'meta': _dialect()},
          _ => _dialect(),
        },
      });
    });
  }

  test('resolves a bundled dialect through nested relative resource IDs', () {
    _expectStringRoundTrip({
      r'$id': 'https://example.test/root',
      r'$schema': _customDialect,
      'type': 'string',
      'allOf': [
        {
          r'$id': 'meta/',
          'allOf': [
            {..._dialect(), r'$id': 'custom'},
          ],
        },
      ],
    });
  });

  test('honors a different dialect along the resource discovery path', () {
    _expectStringRoundTrip({
      r'$schema': _customDialect,
      'type': 'string',
      'allOf': [
        {
          r'$id': 'https://example.test/standard-resource',
          r'$schema': _standardDialect,
          // Enabled by this resource's dialect, but not the root's dialect.
          'unevaluatedProperties': _dialect(),
        },
      ],
    });
  });

  test(
    'discovery leaves unrelated inactive keywords and annotations inert',
    () {
      final annotation = {
        r'$id': _customDialect,
        r'$schema': 'https://example.test/not-supplied',
        r'$ref': 'https://example.test/not-supplied',
      };
      final source = <String, Object?>{
        r'$schema': _customDialect,
        'type': 'string',
        'default': annotation,
        'contentSchema': annotation,
        'unevaluatedProperties': {
          ..._dialect(),
          r'$vocabulary': {
            '${_vocabularyPrefix}core': true,
            'https://example.test/unsupported-vocabulary': true,
          },
        },
        'unevaluatedItems': {r'$id': _customDialect},
        'allOf': [_dialect()],
      };
      _expectStringRoundTrip(source);
      final exported = Ack.fromJsonSchema(source).toJsonSchema();
      expect(exported['default'], annotation);
      expect(exported['contentSchema'], annotation);
      expect(
        exported['unevaluatedProperties'],
        source['unevaluatedProperties'],
      );
      expect(exported['unevaluatedItems'], source['unevaluatedItems']);
    },
  );

  for (final container in ['default', 'examples', 'x-annotation']) {
    test('does not discover dialect IDs inside $container data', () {
      expect(
        () => Ack.fromJsonSchema({
          r'$schema': _customDialect,
          container: container == 'examples' ? [_dialect()] : _dialect(),
        }),
        throwsA(isA<JsonSchemaImportException>()),
      );
    });
  }

  test('does not discover a dialect beneath a keyword it disables', () {
    expect(
      () => Ack.fromJsonSchema({
        r'$schema': _customDialect,
        'allOf': [_dialect(applicator: false)],
      }),
      throwsA(isA<JsonSchemaImportException>()),
    );
  });

  test('reports duplicate active bundled dialect identifiers', () {
    expect(
      () => Ack.fromJsonSchema({
        r'$schema': _customDialect,
        'allOf': [_dialect(), _dialect()],
      }),
      throwsA(
        isA<JsonSchemaImportException>().having(
          (error) => error.toString(),
          'diagnostic',
          contains('Duplicate schema identifier'),
        ),
      ),
    );
  });

  test(
    'still rejects unknown required vocabularies of discovered dialects',
    () {
      expect(
        () => Ack.fromJsonSchema({
          r'$schema': _customDialect,
          'allOf': [
            {
              ..._dialect(),
              r'$vocabulary': {
                '${_vocabularyPrefix}core': true,
                '${_vocabularyPrefix}applicator': true,
                'https://example.test/unsupported-vocabulary': true,
              },
            },
          ],
        }),
        throwsA(
          isA<JsonSchemaImportException>().having(
            (error) => error.toString(),
            'diagnostic',
            contains('Unknown required vocabulary'),
          ),
        ),
      );
    },
  );
}
