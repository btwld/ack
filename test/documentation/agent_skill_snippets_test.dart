@Tags(['integration'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

const _skillsPath = 'plugins/ack/skills';
const _models = 'build-data-classes-with-ack';
const _providers = 'ack-provider-schemas/references';
const _ackImport = "import 'package:ack/ack.dart';";

void main() {
  test(
    'compile and exercise the Dart snippets shipped in the skills',
    () async {
      final project = await Directory.systemTemp.createTemp(
        'ack_skill_examples',
      );
      addTearDown(() => project.delete(recursive: true));
      await _writeProject(project);
      await _run(project, 'flutter', ['pub', 'get', '--offline']);
      await _run(project, Platform.resolvedExecutable, [
        'run',
        'build_runner',
        'build',
      ]);
      await _run(project, 'flutter', ['test', '--no-pub']);
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}

Future<void> _writeProject(Directory project) async {
  final versions =
      (loadYaml(File('pubspec.lock').readAsStringSync()) as YamlMap)['packages']
          as YamlMap;
  final snippets = _readSnippets();
  final [parse, leafErrors] = snippets.remove('using-ack/SKILL.md')!;
  final [allWarnings] = snippets.remove('using-ack/references/json-schema.md')!;
  final [invoice] = snippets.remove('$_models/SKILL.md')!;
  final [payment] = snippets.remove('$_models/references/schema-first.md')!;
  final [money, theme] = snippets.remove(
    '$_models/references/custom-types.md',
  )!;
  final [search, report, callSearch] = snippets.remove('$_providers/mcp.md')!;
  final [task, generate, gate] = snippets.remove('$_providers/gemini-api.md')!;
  final [firebase, cannedBody] = snippets.remove(
    '$_providers/gemini-firebase.md',
  )!;
  expect(snippets, isEmpty, reason: 'Untested Dart snippets: ${snippets.keys}');

  final buildYaml = RegExp(
    r'^   ```yaml\n([\s\S]*?)^   ```$',
    multiLine: true,
  ).firstMatch(File('$_skillsPath/$_models/SKILL.md').readAsStringSync())![1]!;
  final files = {
    'pubspec.yaml':
        '''
name: ack_skill_examples
publish_to: none
environment:
  sdk: '>=3.13.0 <4.0.0'
dependencies:
  flutter: {sdk: flutter}
  ${_local('ack')}
  ${_local('ack_firebase_ai')}
  ${_local('ack_mcp_dart')}
  ${_locked(versions, 'firebase_ai')}
  ${_locked(versions, 'firebase_core')}
  ${_locked(versions, 'firebase_core_platform_interface')}
  ${_locked(versions, 'http')}
  ${_locked(versions, 'mcp_dart')}
dev_dependencies:
  flutter_test: {sdk: flutter}
  ${_local('ack_generator')}
  ${_locked(versions, 'build_runner')}
dependency_overrides:
  ${_local('ack')}
''',
    'build.yaml': buildYaml
        .split('\n')
        .map((line) => line.trim().isEmpty ? line : line.substring(3))
        .join('\n'),
    'lib/validation.dart':
        '''
import 'dart:convert';
$_ackImport

void validate(
  AckSchema<Object, Object> schema,
  String body,
  void Function(Object) use,
  void Function(String, String) log,
) {
$parse
}

$leafErrors
$allWarnings
''',
    'lib/models/invoice.dart': invoice,
    'lib/models/payment.dart': '$_ackImport\n$payment',
    'lib/models/custom.dart':
        '''
$_ackImport
part 'custom.g.dart';

$money

final class HexColor {
  const HexColor(this.hex);
  final String hex;
  static HexColor parse(String hex) => HexColor(hex);
}

$theme
''',
    'lib/mcp.dart':
        '''
import 'dart:async';
import 'dart:convert';
$search

void registerReport(McpServer server) {
$report
}

Future<CallToolResult> callSearch() async {
$callSearch
  return result;
}
''',
    'lib/gemini.dart':
        '''
import 'dart:convert';
$_ackImport
import 'package:http/http.dart' as http;

$task
$generate

void readReply(Map<String, Object?> body) {
$gate
}
''',
    'lib/firebase.dart': "import 'validation.dart';\n$firebase\n$cannedBody",
    'test/examples_test.dart': File(
      'test/documentation/fixtures/agent_skill_examples.dart.template',
    ).readAsStringSync(),
  };
  for (final entry in files.entries) {
    final file = File(p.join(project.path, entry.key));
    await file.create(recursive: true);
    await file.writeAsString(entry.value);
  }
}

Map<String, List<String>> _readSnippets() {
  final fence = RegExp(r'^ *```dart\n([\s\S]*?)^ *```$', multiLine: true);
  final snippets = <String, List<String>>{};
  for (final file in Directory(_skillsPath).listSync(recursive: true)) {
    if (file is! File || !file.path.endsWith('.md')) continue;
    final blocks = fence.allMatches(file.readAsStringSync());
    if (blocks.isNotEmpty) {
      snippets[p.posix.joinAll(
        p.split(p.relative(file.path, from: _skillsPath)),
      )] = blocks
          .map((block) => block[1]!)
          .toList();
    }
  }
  return snippets;
}

String _local(String name) =>
    '$name: {path: ${jsonEncode(p.absolute('packages', name))}}';

String _locked(YamlMap versions, String name) =>
    '$name: ${jsonEncode((versions[name] as YamlMap)['version'])}';

Future<void> _run(Directory project, String command, List<String> args) async {
  final result = await Process.run(
    command,
    args,
    workingDirectory: project.path,
  );
  expect(
    result.exitCode,
    0,
    reason: '$command ${args.join(' ')}\n${result.stdout}\n${result.stderr}',
  );
}
