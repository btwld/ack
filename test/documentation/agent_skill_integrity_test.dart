import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  const plugin = 'plugins/ack';
  const usingAck = '$plugin/skills/using-ack/SKILL.md';
  final pubspec =
      loadYaml(File('packages/ack/pubspec.yaml').readAsStringSync()) as YamlMap;
  final version = pubspec['version'] as String;
  final skills = Directory('$plugin/skills')
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.md'))
      .toList();

  test('agent plugin and marketplace manifests are valid JSON', () {
    for (final path in [
      '.agents/plugins/marketplace.json',
      '.claude-plugin/marketplace.json',
      '.cursor-plugin/marketplace.json',
      for (final tool in ['claude', 'codex', 'cursor'])
        '$plugin/.$tool-plugin/plugin.json',
    ]) {
      final manifest = jsonDecode(File(path).readAsStringSync());
      expect(manifest, isA<Map<String, dynamic>>(), reason: path);
      if (p.basename(path) == 'plugin.json') {
        expect((manifest as Map)['version'], version, reason: path);
      }
    }
  });

  test('skill pins and version-matched links agree with the ack pubspec', () {
    expect(File(usingAck).readAsStringSync(), contains('`^$version`'));
    final pins = RegExp(r'\^(\d+\.\d+\.\d+[\w.+-]*)');
    final tags = RegExp(r'https://github\.com/btwld/ack/blob/([^/\s]+)/');
    for (final file in skills) {
      final source = file.readAsStringSync();
      for (final pin in pins.allMatches(source)) {
        expect(pin[1], version, reason: file.path);
      }
      for (final tag in tags.allMatches(source)) {
        expect(tag[1], 'v$version', reason: file.path);
      }
    }
  });

  test('relative skill links resolve', () {
    final link = RegExp(r'\]\(([^\s)]+)\)');
    for (final file in skills) {
      for (final match in link.allMatches(file.readAsStringSync())) {
        final uri = Uri.tryParse(match[1]!);
        if (uri == null || uri.hasScheme || uri.path.isEmpty) continue;
        final target = p.normalize(p.join(p.dirname(file.path), uri.path));
        expect(
          FileSystemEntity.typeSync(target),
          isNot(FileSystemEntityType.notFound),
          reason: '${file.path}: ${match[1]}',
        );
      }
    }
  });
}
