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
    final model = jsb.Schema.fromMap({'format': 'not-a-supported-format'});
    expect(
      () => model.toAckSchema(),
      throwsA(
        isA<JsonSchemaImportException>().having(
          (error) => error.diagnostics.single.keyword,
          'keyword',
          'format',
        ),
      ),
    );
  });

  test('builder bridge asserts supported date-time on import', () {
    final model = jsb.Schema.fromMap({'type': 'string', 'format': 'date-time'});
    final schema = model.toAckSchema();
    expect(schema.safeParse('2024-02-29T01:02:03Z').isOk, isTrue);
    expect(schema.safeParse('2024-02-30T01:02:03Z').isFail, isTrue);
  });
}
