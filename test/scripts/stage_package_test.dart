import 'dart:io';

import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  late Directory output;

  setUp(() {
    output = Directory.systemTemp.createTempSync('ack-stage-');
  });

  tearDown(() {
    if (output.existsSync()) output.deleteSync(recursive: true);
  });

  test('a staged package leaves the workspace and keeps the lint config', () {
    final result = _stage(['ack_firebase_ai', '${output.path}/staged']);

    expect(result.exitCode, 0, reason: '${result.stderr}');
    final staged = '${result.stdout}'.trim();
    expect(staged, endsWith('packages/ack_firebase_ai'));

    final pubspec = loadYaml(File('$staged/pubspec.yaml').readAsStringSync());
    expect((pubspec as Map).containsKey('resolution'), isFalse);
    expect(
      pubspec.containsKey('dependency_overrides'),
      isFalse,
      reason: 'a staged package must resolve its Ack dependencies from pub.dev',
    );
    expect((pubspec['dependencies'] as Map)['ack'], startsWith('^'));

    expect(
      File('${output.path}/staged/analysis_options.yaml').existsSync(),
      isTrue,
      reason: 'each package analysis_options.yaml includes the root file',
    );
    expect(
      File('$staged/pubspec_overrides.yaml').existsSync(),
      isFalse,
      reason: 'melos path overrides would defeat the hosted resolution check',
    );
  });

  test('--local-deps stages the dependency graph and overrides it', () {
    final result = _stage([
      'ack_generator',
      '${output.path}/staged',
      '--local-deps',
    ]);

    expect(result.exitCode, 0, reason: '${result.stderr}');
    final staged = '${result.stdout}'.trim();

    final pubspec =
        loadYaml(File('$staged/pubspec.yaml').readAsStringSync()) as Map;
    expect(pubspec['dependency_overrides'], {
      'ack': {'path': '../ack'},
    });

    for (final sibling in const ['ack']) {
      final siblingPubspec = File(
        '${output.path}/staged/packages/$sibling/pubspec.yaml',
      );
      expect(siblingPubspec.existsSync(), isTrue);
      expect(
        (loadYaml(siblingPubspec.readAsStringSync()) as Map).containsKey(
          'resolution',
        ),
        isFalse,
      );
    }
    expect(
      Directory('${output.path}/staged/packages/ack_annotations').existsSync(),
      isFalse,
    );
  });

  test('an unknown package reports the usage', () {
    final result = _stage(['not_an_ack_package', '${output.path}/staged']);

    expect(result.exitCode, 64);
    expect(result.stderr, contains('Unknown package'));
  });
}

ProcessResult _stage(List<String> args) => Process.runSync(
  Platform.resolvedExecutable,
  ['scripts/stage_package.dart', ...args],
);
