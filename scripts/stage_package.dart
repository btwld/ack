#!/usr/bin/env dart

import 'dart:io';

import 'package:path/path.dart' as p;

import 'src/staging.dart';
import 'src/workspace_packages.dart';

/// Copies one Ack package out of the melos workspace so pub resolves it the
/// way a pub.dev consumer does.
///
/// Workspace resolution replaces every `ack: ^1.2.0` constraint with the local
/// sibling directory, so a workspace check never proves that the hosted
/// versions resolve. A staged package drops `resolution: workspace` and
/// therefore resolves its Ack dependencies from pub.dev.
///
/// Usage:
/// `dart scripts/stage_package.dart <package> <output> [--local-deps]`
///
/// Options:
///   --local-deps  Also stage the Ack packages that this package depends on,
///                 and override the staged package to use them. Use this for a
///                 minimum-SDK check of unpublished packages; omit it to prove
///                 hosted resolution.
///
/// The script prints the staged package directory on success.
void main(List<String> args) {
  final positional = args.where((arg) => !arg.startsWith('--')).toList();
  final useLocalDeps = args.contains('--local-deps');
  final unknownOptions = args.where(
    (arg) => arg.startsWith('--') && arg != '--local-deps',
  );

  if (positional.length != 2 || unknownOptions.isNotEmpty) {
    stderr.writeln(
      'Usage: dart scripts/stage_package.dart <package> <output-directory> '
      '[--local-deps]',
    );
    exitCode = 64;

    return;
  }

  final package = positional[0];
  final output = positional[1];
  if (!publishableAckPackages.contains(package)) {
    stderr.writeln(
      'Unknown package "$package". '
      'Available packages: ${publishableAckPackages.join(', ')}',
    );
    exitCode = 64;

    return;
  }

  final staged = useLocalDeps
      ? _ackDependencyClosure(package)
      : <String>{package};

  stageTrackedFiles(
    output,
    paths: [
      // Every package analysis_options.yaml includes the workspace root file.
      'analysis_options.yaml',
      for (final name in staged) 'packages/$name',
    ],
  );

  final rootPubspec = File('pubspec.yaml').readAsStringSync();
  for (final name in staged) {
    final pubspec = File(p.join(output, 'packages', name, 'pubspec.yaml'));
    final source = pubspec.readAsStringSync();
    pubspec.writeAsStringSync(
      overrideWithStagedPackages(
        withRootLintDependency(detachFromWorkspace(source), rootPubspec),
        {
          for (final dependency in directDependenciesAmong(
            source,
            publishableAckPackages,
          ))
            if (staged.contains(dependency)) dependency: '../$dependency',
        },
      ),
    );
  }

  stdout.writeln(p.join(output, 'packages', package));
}

/// Returns [package] together with every Ack package it depends on.
Set<String> _ackDependencyClosure(String package) {
  final closure = <String>{};
  final pending = <String>[package];
  while (pending.isNotEmpty) {
    final name = pending.removeLast();
    if (!closure.add(name)) continue;
    pending.addAll(
      directDependenciesAmong(
        File('packages/$name/pubspec.yaml').readAsStringSync(),
        publishableAckPackages,
      ),
    );
  }

  return closure;
}
