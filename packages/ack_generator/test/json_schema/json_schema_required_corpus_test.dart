import 'dart:convert';
import 'dart:io';

import 'package:ack_generator/src/json_schema/json_schema_library.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  const fixtureRoot = '../ack/test/fixtures/json_schema_2020_12_full';
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

  group('complete required 2020-12 generation corpus', () {
    for (final file in corpus.listSync().whereType<File>()) {
      if (!file.path.endsWith('.json')) continue;
      final filename = p.basename(file.path);
      final groups = (jsonDecode(file.readAsStringSync()) as List)
          .cast<Map<String, Object?>>();
      for (final group in groups) {
        test('$filename: ${group['description']}', () {
          final generated = generateAckSchemaLibrary(
            document: group['schema'],
            documentUri: Uri.parse(
              'http://localhost:1234/draft2020-12/__case__.json',
            ),
            partStem: 'case.schema',
            documents: documents,
            includeParts: false,
          );
          expect(generated.source, contains('final class Root'));
          expect(generated.effectiveDocument, isNotEmpty);
        });
      }
    }
  });
}
