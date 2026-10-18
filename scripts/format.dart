#!/usr/bin/env dart

import 'dart:io';

/// Formats authored Dart sources; forwards arguments to `dart format`.
///
/// The pinned beta's formatter drops `augment` tokens. Generated parts are
/// formatted by ack_generator's token-aware formatter instead, and checked by
/// the deterministic-generation CI lane.
Future<void> main(List<String> args) async {
  final root = File.fromUri(Platform.script).parent.parent.path;
  final files = await Process.run('git', [
    'ls-files',
    '-z',
    '--cached',
    '--others',
    '--exclude-standard',
    '--',
    '*.dart',
  ], workingDirectory: root);
  if (files.exitCode != 0) {
    stderr.write(files.stderr);
    exitCode = files.exitCode;

    return;
  }

  final sources =
      (files.stdout as String)
          .split('\u0000')
          .where((path) => path.isNotEmpty && !path.endsWith('.g.dart'))
          .where((path) => File('$root/$path').existsSync())
          .toList()
        ..sort();
  if (sources.isEmpty) return;

  final formatter = await Process.start(
    Platform.resolvedExecutable,
    ['format', '--enable-experiment=augmentations', ...args, ...sources],
    workingDirectory: root,
    mode: ProcessStartMode.inheritStdio,
  );
  exitCode = await formatter.exitCode;
}
