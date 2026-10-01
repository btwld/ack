@Tags(['integration'])
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

Directory _projectRoot() {
  var projectRoot = Directory.current;
  while (!Directory(
    p.join(projectRoot.path, 'packages', 'ack_generator'),
  ).existsSync()) {
    projectRoot = projectRoot.parent;
  }
  return projectRoot;
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

int _helperDefinitionCount(String source, String className, String suffix) {
  return RegExp(
    '^[^\\n]*_\\\$$className$suffix\\(',
    multiLine: true,
  ).allMatches(source).length;
}

void main() {
  test(
    'ack_generator alone generates json_serializable Ack helpers',
    () async {
      final projectRoot = _projectRoot();
      final temporary = await Directory.systemTemp.createTemp(
        'ack_json_ack_only_',
      );
      try {
        Directory(p.join(temporary.path, 'lib')).createSync();
        File(p.join(temporary.path, 'pubspec.yaml')).writeAsStringSync('''
name: ack_json_ack_only
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
        File(p.join(temporary.path, 'lib', 'user.dart')).writeAsStringSync(r'''
import 'package:ack/ack.dart';

part 'user.ack.dart';
part 'user.ack.g.dart';

@Schemable()
final userSchema = Ack.object({
  'name': Ack.string(),
  'createdAt': Ack.datetime(),
});
''');

        _expectSuccess(await _run(temporary, ['pub', 'get']), 'dart pub get');
        _expectSuccess(
          await _run(temporary, ['run', 'build_runner', 'build']),
          'clean build_runner build',
        );

        final ackPart = File(
          p.join(temporary.path, 'lib', 'user.ack.dart'),
        ).readAsStringSync();
        final jsonPart = File(
          p.join(temporary.path, 'lib', 'user.ack.g.dart'),
        ).readAsStringSync();

        expect(ackPart, contains('@Schemable.generatedJson'));
        expect(ackPart, contains(r'_$UserFromJson'));
        expect(ackPart, contains('_ackFromRuntimeCreatedAt'));
        expect(jsonPart, contains('JsonSerializableGenerator'));
        expect(jsonPart, contains('User._ackFromRuntimeName(json[\'name\'])'));
        expect(
          jsonPart,
          contains('User._ackFromRuntimeCreatedAt(json[\'createdAt\'])'),
        );
        expect(jsonPart, contains('User._ackToRuntimeName(instance.name)'));
        expect(_helperDefinitionCount(jsonPart, 'User', 'FromJson'), 1);
        expect(_helperDefinitionCount(jsonPart, 'User', 'ToJson'), 1);
        expect(jsonPart, isNot(contains("value['name']")));
      } finally {
        temporary.deleteSync(recursive: true);
      }
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test(
    'ordinary json_serializable coexists without duplicate Ack helpers',
    () async {
      final projectRoot = _projectRoot();
      final temporary = await Directory.systemTemp.createTemp(
        'ack_json_coexist_',
      );
      try {
        Directory(p.join(temporary.path, 'lib')).createSync();
        Directory(p.join(temporary.path, 'test')).createSync();
        File(p.join(temporary.path, 'pubspec.yaml')).writeAsStringSync('''
name: ack_json_coexist
publish_to: none
environment:
  sdk: '>=3.9.0 <4.0.0'
dependencies:
  ack:
    path: ${p.join(projectRoot.path, 'packages', 'ack')}
  json_annotation: ^4.12.0
dev_dependencies:
  ack_generator:
    path: ${p.join(projectRoot.path, 'packages', 'ack_generator')}
  build_runner: ^2.15.0
  json_serializable: ^6.14.1
  test: ^1.29.0
dependency_overrides:
  ack:
    path: ${p.join(projectRoot.path, 'packages', 'ack')}
''');
        File(p.join(temporary.path, 'build.yaml')).writeAsStringSync('''
targets:
  \$default:
    builders:
      # Both legacy AckType and source_gen own `.g.dart` by contract. This
      # modern-only library disables the unused legacy builder so the ordinary
      # combining builder remains the sole `.g.dart` owner.
      ack_generator:ack_generator:
        enabled: false
      json_serializable:
        options:
          include_if_null: true
''');
        File(p.join(temporary.path, 'lib', 'same.dart')).writeAsStringSync(r'''
import 'package:ack/ack.dart';
import 'package:json_annotation/json_annotation.dart';

part 'same.ack.dart';
part 'same.ack.g.dart';
part 'same.g.dart';

@Schemable()
final userSchema = Ack.object({
  'name': Ack.string(),
  'nickname': Ack.string().optional(),
});

@JsonSerializable()
final class SameEnvelope {
  const SameEnvelope({required this.count, this.label});
  factory SameEnvelope.fromJson(Map<String, dynamic> json) =>
      _$SameEnvelopeFromJson(json);
  final int count;
  final String? label;
  Map<String, dynamic> toJson() => _$SameEnvelopeToJson(this);
}
''');
        File(
          p.join(temporary.path, 'test', 'runtime_test.dart'),
        ).writeAsStringSync(r'''
import 'package:ack_json_coexist/same.dart';
import 'package:test/test.dart';

void main() {
  test('Ack optional null stays omitted when consumer include_if_null is true', () {
    expect(User(name: 'Ada').toJson(), {'name': 'Ada'});
    expect(const SameEnvelope(count: 1).toJson(), {
      'count': 1,
      'label': null,
    });
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

        final ackJson = File(
          p.join(temporary.path, 'lib', 'same.ack.g.dart'),
        ).readAsStringSync();
        final ordinaryJson = File(
          p.join(temporary.path, 'lib', 'same.g.dart'),
        ).readAsStringSync();
        expect(_helperDefinitionCount(ackJson, 'User', 'FromJson'), 1);
        expect(_helperDefinitionCount(ackJson, 'User', 'ToJson'), 1);
        expect(_helperDefinitionCount(ordinaryJson, 'User', 'FromJson'), 0);
        expect(_helperDefinitionCount(ordinaryJson, 'User', 'ToJson'), 0);
        expect(
          _helperDefinitionCount(ordinaryJson, 'SameEnvelope', 'FromJson'),
          1,
        );
        expect(
          _helperDefinitionCount(ordinaryJson, 'SameEnvelope', 'ToJson'),
          1,
        );
        expect(ackJson, contains('User._ackFromRuntimeName(json[\'name\'])'));
        expect(ackJson, contains('JsonSerializableGenerator'));
        _expectSuccess(await _run(temporary, ['test']), 'dart test');
      } finally {
        temporary.deleteSync(recursive: true);
      }
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test(
    'prefixed barrel Schemable imports compile through the JSON phase',
    () async {
      final projectRoot = _projectRoot();
      final temporary = await Directory.systemTemp.createTemp(
        'ack_json_barrel_',
      );
      try {
        Directory(p.join(temporary.path, 'lib')).createSync();
        Directory(p.join(temporary.path, 'test')).createSync();
        File(p.join(temporary.path, 'pubspec.yaml')).writeAsStringSync('''
name: ack_json_barrel
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
''');
        File(
          p.join(temporary.path, 'lib', 'role.dart'),
        ).writeAsStringSync('enum Role { admin, member }\n');
        File(p.join(temporary.path, 'lib', 'support.dart')).writeAsStringSync(
          "export 'package:ack/ack.dart';\n"
          "export 'package:ack/annotations.dart';\n"
          "export 'role.dart';\n",
        );
        File(p.join(temporary.path, 'lib', 'user.dart')).writeAsStringSync(r'''
import 'support.dart' as support;

part 'user.ack.dart';
part 'user.ack.g.dart';

@support.Schemable()
final userSchema = support.Ack.object({
  'name': support.Ack.string(),
  'role': support.Ack.enumValues(support.Role.values),
});
''');
        File(
          p.join(temporary.path, 'test', 'runtime_test.dart'),
        ).writeAsStringSync(r'''
import 'package:ack_json_barrel/user.dart';
import 'package:test/test.dart';

void main() {
  test('prefixed barrel models compile and round-trip', () {
    expect(User.parse({'name': 'Ada', 'role': 'admin'}).toJson(), {
      'name': 'Ada',
      'role': 'admin',
    });
  });
}
''');

        _expectSuccess(await _run(temporary, ['pub', 'get']), 'dart pub get');
        _expectSuccess(
          await _run(temporary, ['run', 'build_runner', 'build']),
          'clean build_runner build',
        );
        _expectSuccess(
          await _run(temporary, ['analyze', '--fatal-infos']),
          'dart analyze --fatal-infos',
        );

        final ackPart = File(
          p.join(temporary.path, 'lib', 'user.ack.dart'),
        ).readAsStringSync();
        expect(ackPart, contains('@support.Schemable.generatedJson'));
        expect(ackPart, contains('support.AckModelAdapter'));
        expect(ackPart, contains('final support.Role role;'));
        _expectSuccess(await _run(temporary, ['test']), 'dart test');
      } finally {
        temporary.deleteSync(recursive: true);
      }
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
