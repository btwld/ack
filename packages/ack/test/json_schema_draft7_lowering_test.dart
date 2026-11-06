import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  final cases =
      <
        ({
          String keyword,
          Map<String, Object?> document,
          Object valid,
          Object invalid,
        })
      >[
        (
          keyword: 'prefixItems',
          document: {
            'prefixItems': [
              {'type': 'string'},
            ],
            'items': false,
          },
          valid: ['name'],
          invalid: [1],
        ),
        (
          keyword: 'dependentRequired',
          document: {
            'dependentRequired': {
              'a': ['b'],
            },
          },
          valid: {'a': 1, 'b': 2},
          invalid: {'a': 1},
        ),
        (
          keyword: 'dependentSchemas',
          document: {
            'dependentSchemas': {
              'a': {
                'required': ['b'],
              },
            },
          },
          valid: {'a': 1, 'b': 2},
          invalid: {'a': 1},
        ),
        (
          keyword: 'unevaluatedProperties',
          document: {'unevaluatedProperties': false},
          valid: <String, Object?>{},
          invalid: {'extra': 1},
        ),
        (
          keyword: 'unevaluatedItems',
          document: {'unevaluatedItems': false},
          valid: <Object>[],
          invalid: [1],
        ),
        (
          keyword: 'minContains',
          document: {
            'contains': {'type': 'integer'},
            'minContains': 2,
          },
          valid: [1, 2],
          invalid: [1],
        ),
        (
          keyword: 'maxContains',
          document: {
            'contains': {'type': 'integer'},
            'maxContains': 1,
          },
          valid: [1],
          invalid: [1, 2],
        ),
      ];

  for (final testCase in cases) {
    for (final referenced in [false, true]) {
      test('${testCase.keyword} rejects lossy Draft-7 export '
          '${referenced ? 'through a reference' : 'at the root'}', () {
        final schema = Ack.fromJsonSchema(
          referenced
              ? {
                  r'$defs': {'constraint': testCase.document},
                  r'$ref': r'#/$defs/constraint',
                }
              : testCase.document,
        );
        expect(schema.safeParse(testCase.valid).isOk, isTrue);
        expect(schema.safeParse(testCase.invalid).isFail, isTrue);
        expect(
          schema.toJsonSchemaDraft7,
          throwsA(
            isA<UnsupportedError>().having(
              (error) => error.message,
              'message',
              contains(testCase.keyword),
            ),
          ),
        );
        final restored = Ack.fromJsonSchema(schema.toJsonSchema());
        expect(restored.safeParse(testCase.valid).isOk, isTrue);
        expect(restored.safeParse(testCase.invalid).isFail, isTrue);
      });
    }
  }

  test('Draft-7 compatible array constraints still export', () {
    final schema = Ack.fromJsonSchema({
      'type': 'array',
      'items': {'type': 'integer'},
      'contains': {'minimum': 2},
      'minItems': 1,
    });
    final exported = schema.toJsonSchemaDraft7();
    final definitions = exported['definitions']! as Map;
    expect(definitions.values, contains(containsPair('minItems', 1)));
    expect(definitions.values, contains(containsPair('type', 'integer')));
    expect(definitions.values, contains(containsPair('minimum', 2)));
  });
}
