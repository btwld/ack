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
      if (file.path.endsWith('.json') && !file.path.endsWith('/example.json'))
        base.resolve(file.uri.pathSegments.last): jsonDecode(
          file.readAsStringSync(),
        ),
  };

  JsonSchemaImportResult load(String name, {bool allowUnsupported = false}) =>
      importJsonSchema(
        documents[base.resolve(name)]!,
        baseUri: base.resolve(name),
        documents: documents,
        allowUnsupported: allowUnsupported,
      );

  test('all eleven upstream protocol documents resolve offline', () {
    for (final entry in documents.entries) {
      final name = entry.key.pathSegments.last;
      if (name == 'catalog.json') continue;
      final imported = load(name, allowUnsupported: true);
      expect(imported.schema.toJsonSchema(), isNotEmpty, reason: name);
      if (imported.isExact) {
        expect(load(name).isExact, isTrue, reason: name);
      } else {
        expect(
          () => load(name),
          throwsA(isA<JsonSchemaImportException>()),
          reason: name,
        );
      }
    }
  });

  test(
    'client capabilities explicitly report three meta-schema references',
    () {
      final result = load('client_capabilities.json', allowUnsupported: true);
      expect(result.diagnostics, hasLength(3));
      expect(
        result.diagnostics.map((d) => d.code),
        everyElement('unsupported_reference'),
      );
    },
  );

  test('date-time is the only omitted client-event keyword', () {
    final result = load('client_to_server.json', allowUnsupported: true);
    expect(result.diagnostics.single.keyword, 'format');
    expect(
      result.schema.safeParse({'version': 'v0.9', 'action': {}}).isFail,
      isTrue,
    );
  });

  test('basic catalog partial imports keep message and component shapes', () {
    final imported = load('server_to_client.json', allowUnsupported: true);
    expect(imported.isExact, isFalse);
    expect(
      imported.diagnostics.map((d) => d.keyword),
      contains('unevaluatedProperties'),
    );
    final roundTrip = importJsonSchema(imported.schema.toJsonSchema()).schema;
    final sample =
        jsonDecode(
              File('test/fixtures/a2ui_v0_9/example.json').readAsStringSync(),
            )
            as Map;
    for (final message in sample['messages'] as List) {
      expect(imported.schema.safeParse(message).isOk, isTrue);
      expect(roundTrip.safeParse(message).isOk, isTrue);
    }
    for (final invalid in [
      <String, Object?>{},
      {'version': 'v0.9'},
      {
        'version': 'v0.9',
        'deleteSurface': {'surfaceId': 12},
      },
      {
        'version': 'v0.9',
        'updateComponents': {
          'surfaceId': 'x',
          'components': [
            {'id': 'root', 'component': 'Text', 'text': 12},
          ],
        },
      },
    ]) {
      expect(imported.schema.safeParse(invalid).isFail, isTrue);
      expect(roundTrip.safeParse(invalid).isFail, isTrue);
    }
    // This extra property is precisely an assertion omitted from the catalog.
    final extra = {
      'version': 'v0.9',
      'updateComponents': {
        'surfaceId': 'x',
        'components': [
          {
            'id': 'root',
            'component': 'Text',
            'text': 'ok',
            'notAnA2uiProperty': true,
          },
        ],
      },
    };
    expect(imported.schema.safeParse(extra).isOk, isTrue);
    expect(roundTrip.safeParse(extra).isOk, isTrue);
  });
}
