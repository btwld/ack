import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('importJsonSchema', () {
    test('rejects conflicting documents with equivalent retrieval URIs', () {
      final base = Uri.parse('https://example.test/root.json');
      final entries = [
        MapEntry(Uri.parse('types.json'), {'type': 'string'}),
        MapEntry(base.resolve('types.json'), {'type': 'number'}),
      ];
      for (final allowUnsupported in [false, true]) {
        for (final ordered in [entries, entries.reversed]) {
          expect(
            () => importJsonSchema(
              {r'$ref': 'types.json'},
              baseUri: base,
              documents: Map.fromEntries(ordered),
              allowUnsupported: allowUnsupported,
            ),
            throwsA(isA<JsonSchemaImportException>()),
          );
        }
        expect(
          () => importJsonSchema(
            {'type': 'string'},
            baseUri: base,
            documents: {
              base: {'type': 'number'},
            },
            allowUnsupported: allowUnsupported,
          ),
          throwsA(isA<JsonSchemaImportException>()),
        );
      }
    });

    test('accepts the draft 2020-12 dialect with an empty fragment', () {
      for (final allowUnsupported in [false, true]) {
        final result = importJsonSchema({
          r'$schema': 'https://json-schema.org/draft/2020-12/schema#',
          'type': 'string',
        }, allowUnsupported: allowUnsupported);
        expect(result.isExact, isTrue);
        expect(result.schema.safeParse('hello').isOk, isTrue);
        expect(result.schema.safeParse(1).isFail, isTrue);
      }
    });

    test('rejects non-empty dialect fragments and different drafts', () {
      for (final dialect in [
        'https://json-schema.org/draft/2020-12/schema#other',
        'https://json-schema.org/draft/2019-09/schema#',
      ]) {
        expect(
          () => importJsonSchema({r'$schema': dialect}, allowUnsupported: true),
          throwsA(isA<JsonSchemaImportException>()),
        );
      }
    });

    test(
      'partial exclusive unions retain branch shapes as inclusive unions',
      () {
        final result = importJsonSchema({
          'anyOf': [
            {'type': 'object'},
            {'type': 'boolean'},
          ],
          'oneOf': [
            {
              'type': 'object',
              'required': ['name'],
              'format': 'custom',
            },
            {'type': 'integer'},
          ],
        }, allowUnsupported: true);
        expect(result.schema.safeParse({'name': 'Ada'}).isOk, isTrue);
        for (final invalid in [null, true, 1, [], <String, Object?>{}]) {
          expect(result.schema.safeParse(invalid).isFail, isTrue);
          expect(
            importJsonSchema(
              result.schema.toJsonSchema(),
            ).schema.safeParse(invalid).isFail,
            isTrue,
          );
        }
      },
    );

    test(
      'rejects invalid annotation shapes instead of emitting invalid schemas',
      () {
        for (final document in [
          {'title': 1},
          {'description': null},
          {'examples': true},
          {'readOnly': 'yes'},
          {'writeOnly': 1},
          {'deprecated': null},
          {r'$comment': false},
        ]) {
          expect(
            () => importJsonSchema(document),
            throwsA(isA<JsonSchemaImportException>()),
          );
        }
      },
    );

    test(
      'added constraints do not become ignored Draft-7 reference siblings',
      () {
        final schema = importJsonSchema(true).schema.constrain(_OnlyStrings());
        expect(schema.safeParse('ok').isOk, isTrue);
        expect(schema.safeParse(1).isFail, isTrue);
        expect(schema.safeParse(null).isOk, isTrue);
        final exported = schema.toJsonSchema();
        // Draft-7 ignores every sibling of $ref. A root reference here would
        // silently discard the additional, exported `type: string` assertion.
        expect(exported.containsKey(r'$ref'), isFalse);
        expect(importJsonSchema(exported).schema.safeParse(1).isFail, isTrue);
        expect(importJsonSchema(exported).schema.safeParse(null).isOk, isTrue);
        expect(schema.toSchemaModel().toJsonSchema(), exported);
      },
    );

    test('source descriptions are available through the Ack schema API', () {
      final schema = importJsonSchema({
        'type': 'string',
        'description': 'A protocol field',
      }).schema;
      expect(schema.description, 'A protocol field');
      expect(schema.describe('Override').description, 'Override');
    });

    test(
      'resolves catalog schemas stored outside standard schema containers',
      () {
        final schema = importJsonSchema(
          {r'$ref': r'catalog.json#/$defs/component'},
          baseUri: Uri.parse('https://example.test/message.json'),
          documents: {
            Uri.parse('catalog.json'): {
              r'$id': 'https://example.test/catalog.json',
              'catalogId': 'example',
              'components': {
                'Text': {
                  'type': 'object',
                  'properties': {
                    'text': {'type': 'string'},
                  },
                  'required': ['text'],
                },
              },
              r'$defs': {
                'component': {r'$ref': '#/components/Text'},
              },
            },
          },
        ).schema;
        expect(schema.safeParse({'text': 'Hello'}).isOk, isTrue);
        expect(schema.safeParse({'text': 1}).isFail, isTrue);
        expect(
          importJsonSchema(
            schema.toJsonSchema(),
          ).schema.safeParse({'text': 1}).isFail,
          isTrue,
        );
      },
    );

    test('only reachable assertions affect strictness and diagnostics', () {
      final result = importJsonSchema(
        {
          'type': 'string',
          r'$defs': {
            'unused': {'format': 'email', r'$ref': 'missing.json'},
          },
        },
        documents: {
          Uri.parse('unused.json'): {'format': 'date-time'},
        },
      );
      expect(result.isExact, isTrue);
      expect(result.schema.safeParse('hello').isOk, isTrue);
    });

    test('empty and repeated enum values export as valid Draft-7 schemas', () {
      final never = importJsonSchema({'enum': []}).schema;
      for (final value in [null, 1, 'x', [], <String, Object?>{}]) {
        expect(never.safeParse(value).isFail, isTrue);
        expect(
          importJsonSchema(never.toJsonSchema()).schema.safeParse(value).isFail,
          isTrue,
        );
      }
      final repeated = importJsonSchema({
        'enum': [1, 1.0, 'x', 'x'],
      }).schema;
      expect(repeated.safeParse(1).isOk, isTrue);
      final definitions = repeated.toJsonSchema()['definitions'] as Map;
      expect((definitions.values.first as Map)['enum'], [1, 'x']);
      final falseDefinitions = never.toJsonSchema()['definitions'] as Map;
      expect(falseDefinitions.values.first, {'not': <String, Object?>{}});
    });

    test('reference failures include source URI and keyword location', () {
      try {
        importJsonSchema({
          'properties': {
            'child': {r'$ref': 'missing.json'},
          },
        }, baseUri: Uri.parse('https://example.test/root.json'));
        fail('Expected an unresolved reference.');
      } on JsonSchemaImportException catch (error) {
        final issue = error.diagnostics.single;
        expect(issue.code, 'unresolved_reference');
        expect(issue.documentUri, Uri.parse('https://example.test/root.json'));
        expect(issue.pointer, r'#/properties/child/$ref');
      }
    });

    test('diagnoses malformed URI fragments and unsupported dialects', () {
      for (final document in [
        {r'$ref': '#/%FF'},
        {r'$schema': null},
        {r'$anchor': null},
        {r'$schema': 'http://json-schema.org/draft-07/schema#'},
      ]) {
        expect(
          () => importJsonSchema(document, allowUnsupported: true),
          throwsA(isA<JsonSchemaImportException>()),
        );
      }
    });

    test('loss propagates through recursive references before negation', () {
      final result = importJsonSchema({
        r'$defs': {
          'node': {
            'properties': {
              'next': {r'$ref': r'#/$defs/node'},
            },
            'format': 'custom',
          },
        },
        'not': {r'$ref': r'#/$defs/node'},
      }, allowUnsupported: true);
      expect(
        result.diagnostics.map((d) => d.keyword),
        containsAll(['format', 'not']),
      );
      expect(result.schema.safeParse({'next': {}}).isOk, isTrue);
      expect(result.schema.safeParse(null).isOk, isTrue);
    });

    test('runtime errors keep the failing instance path', () {
      final schema = importJsonSchema({
        'properties': {
          'a/b': {
            'items': {'type': 'string'},
          },
        },
      }).schema;
      expect(
        schema
            .safeParse({
              'a/b': ['ok', 2],
            })
            .getError()
            .context
            .path,
        '#/a~1b/1',
      );
    });

    test('recursive validation has no hidden Ack.lazy depth limit', () {
      final schema = importJsonSchema({
        'type': 'object',
        'properties': {
          'child': {r'$ref': '#'},
        },
      }).schema;
      var value = <String, Object?>{};
      for (var i = 0; i < 150; i++) {
        value = {'child': value};
      }
      expect(schema.safeParse(value).isOk, isTrue);
    });

    test(
      'URI fragments are decoded once, including percent and tilde tokens',
      () {
        for (final entry in {
          r'#/$defs/a%20b': 'a b',
          r'#/$defs/a%2520b': 'a%20b',
          r'#/$defs/%E2%98%83': '☃',
          r'#/$defs/~01': '~1',
        }.entries) {
          final schema = importJsonSchema({
            r'$defs': {
              entry.value: {'const': 'yes'},
            },
            r'$ref': entry.key,
          }).schema;
          expect(schema.safeParse('yes').isOk, isTrue, reason: entry.key);
          expect(schema.safeParse('no').isFail, isTrue, reason: entry.key);
        }
      },
    );

    test(
      'nested IDs change ref scope without scanning literal data for IDs',
      () {
        final schema = importJsonSchema(
          {
            r'$id': 'https://example.test/root.json',
            r'$defs': {
              'nested': {
                r'$id': 'child/index.json',
                'properties': {
                  'x': {r'$ref': 'value.json'},
                },
                'required': ['x'],
              },
            },
            r'$ref': 'child/index.json',
            'default': {r'$id': 'child/index.json'},
          },
          documents: {
            Uri.parse('https://example.test/child/value.json'): {
              'type': 'boolean',
            },
          },
        ).schema;
        expect(schema.safeParse({'x': true}).isOk, isTrue);
        expect(schema.safeParse({'x': 1}).isFail, isTrue);
      },
    );

    test(
      'the supplied bundle may also contain the identical root document',
      () {
        final uri = Uri.parse('https://example.test/root.json');
        final document = {'type': 'string'};
        expect(
          importJsonSchema(
            document,
            baseUri: uri,
            documents: {uri: document},
          ).schema.safeParse('ok').isOk,
          isTrue,
        );
      },
    );

    test('partial omissions respect coupled applicators', () {
      final object = importJsonSchema({
        'patternProperties': {
          '^x': {'type': 'number'},
        },
        'additionalProperties': false,
      }, allowUnsupported: true);
      expect(object.schema.safeParse({'x': 1}).isOk, isTrue);
      expect(
        object.diagnostics.map((d) => d.keyword),
        containsAll(['patternProperties', 'additionalProperties']),
      );
      final list = importJsonSchema({
        'prefixItems': [
          {'type': 'string'},
        ],
        'items': false,
      }, allowUnsupported: true);
      expect(list.schema.safeParse(['x']).isOk, isTrue);
    });

    test('schema documents and parsed values are detached snapshots', () {
      final types = ['string'];
      final document = {'type': types};
      final schema = importJsonSchema(document).schema;
      types.add('number');
      expect(schema.safeParse(1).isFail, isTrue);
      final input = {
        'a': [1],
      };
      final parsed = importJsonSchema(true).schema.parse(input) as Map;
      input['a']!.add(2);
      expect(parsed, {
        'a': [1],
      });
      expect(() => (parsed['a'] as List).add(2), throwsUnsupportedError);
      final cycle = <Object?>[];
      cycle.add(cycle);
      expect(importJsonSchema(true).schema.safeParse(cycle).isFail, isTrue);
      expect(
        importJsonSchema(true).schema.safeParse(double.nan).isFail,
        isTrue,
      );
    });

    test(
      'fluent nullability overrides preserve parse/encode/export parity',
      () {
        for (final schema in [
          importJsonSchema({'type': 'string'}).schema.nullable(),
          importJsonSchema(true).schema.nullable(value: false),
        ]) {
          final roundTrip = importJsonSchema(schema.toJsonSchema()).schema;
          expect(schema.safeParse(null).isOk, schema.isNullable);
          expect(schema.safeEncode(null).isOk, schema.isNullable);
          expect(roundTrip.safeParse(null).isOk, schema.isNullable);
        }
      },
    );

    test(
      'resolves cross-file, escaped pointers, anchors, and recursive refs',
      () {
        final result = importJsonSchema(
          {
            r'$id': 'https://example.test/root.json',
            r'$ref': 'types.json#node',
          },
          documents: {
            Uri.parse('https://example.test/types.json'): {
              r'$defs': {
                'a/b~c': {
                  r'$anchor': 'node',
                  'type': 'object',
                  'properties': {
                    'value': {'type': 'integer'},
                    'next': {r'$ref': r'#/$defs/a~1b~0c'},
                  },
                  'required': ['value'],
                  'additionalProperties': false,
                },
              },
            },
          },
        );
        final value = {
          'value': 1,
          'next': {'value': 2},
        };
        expect(result.schema.parse(value), value);
        expect(
          result.schema.safeParse({'value': 1, 'next': {}}).isFail,
          isTrue,
        );
        final roundTrip = importJsonSchema(result.schema.toJsonSchema()).schema;
        expect(roundTrip.safeParse(value).isOk, isTrue);
        expect(roundTrip.safeParse({'value': 1, 'next': {}}).isFail, isTrue);
      },
    );

    test('reference siblings still constrain a value', () {
      final schema = importJsonSchema({
        r'$defs': {
          'n': {'type': 'number', 'minimum': 0},
        },
        r'$ref': r'#/$defs/n',
        'maximum': 2,
      }).schema;
      expect(schema.safeParse(1).isOk, isTrue);
      expect(schema.safeParse(3).isFail, isTrue);
      expect(schema.safeParse(-1).isFail, isTrue);
    });

    test(
      'reports missing refs and nonproductive cycles instead of overflowing',
      () {
        for (final document in [
          {r'$ref': 'missing.json'},
          {r'$ref': '#'},
          {
            r'$defs': {
              'a': {r'$ref': '#'},
            },
            r'$ref': r'#/$defs/a',
          },
        ]) {
          expect(
            () => importJsonSchema(document, allowUnsupported: true),
            throwsA(isA<JsonSchemaImportException>()),
          );
        }
      },
    );

    test(
      'reports meta-schema references as unsupported, not as any schema',
      () {
        final result = importJsonSchema({
          r'$ref': 'https://json-schema.org/draft/2020-12/schema',
        }, allowUnsupported: true);
        expect(result.isExact, isFalse);
        expect(result.diagnostics.single.keyword, r'$ref');
      },
    );

    test('preserves required presence, optional nulls, and open objects', () {
      final result = importJsonSchema({
        'type': 'object',
        'properties': {
          'name': {'type': 'string'},
          'nullable': {
            'type': ['string', 'null'],
          },
        },
        'required': ['name', 'unlisted'],
      });
      expect(result.isExact, isTrue);
      final schema = result.schema;
      expect(schema.safeParse({'name': 'A', 'unlisted': null}).isOk, isTrue);
      expect(schema.safeParse({'name': 'A'}).isFail, isTrue);
      expect(schema.safeParse({'name': null, 'unlisted': 1}).isFail, isTrue);
      expect(
        schema.safeParse({
          'name': 'A',
          'unlisted': 1,
          'nullable': null,
          'extra': [null],
        }).isOk,
        isTrue,
      );
    });

    test('applies keywords independently without inferring a type', () {
      final schema = importJsonSchema({
        'minimum': 2,
        'minLength': 2,
        'required': ['a'],
      }).schema;
      for (final value in [
        null,
        true,
        [],
        2,
        'ab',
        {'a': null},
      ]) {
        expect(schema.safeParse(value).isOk, isTrue, reason: '$value');
      }
      for (final value in [1, 'a', <String, Object?>{}]) {
        expect(schema.safeParse(value).isFail, isTrue, reason: '$value');
      }
    });

    test('handles JSON integers, structural enum/const, and null', () {
      expect(
        importJsonSchema({'type': 'integer'}).schema.safeParse(1.0).isOk,
        isTrue,
      );
      expect(
        importJsonSchema({'type': 'integer'}).schema.safeParse(1.5).isFail,
        isTrue,
      );
      final schema = importJsonSchema({
        'enum': [
          null,
          {
            'a': [1],
          },
        ],
      }).schema;
      expect(schema.safeParse(null).isOk, isTrue);
      expect(schema.safeEncode(null).isOk, isTrue);
      expect(
        schema.safeParse({
          'a': [1.0],
        }).isOk,
        isTrue,
      );
      expect(
        schema.safeParse({
          'a': [2],
        }).isFail,
        isTrue,
      );
      expect(
        importJsonSchema({'const': null}).schema.safeParse(0).isFail,
        isTrue,
      );
    });

    test('supports boolean schemas and nullable array items', () {
      expect(importJsonSchema(true).schema.safeParse(null).isOk, isTrue);
      expect(importJsonSchema(false).schema.safeParse(null).isFail, isTrue);
      expect(importJsonSchema(false).schema.safeEncode(null).isFail, isTrue);
      final schema = importJsonSchema({
        'type': 'array',
        'items': {
          'type': ['integer', 'null'],
        },
        'minItems': 1,
        'maxItems': 2,
        'uniqueItems': true,
      }).schema;
      expect(schema.safeParse([null, 1.0]).isOk, isTrue);
      for (final value in [
        [],
        [1, 1.0],
        [1, 2, 3],
        ['a'],
      ]) {
        expect(schema.safeParse(value).isFail, isTrue, reason: '$value');
      }
    });

    test('intersects siblings and implements exclusive composition', () {
      final schema = importJsonSchema({
        'type': 'number',
        'allOf': [
          {'minimum': 0},
          {'maximum': 10},
        ],
        'oneOf': [
          {'maximum': 4},
          {'minimum': 3},
        ],
        'not': {'const': 1},
      }).schema;
      for (final value in [0, 2, 5, 10]) {
        expect(schema.safeParse(value).isOk, isTrue, reason: '$value');
      }
      for (final value in [-1, 1, 3, 4, 11, '5', null]) {
        expect(schema.safeParse(value).isFail, isTrue, reason: '$value');
      }
    });

    test(
      'validates additional property schemas and preserves defaults as data',
      () {
        final schema = importJsonSchema({
          'type': 'object',
          'properties': {
            'name': {'type': 'string', 'default': 'A'},
          },
          'additionalProperties': {'type': 'integer'},
        }).schema;
        expect(schema.parse({'extra': 1}), {'extra': 1});
        expect(schema.safeParse({'extra': 'bad'}).isFail, isTrue);
        expect(
          importJsonSchema({
            'type': 'object',
            'additionalProperties': false,
          }).schema.safeParse({'a': null}).isFail,
          isTrue,
        );
      },
    );

    test('strict mode reports unsupported keywords at escaped locations', () {
      final document = {
        'properties': {
          'a/b': {'format': 'email', 'x-custom': true},
        },
      };
      expect(
        () => importJsonSchema(document),
        throwsA(isA<JsonSchemaImportException>()),
      );
      final result = importJsonSchema(document, allowUnsupported: true);
      expect(result.isExact, isFalse);
      expect(
        result.diagnostics.map((d) => d.pointer),
        containsAll(['#/properties/a~1b/format', '#/properties/a~1b/x-custom']),
      );
      expect(result.schema.safeParse({'a/b': 12}).isOk, isTrue);
      expect(
        result.schema.toJsonSchema().toString(),
        isNot(contains('format')),
      );
    });

    test(
      'partial import cannot tighten not or oneOf through omitted assertions',
      () {
        for (final document in [
          {
            'not': {'format': 'email'},
          },
          {
            'oneOf': [
              {'type': 'string'},
              {'format': 'email'},
            ],
          },
        ]) {
          final result = importJsonSchema(document, allowUnsupported: true);
          expect(result.isExact, isFalse);
          expect(result.schema.safeParse('hello').isOk, isTrue);
          expect(result.schema.safeParse(null).isOk, isTrue);
        }
      },
    );

    test('rejects malformed supported keywords even in partial mode', () {
      for (final document in [
        {'type': 'made-up'},
        {'required': 'a'},
        {'minItems': -1},
        {'anyOf': []},
        {'enum': 1},
        {'items': 3},
      ]) {
        expect(
          () => importJsonSchema(document, allowUnsupported: true),
          throwsA(isA<JsonSchemaImportException>()),
          reason: '$document',
        );
      }
    });
  });
}

final class _OnlyStrings extends Constraint<Object>
    with Validator<Object>, JsonSchemaSpec<Object> {
  const _OnlyStrings()
    : super(
        constraintKey: 'only_strings',
        description: 'Only strings are accepted.',
      );

  @override
  bool isValid(Object value) => value is String;

  @override
  String buildMessage(Object value) => description;

  @override
  Map<String, Object?> toJsonSchema() => {'type': 'string'};
}
