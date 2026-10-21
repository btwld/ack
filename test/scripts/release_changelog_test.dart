import 'dart:io';

import 'package:test/test.dart';

import '../../scripts/src/release_changelog.dart';

void main() {
  group('updateReleaseChangelog', () {
    test('matches stable headings exactly and preserves prereleases', () {
      const input = '''
## 1.0.0

Old stable notes.

## 1.0.0-beta.2

Keep beta two.

## 1.0.0-beta.1

Keep beta one.

## 1.0.0

Duplicate stable notes.
''';

      final result = updateReleaseChangelog(
        input,
        version: '1.0.0',
        releaseUrl: 'https://example.test/v1.0.0',
      );

      expect(result.found, isTrue);
      expect(result.changed, isTrue);
      expect(result.content, contains('## 1.0.0-beta.2'));
      expect(result.content, contains('Keep beta two.'));
      expect(result.content, contains('## 1.0.0-beta.1'));
      expect(result.content, contains('Keep beta one.'));
      expect(
        RegExp(r'^## 1\.0\.0$', multiLine: true).allMatches(result.content),
        hasLength(1),
      );
      expect(
        result.content,
        contains(
          '* See [release notes](https://example.test/v1.0.0) for details.',
        ),
      );
    });

    test('preserves bracket heading style', () {
      const input = '## [2.0.0] - 2026-01-01\n\nNotes.\n';

      final result = updateReleaseChangelog(
        input,
        version: '2.0.0',
        releaseUrl: 'https://example.test/v2.0.0',
      );

      expect(result.content, startsWith('## [2.0.0]\n'));
    });

    test('reports a missing exact version without modifying content', () {
      const input = '## 1.0.0-beta.1\n\nNotes.\n';

      final result = updateReleaseChangelog(
        input,
        version: '1.0.0',
        releaseUrl: 'https://example.test/v1.0.0',
      );

      expect(result.found, isFalse);
      expect(result.changed, isFalse);
      expect(result.content, input);
    });

    test('is idempotent after the release link is installed', () {
      const input = '## 3.0.0\n\nOriginal notes.\n';
      const releaseUrl = 'https://example.test/v3.0.0';

      final first = updateReleaseChangelog(
        input,
        version: '3.0.0',
        releaseUrl: releaseUrl,
      );
      final second = updateReleaseChangelog(
        first.content,
        version: '3.0.0',
        releaseUrl: releaseUrl,
      );

      expect(first.changed, isTrue);
      expect(second.found, isTrue);
      expect(second.changed, isFalse);
      expect(second.content, first.content);
    });
  });

  test('failed batches leave every changelog unchanged', () async {
    final scriptPath = File(
      'scripts/update_release_changelog.dart',
    ).absolute.path;
    final workingDirectory = Directory.systemTemp.createTempSync(
      'ack-release-changelog-',
    );
    addTearDown(() => workingDirectory.deleteSync(recursive: true));

    const paths = [
      'packages/ack/CHANGELOG.md',
      'packages/ack_generator/CHANGELOG.md',
      'packages/ack_firebase_ai/CHANGELOG.md',
      'packages/ack_json_schema_builder/CHANGELOG.md',
      'packages/ack_mcp_dart/CHANGELOG.md',
    ];
    final originals = <String, String>{};
    for (final path in paths) {
      final content = path.contains('ack_mcp_dart')
          ? '## 0.9.0\n\nOlder notes.\n'
          : '## 1.0.0\n\nRelease notes.\n';
      originals[path] = content;
      File('${workingDirectory.path}/$path')
        ..createSync(recursive: true)
        ..writeAsStringSync(content);
    }

    final result = await Process.run(Platform.resolvedExecutable, [
      scriptPath,
      '1.0.0',
    ], workingDirectory: workingDirectory.path);

    expect(result.exitCode, 1);
    for (final path in paths) {
      expect(
        File('${workingDirectory.path}/$path').readAsStringSync(),
        originals[path],
        reason: '$path should not change when batch validation fails',
      );
    }
  });
}
