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

  test('client events reject the unsupported date-time format', () {
    expect(
      () => load('client_to_server.json'),
      throwsA(
        isA<JsonSchemaImportException>().having(
          (error) => error.diagnostics.single.keyword,
          'keyword',
          'format',
        ),
      ),
    );
  });
}
