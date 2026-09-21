#!/usr/bin/env dart

import 'dart:io';

import 'src/staging.dart';
import 'src/workspace_packages.dart';

/// Runs `pub publish --dry-run` for every publishable Ack package and requires
/// a clean result.
///
/// `pub` reports packaging problems as warnings, and a warning that reaches
/// pub.dev cannot be withdrawn. The release therefore treats any warning as a
/// failure. A hint is a separate, advisory category that `pub` exits zero on —
/// a version-skip notice is one, and it appears whenever a coordinated release
/// is published incompletely — so hints are reported but do not fail the gate.
///
/// Usage:
/// `dart scripts/publish_dry_run.dart [package ...]`
///
/// With no arguments the script checks every publishable package.
Future<void> main(List<String> args) async {
  final packages = args.isEmpty ? publishableAckPackages : args;
  final unknown = packages.where(
    (package) => !publishableAckPackages.contains(package),
  );
  if (unknown.isNotEmpty) {
    stderr.writeln(
      'Unknown packages: ${unknown.join(', ')}. '
      'Available packages: ${publishableAckPackages.join(', ')}',
    );
    exitCode = 64;

    return;
  }

  final failures = <String>[];
  for (final package in packages) {
    stdout.writeln('Validating packages/$package ...');
    final failure = await _dryRun(package);
    if (failure != null) failures.add(failure);
  }

  if (failures.isEmpty) {
    stdout.writeln('All ${packages.length} packages publish cleanly.');

    return;
  }

  stderr.writeln('Publish validation failed:');
  for (final failure in failures) {
    stderr.writeln('  - $failure');
  }
  exitCode = 1;
}

/// Returns a failure description, or `null` when [package] is publishable.
Future<String?> _dryRun(String package) async {
  final directory = 'packages/$package';
  // A Flutter package must resolve through the Flutter SDK, so its dry run
  // goes through the `flutter` executable.
  final executable =
      requiresFlutter(File('$directory/pubspec.yaml').readAsStringSync())
      ? 'flutter'
      : 'dart';

  final ProcessResult result;
  try {
    result = await Process.run(executable, [
      'pub',
      'publish',
      '--dry-run',
    ], workingDirectory: directory);
  } on ProcessException catch (error) {
    return '$package: could not run $executable pub publish: ${error.message}';
  }

  final output = '${result.stdout}${result.stderr}';
  stdout.writeln(output);
  if (result.exitCode != 0) {
    return '$package: $executable pub publish exited with ${result.exitCode}';
  }

  final counts = publishValidationCounts(output);
  if (counts == null) {
    return '$package: publish validation printed no summary to verify';
  }
  if (counts.warnings > 0) {
    return '$package: publish validation reported ${counts.warnings} '
        '${counts.warnings == 1 ? 'warning' : 'warnings'}';
  }
  if (counts.hints > 0) {
    stdout.writeln(
      'Note: $package has ${counts.hints} publish '
      '${counts.hints == 1 ? 'hint' : 'hints'} (advisory, not blocking).',
    );
  }

  return null;
}

/// The warning and hint counts `pub` reports in its dry-run summary, or `null`
/// when the output carries no summary line to read.
///
/// `pub` closes a validated dry run with `Package has 0 warnings.`, or
/// `Package has 0 warnings and 1 hint.` when it also has advice. Matching the
/// clean line literally would read the second form as a failure even though it
/// reports no warnings at all.
({int warnings, int hints})? publishValidationCounts(String output) {
  final summaries = RegExp(r'Package has ([^.\n]*)\.').allMatches(output);
  if (summaries.isEmpty) return null;

  // Only the final summary describes the package that was just validated.
  final summary = summaries.last.group(1)!;

  return (
    warnings: _countOf(summary, 'warning'),
    hints: _countOf(summary, 'hint'),
  );
}

/// The count `pub` attached to [noun] in a summary, or `0` when the summary
/// omits that category entirely.
int _countOf(String summary, String noun) {
  final match = RegExp('([0-9]+) ${noun}s?\\b').firstMatch(summary);

  return match == null ? 0 : int.parse(match.group(1)!);
}
