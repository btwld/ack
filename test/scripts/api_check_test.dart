import 'dart:io';

import 'package:test/test.dart';

void main() {
  test(
    'additive mode changes only the API version check mode',
    () async {
      final fakeBin = Directory.systemTemp.createTempSync('ack-api-mode-');
      final workingDirectory = Directory.systemTemp.createTempSync(
        'ack-api-mode-report-',
      );
      addTearDown(() => fakeBin.deleteSync(recursive: true));
      addTearDown(() => workingDirectory.deleteSync(recursive: true));
      final arguments = File('${workingDirectory.path}/arguments.txt');
      _writeExecutable(fakeBin, 'dart', '''#!/bin/sh
if [ "\$3" = "activate" ]; then exit 0; fi
printf '%s\\n' "\$@" > '${arguments.path}'
exit 23
''');
      final scriptPath = File('scripts/api_check.dart').absolute.path;
      final environment = {
        ...Platform.environment,
        'PATH': '${fakeBin.path}:/usr/bin:/bin',
      };

      final additive = await Process.run(
        Platform.resolvedExecutable,
        [scriptPath, 'ack', '1.6.2', '--allow-additive'],
        workingDirectory: workingDirectory.path,
        environment: environment,
      );
      expect(additive.exitCode, 1);
      expect(arguments.readAsStringSync(), contains('onlyBreakingChanges'));

      final strict = await Process.run(
        Platform.resolvedExecutable,
        [scriptPath, 'ack', '1.6.2'],
        workingDirectory: workingDirectory.path,
        environment: environment,
      );
      expect(strict.exitCode, 1);
      expect(
        arguments.readAsStringSync(),
        isNot(contains('onlyBreakingChanges')),
      );
    },
    skip: Platform.isWindows ? 'Uses POSIX test executables.' : false,
  );

  for (final baseline in ['1.1.0', '1.2.0', '1.3.0']) {
    test(
      'new adapter API baseline $baseline respects its first release',
      () async {
        final fakeBin = Directory.systemTemp.createTempSync(
          'ack-api-first-release-',
        );
        addTearDown(() => fakeBin.deleteSync(recursive: true));
        _writeExecutable(fakeBin, 'dart', '#!/bin/sh\nexit 23\n');
        final result = await Process.run(
          Platform.resolvedExecutable,
          ['scripts/api_check.dart', 'ack_mcp_dart', baseline],
          environment: {
            ...Platform.environment,
            'PATH': '${fakeBin.path}:/usr/bin:/bin',
          },
        );
        if (baseline != '1.3.0') {
          expect(result.exitCode, 0);
          expect(
            result.stdout,
            contains('ack_mcp_dart first releases in 1.3.0'),
          );
          expect(result.stderr, isEmpty);
        } else {
          expect(result.exitCode, 1);
          expect(result.stderr, contains('Unable to activate dart_apitool'));
        }
      },
      skip: Platform.isWindows ? 'Uses POSIX test executables.' : false,
    );
  }

  test(
    'activation failures stop API checks with a non-zero exit code',
    () async {
      final fakeBin = Directory.systemTemp.createTempSync('ack-api-check-');
      addTearDown(() => fakeBin.deleteSync(recursive: true));

      _writeExecutable(fakeBin, 'dart', '#!/bin/sh\nexit 23\n');

      final result = await Process.run(
        Platform.resolvedExecutable,
        ['scripts/api_check.dart', 'ack', '1.0.0'],
        environment: {
          ...Platform.environment,
          'PATH': '${fakeBin.path}:/usr/bin:/bin',
        },
      );

      expect(result.exitCode, 1);
      expect(result.stderr, contains('Unable to activate dart_apitool'));
      expect(result.stdout, isNot(contains('Checking ack package')));
    },
    skip: Platform.isWindows ? 'Uses POSIX test executables.' : false,
  );

  test(
    'stale reports do not satisfy the current API check',
    () async {
      final fakeBin = Directory.systemTemp.createTempSync('ack-api-check-');
      final workingDirectory = Directory.systemTemp.createTempSync(
        'ack-api-report-',
      );
      addTearDown(() => fakeBin.deleteSync(recursive: true));
      addTearDown(() => workingDirectory.deleteSync(recursive: true));

      _writeExecutable(fakeBin, 'dart', '#!/bin/sh\nexit 0\n');
      final staleReport = File(
        '${workingDirectory.path}/api-compat-ack-vs-1.0.0.md',
      )..writeAsStringSync('stale report');
      final scriptPath = File('scripts/api_check.dart').absolute.path;

      final result = await Process.run(
        Platform.resolvedExecutable,
        [scriptPath, 'ack', '1.0.0'],
        workingDirectory: workingDirectory.path,
        environment: {
          ...Platform.environment,
          'PATH': '${fakeBin.path}:/usr/bin:/bin',
        },
      );

      expect(result.exitCode, 1);
      expect(result.stderr, contains('did not create'));
      expect(staleReport.existsSync(), isFalse);
    },
    skip: Platform.isWindows ? 'Uses POSIX test executables.' : false,
  );
}

void _writeExecutable(Directory directory, String name, String contents) {
  final file = File('${directory.path}/$name')..writeAsStringSync(contents);
  final chmod = Process.runSync('chmod', ['+x', file.path]);
  expect(chmod.exitCode, 0);
}
