import 'dart:convert';
import 'dart:io';

import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  final base = Uri.parse('https://a2ui.org/specification/v0_9/');
  final documents = <Uri, Object>{
    for (final file in Directory(
      'test/fixtures/a2ui_v0_9',
    ).listSync().whereType<File>())
      if (file.path.endsWith('.json') &&
          file.uri.pathSegments.last != 'example.json')
        base.resolve(file.uri.pathSegments.last): jsonDecode(
          file.readAsStringSync(),
        ),
  };

  AckSchema<Object, Object> load(String name) => Ack.fromJsonSchema(
    documents[base.resolve(name)]!,
    baseUri: base.resolve(name),
    documents: documents,
  );

  test('supported upstream documents import strictly', () {
    for (final name in [
      'client_data_model.json',
      'common_types.json',
      'server_capabilities.json',
    ]) {
      expect(load(name).toJsonSchema(), isNotEmpty, reason: name);
    }
  });

  test(
    'client capabilities reject meta-schema references with diagnostics',
    () {
      expect(
        () => load('client_capabilities.json'),
        throwsA(
          isA<JsonSchemaImportException>().having(
            (error) => error.diagnostics.map((issue) => issue.code),
            'diagnostic codes',
            everyElement('unsupported_reference'),
          ),
        ),
      );
    },
  );

  test('client events assert the action timestamp format', () {
    final schema = load('client_to_server.json');
    final event = {
      'version': 'v0.9',
      'action': {
        'name': 'submit',
        'surfaceId': 'surface-1',
        'sourceComponentId': 'button-1',
        'timestamp': '2024-02-29T01:02:03Z',
        'context': <String, Object?>{},
      },
    };
    expect(schema.safeParse(event).isOk, isTrue);
    final invalid = {
      ...event,
      'action': {
        ...(event['action']! as Map<String, Object?>),
        'timestamp': '2024-02-30T01:02:03Z',
      },
    };
    expect(schema.safeParse(invalid).isFail, isTrue);
  });
}
