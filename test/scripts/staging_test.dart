import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import '../../scripts/src/staging.dart';

void main() {
  group('detachFromWorkspace', () {
    test('removes workspace resolution so pub resolves hosted versions', () {
      const pubspec = '''
name: ack_firebase_ai
version: 1.2.0
resolution: workspace

dependencies:
  ack: ^1.2.0
''';

      final detached = loadYaml(detachFromWorkspace(pubspec)) as Map;

      expect(detached.containsKey('resolution'), isFalse);
      expect((detached['dependencies'] as Map)['ack'], '^1.2.0');
    });

    test('leaves a package that already resolves on its own', () {
      const pubspec = 'name: ack\nversion: 1.2.0\n';

      expect(detachFromWorkspace(pubspec), pubspec);
    });
  });

  group('overrideWithStagedPackages', () {
    test('points a dependency at the staged sibling', () {
      const pubspec = 'name: ack_generator\ndependencies:\n  ack: ^1.2.0\n';

      final overridden =
          loadYaml(overrideWithStagedPackages(pubspec, {'ack': '../ack'}))
              as Map;

      expect((overridden['dependency_overrides'] as Map)['ack'], {
        'path': '../ack',
      });
    });

    test('keeps the pubspec unchanged when there is nothing to override', () {
      const pubspec = 'name: ack\n';

      expect(overrideWithStagedPackages(pubspec, const {}), pubspec);
    });
  });

  group('toPureDartWorkspace', () {
    test('drops the Flutter members and the Flutter SDK constraint', () {
      const pubspec = '''
name: ack_workspace

environment:
  sdk: '>=3.9.0 <4.0.0'
  flutter: '>=3.35.0'

workspace:
  - packages/ack
  - packages/ack_firebase_ai
  - example
''';

      final pure =
          loadYaml(
                toPureDartWorkspace(
                  pubspec,
                  flutterMembers: const {'packages/ack_firebase_ai'},
                ),
              )
              as Map;

      expect(pure['workspace'], ['packages/ack', 'example']);
      expect((pure['environment'] as Map).containsKey('flutter'), isFalse);
      expect((pure['environment'] as Map)['sdk'], '>=3.9.0 <4.0.0');
    });
  });

  group('requiresFlutter', () {
    test('reports a Flutter SDK constraint', () {
      expect(requiresFlutter("environment:\n  flutter: '>=3.35.0'\n"), isTrue);
    });

    test('reports a Flutter SDK dependency', () {
      expect(
        requiresFlutter('dev_dependencies:\n  flutter_test:\n    sdk: flutter'),
        isTrue,
      );
    });

    test('reports a pure-Dart package', () {
      expect(
        requiresFlutter("environment:\n  sdk: '>=3.9.0 <4.0.0'\n"),
        isFalse,
      );
    });
  });

  test('workspaceMembers lists the declared members', () {
    expect(workspaceMembers('workspace:\n  - packages/ack\n  - example\n'), [
      'packages/ack',
      'example',
    ]);
  });

  test('directDependenciesAmong finds the Ack dependencies', () {
    const pubspec = '''
name: ack_generator
dependencies:
  ack: ^1.2.0
  analyzer: ^10.0.0
dev_dependencies:
  ack_json_schema_builder: ^1.2.0
''';

    expect(
      directDependenciesAmong(pubspec, const [
        'ack',
        'ack_json_schema_builder',
        'ack_firebase_ai',
      ]),
      ['ack', 'ack_json_schema_builder'],
    );
  });

  test('readPubspecVersion reads the declared version', () {
    expect(readPubspecVersion('name: ack\nversion: 1.2.0\n'), '1.2.0');
    expect(readPubspecVersion('name: ack_workspace\n'), isNull);
  });
}
