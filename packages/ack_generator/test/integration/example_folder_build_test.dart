@Tags(['integration'])
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void _copyDirectory(
  Directory source,
  Directory destination, {
  bool keepGenerated = false,
}) {
  destination.createSync(recursive: true);
  for (final entity in source.listSync()) {
    final name = p.basename(entity.path);
    if (name == '.dart_tool' || name == 'build') {
      continue;
    }
    final target = p.join(destination.path, name);
    if (entity is Directory) {
      _copyDirectory(entity, Directory(target), keepGenerated: keepGenerated);
    } else if (entity is File &&
        (keepGenerated ||
            (!name.endsWith('.ack.dart') && !name.endsWith('.g.dart')))) {
      entity.copySync(target);
    }
  }
}

Future<ProcessResult> _run(Directory directory, List<String> arguments) {
  return Process.run('dart', arguments, workingDirectory: directory.path);
}

void _expectSuccess(ProcessResult result, String command) {
  expect(
    result.exitCode,
    0,
    reason:
        '$command failed\nSTDOUT:\n${result.stdout}\nSTDERR:\n${result.stderr}',
  );
}

Map<String, String> _generatedContents(Directory directory) => {
  for (final file
      in directory
          .listSync(recursive: true)
          .whereType<File>()
          .where(
            (file) =>
                file.path.endsWith('.ack.dart') ||
                file.path.endsWith('.g.dart'),
          ))
    p.relative(file.path, from: directory.path): file.readAsStringSync(),
};

void main() {
  test(
    'example clean-builds, analyzes, tests, and regenerates deterministically',
    () async {
      var projectRoot = Directory.current;
      while (!Directory(
        p.join(projectRoot.path, 'packages', 'ack_generator'),
      ).existsSync()) {
        projectRoot = projectRoot.parent;
      }
      final sourceExample = Directory(p.join(projectRoot.path, 'example'));
      final temporaryRoot = await Directory.systemTemp.createTemp(
        'ack_generator_example_',
      );
      final temporaryExample = Directory(
        p.join(temporaryRoot.path, 'ack_example'),
      );

      try {
        _copyDirectory(sourceExample, temporaryExample);
        File(
          p.join(temporaryExample.path, 'analysis_options.yaml'),
        ).writeAsStringSync('''
analyzer:
  language:
    strict-casts: true
''');
        File(p.join(temporaryExample.path, 'pubspec.yaml')).writeAsStringSync(
          '''
name: ack_example
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
  test: ^1.29.0
dependency_overrides:
  ack:
    path: ${p.join(projectRoot.path, 'packages', 'ack')}
''',
        );

        _expectSuccess(
          await _run(temporaryExample, ['pub', 'get']),
          'dart pub get',
        );
        _expectSuccess(
          await _run(temporaryExample, ['run', 'build_runner', 'build']),
          'clean build_runner build',
        );

        final first = _generatedContents(temporaryExample);
        expect(first.keys, {
          'lib/additional_properties_example.ack.dart',
          'lib/additional_properties_example.ack.g.dart',
          'lib/class_first_models.ack.dart',
          'lib/class_first_models.ack.g.dart',
          'lib/pet.ack.dart',
          'lib/pet.ack.g.dart',
          'lib/schema_types_discriminated.ack.dart',
          'lib/schema_types_discriminated.ack.g.dart',
          'lib/schema_types_edge_cases.ack.dart',
          'lib/schema_types_edge_cases.ack.g.dart',
          'lib/schema_types_primitives.ack.dart',
          'lib/schema_types_primitives.ack.g.dart',
          'lib/schema_types_simple.ack.dart',
          'lib/schema_types_simple.ack.g.dart',
          'lib/schema_types_transforms.ack.dart',
          'lib/schema_types_transforms.ack.g.dart',
          'lib/user_with_color.ack.dart',
          'lib/user_with_color.ack.g.dart',
        });
        for (final entry in first.entries) {
          final isClassFirst = entry.key.contains('class_first_models');
          if (entry.key.endsWith('.ack.dart')) {
            if (isClassFirst) {
              expect(entry.value, contains(r'mixin _$AccountAck'));
              expect(entry.value, contains('final _accountSchema'));
              expect(
                entry.value,
                contains('abstract final class AccountSchema'),
              );
              expect(entry.value, isNot(contains('final accountSchema')));
            } else {
              expect(entry.value, contains('class '));
              expect(entry.value, contains('generatedJson'));
            }
            expect(entry.value, isNot(contains('extension type')));
            expect(entry.value, isNot(contains('fromMap')));
            expect(entry.value, isNot(contains('toMap')));
          } else {
            expect(entry.value, contains('JsonSerializableGenerator'));
            expect(
              entry.value,
              contains(
                isClassFirst ? '_ackAccountFromRuntime' : '_ackFromRuntime',
              ),
            );
          }
        }

        _expectSuccess(
          await _run(temporaryExample, ['analyze', '--fatal-infos']),
          'dart analyze --fatal-infos',
        );
        _expectSuccess(await _run(temporaryExample, ['test']), 'dart test');
        _expectSuccess(
          await _run(temporaryExample, ['run', 'build_runner', 'build']),
          'second build_runner build',
        );
        expect(_generatedContents(temporaryExample), first);
      } finally {
        temporaryRoot.deleteSync(recursive: true);
      }
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test(
    'rebuilds when generated outputs are already present',
    () async {
      var projectRoot = Directory.current;
      while (!Directory(
        p.join(projectRoot.path, 'packages', 'ack_generator'),
      ).existsSync()) {
        projectRoot = projectRoot.parent;
      }
      final sourceExample = Directory(p.join(projectRoot.path, 'example'));
      final temporaryRoot = await Directory.systemTemp.createTemp(
        'ack_generator_example_present_',
      );
      final temporaryExample = Directory(
        p.join(temporaryRoot.path, 'ack_example'),
      );

      try {
        _copyDirectory(sourceExample, temporaryExample, keepGenerated: true);
        File(
          p.join(temporaryExample.path, 'analysis_options.yaml'),
        ).writeAsStringSync('''
analyzer:
  language:
    strict-casts: true
''');
        File(p.join(temporaryExample.path, 'pubspec.yaml')).writeAsStringSync(
          '''
name: ack_example
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
  test: ^1.29.0
dependency_overrides:
  ack:
    path: ${p.join(projectRoot.path, 'packages', 'ack')}
''',
        );

        _expectSuccess(
          await _run(temporaryExample, ['pub', 'get']),
          'dart pub get',
        );

        final schemaFile = File(
          p.join(temporaryExample.path, 'lib', 'schema_types_simple.dart'),
        );
        schemaFile.writeAsStringSync(
          schemaFile.readAsStringSync().replaceFirst(
            "'name': Ack.string(),",
            "'name': Ack.string(),\n  'nickname': Ack.string().optional(),",
          ),
        );
        final generatedFile = File(
          p.join(temporaryExample.path, 'lib', 'schema_types_simple.ack.dart'),
        );
        final before = generatedFile.readAsStringSync();

        _expectSuccess(
          await _run(temporaryExample, ['run', 'build_runner', 'build']),
          'outputs-present build_runner build',
        );

        final after = generatedFile.readAsStringSync();
        expect(after, isNot(equals(before)));
        expect(after, contains('nickname'));
        _expectSuccess(
          await _run(temporaryExample, ['analyze', '--fatal-infos']),
          'dart analyze --fatal-infos',
        );
        _expectSuccess(await _run(temporaryExample, ['test']), 'dart test');
      } finally {
        temporaryRoot.deleteSync(recursive: true);
      }
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
