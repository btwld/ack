import 'package:ack_generator/src/json_schema/json_schema_generation_exception.dart';
import 'package:ack_generator/src/json_schema/json_schema_library.dart';
import 'package:test/test.dart';

final _uri = Uri.parse('package:test_pkg/model.schema.json');

AckJsonSchemaLibrary _generate(
  Object? document, {
  AckUnknownPropertiesMode unknownProperties = AckUnknownPropertiesMode.schema,
  AckJsonSchemaModelMode modelMode = AckJsonSchemaModelMode.auto,
}) => generateAckSchemaLibrary(
  document: document,
  documentUri: _uri,
  partStem: 'model.schema',
  includeParts: false,
  options: AckJsonSchemaLibraryOptions(
    unknownProperties: unknownProperties,
    modelMode: modelMode,
  ),
);

Map<String, Object?> _model(
  Map<String, Object?> properties, {
  List<String> required = const [],
}) => {
  r'$defs': {
    'Model': {
      'type': 'object',
      'properties': properties,
      if (required.isNotEmpty) 'required': required,
    },
  },
};

/// The generated source without whitespace or formatter trailing commas, so
/// expectations don't depend on line breaks.
String _squash(String source) => source
    .replaceAll(RegExp(r'\s'), '')
    .replaceAll(',)', ')')
    .replaceAll(',}', '}')
    .replaceAll(',]', ']');

String _field(Object? schema, {bool required = false}) => _squash(
  _generate(_model({'f': schema}, required: [if (required) 'f'])).source,
);

List<AckJsonSchemaDiagnostic> _diagnostics(Object? document) {
  try {
    _generate(document);
  } on AckJsonSchemaGenerationException catch (error) {
    return error.diagnostics;
  }
  fail('Expected generation to fail.');
}

Matcher _diagnostic(String pointer, String message) =>
    isA<AckJsonSchemaDiagnostic>()
        .having((d) => d.pointer, 'pointer', pointer)
        .having((d) => d.message, 'message', contains(message));

void main() {
  group('maps', () {
    final rows = <String, (Object?, String)>{
      'a string': ({'type': 'string'}, "'f':ack.Ack.string().optional()"),
      'string length bounds': (
        {'type': 'string', 'minLength': 2, 'maxLength': 8},
        'ack.Ack.string().minLength(2).maxLength(8).optional()',
      ),
      'an escaped pattern': (
        {'type': 'string', 'pattern': r'^[A-Z]{2}-\d+$'},
        r"ack.Ack.string().matches('^[A-Z]{2}-\\d+\$')",
      ),
      'integer bounds': (
        {'type': 'integer', 'minimum': 1, 'maximum': 9},
        'ack.Ack.integer().min(1).max(9)',
      ),
      'fractional integer bounds inward': (
        {'type': 'integer', 'minimum': 1.5, 'exclusiveMaximum': 4.5},
        'ack.Ack.integer().min(2).max(4)',
      ),
      'integral exclusive integer bounds': (
        {'type': 'integer', 'exclusiveMinimum': 0, 'exclusiveMaximum': 5},
        'ack.Ack.integer().greaterThan(0).lessThan(5)',
      ),
      'a number as num': (
        {'type': 'number', 'minimum': 0, 'exclusiveMaximum': 1.5},
        'ack.Ack.number().min(0).lessThan(1.5)',
      ),
      'a boolean': ({'type': 'boolean'}, 'ack.Ack.boolean()'),
      'a deduped enum with null': (
        {
          'enum': ['A', 'B', 'A', null],
        },
        "ack.Ack.enumString(['A','B']).nullable()",
      ),
      'a string-typed enum ignoring a null member': (
        {
          'type': 'string',
          'enum': ['A', null],
        },
        "ack.Ack.enumString(['A']).optional()",
      ),
      'a string const': ({'const': 'x'}, "ack.Ack.literal('x')"),
      'array bounds and uniqueness': (
        {
          'type': 'array',
          'items': {'type': 'string'},
          'minItems': 1,
          'maxItems': 3,
          'uniqueItems': true,
        },
        'ack.Ack.list(ack.Ack.string()).minItems(1).maxItems(3).unique()',
      ),
      'anyOf with null': (
        {
          'anyOf': [
            {'type': 'string'},
            {'type': 'null'},
          ],
        },
        'ack.Ack.string().nullable()',
      ),
      'a nullable type list': (
        {
          'type': ['integer', 'null'],
        },
        'ack.Ack.integer().nullable()',
      ),
      'a nested scalar union': (
        {
          'anyOf': [
            {
              'anyOf': [
                {'type': 'string'},
                {'type': 'number'},
              ],
            },
            {'type': 'null'},
          ],
        },
        'ack.Ack.any().refine((value)=>valueisString||valueisnum,'
            "message:'Expectedastringoranumber.').nullable()",
      ),
      'the empty schema': (<String, Object?>{}, 'ack.Ack.any().nullable()'),
      'a map with typed values': (
        {
          'type': 'object',
          'propertyNames': {'type': 'string'},
          'additionalProperties': {'type': 'integer'},
        },
        'ack.Ack.map(ack.Ack.integer())',
      ),
      'an open map': (
        {'type': 'object'},
        'ack.Ack.map(ack.Ack.any().nullable())',
      ),
      'a description with special characters': (
        {'type': 'string', 'description': "It's \$5\n\\ok"},
        r"ack.Ack.string().describe('It\'s\$5\n\\ok')",
      ),
    };
    for (final MapEntry(key: name, value: (schema, expected)) in rows.entries) {
      test(name, () => expect(_field(schema), contains(expected)));
    }

    test('a required property without optional()', () {
      expect(
        _field({'type': 'string'}, required: true),
        contains("'f':ack.Ack.string()}"),
      );
    });

    test('an inline object as a hoisted named model', () {
      final source = _field({
        'type': 'object',
        'properties': {
          'city': {'type': 'string'},
        },
        'additionalProperties': false,
      });
      expect(source, contains("'f':modelFSchema.optional()"));
      expect(
        source,
        contains(
          "@ack_annotations.AckInfer(name:'ModelF')finalmodelFSchema="
          "ack.Ack.object({'city':ack.Ack.string().optional()})",
        ),
      );
    });

    test(r'a $ref as the referenced model', () {
      final source = _squash(
        _generate({
          r'$defs': {
            'Model': {
              'type': 'object',
              'properties': {
                'photo': {r'$ref': r'#/$defs/Photo'},
              },
            },
            'Photo': {'type': 'object', 'properties': <String, Object?>{}},
          },
        }).source,
      );
      expect(source, contains("'photo':photoSchema.optional()"));
    });

    test('models in document order with explicit names', () {
      final source = _generate({
        r'$defs': {
          'Beta': {'type': 'object'},
          'Alpha': {'type': 'object'},
        },
      }).source;
      expect(
        source.indexOf("AckInfer(name: 'Beta')"),
        lessThan(source.indexOf("AckInfer(name: 'Alpha')")),
      );
      expect(source, contains('final betaSchema = ack.Ack.object('));
    });
  });

  group('unknown_properties: preserve', () {
    test('widens strict objects and records them', () {
      final library = _generate({
        r'$defs': {
          'Model': {
            'type': 'object',
            'properties': {
              'address': {
                'type': 'object',
                'properties': {
                  'street': {'type': 'string'},
                },
                'additionalProperties': false,
              },
            },
            'additionalProperties': false,
          },
        },
      }, unknownProperties: AckUnknownPropertiesMode.preserve);

      expect(library.widenedPointers, [
        r'#/$defs/Model',
        r'#/$defs/Model/properties/address',
      ]);
      expect(
        library.source,
        contains(r'// - #/$defs/Model/properties/address'),
      );
      final model =
          (library.effectiveDocument[r'$defs']! as Map)['Model']! as Map;
      expect(model['additionalProperties'], isTrue);
    });

    test('leaves the input document unchanged', () {
      final document =
          _model({
              'f': {'type': 'string'},
            })
            ..[r'$defs'] = {
              'Model': {
                'type': 'object',
                'properties': {
                  'f': {'type': 'string'},
                },
                'additionalProperties': false,
              },
            };
      _generate(document, unknownProperties: AckUnknownPropertiesMode.preserve);
      expect(
        ((document[r'$defs']! as Map)['Model']! as Map)['additionalProperties'],
        isFalse,
      );
    });

    test('records fallback widenings in supplied resources', () {
      final externalUri = Uri.parse('https://example.test/external.json');
      final external = <String, Object?>{
        'type': 'object',
        'additionalProperties': false,
      };
      final library = generateAckSchemaLibrary(
        document: {r'$ref': externalUri.toString()},
        documentUri: _uri,
        partStem: 'model.schema',
        includeParts: false,
        options: const AckJsonSchemaLibraryOptions(
          unknownProperties: AckUnknownPropertiesMode.preserve,
        ),
        documents: {externalUri: external},
      );
      expect(external['additionalProperties'], isFalse);
      expect(library.widenedPointers, ['$externalUri#']);
      expect(library.source, contains('// - $externalUri#'));
    });

    test('escapes schema keys in generated widening comments', () {
      final library = _generate(
        _model({
          'x\nfinal injected = true;': {
            'type': 'object',
            'additionalProperties': false,
          },
        }),
        unknownProperties: AckUnknownPropertiesMode.preserve,
      );
      expect(library.source, contains(r'x\nfinal injected = true;'));
      expect(library.source, isNot(contains('\nfinal injected = true;')));
    });
  });

  group('Draft 2020-12 validated fallback', () {
    final examples = <String, Object?>{
      'composition': {
        'allOf': [
          {'type': 'string'},
          {'minLength': 2},
        ],
      },
      'format annotation': {'type': 'string', 'format': 'email'},
      'multipleOf': {'type': 'number', 'multipleOf': 0.1},
      'nullable array items': {
        'type': 'array',
        'items': {
          'type': ['string', 'null'],
        },
      },
      'unconstrained array': {'type': 'array'},
      'mixed enum': {
        'enum': ['a', 1, null],
      },
      'conditional': {
        'if': {
          'properties': {
            'kind': {'const': 'a'},
          },
        },
        'then': {
          'required': ['name'],
        },
      },
      'unevaluated properties': {
        'type': 'object',
        'properties': {
          'name': {'type': 'string'},
        },
        'unevaluatedProperties': false,
      },
    };
    for (final MapEntry(:key, :value) in examples.entries) {
      test(key, () {
        final library = _generate(_model({'f': value}));
        expect(library.source, contains('final class Model'));
        expect(library.source, contains('Ack.fromJsonSchema'));
        expect(library.source, isNot(contains('@ack_annotations.AckInfer')));
        expect(library.source, isNot(contains("part 'model.schema.ack.dart'")));
      });
    }

    test(r'generates a root model without $defs', () {
      final library = _generate({
        'type': 'array',
        'prefixItems': [
          {'type': 'string'},
          {'type': 'integer'},
        ],
        'items': false,
      });
      expect(library.source, contains('final class Root'));
      expect(library.source, contains('rootSchema'));
    });

    test('generates boolean root schemas', () {
      final library = _generate(false);
      expect(library.source, contains('final class Root'));
      expect(library.effectiveDocument, {
        'allOf': [false],
      });
    });

    test(
      'validated mode uses the exact importer for a typed-compatible model',
      () {
        final library = _generate(
          _model({
            'count': {'type': 'integer'},
          }),
          modelMode: AckJsonSchemaModelMode.validated,
        );
        expect(library.source, contains('final class Model'));
        expect(library.source, isNot(contains('@ack_annotations.AckInfer')));
      },
    );

    test('assigns unique stable names to arbitrary definition keys', () {
      final library = _generate({
        r'$defs': {
          'my-model': {'type': 'string'},
          'my model': {'type': 'integer'},
          'String': {'type': 'null'},
        },
      });
      expect(library.source, contains('final class MyModel '));
      expect(library.source, contains('final class MyModel2 '));
      expect(library.source, contains('final class StringModel '));
      expect(_generate(library.effectiveDocument).source, library.source);
    });

    test(
      'keeps a named Root definition when the document has a root model',
      () {
        final library = _generate({
          r'$defs': {
            'Root': {'type': 'string', 'format': 'email'},
          },
          r'$ref': r'#/$defs/Root',
        });
        expect(library.source, contains('final class Root '));
        expect(library.source, contains('final class DocumentRoot '));
      },
    );

    test('generates recursive and nullable definition wrappers', () {
      final library = _generate({
        r'$defs': {
          'Node': {
            'anyOf': [
              {
                'type': 'object',
                'properties': {
                  'next': {r'$ref': r'#/$defs/Node'},
                },
              },
              {'type': 'null'},
            ],
          },
        },
      });
      expect(library.source, contains('final class Node'));
      expect(library.source, contains('nodeSchema'));
    });

    test('reports invalid references at their JSON pointer', () {
      expect(
        _diagnostics(
          _model({
            'f': {r'$ref': r'#/$defs/Missing'},
          }),
        ),
        [
          _diagnostic(
            r'#/$defs/Model/properties/f/$ref',
            'Unresolved schema reference',
          ),
        ],
      );
    });

    test('still rejects malformed and unsupported source semantics', () {
      for (final (schema, keyword) in <(Object?, String)>[
        ({'type': 'not-a-type'}, 'type'),
        ({'pattern': '['}, 'pattern'),
        (
          {
            r'$vocabulary': {'https://example.test/required': true},
          },
          r'$vocabulary',
        ),
      ]) {
        expect(_diagnostics(_model({'f': schema})), [
          isA<AckJsonSchemaDiagnostic>().having(
            (diagnostic) => diagnostic.pointer,
            'pointer',
            r'#/$defs/Model/properties/f/' + keyword,
          ),
        ]);
      }
      expect(_diagnostics(null), [_diagnostic('#', 'Expected')]);
    });
  });

  group('options', () {
    test('parse unknown_properties', () {
      expect(
        AckJsonSchemaLibraryOptions.fromConfig(const {
          'unknown_properties': 'preserve',
        }).unknownProperties,
        AckUnknownPropertiesMode.preserve,
      );
      expect(
        AckJsonSchemaLibraryOptions.fromConfig(const {}).unknownProperties,
        AckUnknownPropertiesMode.schema,
      );
      final configured = AckJsonSchemaLibraryOptions.fromConfig(const {
        'assert_formats': true,
        'documents': {'https://example.test/schema.json': 'lib/schema.json'},
      });
      expect(configured.assertFormats, isTrue);
      expect(configured.modelMode, AckJsonSchemaModelMode.auto);
      expect(configured.documentPaths, {
        Uri.parse('https://example.test/schema.json'): 'lib/schema.json',
      });
      expect(
        AckJsonSchemaLibraryOptions.fromConfig(const {
          'model_mode': 'validated',
        }).modelMode,
        AckJsonSchemaModelMode.validated,
      );
    });

    test('reject unknown keys and values', () {
      expect(
        () => AckJsonSchemaLibraryOptions.fromConfig(const {'typo': 1}),
        throwsArgumentError,
      );
      expect(
        () => AckJsonSchemaLibraryOptions.fromConfig(const {
          'unknown_properties': 'loose',
        }),
        throwsArgumentError,
      );
      expect(
        () => AckJsonSchemaLibraryOptions.fromConfig(const {
          'assert_formats': 'yes',
        }),
        throwsArgumentError,
      );
      expect(
        () => AckJsonSchemaLibraryOptions.fromConfig(const {
          'documents': ['lib/schema.json'],
        }),
        throwsArgumentError,
      );
      expect(
        () => AckJsonSchemaLibraryOptions.fromConfig(const {
          'model_mode': 'loose',
        }),
        throwsArgumentError,
      );
    });
  });
}
