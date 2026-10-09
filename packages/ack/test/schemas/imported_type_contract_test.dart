import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  test('singleton and union import types preserve JSON numeric semantics', () {
    final vectors = <(Object?, Set<String>)>[
      (null, {'null'}),
      ('value', {'string'}),
      (true, {'boolean'}),
      (3, {'integer', 'number'}),
      (3.0, {'integer', 'number'}),
      (-0.0, {'integer', 'number'}),
      (3.5, {'number'}),
      (<Object?>[1, 'value'], {'array'}),
      (<String, Object?>{'value': 1}, {'object'}),
      (double.infinity, {}),
      (double.nan, {}),
    ];

    for (final types in <List<String>>[
      ['null'],
      ['string'],
      ['boolean'],
      ['integer'],
      ['number'],
      ['array'],
      ['object'],
      ['integer', 'string', 'null'],
      ['number', 'boolean'],
      ['array', 'object'],
    ]) {
      final forms = <Object>[if (types.length == 1) types.single, types];
      for (final form in forms) {
        final schema = Ack.fromJsonSchema({'type': form});
        for (final (input, matchingTypes) in vectors) {
          final expected = types.any(matchingTypes.contains);
          final result = schema.safeParse(input);
          expect(result.isOk, expected, reason: 'type: $form, input: $input');
          expect(schema.safeEncode(input).isOk, expected);
          if (expected) expect(result.getOrNull(), input);
        }
      }
    }
  });

  test(
    'singleton and union type failures preserve all diagnostic locations',
    () {
      final uri = Uri.parse('https://example.test/types.json');
      for (final type in <Object>[
        'integer',
        ['integer'],
        ['integer', 'string'],
      ]) {
        final schema = Ack.fromJsonSchema({
          'type': 'object',
          'properties': {
            'a/b~c': {'type': type},
          },
        }, baseUri: uri);
        for (final result in [
          schema.safeParse({'a/b~c': false}),
          schema.safeEncode({'a/b~c': false}),
        ]) {
          final error = result.getError() as JsonSchemaValidationError;
          expect(error.keyword, 'type');
          expect(error.path, '#/a~1b~0c');
          expect(error.pointer, '#/properties/a~1b~0c/type');
          expect(error.keywordLocation, '/properties/a~1b~0c/type');
          expect(error.documentUri, uri);
          expect(error.value, isFalse);
        }
      }
    },
  );

  test('JSON safety failures still precede imported type failures', () {
    final schema = Ack.fromJsonSchema({
      'type': 'object',
      'properties': {
        'first': {'type': 'string'},
      },
    });
    final input = {
      'first': 12,
      'later': [double.infinity],
    };

    final error = schema.safeParse(input).getError();

    expect(error.runtimeType, SchemaValidationError);
    expect(
      error.message,
      'Expected an acyclic JSON value with finite numbers.',
    );
    expect(error.path, '#');
    expect(error.value, same(input));
  });
}
