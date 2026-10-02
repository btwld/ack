@Tags(['integration'])
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

Future<ProcessResult> _run(Directory directory, List<String> arguments) =>
    Process.run('dart', arguments, workingDirectory: directory.path);

void main() {
  test(
    'a clean build rejects a two-library class-first cycle with a field path',
    () async {
      var projectRoot = Directory.current;
      while (!Directory(
        p.join(projectRoot.path, 'packages', 'ack_generator'),
      ).existsSync()) {
        projectRoot = projectRoot.parent;
      }
      final temporary = await Directory.systemTemp.createTemp(
        'ack_class_first_cycle_',
      );
      addTearDown(() => temporary.deleteSync(recursive: true));
      Directory(p.join(temporary.path, 'lib')).createSync();

      File(p.join(temporary.path, 'pubspec.yaml')).writeAsStringSync('''
name: ack_class_first_cycle
publish_to: none
environment:
  sdk: '>=3.9.0 <4.0.0'
dependencies:
  ack:
    path: ${p.join(projectRoot.path, 'packages', 'ack')}
dev_dependencies:
  ack_generator:
    path: ${p.join(projectRoot.path, 'packages', 'ack_generator')}
  build_runner: ^2.15.0
dependency_overrides:
  ack:
    path: ${p.join(projectRoot.path, 'packages', 'ack')}
''');
      File(p.join(temporary.path, 'lib', 'parent.dart')).writeAsStringSync(r'''
import 'package:ack/ack.dart';

import 'child.dart';

part 'parent.ack.dart';
part 'parent.ack.g.dart';

@Schemable()
final class Parent with _$ParentAck {
  const Parent({required this.child});

  final Child child;
}
''');
      File(p.join(temporary.path, 'lib', 'child.dart')).writeAsStringSync(r'''
import 'package:ack/ack.dart';

import 'parent.dart';

part 'child.ack.dart';
part 'child.ack.g.dart';

@Schemable()
final class Child with _$ChildAck {
  const Child({required this.parent});

  final Parent parent;
}
''');

      final pubGet = await _run(temporary, ['pub', 'get']);
      expect(
        pubGet.exitCode,
        0,
        reason: 'dart pub get failed\n${pubGet.stdout}\n${pubGet.stderr}',
      );

      final build = await _run(temporary, [
        'run',
        'build_runner',
        'build',
        '--delete-conflicting-outputs',
      ]);
      final output = '${build.stdout}\n${build.stderr}';
      expect(build.exitCode, isNot(0), reason: output);
      expect(output, contains('recursive class-first schema graph'));
      expect(output, anyOf(contains('Child.parent'), contains('Parent.child')));
      expect(
        File(p.join(temporary.path, 'lib', 'parent.ack.dart')).existsSync(),
        isFalse,
      );
      expect(
        File(p.join(temporary.path, 'lib', 'child.ack.dart')).existsSync(),
        isFalse,
      );
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
