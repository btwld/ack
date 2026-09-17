import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  test('JsonSchema is the concrete core JSON Schema value type', () {
    final input = JsonSchema.fromMap({'type': 'string', 'minLength': 2});

    final schema = Ack.fromJsonSchema(input);
    final JsonSchema exported = schema.toJsonSchema();
    final JsonSchema modelExport = schema.toSchemaModel().toJsonSchema();

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

  test('strict factory and report agree for supplied recursive bundles', () {
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
    final JsonSchemaImportResult report = importJsonSchema(
      document,
      baseUri: baseUri,
      documents: documents,
    );
    final AckSchema<Object, Object> reported = report.schema;
    expect(report.isExact, isTrue);
    expect(schema.toJsonSchema(), reported.toJsonSchema());
    for (final value in [
      {
        'value': 1,
        'child': {'value': 2},
      },
      {'value': 1, 'child': {}},
      null,
    ]) {
      expect(schema.safeParse(value).isOk, reported.safeParse(value).isOk);
    }
    expect(
      schema.safeParse({
        'value': 1,
        'child': {'value': 2},
      }).isOk,
      isTrue,
    );
    expect(schema.safeParse({'value': 1, 'child': {}}).isFail, isTrue);
  });

  test('partial conversion is explicit and diagnostics are immutable', () {
    final document = {'type': 'string', 'format': 'email'};
    expect(
      () => Ack.fromJsonSchema(document),
      throwsA(isA<JsonSchemaImportException>()),
    );
    final JsonSchemaImportResult report = importJsonSchema(
      document,
      allowUnsupported: true,
    );
    final AckSchema<Object, Object> schema = report.schema;
    expect(report.isExact, isFalse);
    expect(report.diagnostics.single.code, 'unsupported_keyword');
    expect(report.diagnostics.single.pointer, '#/format');
    expect(() => report.diagnostics.clear(), throwsUnsupportedError);
    expect(schema.parse('not an email'), 'not an email');
    expect(schema.toJsonSchema().toString(), isNot(contains('format')));
  });

  test('invalid inputs remain errors through both core entry points', () {
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
      expect(
        () => importJsonSchema(document, allowUnsupported: true),
        throwsA(isA<JsonSchemaImportException>()),
      );
    }
    final AckSchema<Object, Object> never = Ack.fromJsonSchema(false);
    expect(never.safeParse(null).isFail, isTrue);
    expect(never.safeParse('anything').isFail, isTrue);
  });
}
