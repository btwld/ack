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
    'the model-generation guide sample builds and runs in both directions',
    () async {
      var projectRoot = Directory.current;
      while (!Directory(p.join(projectRoot.path, 'packages', 'ack_generator'))
          .existsSync()) {
        projectRoot = projectRoot.parent;
      }

      final guide = File(
        p.join(
          projectRoot.path,
          'docs',
          'core-concepts',
          'typesafe-schemas.mdx',
        ),
      ).readAsStringSync();
      final sample = RegExp(r'```dart title="lib/models.dart"\n([\s\S]*?)\n```')
          .firstMatch(guide)
          ?.group(1);
      expect(
        sample,
        isNotNull,
        reason: 'The guide must contain its canonical lib/models.dart sample.',
      );

      final temporary = await Directory.systemTemp.createTemp(
        'ack_model_generation_guide_',
      );
      try {
        Directory(p.join(temporary.path, 'lib')).createSync();
        Directory(p.join(temporary.path, 'test')).createSync();
        File(p.join(temporary.path, 'pubspec.yaml')).writeAsStringSync('''
name: ack_model_generation_guide
publish_to: none
environment:
  sdk: '>=3.13.0 <4.0.0'
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
        File(p.join(temporary.path, 'lib', 'models.dart'))
            .writeAsStringSync(sample!);
        File(p.join(temporary.path, 'test', 'models_test.dart'))
            .writeAsStringSync(r'''
import 'package:ack_model_generation_guide/models.dart';
import 'package:test/test.dart';

void main() {
  test('schema-first generates a model from a schema', () {
    final order = Order.parse({'id': 'o1', 'total': 12.5});
    expect(order.id, 'o1');
    expect(order.toJson(), {'id': 'o1', 'total': 12.5});
  });

  test('class-first generates a schema from a model', () {
    final json = {
      'display_name': 'Ada',
      'email': 'ada@example.com',
      'middle_name': null,
    };
    final account = Account.fromJson(json);
    expect(account.role, 'member');
    expect(account.website, isNull);
    final encoded = {
      'display_name': 'Ada',
      'email': 'ada@example.com',
      'middle_name': null,
      'role': 'member',
    };
    expect(account.toJson(), encoded);
    expect(AccountSchema.parse(json).displayName, 'Ada');
    expect(AccountSchema.safeParse({...json, 'email': 'invalid'}).isFail, isTrue);
    expect(AccountSchema.encode(account), encoded);
    expect(AccountSchema.safeEncode(account).isOk, isTrue);
    expect(AccountSchema.toJsonSchema()['type'], 'object');
    expect(AccountSchema.toSchemaModel(), isNotNull);
    expect(AccountSchema.wireSchema, isNotNull);
    expect(account.copyWith(role: 'admin').role, 'admin');
    expect(account.copyWith().role, 'member');
  });
}
''');

        _expectSuccess(await _run(temporary, ['pub', 'get']), 'dart pub get');
        _expectSuccess(
          await _run(temporary, ['run', 'build_runner', 'build']),
          'build_runner build',
        );
        _expectSuccess(
          await _run(temporary, ['analyze', '--fatal-infos']),
          'dart analyze --fatal-infos',
        );
        _expectSuccess(await _run(temporary, ['test']), 'dart test');
      } finally {
        temporary.deleteSync(recursive: true);
      }
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
