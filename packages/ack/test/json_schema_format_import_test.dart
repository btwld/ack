import 'dart:convert';
import 'dart:io';

import 'package:ack/ack.dart';
import 'package:test/test.dart';

const _assert = JsonSchemaFormatPolicy.assertSupported;

void main() {
  group('JSON Schema format import policy', () {
    test(
      'default rejects format; annotations retain known and unknown labels',
      () {
        expect(
          () => Ack.fromJsonSchema({'format': 'date-time'}),
          throwsA(
            isA<JsonSchemaImportException>().having(
              (error) => error.diagnostics.single.code,
              'code',
              'unsupported_keyword',
            ),
          ),
        );

        for (final label in ['date-time', 'private-format']) {
          final schema = Ack.fromJsonSchema({
            'format': label,
          }, formatPolicy: JsonSchemaFormatPolicy.annotate);
          expect(schema.safeParse('anything').isOk, isTrue);
          expect(schema.safeParse(42).isOk, isTrue);
          final exported = schema.toJsonSchema();
          expect((exported['definitions'] as Map).values.single, {
            'format': label,
          });
          expect(
            Ack.fromJsonSchema(
              exported,
              formatPolicy: JsonSchemaFormatPolicy.annotate,
            ).safeParse('anything').isOk,
            isTrue,
          );
        }
      },
    );

    test('assertion rejects unsupported labels with source pointer', () {
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
                'stamp': {'format': 'email'},
              },
            },
          },
          formatPolicy: _assert,
        );
        fail('Expected an unsupported format diagnostic.');
      } on JsonSchemaImportException catch (error) {
        final issue = error.diagnostics.single;
        expect(issue.code, 'unsupported_format');
        expect(issue.keyword, 'format');
        expect(issue.pointer, r'#/$defs/stamp/format');
        expect(issue.documentUri, base.resolve('formats.json'));
      }

      // Unused definitions are not part of the validation graph.
      expect(
        Ack.fromJsonSchema({
          r'$defs': {
            'unused': {'format': 'email'},
          },
        }, formatPolicy: _assert).safeParse('anything').isOk,
        isTrue,
      );
    });

    test('invalid format values are diagnosed when format is enabled', () {
      for (final policy in [JsonSchemaFormatPolicy.annotate, _assert]) {
        expect(
          () => Ack.fromJsonSchema({'format': 17}, formatPolicy: policy),
          throwsA(
            isA<JsonSchemaImportException>().having(
              (error) => error.diagnostics.single.pointer,
              'pointer',
              '#/format',
            ),
          ),
        );
      }
    });

    test('date-time assertion applies only to strings and preserves input', () {
      final schema = Ack.fromJsonSchema({
        'format': 'date-time',
      }, formatPolicy: _assert);
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
      }, formatPolicy: _assert);
      expect(typed.safeParse(4).isFail, isTrue);
      expect(typed.safeParse(original).isOk, isTrue);
    });

    test('assertion survives references, siblings, arrays and composition', () {
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
      }, formatPolicy: _assert);
      expect(
        schema.safeParse({
          'stamps': ['2024-02-29T00:00:00Z'],
        }).isOk,
        isTrue,
      );
      expect(
        schema.safeParse({
          'stamps': ['2024-02-30T00:00:00Z'],
        }).isFail,
        isTrue,
      );
      expect(
        schema.safeParse({
          'stamps': [7],
        }).isFail,
        isTrue,
      );

      final exported = schema.toJsonSchema();
      final roundTrip = Ack.fromJsonSchema(exported, formatPolicy: _assert);
      expect(
        roundTrip.safeParse({
          'stamps': ['2024-02-29T00:00:00Z'],
        }).isOk,
        isTrue,
      );
      expect(
        roundTrip.safeParse({
          'stamps': ['2024-02-30T00:00:00Z'],
        }).isFail,
        isTrue,
      );
      expect(
        roundTrip.safeParse({
          'stamps': [7],
        }).isFail,
        isTrue,
      );
      expect(
        () => Ack.fromJsonSchema(exported),
        throwsA(isA<JsonSchemaImportException>()),
      );
    });

    test('matches native string validation across the date-time fixture', () {
      final fixture =
          jsonDecode(
                File(
                  'test/fixtures/json_schema_2020_12_full/'
                  'draft2020-12/optional/format/date-time.json',
                ).readAsStringSync(),
              )
              as List<dynamic>;
      final imported = Ack.fromJsonSchema({
        'format': 'date-time',
      }, formatPolicy: _assert);
      final native = Ack.string().datetime();
      var count = 0;
      for (final group in fixture.cast<Map<String, dynamic>>()) {
        for (final probe
            in (group['tests'] as List).cast<Map<String, dynamic>>()) {
          final value = probe['data'];
          final expected = probe['valid'] as bool;
          expect(
            imported.safeParse(value).isOk,
            expected,
            reason: probe['description'] as String,
          );
          if (value is String) {
            expect(
              native.safeParse(value).isOk,
              expected,
              reason: probe['description'] as String,
            );
          }
          count++;
        }
      }
      expect(count, 43);
    });

    test('rejects invalid dates, offsets and unannounced leap seconds', () {
      final schema = Ack.fromJsonSchema({
        'format': 'date-time',
      }, formatPolicy: _assert);
      for (final value in [
        '2023-02-29T00:00:00Z',
        '2024-02-29T00:00:00',
        '2024-02-29T00:00:00+24:00',
        '2024-02-29T00:00:00+01:60',
        '2030-06-30T23:59:60Z',
        '1998-12-31T15:58:60-08:00',
      ]) {
        expect(schema.safeParse(value).isFail, isTrue, reason: value);
      }
      for (final value in [
        '2024-02-29T00:00:00Z',
        '2024-02-29t00:00:00.123456789z',
        '1998-12-31T23:59:60Z',
        '1998-12-31T15:59:60-08:00',
        '1998-12-31t23:59:60z',
      ]) {
        expect(schema.safeParse(value).isOk, isTrue, reason: value);
      }
    });
  });
}
