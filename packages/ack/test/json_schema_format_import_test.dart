import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('JSON Schema date-time format import', () {
    test('strict import asserts date-time without an option', () {
      final schema = Ack.fromJsonSchema({'format': 'date-time'});
      expect(schema.safeParse('2024-02-29T00:00:00Z').isOk, isTrue);
      expect(schema.safeParse('2024-02-30T00:00:00Z').isFail, isTrue);
    });

    test('unsupported assertion reports its source pointer', () {
      final base = Uri.parse('https://example.test/root.json');
      try {
        Ack.fromJsonSchema(
          {
            'properties': {
              'stamp': {r'$ref': r'formats.json#/$defs/stamp'},
            },
          },
          baseUri: base,
          documents: {
            Uri.parse('formats.json'): {
              r'$defs': {
                'stamp': {'format': 'not-a-supported-format'},
              },
            },
          },
        );
        fail('Expected an unsupported format diagnostic.');
      } on JsonSchemaImportException catch (error) {
        final issue = error.diagnostics.single;
        expect(issue.code, 'unsupported_keyword');
        expect(issue.keyword, 'format');
        expect(issue.pointer, r'#/$defs/stamp/format');
        expect(issue.documentUri, base.resolve('formats.json'));
      }

      // Only reachable definitions are compiled.
      expect(
        Ack.fromJsonSchema({
          r'$defs': {
            'unused': {'format': 'not-a-supported-format'},
          },
        }).safeParse('anything').isOk,
        isTrue,
      );
    });

    test('non-string format values are invalid schema input', () {
      expect(
        () => Ack.fromJsonSchema({'format': 17}),
        throwsA(
          isA<JsonSchemaImportException>().having(
            (error) => error.diagnostics.single.pointer,
            'pointer',
            '#/format',
          ),
        ),
      );
    });

    test('format applies only to strings and preserves valid input', () {
      final schema = Ack.fromJsonSchema({'format': 'date-time'});
      for (final value in [
        null,
        true,
        4,
        1.25,
        <Object?>[],
        <String, Object?>{},
      ]) {
        expect(schema.safeParse(value).isOk, isTrue, reason: '$value');
      }
      const original = '1998-12-31t15:59:60.123456789-08:00';
      expect(schema.parse(original), original);
      expect(schema.safeParse('2024-02-30T01:02:03Z').isFail, isTrue);

      final typed = Ack.fromJsonSchema({
        'type': 'string',
        'format': 'date-time',
      });
      expect(typed.safeParse(4).isFail, isTrue);
      expect(typed.safeParse(original).isOk, isTrue);
    });

    test('assertion survives references, siblings, arrays and export', () {
      final schema = Ack.fromJsonSchema({
        r'$defs': {
          'stamp': {'format': 'date-time'},
        },
        'properties': {
          'stamps': {
            'type': 'array',
            'items': {
              r'$ref': r'#/$defs/stamp',
              'allOf': [
                {'type': 'string'},
              ],
            },
          },
        },
      });
      final exported = schema.toJsonSchema();
      final roundTrip = Ack.fromJsonSchema(exported);
      for (final imported in [schema, roundTrip]) {
        expect(
          imported.safeParse({
            'stamps': ['2024-02-29T00:00:00Z'],
          }).isOk,
          isTrue,
        );
        expect(
          imported.safeParse({
            'stamps': ['2024-02-30T00:00:00Z'],
          }).isFail,
          isTrue,
        );
        expect(
          imported.safeParse({
            'stamps': [7],
          }).isFail,
          isTrue,
        );
      }
    });

    test('native date-time export can be asserted on import', () {
      final native = Ack.string().datetime();
      final imported = Ack.fromJsonSchema(native.toJsonSchema());
      expect(imported.safeParse('2024-02-29T00:00:00Z').isOk, isTrue);
      expect(imported.safeParse('2024-02-30T00:00:00Z').isFail, isTrue);
      expect(imported.safeParse(4).isFail, isTrue);
    });

    test('checks dates, offsets and leap seconds in UTC', () {
      final schema = Ack.fromJsonSchema({'format': 'date-time'});
      for (final value in [
        '2023-02-29T00:00:00Z',
        '2024-02-29T00:00:00',
        '2024-02-29T00:00:00+24:00',
        '2024-02-29T00:00:00+01:60',
        '2030-06-30T23:59:60Z',
        '1998-12-31T15:58:60-08:00',
        '1999-01-01T23:59:60Z',
        '2024-02-29T00:00:00Z😀',
      ]) {
        expect(schema.safeParse(value).isFail, isTrue, reason: value);
      }
      for (final value in [
        '2024-02-29T00:00:00Z',
        '2024-02-29t00:00:00.123456789z',
        '1998-12-31T23:59:60Z',
        '1998-12-31T15:59:60-08:00',
        '1998-12-31t23:59:60z',
        '1999-01-01t00:59:60+01:00',
      ]) {
        expect(schema.safeParse(value).isOk, isTrue, reason: value);
      }
    });
  });
}
