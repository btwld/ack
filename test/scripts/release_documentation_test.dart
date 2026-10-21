import 'dart:io';

import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  test('adapter installation examples use the release version', () {
    for (final package in const [
      'ack_firebase_ai',
      'ack_json_schema_builder',
      'ack_mcp_dart',
    ]) {
      final directory = 'packages/$package';
      final pubspec = loadYaml(
        File('$directory/pubspec.yaml').readAsStringSync(),
      );
      final version = (pubspec as Map)['version'];
      final readme = File('$directory/README.md').readAsStringSync();

      expect(
        readme,
        contains('$package: ^$version'),
        reason: '$package installation guidance must match its release version',
      );
    }
  });

  test(
    'repository guidance does not advertise disabled publishing commands',
    () {
      final guidance = File(
        '.github/copilot-instructions.md',
      ).readAsStringSync();

      expect(guidance, isNot(contains('dart run melos publish')));
      expect(guidance, contains('/PUBLISHING.md'));
    },
  );

  test('manual publishing documents supported pub authentication', () {
    final publishing = File('PUBLISHING.md').readAsStringSync();

    expect(publishing, isNot(contains('dart pub login')));
    expect(publishing, matches(RegExp(r'authentication\s+prompt')));
    expect(publishing, contains('dart pub token add https://pub.dev'));
  });

  test('automated publishing documents OIDC credential provisioning', () {
    final publishing = File('PUBLISHING.md').readAsStringSync();

    expect(publishing, contains('dart-lang/setup-dart'));
    expect(publishing, contains('PUB_TOKEN'));
    expect(publishing, isNot(contains('by itself')));
  });
}
