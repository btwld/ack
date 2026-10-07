import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('Ack.fromJsonSchema', () {
    test('rejects conflicting documents with equivalent retrieval URIs', () {
      final base = Uri.parse('https://example.test/root.json');
      final entries = [
        MapEntry(Uri.parse('types.json'), {'type': 'string'}),
        MapEntry(base.resolve('types.json'), {'type': 'number'}),
      ];
      for (final ordered in [entries, entries.reversed]) {
        expect(
          () => Ack.fromJsonSchema(
            {r'$ref': 'types.json'},
            baseUri: base,
            documents: Map.fromEntries(ordered),
          ),
          throwsA(isA<JsonSchemaImportException>()),
        );
      }
      expect(
        () => Ack.fromJsonSchema(
          {'type': 'string'},
          baseUri: base,
          documents: {
            base: {'type': 'number'},
          },
        ),
        throwsA(isA<JsonSchemaImportException>()),
      );
    });

    test('accepts the draft 2020-12 dialect with an empty fragment', () {
      final schema = Ack.fromJsonSchema({
        r'$schema': 'https://json-schema.org/draft/2020-12/schema#',
        'type': 'string',
      });
      expect(schema.safeParse('hello').isOk, isTrue);
      expect(schema.safeParse(1).isFail, isTrue);
    });

    test('rejects non-empty dialect fragments and different drafts', () {
      for (final dialect in [
        'https://json-schema.org/draft/2020-12/schema#other',
        'https://json-schema.org/draft/2019-09/schema#',
      ]) {
        expect(
          () => Ack.fromJsonSchema({r'$schema': dialect}),
          throwsA(isA<JsonSchemaImportException>()),
        );
      }
    });

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
            () => Ack.fromJsonSchema(document),
            throwsA(isA<JsonSchemaImportException>()),
          );
        }
      },
    );

    test(
      'added constraints do not become ignored Draft-7 reference siblings',
      () {
        final schema = Ack.fromJsonSchema(true).constrain(_OnlyStrings());
        expect(schema.safeParse('ok').isOk, isTrue);
        expect(schema.safeParse(1).isFail, isTrue);
        expect(schema.safeParse(null).isOk, isTrue);
        final exported = schema.toJsonSchema();
        // Draft-7 ignores every sibling of $ref. A root reference here would
        // silently discard the additional, exported `type: string` assertion.
        expect(exported.containsKey(r'$ref'), isFalse);
        final branches = exported['anyOf'] as List<Object?>;
        final constrained = branches
            .whereType<Map<String, Object?>>()
            .singleWhere((branch) => branch['type'] == 'string');
        expect(constrained, isNot(contains(r'$ref')));
        final referenceEnvelope = constrained['allOf'] as List<Object?>;
        expect(referenceEnvelope, hasLength(1));
        expect(
          referenceEnvelope.single,
          isA<Map<String, Object?>>().having(
            (reference) => reference[r'$ref'],
            r'$ref',
            isA<String>(),
          ),
        );
        expect(Ack.fromJsonSchema(exported).safeParse(1).isFail, isTrue);
        expect(Ack.fromJsonSchema(exported).safeParse(null).isOk, isTrue);
        expect(schema.toSchemaModel().toJsonSchema(), exported);
      },
    );

    test('source descriptions are available through the Ack schema API', () {
      final schema = Ack.fromJsonSchema({
        'type': 'string',
        'description': 'A protocol field',
      });
      expect(schema.description, 'A protocol field');
      expect(schema.describe('Override').description, 'Override');
    });

    test(
      'resolves catalog schemas stored outside standard schema containers',
      () {
        final schema = Ack.fromJsonSchema(
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
        );
        expect(schema.safeParse({'text': 'Hello'}).isOk, isTrue);
        expect(schema.safeParse({'text': 1}).isFail, isTrue);
        expect(
          Ack.fromJsonSchema(
            schema.toJsonSchema(),
          ).safeParse({'text': 1}).isFail,
          isTrue,
        );
      },
    );

    test('only reachable assertions affect strictness and diagnostics', () {
      final schema = Ack.fromJsonSchema(
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
      expect(schema.safeParse('hello').isOk, isTrue);
    });

    test('empty and repeated enum values export as valid Draft-7 schemas', () {
      final never = Ack.fromJsonSchema({'enum': []});
      for (final value in [null, 1, 'x', [], <String, Object?>{}]) {
        expect(never.safeParse(value).isFail, isTrue);
        expect(
          Ack.fromJsonSchema(never.toJsonSchema()).safeParse(value).isFail,
          isTrue,
        );
      }
      final repeated = Ack.fromJsonSchema({
        'enum': [1, 1.0, 'x', 'x'],
      });
      expect(repeated.safeParse(1).isOk, isTrue);
      final definitions = repeated.toJsonSchema()['definitions'] as Map;
      expect((definitions.values.first as Map)['enum'], [1, 'x']);
      final falseDefinitions = never.toJsonSchema()['definitions'] as Map;
      expect(falseDefinitions.values.first, {'not': <String, Object?>{}});
    });

    test('pattern and propertyNames validate and export verbatim', () {
      final schema = Ack.fromJsonSchema({
        'properties': {
          'name': {'pattern': r'^a+$'},
        },
        'propertyNames': {'maxLength': 4},
      });
      const accepted = {'name': 'aaa'};
      const badPattern = {'name': 'bbb'};
      const badPropertyName = {'name': 'aaa', 'other': 1};
      expect(schema.safeParse(accepted).isOk, isTrue);
      expect(schema.safeParse(badPattern).isFail, isTrue);
      expect(schema.safeParse(badPropertyName).isFail, isTrue);
      // "pattern" is skipped rather than failed for non-strings.
      expect(schema.safeParse({'name': 42}).isOk, isTrue);

      final export = schema.toJsonSchema();
      final definitions = (export['definitions'] as Map).values.cast<Map>();
      expect(definitions.any((d) => d['pattern'] == r'^a+$'), isTrue);
      expect(
        definitions.any((d) => (d['propertyNames'] as Map?)?[r'$ref'] != null),
        isTrue,
      );
      final roundTrip = Ack.fromJsonSchema(export);
      expect(roundTrip.safeParse(accepted).isOk, isTrue);
      expect(roundTrip.safeParse(badPattern).isFail, isTrue);
      expect(roundTrip.safeParse(badPropertyName).isFail, isTrue);
    });

    test('pattern compiles in ECMA-262 Unicode mode', () {
      final single = Ack.fromJsonSchema({'pattern': r'^.$'});
      expect(single.safeParse('😀').isOk, isTrue);
      expect(single.safeParse('😀😀').isFail, isTrue);

      expect(
        () => Ack.fromJsonSchema({'pattern': r'^\d{3}\-\d{4}$'}),
        throwsA(
          isA<JsonSchemaImportException>().having(
            (e) => e.diagnostics.single.pointer,
            'pointer',
            '#/pattern',
          ),
        ),
      );
    });

    test('reference failures include source URI and keyword location', () {
      try {
        Ack.fromJsonSchema({
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
          () => Ack.fromJsonSchema(document),
          throwsA(isA<JsonSchemaImportException>()),
        );
      }
    });

    test('attributes duplicate anchors to the second anchor keyword', () {
      final documentUri = Uri.parse('https://example.test/anchors.json');
      expect(
        () => Ack.fromJsonSchema({
          r'$defs': {
            'a': {r'$anchor': 'dup'},
            'b': {r'$anchor': 'dup'},
          },
        }, baseUri: documentUri),
        throwsA(
          isA<JsonSchemaImportException>().having(
            (error) => error.diagnostics.last,
            'diagnostic',
            isA<JsonSchemaImportDiagnostic>()
                .having((issue) => issue.keyword, 'keyword', r'$anchor')
                .having(
                  (issue) => issue.pointer,
                  'pointer',
                  r'#/$defs/b/$anchor',
                )
                .having(
                  (issue) => issue.documentUri,
                  'documentUri',
                  documentUri,
                ),
          ),
        ),
      );
    });

    test('attributes duplicate resource IDs to the second id keyword', () {
      final documentUri = Uri.parse('https://example.test/resources.json');
      expect(
        () => Ack.fromJsonSchema({
          r'$defs': {
            'a': {r'$id': 'duplicate.json'},
            'b': {r'$id': 'duplicate.json'},
          },
        }, baseUri: documentUri),
        throwsA(
          isA<JsonSchemaImportException>().having(
            (error) => error.diagnostics.last,
            'diagnostic',
            isA<JsonSchemaImportDiagnostic>()
                .having((issue) => issue.keyword, 'keyword', r'$id')
                .having((issue) => issue.pointer, 'pointer', r'#/$defs/b/$id')
                .having(
                  (issue) => issue.documentUri,
                  'documentUri',
                  documentUri,
                ),
          ),
        ),
      );
    });

    test('runtime errors keep the failing instance path', () {
      final schema = Ack.fromJsonSchema({
        'properties': {
          'a/b': {
            'items': {'type': 'string'},
          },
        },
      });
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

    test('propertyNames errors keep the failing property path', () {
      final schema = Ack.fromJsonSchema({
        'propertyNames': {'maxLength': 3},
      });
      final error = schema.safeParse({'foobar': 1}).getError();
      expect(error.context.path, '#/foobar');
      expect(error.value, 'foobar');
      expect(error.toMap()['value'], 'foobar');
    });

    test('runtime errors expose the failing keyword and its location', () {
      final schema = Ack.fromJsonSchema({
        'type': 'object',
        'properties': {
          'tags': {
            'type': 'array',
            'items': {
              'enum': ['x', 'y'],
            },
          },
        },
      });
      final error =
          schema.safeParse({
                'tags': ['x', 'z'],
              }).getError()
              as JsonSchemaValidationError;
      expect(error.keyword, 'enum');
      expect(error.documentUri, Uri.parse('ack-import:///root.json'));
      expect(error.pointer, '#/properties/tags/items/enum');
      expect(error.path, '#/tags/1');
      expect(
        error.toMap(),
        allOf(
          containsPair('keyword', 'enum'),
          containsPair('documentUri', 'ack-import:///root.json'),
          containsPair('pointer', '#/properties/tags/items/enum'),
        ),
      );
    });

    test('runtime error locations follow references across documents', () {
      final schema = Ack.fromJsonSchema(
        {
          'properties': {
            'a': {r'$ref': r'defs.json#/$defs/a~1b'},
            'b': {
              'properties': {'c': false},
            },
          },
          'required': ['a'],
        },
        baseUri: Uri.parse('https://example.test/root.json'),
        documents: {
          Uri.parse('https://example.test/defs.json'): {
            r'$defs': {
              'a/b': {'type': 'string'},
            },
          },
        },
      );
      JsonSchemaValidationError failure(Object value) =>
          schema.safeParse(value).getError() as JsonSchemaValidationError;

      final type = failure({'a': 1});
      expect(type.keyword, 'type');
      expect(type.documentUri, Uri.parse('https://example.test/defs.json'));
      expect(type.pointer, r'#/$defs/a~1b/type');
      expect(type.path, '#/a');

      final rejected = failure({
        'a': 'ok',
        'b': {'c': 1},
      });
      expect(rejected.keyword, isEmpty);
      expect(rejected.documentUri, Uri.parse('https://example.test/root.json'));
      expect(rejected.pointer, '#/properties/b/properties/c');
      expect(rejected.message, contains('"false" failed'));

      final missing = failure(<String, Object?>{});
      expect(missing.keyword, 'required');
      expect(missing.pointer, '#/required');
      expect(missing.path, '#/a');
    });

    group('error locations use URI fragment encoding', () {
      for (final entry in {
        '%': '%25',
        '%2F': '%252F',
        ' ': '%20',
        '#': '%23',
        '☃😀': '%E2%98%83%F0%9F%98%80',
        '/': '~1',
        '~': '~0',
        '~1': '~01',
      }.entries) {
        test('runtime keyword location for "${entry.key}"', () {
          final schema = Ack.fromJsonSchema({
            'properties': {
              entry.key: {'type': 'string'},
            },
          });
          expect(schema.safeParse({entry.key: 'ok'}).isOk, isTrue);
          for (final result in [
            schema.safeParse({entry.key: 42}),
            schema.safeEncode({entry.key: 42}),
          ]) {
            final error = result.getError() as JsonSchemaValidationError;
            final pointer = '#/properties/${entry.value}/type';
            expect(error.keyword, 'type');
            expect(error.pointer, pointer);
            expect(error.toMap(), containsPair('pointer', pointer));
            expect(error.value, 42);
          }
        });

        test('referenced false schema location for "${entry.key}"', () {
          final documentUri = Uri.parse('https://example.test/defs.json');
          final schema = Ack.fromJsonSchema(
            {r'$ref': 'child.json#/properties/${entry.value}'},
            baseUri: Uri.parse('https://example.test/root.json'),
            documents: {
              documentUri: {
                r'$defs': {
                  'resource': {
                    r'$id': 'child.json',
                    'properties': {entry.key: false},
                  },
                },
              },
            },
          );
          final error =
              schema.safeParse(42).getError() as JsonSchemaValidationError;
          expect(error.keyword, isEmpty);
          expect(error.documentUri, documentUri);
          expect(error.pointer, '#/\$defs/resource/properties/${entry.value}');
          expect(error.path, '#');
        });

        test('import diagnostic location for "${entry.key}"', () {
          expect(
            () => Ack.fromJsonSchema({
              'properties': {
                entry.key: {'type': 'invalid'},
              },
            }),
            throwsA(
              isA<JsonSchemaImportException>().having(
                (error) => error.diagnostics.single.pointer,
                'pointer',
                '#/properties/${entry.value}/type',
              ),
            ),
          );
        });
      }

      test('root false schema keeps the empty fragment', () {
        final error =
            Ack.fromJsonSchema(false).safeParse(42).getError()
                as JsonSchemaValidationError;
        expect(error.keyword, isEmpty);
        expect(error.pointer, '#');
      });
    });

    test('recursive validation has no hidden Ack.lazy depth limit', () {
      final schema = Ack.fromJsonSchema({
        'type': 'object',
        'properties': {
          'child': {r'$ref': '#'},
        },
      });
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
          final schema = Ack.fromJsonSchema({
            r'$defs': {
              entry.value: {'const': 'yes'},
            },
            r'$ref': entry.key,
          });
          expect(schema.safeParse('yes').isOk, isTrue, reason: entry.key);
          expect(schema.safeParse('no').isFail, isTrue, reason: entry.key);
        }
      },
    );

    test(
      'nested IDs change ref scope without scanning literal data for IDs',
      () {
        final schema = Ack.fromJsonSchema(
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
        );
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
          Ack.fromJsonSchema(
            document,
            baseUri: uri,
            documents: {uri: document},
          ).safeParse('ok').isOk,
          isTrue,
        );
      },
    );

    test('schema documents and parsed values are detached snapshots', () {
      final types = ['string'];
      final document = {'type': types};
      final schema = Ack.fromJsonSchema(document);
      types.add('number');
      expect(schema.safeParse(1).isFail, isTrue);
      final input = {
        'a': [1],
      };
      final parsed = Ack.fromJsonSchema(true).parse(input) as Map;
      input['a']!.add(2);
      expect(parsed, {
        'a': [1],
      });
      expect(() => (parsed['a'] as List).add(2), throwsUnsupportedError);
      final cycle = <Object?>[];
      cycle.add(cycle);
      expect(Ack.fromJsonSchema(true).safeParse(cycle).isFail, isTrue);
      expect(Ack.fromJsonSchema(true).safeParse(double.nan).isFail, isTrue);
    });

    test('parse and encode reject the same non-JSON values', () {
      final schema = Ack.fromJsonSchema(true);
      final cycle = <String, Object?>{};
      cycle['self'] = [cycle];
      for (final value in <Object>[
        {1: 'a'},
        {
          'a': [double.infinity],
        },
        cycle,
        [DateTime(2026)],
      ]) {
        final parsed = schema.safeParse(value);
        final encoded = schema.safeEncode(value);
        expect(parsed.isFail, isTrue, reason: '$value');
        expect(encoded.isFail, isTrue, reason: '$value');
        expect(parsed.getError().message, encoded.getError().message);
      }
      final shared = ['x'];
      final parsed = schema.parse({'a': shared, 'b': shared}) as Map;
      expect(parsed, {
        'a': ['x'],
        'b': ['x'],
      });
      expect(() => parsed['c'] = 1, throwsUnsupportedError);
    });

    test(
      'fluent nullability overrides preserve parse/encode/export parity',
      () {
        for (final schema in [
          Ack.fromJsonSchema({'type': 'string'}).nullable(),
          Ack.fromJsonSchema(true).nullable(value: false),
        ]) {
          final roundTrip = Ack.fromJsonSchema(schema.toJsonSchema());
          expect(schema.safeParse(null).isOk, schema.isNullable);
          expect(schema.safeEncode(null).isOk, schema.isNullable);
          expect(roundTrip.safeParse(null).isOk, schema.isNullable);
        }
      },
    );

    test(
      'resolves cross-file, escaped pointers, anchors, and recursive refs',
      () {
        final schema = Ack.fromJsonSchema(
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
        expect(schema.parse(value), value);
        expect(schema.safeParse({'value': 1, 'next': {}}).isFail, isTrue);
        final roundTrip = Ack.fromJsonSchema(schema.toJsonSchema());
        expect(roundTrip.safeParse(value).isOk, isTrue);
        expect(roundTrip.safeParse({'value': 1, 'next': {}}).isFail, isTrue);
      },
    );

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
            () => Ack.fromJsonSchema(document),
            throwsA(isA<JsonSchemaImportException>()),
          );
        }
      },
    );

    test('conditional reference cycles are nonproductive', () {
      for (final keyword in ['if', 'then', 'else']) {
        expect(
          () => Ack.fromJsonSchema({
            r'$defs': {
              'a': {
                'if': true,
                keyword: {r'$ref': r'#/$defs/a'},
              },
            },
            r'$ref': r'#/$defs/a',
          }),
          throwsA(
            isA<JsonSchemaImportException>().having(
              (e) => e.diagnostics.single.code,
              'code',
              'nonproductive_reference_cycle',
            ),
          ),
          reason: keyword,
        );
      }
    });

    test('contains and then report their failure locations', () {
      final schema = Ack.fromJsonSchema({
        'properties': {
          'tags': {
            'contains': {'const': 'x'},
          },
          'pet': {
            'if': {
              'properties': {
                'kind': {'const': 'dog'},
              },
            },
            'then': {
              'required': ['breed'],
            },
          },
        },
      });
      final noMatch = schema.safeParse({
        'tags': ['y'],
      }).getError();
      expect(noMatch.path, '#/tags');
      expect(
        noMatch,
        isA<JsonSchemaValidationError>()
            .having((e) => e.keyword, 'keyword', 'contains')
            .having((e) => e.pointer, 'pointer', '#/properties/tags/contains'),
      );

      final thenError = schema.safeParse({
        'pet': {'kind': 'dog'},
      }).getError();
      expect(thenError.path, '#/pet/breed');
      expect(
        thenError,
        isA<JsonSchemaValidationError>()
            .having((e) => e.keyword, 'keyword', 'required')
            .having(
              (e) => e.pointer,
              'pointer',
              '#/properties/pet/then/required',
            ),
      );
    });

    test(
      'reports meta-schema references as unsupported, not as any schema',
      () {
        expect(
          () => Ack.fromJsonSchema({
            r'$ref': 'https://json-schema.org/draft/2020-12/schema',
          }),
          throwsA(
            isA<JsonSchemaImportException>().having(
              (error) => error.diagnostics.single.keyword,
              'keyword',
              r'$ref',
            ),
          ),
        );
      },
    );

    test('strict mode reports unsupported keywords at escaped locations', () {
      final document = {
        'properties': {
          'a/b': {'format': 'email', 'x-custom': true},
        },
      };
      try {
        Ack.fromJsonSchema(document);
        fail('Expected unsupported keyword diagnostics.');
      } on JsonSchemaImportException catch (error) {
        expect(
          error.diagnostics.map((diagnostic) => diagnostic.pointer),
          containsAll([
            '#/properties/a~1b/format',
            '#/properties/a~1b/x-custom',
          ]),
        );
      }
    });

    test('rejects malformed supported keywords', () {
      for (final document in [
        {'type': 'made-up'},
        {'required': 'a'},
        {'minItems': -1},
        {'anyOf': []},
        {'enum': 1},
        {'items': 3},
        {'pattern': 1},
        {'pattern': '('},
      ]) {
        expect(
          () => Ack.fromJsonSchema(document),
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
