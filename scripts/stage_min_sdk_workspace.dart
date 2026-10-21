#!/usr/bin/env dart

import 'dart:io';

import 'package:path/path.dart' as p;

import 'src/staging.dart';

/// Copies the repository into a pure-Dart workspace that resolves on the
/// minimum Dart SDK.
///
/// The complete workspace cannot resolve on Dart 3.9, because `flutter_test`
/// pins `test_api 0.7.6` while the root `test` constraint and the Analyzer 10
/// dependency of `ack_generator` require a newer `test_api`. Removing the
/// Flutter workspace members leaves a resolvable workspace that still covers
/// every pure-Dart package. The Flutter packages get their own staged lane
/// through `scripts/stage_package.dart`.
///
/// Usage:
/// `dart scripts/stage_min_sdk_workspace.dart <output-directory>`
///
/// The script prints the staged workspace root on success.
void main(List<String> args) {
  if (args.length != 1) {
    stderr.writeln(
      'Usage: dart scripts/stage_min_sdk_workspace.dart <output-directory>',
    );
    exitCode = 64;

    return;
  }

  final output = args.single;
  stageTrackedFiles(output, paths: const ['.']);

  final root = File(p.join(output, 'pubspec.yaml'));
  final flutterMembers = _flutterWorkspaceMembers(output, root);
  root.writeAsStringSync(
    toPureDartWorkspace(
      root.readAsStringSync(),
      flutterMembers: flutterMembers,
    ),
  );
  // Removing the sources as well keeps the staged tree consistent: every
  // remaining pubspec belongs to the staged workspace.
  for (final member in flutterMembers) {
    Directory(p.join(output, member)).deleteSync(recursive: true);
  }

  stdout
    ..writeln('Removed Flutter workspace members: ${flutterMembers.join(', ')}')
    ..writeln(output);
}

/// Returns the staged workspace members that need the Flutter SDK.
Set<String> _flutterWorkspaceMembers(String output, File root) {
  final members = workspaceMembers(root.readAsStringSync());

  return members
      .where(
        (member) => requiresFlutter(
          File(p.join(output, member, 'pubspec.yaml')).readAsStringSync(),
        ),
      )
      .toSet();
}
