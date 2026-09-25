import 'dart:io';

import 'src/release_changelog.dart';
import 'src/workspace_packages.dart';

/// Updates package changelog entries for the latest release so they contain
/// only a link to the GitHub release notes.
///
/// Usage:
///   dart scripts/update_release_changelog.dart [version] [tag]
///
/// If args are omitted:
///   * version defaults to the value in packages/ack/pubspec.yaml
///   * tag defaults to `v<version>`
void main(List<String> args) {
  final version = args.isNotEmpty
      ? args[0].trim()
      : _readVersionFromPubspec('packages/ack/pubspec.yaml');
  if (version == null || version.isEmpty) {
    stderr.writeln(
      'Unable to determine version. Provide it explicitly or ensure packages/ack/pubspec.yaml has a version.',
    );
    exitCode = 64;
    return;
  }

  final tag = (args.length >= 3 && args[2].trim().isNotEmpty)
      // Backward compatible: if the historical [version] [date] [tag] form
      // is used, the third argument still wins as tag.
      ? args[2].trim()
      : (args.length >= 2 && args[1].trim().isNotEmpty)
      ? args[1].trim()
      : 'v$version';

  final releaseUrl = 'https://github.com/btwld/ack/releases/tag/$tag';
  final changelogPaths = publishableAckPackages
      .map((p) => 'packages/$p/CHANGELOG.md')
      .toList();
  var hasErrors = false;
  final updates = <({File file, ChangelogUpdate update})>[];

  for (final path in changelogPaths) {
    final file = File(path);
    if (!file.existsSync()) {
      stderr.writeln('Could not update $path (file not found)');
      hasErrors = true;
      continue;
    }

    final original = file.readAsStringSync();
    final update = updateReleaseChangelog(
      original,
      version: version,
      releaseUrl: releaseUrl,
    );
    if (!update.found) {
      stderr.writeln('Warning: Could not find version $version in $path');
      hasErrors = true;
      continue;
    }

    updates.add((file: file, update: update));
  }
  if (hasErrors) {
    exitCode = 1;
    return;
  }

  for (final entry in updates) {
    if (entry.update.changed) {
      entry.file.writeAsStringSync(entry.update.content);
      stdout.writeln('Updated changelog entry in ${entry.file.path}');
    } else {
      stdout.writeln('No changes required for ${entry.file.path}');
    }
  }
}

String? _readVersionFromPubspec(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    return null;
  }

  for (final line in file.readAsLinesSync()) {
    final trimmed = line.trim();
    if (trimmed.startsWith('version:')) {
      return trimmed.split(':').last.trim();
    }
  }
  return null;
}
