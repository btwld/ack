import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('every workflow and action', () {
    test('executes only immutable reviewed dependencies', () {
      for (final entry in _automationSources().entries) {
        for (final match in _externalUses.allMatches(entry.value)) {
          final action = match.group(1)!;
          final reference = match.group(2)!;
          expect(
            reference,
            matches(RegExp(r'^[0-9a-f]{40}$')),
            reason: '$action in ${entry.key} must use a full commit SHA',
          );
        }
      }
    });

    test('runs no reusable workflow from another repository', () {
      for (final entry in _automationSources().entries) {
        for (final match in _anyUses.allMatches(entry.value)) {
          final reference = match.group(1)!;
          if (!reference.contains('.github/workflows/')) continue;
          expect(
            reference,
            startsWith('./'),
            reason:
                '${entry.key} must call reusable workflows from this '
                'repository, because an external branch reference is mutable',
          );
        }
      }
    });

    test('executes no unverified downloaded script', () {
      for (final entry in _automationSources().entries) {
        expect(
          entry.value,
          isNot(matches(RegExp(r'curl[^\n]*\|\s*(?:ba)?sh'))),
          reason: '${entry.key} must not execute unverified downloaded scripts',
        );
      }
    });

    test('runs on a pinned runner image', () {
      final runner = RegExp(r'runs-on:\s*([^\s]+)', multiLine: true);
      for (final entry in _automationSources().entries) {
        for (final match in runner.allMatches(entry.value)) {
          expect(
            match.group(1),
            isNot(endsWith('-latest')),
            reason:
                '${entry.key} must pin the runner image, because a rolling '
                'image changes the toolchain without a review',
          );
        }
      }
    });

    test('installs only pinned npm packages', () {
      // `npm ci` is exact by definition, because it reads the lockfile. Every
      // other npm invocation must name a version, either literally or through
      // an environment variable that the workflow sets.
      final pinned = RegExp(r'@\d+\.\d+\.\d+|@\$[A-Z_]');
      for (final entry in _automationSources().entries) {
        for (final line in entry.value.split('\n')) {
          final statement = line.trim();
          if (statement.startsWith('#')) continue;
          if (!statement.contains('npm install') &&
              !statement.contains('npx ')) {
            continue;
          }
          expect(
            statement,
            matches(pinned),
            reason:
                '${entry.key} installs an npm package without a version: '
                '$statement',
          );
        }
      }
    });
  });

  group('the Flutter SDK', () {
    test('is installed only through the checksum-verified action', () {
      final sources = _automationSources()
        ..remove('.github/actions/setup-flutter/action.yml');

      for (final entry in sources.entries) {
        expect(
          entry.value,
          isNot(contains('storage.googleapis.com/flutter_infra_release')),
          reason:
              '${entry.key} must install Flutter through '
              '.github/actions/setup-flutter, which verifies the checksum',
        );
      }
    });

    test('verifies the downloaded archive against a pinned checksum', () {
      final action = File(
        '.github/actions/setup-flutter/action.yml',
      ).readAsStringSync();

      expect(action, contains('sha256sum --check'));
      expect(action, contains('.github/flutter-releases.json'));
      expect(action, contains("--proto '=https'"));
    });

    test('pins every release that the manifest offers', () {
      for (final entry in _flutterReleases.entries) {
        expect(
          entry.value['sha256'],
          matches(RegExp(r'^[0-9a-f]{64}$')),
          reason: 'Flutter ${entry.key} needs a full SHA-256 checksum',
        );
        expect(
          entry.value['dart'],
          matches(RegExp(r'^\d+\.\d+\.\d+$')),
          reason: 'Flutter ${entry.key} needs the exact bundled Dart version',
        );
      }
    });

    test('pins the repository default to an exact manifest entry', () {
      final pinned =
          (jsonDecode(File('.fvmrc').readAsStringSync()) as Map)['flutter'];

      expect(pinned, isNot('stable'));
      expect(
        _flutterReleases,
        contains(pinned),
        reason: '.fvmrc pins Flutter $pinned, which has no checked-in checksum',
      );
    });

    test('pins every version that a workflow requests', () {
      final requested = RegExp(r"flutter-version:\s*'?([0-9][^'\s]*)'?");
      for (final entry in _automationSources().entries) {
        for (final match in requested.allMatches(entry.value)) {
          expect(
            _flutterReleases,
            contains(match.group(1)),
            reason:
                '${entry.key} requests Flutter ${match.group(1)}, '
                'which has no checked-in checksum',
          );
        }
      }
    });
  });

  group('the release workflow', () {
    test('verifies the tag and runs the preflight before publishing', () {
      final jobs = _jobs('.github/workflows/release.yml');

      expect(jobs, contains('verify-tag'));
      expect((jobs['preflight'] as Map)['needs'], 'verify-tag');
      expect(
        (jobs['preflight'] as Map)['uses'],
        './.github/workflows/preflight.yml',
      );

      for (final entry in jobs.entries) {
        final job = entry.value as Map;
        if (job['uses'] != './.github/workflows/publish-packages.yml') continue;
        expect(
          _dependencyClosure(jobs, entry.key),
          containsAll(<String>['verify-tag', 'preflight']),
          reason: '${entry.key} must publish only after the release checks',
        );
      }
    });

    test('publishes only through the protected environment', () {
      final jobs = _jobs('.github/workflows/publish-packages.yml');
      final publish = jobs['publish'] as Map;

      expect(publish['environment'], 'Production');
    });

    test('provisions pub.dev OIDC credentials before publishing', () {
      final jobs = _jobs('.github/workflows/publish-packages.yml');
      final publish = jobs['publish'] as Map;
      final steps = (publish['steps'] as List).cast<Map>();
      final oidcStep = steps.indexWhere(
        (step) => '${step['uses']}'.startsWith('dart-lang/setup-dart@'),
      );
      final publishStep = steps.indexWhere(
        (step) => step['name'] == 'Publish package with pub.dev OIDC',
      );

      expect(
        oidcStep,
        isNonNegative,
        reason:
            'dart-lang/setup-dart exchanges the GitHub Actions ID token for '
            'the PUB_TOKEN that pub.dev requires',
      );
      expect(
        oidcStep,
        publishStep - 1,
        reason:
            'the short-lived token must be acquired immediately before upload',
      );
    });

    test('preserves the selected SDK path across OIDC provisioning', () {
      final jobs = _jobs('.github/workflows/publish-packages.yml');
      final publish = jobs['publish'] as Map;
      final steps = (publish['steps'] as List).cast<Map>();
      final selectSdk = steps.singleWhere(
        (step) => step['name'] == 'Choose the SDK executable for this package',
      );
      final script = '${selectSdk['run']}';

      expect(script, contains('command -v flutter'));
      expect(script, contains('command -v dart'));
    });

    test('proves the hosted dependency graph before it uploads', () {
      final source = File(
        '.github/workflows/publish-packages.yml',
      ).readAsStringSync();

      expect(source, contains('scripts/stage_package.dart'));
      expect(source, contains('scripts/publish_dry_run.dart'));
    });
  });
}

final _externalUses = RegExp(
  r'^\s*-?\s*uses:\s*([^\s./][^\s]*)@([^\s#]+)',
  multiLine: true,
);

final _anyUses = RegExp(r'^\s*-?\s*uses:\s*([^\s#]+)', multiLine: true);

/// Every workflow and composite action that this repository can execute.
Map<String, String> _automationSources() {
  final sources = <String, String>{};
  for (final directory in const ['.github/workflows', '.github/actions']) {
    final entries = Directory(directory).listSync(recursive: true);
    for (final entry in entries.whereType<File>()) {
      if (!entry.path.endsWith('.yml') && !entry.path.endsWith('.yaml')) {
        continue;
      }
      sources[entry.path] = entry.readAsStringSync();
    }
  }

  return sources;
}

Map<String, Map<String, Object?>> get _flutterReleases {
  final manifest =
      jsonDecode(File('.github/flutter-releases.json').readAsStringSync())
          as Map;
  final releases = manifest['releases'] as Map;

  return {
    for (final entry in releases.entries)
      '${entry.key}': (entry.value as Map).cast<String, Object?>(),
  };
}

Map<String, Object?> _jobs(String workflow) {
  final document = loadYaml(File(workflow).readAsStringSync()) as Map;

  return (document['jobs'] as Map).cast<String, Object?>();
}

/// Returns every job that [job] waits for, directly or indirectly.
Set<String> _dependencyClosure(Map<String, Object?> jobs, String job) {
  final closure = <String>{};
  final pending = <String>[job];
  while (pending.isNotEmpty) {
    final current = jobs[pending.removeLast()];
    if (current is! Map) continue;
    final needs = current['needs'];
    final names = switch (needs) {
      String name => <String>[name],
      List list => list.map((name) => '$name').toList(),
      _ => const <String>[],
    };
    for (final name in names) {
      if (closure.add(name)) pending.add(name);
    }
  }

  return closure;
}
