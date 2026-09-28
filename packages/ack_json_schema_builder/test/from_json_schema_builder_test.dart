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

  test('builder bridge forwards the format assertion policy', () {
    final model = jsb.Schema.fromMap({'type': 'string', 'format': 'email'});
    expect(model.toAckSchema().safeParse('not an email').isOk, isTrue);

    final asserted = model.toAckSchema(assertFormats: true);
    expect(asserted.safeParse('ada@example.com').isOk, isTrue);
    expect(asserted.safeParse('not an email').isFail, isTrue);
  });

  test('builder exports keep the legacy default and expose 2020-12 opt-in', () {
    final imported = Ack.fromJsonSchema({'type': 'string', 'minLength': 2});
    final legacy = imported.toJsonSchemaBuilder().value as Map;
    final preserving =
        imported.toJsonSchemaBuilderPreservingImportedDialect().value as Map;

    expect(legacy['definitions'], isA<Map<String, Object?>>());
    expect(legacy[r'$schema'], isNull);
    expect(preserving['type'], 'string');
    expect(
      preserving[r'$schema'],
      'https://json-schema.org/draft/2020-12/schema',
    );
  });
}
