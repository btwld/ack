import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('the repository version is releasable under its own tag', () async {
    final tag = 'v${_declaredAckVersion()}';

    final result = await _verify([tag, '--skip-ancestry']);

    expect(result.exitCode, 0, reason: '${result.stderr}');
    expect(result.stdout, contains('$tag is releasable.'));
  });

  test('a tag that no package declares is rejected', () async {
    final result = await _verify(['v9.9.9', '--skip-ancestry']);

    expect(result.exitCode, 1);
    expect(result.stderr, contains('packages/ack/pubspec.yaml declares'));
    expect(result.stderr, contains('has no "## 9.9.9" heading'));
  });

  test('a tag without the release prefix is rejected', () async {
    final result = await _verify(['1.2.0', '--skip-ancestry']);

    expect(result.exitCode, 1);
    expect(result.stderr, contains('is not a'));
  });

  test('a commit outside the release branch is rejected', () async {
    final result = await _verify([
      'v${_declaredAckVersion()}',
      '--commit=${'0' * 40}',
      '--main-ref=HEAD',
    ]);

    expect(result.exitCode, 1);
    expect(result.stderr, contains('is not reachable from HEAD'));
  });

  test('a missing release branch is rejected', () async {
    final result = await _verify([
      'v${_declaredAckVersion()}',
      '--commit=HEAD',
      '--main-ref=refs/heads/ack-release-branch-that-does-not-exist',
    ]);

    expect(result.exitCode, 1);
    expect(result.stderr, contains('is not available'));
  });

  test('an unknown option reports the usage', () async {
    final result = await _verify(['v${_declaredAckVersion()}', '--unknown']);

    expect(result.exitCode, 64);
    expect(result.stderr, contains('Usage:'));
  });
}

Future<ProcessResult> _verify(List<String> args) => Process.run(
  Platform.resolvedExecutable,
  ['scripts/verify_release_tag.dart', ...args],
);

/// Reads the version that the core package currently declares.
String _declaredAckVersion() => File('packages/ack/pubspec.yaml')
    .readAsLinesSync()
    .firstWhere((line) => line.startsWith('version:'))
    .split(':')
    .last
    .trim();
