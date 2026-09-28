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

  test('builder bridge treats formats as annotations by default', () {
    final model = jsb.Schema.fromMap({'type': 'string', 'format': 'email'});
    final schema = model.toAckSchema();
    expect(schema.safeParse('not an email').isOk, isTrue);
    expect(schema.safeParse(42).isFail, isTrue);
  });
}
