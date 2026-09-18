import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  test('JSON Schema maps round-trip through existing schema models', () {
    final input = <String, Object?>{'type': 'string', 'minLength': 2};

    final schema = Ack.fromJsonSchema(input);
    final Map<String, Object?> exported = schema.toJsonSchema();
    final Map<String, Object?> modelExport = schema
        .toSchemaModel()
        .toJsonSchema();

    expect(exported['type'], isNull);
    expect(exported['definitions'], isA<Map<String, Object?>>());
    expect(modelExport, exported);
    expect(schema.safeParse('Ada').isOk, isTrue);
    expect(schema.safeParse('A').isFail, isTrue);
  });

  test('strict factory returns an executable abstract schema', () {
    final AckSchema<Object, Object> schema = Ack.fromJsonSchema({
      'type': 'string',
      'minLength': 2,
    });
    expect(schema.parse('Ada'), 'Ada');
    expect(schema.encode('Ada'), 'Ada');
    expect(schema.safeParse('A').isFail, isTrue);
    expect(schema.safeEncode(1).isFail, isTrue);
    final AckSchema<Object, Object> refined = schema
        .describe('Name')
        .refine((value) => value != 'blocked', message: 'Blocked name');
    expect(refined.description, 'Name');
    expect(refined.safeParse('blocked').isFail, isTrue);
    expect(refined.safeEncode('blocked').isFail, isTrue);
    expect(refined.safeParse('Ada').isOk, isTrue);
    final composed = Ack.object({'name': schema.optional()});
    expect(composed.safeParse({}).isOk, isTrue);
    expect(composed.safeParse({'name': 'A'}).isFail, isTrue);
    for (final candidate in [
      schema.nullable(),
      Ack.fromJsonSchema(true).nullable(value: false),
    ]) {
      final AckSchema<Object, Object> restored = Ack.fromJsonSchema(
        candidate.toJsonSchema(),
      );
      for (final value in <Object?>[null, 'Ada', 'A', 1]) {
        expect(restored.safeParse(value).isOk, candidate.safeParse(value).isOk);
        expect(
          candidate.safeEncode(value).isOk,
          candidate.safeParse(value).isOk,
        );
      }
    }
    final restored = Ack.fromJsonSchema(composed.toJsonSchema());
    expect(restored.safeParse({'name': 'Ada'}).isOk, isTrue);
    expect(restored.safeParse({'name': 1}).isFail, isTrue);
  });

  test('strict factory imports supplied recursive bundles', () {
    final baseUri = Uri.parse('https://example.test/root.json');
    final document = {r'$ref': 'node.json'};
    final documents = <Uri, Object>{
      Uri.parse('node.json'): {
        'type': 'object',
        'properties': {
          'child': {r'$ref': '#'},
          'value': {'type': 'integer'},
        },
        'required': ['value'],
      },
    };
    final AckSchema<Object, Object> schema = Ack.fromJsonSchema(
      document,
      baseUri: baseUri,
      documents: documents,
    );
    for (final testCase in [
      (
        value: <String, Object?>{
          'value': 1,
          'child': {'value': 2},
        },
        valid: true,
      ),
      (value: <String, Object?>{'value': 1, 'child': {}}, valid: false),
      (value: null, valid: false),
    ]) {
      expect(schema.safeParse(testCase.value).isOk, testCase.valid);
    }
  });

  test('unsupported assertions expose immutable diagnostics', () {
    final document = {'type': 'string', 'format': 'email'};
    late JsonSchemaImportException failure;
    try {
      Ack.fromJsonSchema(document);
      fail('Expected an unsupported keyword failure.');
    } on JsonSchemaImportException catch (error) {
      failure = error;
    }
    expect(failure.diagnostics.single.code, 'unsupported_keyword');
    expect(failure.diagnostics.single.pointer, '#/format');
    expect(() => failure.diagnostics.clear(), throwsUnsupportedError);
  });

  test('invalid inputs remain errors through the core entry point', () {
    for (final document in <Object>[
      '{"type":"string"}',
      [],
      {'minLength': -1},
      {r'$ref': 'missing.json'},
      {r'$ref': '#'},
      {r'$schema': 'http://json-schema.org/draft-07/schema#'},
    ]) {
      expect(
        () => Ack.fromJsonSchema(document),
        throwsA(isA<JsonSchemaImportException>()),
      );
    }
    final AckSchema<Object, Object> never = Ack.fromJsonSchema(false);
    expect(never.safeParse(null).isFail, isTrue);
    expect(never.safeParse('anything').isFail, isTrue);
  });
}
