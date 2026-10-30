@Tags(['integration'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

Future<ProcessResult> _run(Directory project, List<String> args) =>
    Process.run('dart', args, workingDirectory: project.path);

void _succeeds(ProcessResult result, String command) {
  expect(
    result.exitCode,
    0,
    reason: '$command failed\n${result.stdout}\n${result.stderr}',
  );
}

void main() {
  test(
    'JSON Schema builds into usable models in one deterministic build',
    () async {
      var repository = Directory.current;
      while (!Directory(
        p.join(repository.path, 'packages', 'ack_generator'),
      ).existsSync()) {
        repository = repository.parent;
      }
      final project = await Directory.systemTemp.createTemp('ack_json_schema_');
      try {
        Directory(p.join(project.path, 'lib')).createSync();
        Directory(p.join(project.path, 'test')).createSync();
        File(p.join(project.path, 'pubspec.yaml')).writeAsStringSync('''
name: ack_json_schema_runtime
publish_to: none
environment:
  sdk: '>=3.9.0 <4.0.0'
dependencies:
  ack:
    path: ${p.join(repository.path, 'packages', 'ack')}
dev_dependencies:
  ack_generator:
    path: ${p.join(repository.path, 'packages', 'ack_generator')}
  build_runner: ^2.15.0
  test: ^1.29.0
dependency_overrides:
  ack:
    path: ${p.join(repository.path, 'packages', 'ack')}
''');
        File(p.join(project.path, 'build.yaml')).writeAsStringSync('''
targets:
  \$default:
    builders:
      ack_generator:ack_json_schema:
        enabled: true
        options:
          unknown_properties: preserve
          assert_formats: true
          documents:
            "https://example.test/flag.json": "lib/flag.json"
''');
        File(p.join(project.path, 'lib', 'flag.json')).writeAsStringSync(
          '{"type":"object","properties":{"flag":{"type":"boolean"}},'
          '"required":["flag"],"additionalProperties":false}',
        );
        final schema = File(
          p.join(project.path, 'lib', 'contract.schema.json'),
        );
        schema.writeAsStringSync(r'''
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$defs": {
    "Photo": {
      "type": "object",
      "properties": {"url": {"type": "string"}},
      "required": ["url"],
      "additionalProperties": false
    },
    "Listing": {
      "type": "object",
      "properties": {
        "key": {"type": "string"},
        "photo": {"$ref": "#/$defs/Photo"}
      },
      "required": ["key"],
      "additionalProperties": false
    }
  }
}
''');
        File(
          p.join(project.path, 'test', 'models_test.dart'),
        ).writeAsStringSync(r'''
import 'package:ack_json_schema_runtime/contract.schema.dart';
import 'package:test/test.dart';

void main() {
  test('parse, preserve extras, round-trip, and typed copyWith', () {
    final listing = Listing.parse({
      'key': 'abc',
      'photo': {'url': 'https://example.test/1', 'newField': 1},
      'serverField': true,
    });
    expect(listing.key, 'abc');
    expect(listing.photo?.url, 'https://example.test/1');
    expect(listing.photo?.additionalProperties, {'newField': 1});
    expect(listing.additionalProperties, {'serverField': true});
    expect(listing.toJson(), {
      'key': 'abc',
      'photo': {'url': 'https://example.test/1', 'newField': 1},
      'serverField': true,
    });
    expect(listing.copyWith(key: 'def').key, 'def');
    expect(listing.copyWith(), listing);
  });
}
''');

        File(
          p.join(project.path, 'lib', 'advanced.schema.json'),
        ).writeAsStringSync(r'''
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$defs": {
    "Node": {
      "$dynamicAnchor": "node",
      "type": "object",
      "properties": {
        "value": {"type": "integer"},
        "next": {"$dynamicRef": "#node"}
      },
      "required": ["value"],
      "unevaluatedProperties": false
    },
    "Choice": {
      "oneOf": [
        {"type": "string", "format": "email"},
        {"type": "number", "multipleOf": 0.5}
      ]
    },
    "External": {
      "$ref": "https://example.test/flag.json"
    }
  },
  "anyOf": [
    {"$ref": "#/$defs/Node"},
    {"$ref": "#/$defs/Choice"},
    {"$ref": "#/$defs/External"}
  ]
}
''');
        File(
          p.join(project.path, 'test', 'advanced_test.dart'),
        ).writeAsStringSync(r'''
import 'package:ack_json_schema_runtime/advanced.schema.dart';
import 'package:test/test.dart';

void main() {
  test('validated value models preserve 2020-12 parse and encode', () {
    final tree = {'value': 1, 'next': {'value': 2}};
    final node = Node.parse(tree);
    expect(node.value, tree);
    expect(Node.encode(node), tree);
    expect(node.toJson(), tree);
    expect(Node.safeParse({'value': 1, 'next': null}).isFail, isTrue);
    expect(Node.safeParse({'value': 1, 'extra': true}).isOk, isTrue);
    expect(Choice.safeParse('a@example.test').isOk, isTrue);
    expect(Choice.safeParse('not-an-email').isFail, isTrue);
    expect(Choice.safeParse(1.5).isOk, isTrue);
    expect(Choice.safeParse(1.3).isFail, isTrue);
    expect(Root.safeParse(tree).isOk, isTrue);
    expect(Root.safeParse(1.3).isFail, isTrue);
    expect(External.safeParse({'flag': true, 'new': 1}).isOk, isTrue);
    expect(External.safeParse(1).isFail, isTrue);
    expect(Root.encode(Root.parse('a@example.test')), 'a@example.test');
  });
}
''');

        final regressions = <String, Map<String, Object?>>{
          'precision': {
            'Precise': {
              'type': 'object',
              'properties': {
                'lower': {'type': 'number', 'minimum': 9007199254740993},
                'upper': {'type': 'number', 'maximum': -9007199254740993},
              },
              'required': ['lower', 'upper'],
            },
          },
          'bounds': {
            'Bounded': {
              'type': 'object',
              'properties': {
                'name': {'type': 'string', 'minLength': 2.0, 'maxLength': 3e0},
                'items': {
                  'type': 'array',
                  'items': {'type': 'string'},
                  'minItems': 1.0,
                  'maxItems': 2e0,
                },
              },
              'required': ['name', 'items'],
            },
          },
          'patterns': {
            'Glyph': {'type': 'string', 'pattern': r'^.$'},
            'Pair': {'type': 'string', 'pattern': r'^[😀]{2}$'},
          },
          'types': {
            'Choice': {
              'type': ['string', 'number'],
            },
          },
          'anyof': {
            'Choice': {
              'anyOf': [
                {'type': 'string'},
                {'type': 'number'},
              ],
            },
          },
        };
        for (final entry in regressions.entries) {
          File(
            p.join(project.path, 'lib', '${entry.key}.schema.json'),
          ).writeAsStringSync(jsonEncode({r'$defs': entry.value}));
        }
        File(
          p.join(project.path, 'test', 'regressions_test.dart'),
        ).writeAsStringSync(r'''
import 'package:ack_json_schema_runtime/bounds.schema.dart';
import 'package:ack_json_schema_runtime/precision.schema.dart';
import 'package:ack_json_schema_runtime/patterns.schema.dart';
import 'package:ack_json_schema_runtime/types.schema.dart' as types;
import 'package:ack_json_schema_runtime/anyof.schema.dart' as anyof;
import 'package:test/test.dart';

void main() {
  test('integer number bounds retain precision beyond 2^53', () {
    expect(Precise.safeParse({
      'lower': 9007199254740993,
      'upper': -9007199254740993,
    }).isOk, isTrue);
    expect(Precise.safeParse({
      'lower': 9007199254740992,
      'upper': -9007199254740993,
    }).isFail, isTrue);
    expect(Precise.safeParse({
      'lower': 9007199254740993,
      'upper': -9007199254740992,
    }).isFail, isTrue);
  });
  test('integral decimal bounds preserve validation', () {
    expect(Bounded.safeParse({'name': 'ab', 'items': ['x']}).isOk, isTrue);
    for (final name in ['a', 'abcd']) {
      expect(Bounded.safeParse({'name': name, 'items': ['x']}).isFail, isTrue);
    }
    for (final items in [<String>[], ['x', 'y', 'z']]) {
      expect(Bounded.safeParse({'name': 'ab', 'items': items}).isFail, isTrue);
    }
  });
  test('patterns preserve Unicode code point semantics', () {
    expect(Glyph.safeParse('😀').isOk, isTrue);
    expect(Glyph.safeParse('ab').isFail, isTrue);
    expect(Pair.safeParse('😀😀').isOk, isTrue);
    expect(Pair.safeParse('😀').isFail, isTrue);
  });
  test('named scalar unions build and validate', () {
    for (final value in ['ok', 1, 1.5]) {
      expect(types.Choice.safeParse(value).isOk, isTrue);
      expect(anyof.Choice.safeParse(value).isOk, isTrue);
    }
    for (final value in [null, true, <String>[]]) {
      expect(types.Choice.safeParse(value).isFail, isTrue);
      expect(anyof.Choice.safeParse(value).isFail, isTrue);
    }
  });
}
''');

        _succeeds(
          await _run(project, ['pub', 'get', '--offline']),
          'dart pub get --offline',
        );
        _succeeds(
          await _run(project, ['run', 'build_runner', 'build']),
          'first build_runner build',
        );
        final outputs = {
          for (final suffix in ['.dart', '.g.dart'])
            suffix: File(
              p.join(project.path, 'lib', 'contract.schema$suffix'),
            ).readAsStringSync(),
        };
        expect(outputs['.dart'], contains('unknown_properties: preserve'));
        expect(outputs['.g.dart'], contains('class Listing'));
        final advancedOutput = File(
          p.join(project.path, 'lib', 'advanced.schema.dart'),
        ).readAsStringSync();
        expect(advancedOutput, contains('final class Node'));
        expect(advancedOutput, contains('final class Choice'));
        expect(advancedOutput, contains('final class Root'));
        _succeeds(
          await _run(project, ['analyze', '--fatal-infos']),
          'dart analyze --fatal-infos',
        );
        _succeeds(await _run(project, ['test']), 'dart test');
        _succeeds(
          await _run(project, ['run', 'build_runner', 'build']),
          'second build_runner build',
        );
        expect({
          for (final suffix in outputs.keys)
            suffix: File(
              p.join(project.path, 'lib', 'contract.schema$suffix'),
            ).readAsStringSync(),
        }, outputs);
        expect(
          File(
            p.join(project.path, 'lib', 'advanced.schema.dart'),
          ).readAsStringSync(),
          advancedOutput,
        );

        schema.writeAsStringSync(r'''
{"$defs":{"Broken":{"$ref":"#/$defs/Missing"}}}
''');
        final rejected = await _run(project, ['run', 'build_runner', 'build']);
        expect(rejected.exitCode, isNot(0));
        expect(
          '${rejected.stdout}\n${rejected.stderr}',
          contains(r'#/$defs/Broken/$ref'),
        );
      } finally {
        project.deleteSync(recursive: true);
      }
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
