import 'package:ack/ack.dart';
import 'package:test/test.dart';

const _standardDialect = 'https://json-schema.org/draft/2020-12/schema';
const _vocabularyPrefix = 'https://json-schema.org/draft/2020-12/vocab/';
final _dialectUri = Uri.parse('https://example.test/meta/custom');

Map<String, Object?> _dialect(List<String> vocabularies) => {
  r'$id': _dialectUri.toString(),
  r'$schema': _standardDialect,
  r'$vocabulary': {
    '${_vocabularyPrefix}core': true,
    for (final vocabulary in vocabularies)
      '$_vocabularyPrefix$vocabulary': true,
  },
};

AckSchema<Object, Object> _import(
  Map<String, Object?> source, {
  List<String> vocabularies = const ['validation'],
  bool assertFormats = false,
}) => Ack.fromJsonSchema(
  {r'$schema': _dialectUri.toString(), ...source},
  documents: {_dialectUri: _dialect(vocabularies)},
  assertFormats: assertFormats,
);

Iterable<Map<String, Object?>> _maps(Object? value) sync* {
  if (value is Map<String, Object?>) {
    yield value;
    for (final child in value.values) {
      yield* _maps(child);
    }
  } else if (value is List) {
    for (final child in value) {
      yield* _maps(child);
    }
  }
}

const _officialFormatAnnotationMetaSchema = <String, Object?>{
  r'$schema': _standardDialect,
  r'$id': 'https://json-schema.org/draft/2020-12/meta/format-annotation',
  r'$dynamicAnchor': 'meta',
  'title': 'Format vocabulary meta-schema for annotation results',
  'type': ['object', 'boolean'],
  'properties': {
    'format': {'type': 'string'},
  },
};

void main() {
  group('inactive vocabulary keywords are annotations', () {
    final applicatorCases = <String, Object?>{
      'properties': false,
      'patternProperties': 'annotation',
      'dependentSchemas': 42,
      'items': 'annotation',
      'additionalProperties': [],
      'not': 42,
      'contains': 'annotation',
      'propertyNames': null,
      'if': [],
      'then': null,
      'else': 'annotation',
      'allOf': [],
      'anyOf': false,
      'oneOf': 'annotation',
      'prefixItems': {},
    };
    for (final entry in applicatorCases.entries) {
      test('does not interpret inactive ${entry.key}', () {
        final schema = _import({'type': 'string', entry.key: entry.value});
        expect(schema.safeParse('ok').isOk, isTrue);
        expect(schema.safeParse(1).isFail, isTrue);
        final exported = schema.toJsonSchema();
        expect(exported[entry.key], entry.value);
        final restored = Ack.fromJsonSchema(exported);
        expect(restored.safeParse('ok').isOk, isTrue);
        expect(restored.safeParse(1).isFail, isTrue);
      });
    }

    test(
      'does not register identifiers or resolve references in annotations',
      () {
        final annotation = {
          'notASchema': {
            r'$id': 'https://example.test/real',
            r'$ref': 'https://example.test/not-supplied',
          },
          'alsoNotASchema': {r'$id': 42},
        };
        final schema = _import({
          'type': 'string',
          'properties': annotation,
          r'$defs': {
            'real': {r'$id': 'https://example.test/real', 'type': 'string'},
          },
        });
        expect(schema.parse('ok'), 'ok');
        expect(schema.toJsonSchema()['properties'], annotation);
      },
    );

    test(
      'does not validate inactive validation, metadata, or content syntax',
      () {
        final source = <String, Object?>{
          'type': 42,
          'enum': 'annotation',
          'minimum': false,
          'multipleOf': 0,
          'minLength': 'annotation',
          'required': false,
          'dependentRequired': [],
          'uniqueItems': 'annotation',
          'description': 42,
          'readOnly': 'annotation',
          'examples': false,
          'format': false,
          'contentSchema': 'annotation',
          'unevaluatedProperties': 'annotation',
          'unevaluatedItems': 42,
        };
        final schema = _import(source, vocabularies: []);
        final restored = Ack.fromJsonSchema(schema.toJsonSchema());
        for (final value in <Object?>[null, 1, 'text', {}, []]) {
          expect(schema.safeParse(value).isOk, isTrue);
          expect(restored.safeParse(value).isOk, isTrue);
        }
        for (final entry in source.entries) {
          expect(schema.toJsonSchema()[entry.key], entry.value);
        }
      },
    );
  });

  test('still validates the syntax of active vocabularies', () {
    for (final testCase in [
      (
        vocabulary: 'applicator',
        source: <String, Object?>{'properties': false},
      ),
      (vocabulary: 'validation', source: <String, Object?>{'minLength': 'bad'}),
      (vocabulary: 'meta-data', source: <String, Object?>{'description': 42}),
      (vocabulary: 'content', source: <String, Object?>{'contentSchema': 42}),
      (
        vocabulary: 'unevaluated',
        source: <String, Object?>{'unevaluatedItems': 'bad'},
      ),
      (
        vocabulary: 'format-annotation',
        source: <String, Object?>{'format': 42},
      ),
    ]) {
      expect(
        () => _import(testCase.source, vocabularies: [testCase.vocabulary]),
        throwsA(isA<JsonSchemaImportException>()),
      );
    }
    expect(
      () => _import({'format': 42}, vocabularies: [], assertFormats: true),
      throwsA(isA<JsonSchemaImportException>()),
    );
  });

  test(
    'core definitions remain schemas regardless of optional vocabularies',
    () {
      expect(
        () => _import({
          r'$defs': {'invalid': 42},
        }, vocabularies: []),
        throwsA(isA<JsonSchemaImportException>()),
      );
    },
  );

  test('explicit references can target schemas inside inert containers', () {
    final schema = _import({
      r'$ref': '#/properties/target',
      'properties': {
        'target': {'type': 'string', 'minLength': 2},
      },
    });
    expect(schema.safeParse('ok').isOk, isTrue);
    expect(schema.safeParse('x').isFail, isTrue);
    expect(schema.safeParse(1).isFail, isTrue);
  });

  test('a dialect can be indexed after the schema that selects it', () {
    final catalogUri = Uri.parse('https://example.test/catalog');
    for (final container in [r'$defs', 'properties']) {
      final schema = Ack.fromJsonSchema(
        {
          r'$schema': _dialectUri.toString(),
          'type': 'string',
          'properties': false,
        },
        documents: {
          catalogUri: {
            container: {
              'customDialect': _dialect(['validation']),
            },
          },
        },
      );
      expect(schema.parse('ok'), 'ok');
      expect(schema.safeParse(1).isFail, isTrue);
    }
  });

  test('nullable export does not rewrite references in inert containers', () {
    const id = 'https://example.test/nullable-source';
    final annotation = {
      'notASchema': {r'$ref': '#'},
    };
    final schema = _import({
      r'$id': id,
      'type': 'string',
      'properties': annotation,
    }).nullable();
    final resource = _maps(
      schema.toJsonSchema(),
    ).where((map) => map[r'$id'] == id).single;
    // The source may be enveloped, but its annotation payload is unchanged.
    final properties =
        resource['properties'] ??
        _maps(
          resource,
        ).firstWhere((map) => map.containsKey('properties'))['properties'];
    expect(properties, annotation);
  });

  test('composed export does not register or rewrite inert resource IDs', () {
    const id = 'https://example.test/composed-source';
    const realId = 'https://example.test/real-resource';
    final annotation = {
      'notASchema': {r'$id': realId, r'$ref': '#', 'type': 'integer'},
    };
    final schema = Ack.object({
      'value': _import({
        r'$id': id,
        'type': 'string',
        'properties': annotation,
        r'$defs': {
          'real': {r'$id': realId, 'type': 'string'},
        },
      }),
    });
    final exported = schema.toJsonSchema();
    final resource = _maps(exported).where((map) => map[r'$id'] == id).single;
    expect(resource['properties'], annotation);
    final restored = Ack.fromJsonSchema(exported);
    expect(restored.safeParse({'value': 'ok'}).isOk, isTrue);
    expect(restored.safeParse({'value': 1}).isFail, isTrue);
  });

  test('fluent null policies use operators from an active dialect', () {
    final widened = _import({'type': 'string'}).nullable();
    final narrowed = _import({}, vocabularies: []).nullable(value: false);
    final wrapped = _import({}, vocabularies: [])
        .codec<Object>(decode: (value) => value, encode: (value) => value)
        .nullable(value: false);
    final defaulted = _import({
      'type': ['string', 'null'],
    }).withDefault('fallback');
    for (final schema in [widened, narrowed, wrapped, defaulted]) {
      for (final exported in [
        schema.toJsonSchema(),
        schema.toJsonSchemaDraft7(),
      ]) {
        final restored = Ack.fromJsonSchema(exported);
        for (final value in <Object?>[null, 'ok', 42, {}]) {
          expect(
            restored.safeParse(value).isOk,
            schema.safeParse(value).isOk,
            reason: '$value exported as $exported',
          );
        }
      }
    }
  });

  test(
    'inactive modern keywords do not block semantics-preserving Draft-7',
    () {
      final schema = _import({
        'type': 'string',
        'prefixItems': 'annotation',
        'unevaluatedItems': false,
        'format': 42,
      });
      final restored = Ack.fromJsonSchema(schema.toJsonSchemaDraft7());
      expect(restored.safeParse('ok').isOk, isTrue);
      expect(restored.safeParse(1).isFail, isTrue);
    },
  );

  test('identical supplied official resources precede bundled fallbacks', () {
    for (final container in [r'$defs', 'properties']) {
      final schema = Ack.fromJsonSchema(
        {r'$ref': _officialFormatAnnotationMetaSchema[r'$id']},
        documents: {
          Uri.parse('https://example.test/catalog'): {
            container: {'official': _officialFormatAnnotationMetaSchema},
          },
        },
      );
      expect(schema.safeParse({'format': 'email'}).isOk, isTrue);
      expect(schema.safeParse({'format': 42}).isFail, isTrue);
    }
  });

  test(
    'caller resource conflicts still fail instead of replacing fallbacks',
    () {
      for (final resources in [
        {
          'different': {
            ..._officialFormatAnnotationMetaSchema,
            'title': 'A different definition using the same official ID',
          },
        },
        {
          'first': _officialFormatAnnotationMetaSchema,
          'second': _officialFormatAnnotationMetaSchema,
        },
      ]) {
        expect(
          () => Ack.fromJsonSchema(
            {'type': 'string'},
            documents: {
              Uri.parse('https://example.test/catalog'): {
                'properties': resources,
              },
            },
          ),
          throwsA(isA<JsonSchemaImportException>()),
        );
      }
    },
  );

  test('custom format assertion exports add only the requested vocabulary', () {
    for (final validation in [false, true]) {
      final schema = _import(
        {
          'type': validation ? 'string' : 42,
          'format': 'email',
          'allOf': [false],
          'properties': false,
        },
        vocabularies: [if (validation) 'validation'],
        assertFormats: true,
      );
      final restored = Ack.fromJsonSchema(schema.toJsonSchema());
      for (final candidate in [
        (value: 'alice@example.com', valid: true),
        (value: 'not-an-email', valid: false),
        (value: 42, valid: !validation),
      ]) {
        expect(schema.safeParse(candidate.value).isOk, candidate.valid);
        expect(restored.safeParse(candidate.value).isOk, candidate.valid);
      }
    }
  });

  test('custom assertion dialects retain aliases and compose consistently', () {
    const canonical = 'https://example.test/meta/canonical';
    final retrieval = Uri.parse('https://example.test/meta/retrieval');
    const originalVocabulary = {
      '${_vocabularyPrefix}core': true,
      '${_vocabularyPrefix}validation': true,
      '${_vocabularyPrefix}format-annotation': false,
    };
    final schema = Ack.fromJsonSchema(
      {
        r'$id': 'https://example.test/aliased-source',
        r'$schema': retrieval.toString(),
        'type': 'string',
        'format': 'email',
        'properties': false,
      },
      documents: {
        retrieval: {
          r'$id': canonical,
          r'$schema': _standardDialect,
          r'$vocabulary': originalVocabulary,
        },
      },
      assertFormats: true,
    );
    final exported = schema.toJsonSchema();
    expect(schema.toJsonSchema(), exported);
    final originalDialect = _maps(
      exported,
    ).where((map) => map[r'$id'] == canonical).single;
    expect(originalDialect[r'$vocabulary'], originalVocabulary);

    for (final testCase in [
      (
        schema: Ack.fromJsonSchema(exported),
        valid: 'alice@example.com',
        invalid: 'not-an-email',
      ),
      (
        schema: Ack.fromJsonSchema(
          Ack.object({'first': schema, 'second': schema}).toJsonSchema(),
        ),
        valid: {'first': 'alice@example.com', 'second': 'bob@example.com'},
        invalid: {'first': 'alice@example.com', 'second': 'not-an-email'},
      ),
    ]) {
      expect(testCase.schema.safeParse(testCase.valid).isOk, isTrue);
      expect(testCase.schema.safeParse(testCase.invalid).isFail, isTrue);
    }
  });
}
