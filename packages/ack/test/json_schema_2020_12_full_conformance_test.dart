import 'dart:convert';
import 'dart:io';

import 'package:ack/ack.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  const fixtureRoot = 'test/fixtures/json_schema_2020_12_full';
  final remoteRoot = Directory('$fixtureRoot/remotes/draft2020-12');
  final documents = <Uri, Object>{
    for (final file in remoteRoot.listSync(recursive: true).whereType<File>())
      if (file.path.endsWith('.json'))
        Uri.parse(
          'http://localhost:1234/draft2020-12/'
          '${p.relative(file.path, from: remoteRoot.path).replaceAll('\\', '/')}',
        ): jsonDecode(
          file.readAsStringSync(),
        )!,
  };
  final corpus = Directory('$fixtureRoot/draft2020-12');

  group('official draft 2020-12 complete required suite', () {
    for (final file in corpus.listSync().whereType<File>()) {
      if (!file.path.endsWith('.json')) continue;
      final filename = p.basename(file.path);
      final groups = (jsonDecode(file.readAsStringSync()) as List)
          .cast<Map<String, Object?>>();
      for (final group in groups) {
        test('$filename: ${group['description']}', () {
          final schema = Ack.fromJsonSchema(
            group['schema']!,
            baseUri: Uri.parse(
              'http://localhost:1234/draft2020-12/__case__.json',
            ),
            documents: documents,
          );
          final roundTrip = Ack.fromJsonSchema(schema.toJsonSchema());
          for (final example in group['tests']! as List) {
            final testCase = example as Map<String, Object?>;
            final expected = testCase['valid'] as bool;
            expect(
              schema.safeParse(testCase['data']).isOk,
              expected,
              reason: testCase['description'] as String,
            );
            expect(
              roundTrip.safeParse(testCase['data']).isOk,
              expected,
              reason: 'export: ${testCase['description']}',
            );
          }
        });
      }
    }
  });
}
