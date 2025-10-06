import 'dart:io';

/// Updates package changelog entries for the latest release so they contain
/// only a link to the GitHub release notes.
///
/// Usage:
///   dart scripts/update_release_changelog.dart [version] [yyyy-mm-dd] [tag]
///
/// If args are omitted:
///   * version defaults to the value in packages/ack/pubspec.yaml
///   * date defaults to today (local time)
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

  final date = (args.length >= 2 && args[1].trim().isNotEmpty)
      ? args[1].trim()
      : _today();
  final tag = (args.length >= 3 && args[2].trim().isNotEmpty)
      ? args[2].trim()
      : 'v$version';

  final releaseUrl = 'https://github.com/btwld/ack/releases/tag/$tag';
  final changelogPaths = [
    'packages/ack/CHANGELOG.md',
    'packages/ack_annotations/CHANGELOG.md',
    'packages/ack_generator/CHANGELOG.md',
  ];

  for (final path in changelogPaths) {
    final file = File(path);
    if (!file.existsSync()) {
      stderr.writeln('Skipping $path (file not found)');
      continue;
    }

    final lines = file.readAsLinesSync();
    final headingIndex = lines.indexWhere(
      (line) => line.startsWith('## ') && line.contains(version),
    );
    if (headingIndex == -1) {
      stderr.writeln('Warning: Could not find version $version in $path');
      continue;
    }

    lines[headingIndex] = '## $version ($date)';

    var sectionEnd = headingIndex + 1;
    while (sectionEnd < lines.length && !lines[sectionEnd].startsWith('## ')) {
      sectionEnd++;
    }

    final newSection = [
      '',
      '* See [release notes]($releaseUrl) for details.',
      '',
    ];

    final existingSection = lines.sublist(headingIndex + 1, sectionEnd);
    if (!_sectionMatches(existingSection, newSection)) {
      lines.replaceRange(headingIndex + 1, sectionEnd, newSection);
      stdout.writeln('Updated changelog entry in $path');
    } else {
      stdout.writeln('No changes required for $path');
    }

    // Remove any duplicate headings for the same version further down the file.
    var duplicateIndex = lines.indexWhere(
      (line) => line.startsWith('## ') && line.contains(version),
      headingIndex + 1,
    );
    while (duplicateIndex != -1) {
      var duplicateEnd = duplicateIndex + 1;
      while (duplicateEnd < lines.length &&
          !lines[duplicateEnd].startsWith('## ')) {
        duplicateEnd++;
      }
      lines.removeRange(duplicateIndex, duplicateEnd);
      duplicateIndex = lines.indexWhere(
        (line) => line.startsWith('## ') && line.contains(version),
        headingIndex + 1,
      );
    }

    file.writeAsStringSync(lines.join('\n'));
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

String _today() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
}

bool _sectionMatches(List<String> existing, List<String> expected) {
  List<String> clean(List<String> input) => input
      .map((line) => line.trimRight())
      .skipWhile((line) => line.isEmpty)
      .toList();

  final cleanedExisting = clean(existing);
  final cleanedExpected = clean(expected);
  if (cleanedExisting.length != cleanedExpected.length) {
    return false;
  }
  for (var i = 0; i < cleanedExisting.length; i++) {
    if (cleanedExisting[i] != cleanedExpected[i]) {
      return false;
    }
  }
  return true;
}
