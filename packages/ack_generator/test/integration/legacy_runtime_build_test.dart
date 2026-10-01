@Tags(['integration'])
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

Future<ProcessResult> _run(Directory directory, List<String> arguments) =>
    Process.run('dart', arguments, workingDirectory: directory.path);

void _expectSuccess(ProcessResult result, String command) {
  expect(
    result.exitCode,
    0,
    reason:
        '$command failed\nSTDOUT:\n${result.stdout}\nSTDERR:\n${result.stderr}',
  );
}

void main() {
  test(
    'an unchanged Ack 1.1 source builds and reports the migration deprecation',
    () async {
      var projectRoot = Directory.current;
      while (!Directory(p.join(projectRoot.path, 'packages', 'ack_generator'))
          .existsSync()) {
        projectRoot = projectRoot.parent;
      }
      final temporary = await Directory.systemTemp.createTemp(
        'ack_legacy_compat_',
      );
      try {
        Directory(p.join(temporary.path, 'lib')).createSync();
        Directory(p.join(temporary.path, 'test')).createSync();
        File(p.join(temporary.path, 'pubspec.yaml')).writeAsStringSync('''
name: ack_legacy_compat
publish_to: none
environment:
  sdk: '>=3.9.0 <4.0.0'
dependencies:
  ack:
    path: ${p.join(projectRoot.path, 'packages', 'ack')}
  ack_annotations:
    path: ${p.join(projectRoot.path, 'packages', 'ack_annotations')}
dev_dependencies:
  ack_generator:
    path: ${p.join(projectRoot.path, 'packages', 'ack_generator')}
  build_runner: ^2.15.0
  test: ^1.29.0
dependency_overrides:
  ack:
    path: ${p.join(projectRoot.path, 'packages', 'ack')}
  ack_annotations:
    path: ${p.join(projectRoot.path, 'packages', 'ack_annotations')}
''');
        File(p.join(temporary.path, 'lib', 'legacy.dart'))
            .writeAsStringSync(r'''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

part 'legacy.g.dart';

@AckType(name: 'LegacyUser')
final userSchema = Ack.object({
  'name': Ack.string(),
}).passthrough();
''');
        File(p.join(temporary.path, 'test', 'legacy_test.dart'))
            .writeAsStringSync(r'''
import 'package:ack_legacy_compat/legacy.dart';
import 'package:test/test.dart';

List<String> sortedKeys(Map<String, Object?> value) =>
    value.keys.toList()..sort();

void main() {
  test('legacy extension type keeps its Ack 1.1 API', () {
    final user = LegacyUserType.parse({'name': 'Ada', 'role': 'admin'});
    final Map<String, Object?> map = user;
    expect(user.name, 'Ada');
    expect(user['name'], 'Ada');
    expect(user.args, {'role': 'admin'});
    expect(map.length, 2);
    expect(sortedKeys(user), ['name', 'role']);
    expect(map.values, containsAll(['Ada', 'admin']));
    expect(
      map.entries.map((entry) => '${entry.key}=${entry.value}'),
      containsAll(['name=Ada', 'role=admin']),
    );
    expect(map.containsKey('name'), isTrue);
    expect(map.containsValue('admin'), isTrue);
    expect(LegacyUserType.safeParse({'name': 'Ada'}).isOk, isTrue);
  });
}
''');

        _expectSuccess(await _run(temporary, ['pub', 'get']), 'dart pub get');
        _expectSuccess(
          await _run(temporary, ['run', 'build_runner', 'build']),
          'build_runner build',
        );
        _expectSuccess(await _run(temporary, ['test']), 'dart test');

        final analysis = await _run(temporary, ['analyze']);
        _expectSuccess(analysis, 'dart analyze');
        final diagnostics = '${analysis.stdout}\n${analysis.stderr}';
        expect(
          diagnostics,
          contains(
            'Use @AckInfer() for schema-first models or @AckModel() for '
            'class-first models. AckType will be removed in 2.0.0.',
          ),
        );
      } finally {
        temporary.deleteSync(recursive: true);
      }
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
