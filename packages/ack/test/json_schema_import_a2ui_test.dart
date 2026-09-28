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

  test('client capabilities validate embedded schemas offline', () {
    final schema = load('client_capabilities.json');
    Map<String, Object?> withComponentType(String type) => {
      'v0.9': {
        'supportedCatalogIds': <String>[],
        'inlineCatalogs': [
          {
            'catalogId': 'example',
            'components': {
              'Button': {'type': type},
            },
          },
        ],
      },
    };
    expect(schema.safeParse(withComponentType('string')).isOk, isTrue);
    expect(schema.safeParse(withComponentType('invalid')).isFail, isTrue);
  });

  test('client event date-time format is an annotation by default', () {
    final schema = load('client_to_server.json');
    final message = {
      'version': 'v0.9',
      'action': {
        'name': 'click',
        'surfaceId': 'surface',
        'sourceComponentId': 'button',
        'timestamp': 'not-a-date',
        'context': <String, Object?>{},
      },
    };
    expect(schema.safeParse(message).isOk, isTrue);
    expect(
      schema.safeParse({
        ...message,
        'action': {...message['action']! as Map, 'timestamp': 1},
      }).isFail,
      isTrue,
    );
  });
}
