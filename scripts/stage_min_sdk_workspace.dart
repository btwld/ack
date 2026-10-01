#!/usr/bin/env dart

import 'dart:io';

import 'package:path/path.dart' as p;

import 'src/staging.dart';

/// Copies the repository into a pure-Dart workspace that resolves on the
/// minimum Dart SDK.
///
/// Removes Flutter members so Dart can resolve the staged workspace without
/// a Flutter SDK. The runtime-only mode also removes generator consumers,
/// which require a newer Dart SDK than the runtime packages.
///
/// Usage:
/// `dart scripts/stage_min_sdk_workspace.dart <output-directory> [--runtime-only]`
///
/// `--runtime-only` excludes the generator and its example. They require
/// Dart 3.13 and have a separate minimum-SDK check.
///
/// The script prints the staged workspace root on success.
void main(List<String> args) {
  final positional = args.where((arg) => arg != '--runtime-only').toList();
  if (positional.length != 1 || positional.single.startsWith('--')) {
    stderr.writeln(
      'Usage: dart scripts/stage_min_sdk_workspace.dart <output-directory> '
      '[--runtime-only]',
    );
    exitCode = 64;

    return;
  }

  final output = positional.single;
  stageTrackedFiles(output, paths: const ['.']);

  final root = File(p.join(output, 'pubspec.yaml'));
  final flutterMembers = _flutterWorkspaceMembers(output, root);
  final excludedMembers = args.contains('--runtime-only')
      ? const {'packages/ack_generator', 'example'}
      : const <String>{};
  root.writeAsStringSync(
    toPureDartWorkspace(
      root.readAsStringSync(),
      flutterMembers: flutterMembers,
      excludedMembers: excludedMembers,
    ),
  );
  // Removing the sources as well keeps the staged tree consistent: every
  // remaining pubspec belongs to the staged workspace.
  for (final member in {...flutterMembers, ...excludedMembers}) {
    Directory(p.join(output, member)).deleteSync(recursive: true);
  }

  stdout
    ..writeln(
      'Removed workspace members: '
      '${{...flutterMembers, ...excludedMembers}.join(', ')}',
    )
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
