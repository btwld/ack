import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  const fixtureRoot = 'test/fixtures/json_schema_2020_12_full';

  test('the pinned corpus and offline remotes are complete JSON assets', () {
    final root = Directory(fixtureRoot);
    final jsonFiles = root
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.json'))
        .toList();
    expect(jsonFiles, hasLength(159));

    for (final file in jsonFiles) {
      expect(
        () => jsonDecode(file.readAsStringSync()),
        returnsNormally,
        reason: p.relative(file.path, from: root.path),
      );
    }

    final remotes = jsonFiles.where(
      (file) => p.isWithin(p.join(root.path, 'remotes'), file.path),
    );
    expect(remotes, hasLength(79));
    expect(File(p.join(root.path, 'LICENSE')).existsSync(), isTrue);
    expect(
      File(p.join(root.path, 'README.md')).readAsStringSync(),
      contains('80c87e8fca8b207a7a7ae944b875f0fcf889f46a'),
    );
  });

  test('all required 2020-12 groups have executable case data', () {
    final directory = Directory(p.join(fixtureRoot, 'draft2020-12'));
    final files = directory
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.json'))
        .toList();
    expect(files, hasLength(46));

    var groupCount = 0;
    var caseCount = 0;
    for (final file in files) {
      final groups = (jsonDecode(file.readAsStringSync()) as List<Object?>)
          .cast<Map<String, Object?>>();
      for (final group in groups) {
        expect(group['description'], isA<String>(), reason: file.path);
        expect(group.containsKey('schema'), isTrue, reason: file.path);
        expect(
          group['schema'],
          anyOf(isA<bool>(), isA<Map<String, Object?>>()),
        );
        final cases = (group['tests'] as List<Object?>)
            .cast<Map<String, Object?>>();
        expect(cases, isNotEmpty, reason: file.path);
        for (final testCase in cases) {
          expect(testCase['description'], isA<String>(), reason: file.path);
          expect(testCase['valid'], isA<bool>(), reason: file.path);
          expect(testCase.containsKey('data'), isTrue, reason: file.path);
        }
        groupCount++;
        caseCount += cases.length;
      }
    }

    expect(groupCount, 384);
    expect(caseCount, 1301);
  });
}
