import 'dart:convert';

import 'package:ack/ack.dart';
import 'package:ack_json_schema_builder/ack_json_schema_builder.dart';
import 'package:json_schema_builder/json_schema_builder.dart' as jsb;
import 'package:test/test.dart';

void main() {
  test('imports builder models, including referenced documents', () {
    final AckSchema<Object, Object> strict =
        jsb.Schema.fromMap({r'$ref': 'types.json'}).toAckSchema(
          baseUri: Uri.parse('https://example.test/root.json'),
          documents: {
            Uri.parse('types.json'): jsb.Schema.object(
              properties: {'name': jsb.Schema.string()},
              required: ['name'],
            ),
          },
        );
    expect(strict.safeParse({'name': 'Ada'}).isOk, isTrue);
    expect(strict.safeParse({}).isFail, isTrue);
  });

  test('builder bridge retains strictness and diagnostics', () {
    final model = jsb.Schema.fromMap({'format': 'email'});
    expect(
      () => model.toAckSchema(),
      throwsA(isA<JsonSchemaImportException>()),
    );
  });

  test(
    'original, imported, and exported validators agree on the subset',
    () async {
      final documents = <Object>[
        true,
        false,
        {
          'type': ['integer', 'null'],
          'minimum': 0,
          'maximum': 10,
        },
        {'const': null},
        {
          'enum': [
            null,
            1,
            {
              'a': [1],
            },
          ],
        },
        {'minLength': 2, 'maxLength': 4},
        {'type': 'number', 'exclusiveMinimum': 1, 'exclusiveMaximum': 4},
        {
          'items': {
            'type': ['integer', 'null'],
          },
          'minItems': 1,
          'maxItems': 2,
          'uniqueItems': true,
        },
        {
          'properties': {
            'a': {'type': 'string'},
          },
          'required': ['a'],
          'additionalProperties': false,
        },
        {
          'required': ['unlisted'],
          'minProperties': 1,
          'maxProperties': 2,
        },
        {
          'additionalProperties': {'type': 'integer'},
        },
        {
          'oneOf': [
            {'type': 'number'},
            {'minimum': 1},
          ],
        },
        {
          'allOf': [
            {'minimum': 1},
            {'maximum': 3},
          ],
          'not': {'const': 2},
        },
        {
          'anyOf': [
            {'type': 'boolean'},
            {'type': 'string'},
          ],
          'enum': [true, 'yes'],
        },
        {
          r'$defs': {
            'n': {'type': 'number', 'minimum': 1},
          },
          r'$ref': r'#/$defs/n',
          'maximum': 3,
        },
        {
          'type': 'object',
          'properties': {
            'a': {r'$ref': '#'},
          },
          'additionalProperties': false,
        },
      ];
      final values = <Object?>[
        null,
        true,
        false,
        -1,
        0,
        1,
        1.0,
        1.5,
        2,
        3,
        4,
        10,
        11,
        '',
        'a',
        'ab',
        'yes',
        'abcde',
        [],
        [null],
        [1, null],
        [1, 1.0],
        [1, 2, 3],
        <String, Object?>{},
        {'a': 'x'},
        {'a': null},
        {
          'a': [1],
        },
        {'a': <String, Object?>{}, 'b': 2},
        {
          'a': {'a': <String, Object?>{}},
        },
        {'unlisted': null},
      ];
      for (final document in documents) {
        final original = document is bool
            ? jsb.Schema.fromBoolean(document)
            : jsb.Schema.fromMap(document as Map<String, Object?>);
        final AckSchema<Object, Object> imported = original.toAckSchema();
        final AckSchema<Object, Object> core = Ack.fromJsonSchema(document);
        expect(
          imported.toJsonSchema(),
          Ack.fromJsonSchema(original.value).toJsonSchema(),
        );
        final exported = imported.toJsonSchemaBuilder();
        final AckSchema<Object, Object> reimported = exported.toAckSchema();
        for (final raw in values) {
          final value = jsonDecode(jsonEncode(raw));
          final expected = (await original.validate(value)).isEmpty;
          final reason = 'schema: $document; value: $value';
          expect(imported.safeParse(value).isOk, expected, reason: reason);
          expect(core.safeParse(value).isOk, expected, reason: reason);
          expect(imported.safeEncode(value).isOk, expected, reason: reason);
          expect(
            (await exported.validate(value)).isEmpty,
            expected,
            reason: reason,
          );
          expect(reimported.safeParse(value).isOk, expected, reason: reason);
        }
      }
    },
  );

  test(
    'imported schemas compose and export alongside native and lazy schemas',
    () async {
      final imported = Ack.fromJsonSchema({
        r'$defs': {
          'v': {'type': 'integer'},
        },
        'type': 'object',
        'properties': {
          'v': {r'$ref': r'#/$defs/v'},
        },
        'required': ['v'],
      });
      final schema = Ack.object({
        'a': imported,
        'b': imported,
        'native': Ack.lazy('native', () => Ack.string()),
      });
      final exported = schema.toJsonSchemaBuilder();
      for (final value in [
        {
          'a': {'v': 1},
          'b': {'v': 2},
          'native': 'yes',
        },
        {
          'a': {'v': 'wrong'},
          'b': {'v': 2},
          'native': 'yes',
        },
      ]) {
        expect(
          (await exported.validate(value)).isEmpty,
          schema.safeParse(value).isOk,
        );
      }
    },
  );

  test(
    'ordinary lazy and imported schemas retain independent validation',
    () async {
      final imported = Ack.fromJsonSchema(true).nullable(value: false);
      final schema = Ack.object({
        'a': imported,
        'b': Ack.lazy('native', () => imported),
      });
      final value = {'a': 'ok', 'b': null};

      expect(schema.safeParse(value).isFail, isTrue);
      expect(
        (await schema.toJsonSchemaBuilder().validate(value)).isEmpty,
        isFalse,
      );
    },
  );
}
