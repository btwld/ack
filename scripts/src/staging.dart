import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

/// Files that must never reach a staging directory.
///
/// `melos` writes path overrides into `pubspec_overrides.yaml`. A staged tree
/// must resolve its Ack dependencies the way a pub.dev consumer does, so the
/// override file stays behind.
const _excludedFileNames = <String>{'pubspec_overrides.yaml'};

/// Copies the tracked files under [paths] into [output].
///
/// Every file keeps its repository-relative path, so a staged package still
/// finds sibling files such as the shared `analysis_options.yaml`. The copy
/// reads the working tree, which lets a maintainer stage uncommitted work.
Directory stageTrackedFiles(String output, {required List<String> paths}) {
  final directory = Directory(output);
  if (directory.existsSync()) directory.deleteSync(recursive: true);
  directory.createSync(recursive: true);

  for (final relativePath in trackedFiles(paths)) {
    final source = File(relativePath);
    // `git ls-files` also lists files that the working tree has deleted.
    if (!source.existsSync()) continue;
    if (_excludedFileNames.contains(p.basename(relativePath))) continue;

    final target = File(p.join(output, relativePath));
    target.parent.createSync(recursive: true);
    source.copySync(target.path);
  }

  return directory;
}

/// Lists the repository-relative paths that git tracks under [paths].
///
/// `-z` makes git separate the paths with NUL and leave them unquoted, so the
/// list stays exact for every path name that the repository can hold.
List<String> trackedFiles(List<String> paths) {
  final result = Process.runSync('git', ['ls-files', '-z', '--', ...paths]);
  if (result.exitCode != 0) {
    throw ProcessException(
      'git',
      ['ls-files', '--', ...paths],
      '${result.stderr}',
      result.exitCode,
    );
  }

  return (result.stdout as String)
      .split(String.fromCharCode(0))
      .where((entry) => entry.isNotEmpty)
      .toList();
}

/// Removes `resolution: workspace` from [pubspec].
///
/// Pub then resolves the staged package on its own and honours its published
/// version constraints instead of the workspace sibling paths.
String detachFromWorkspace(String pubspec) {
  final editor = YamlEditor(pubspec);
  if (_valueAt(editor, ['resolution']) == null) return pubspec;
  editor.remove(['resolution']);

  return editor.toString();
}

/// Points the [overrides] dependencies of [pubspec] at staged sibling paths.
String overrideWithStagedPackages(
  String pubspec,
  Map<String, String> overrides,
) {
  if (overrides.isEmpty) return pubspec;

  final editor = YamlEditor(pubspec);
  if (_valueAt(editor, ['dependency_overrides']) == null) {
    editor.update(['dependency_overrides'], <String, Object?>{});
  }
  for (final entry in overrides.entries) {
    editor.update(
      ['dependency_overrides', entry.key],
      <String, Object?>{'path': entry.value},
    );
  }

  return editor.toString();
}

/// Removes the [flutterMembers] workspace entries and the Flutter SDK
/// constraint from a workspace root [pubspec].
///
/// The complete workspace cannot resolve on the minimum Dart SDK, because
/// `flutter_test` pins an older `test_api` than the analyzer floor of
/// `ack_generator` allows. Dropping the Flutter members produces a resolvable
/// pure-Dart workspace that still covers every other package.
String toPureDartWorkspace(
  String pubspec, {
  required Set<String> flutterMembers,
}) {
  final editor = YamlEditor(pubspec);
  final members = _valueAt(editor, ['workspace']);
  if (members is List) {
    editor.update([
      'workspace',
    ], members.where((member) => !flutterMembers.contains(member)).toList());
  }
  if (_valueAt(editor, ['environment', 'flutter']) != null) {
    editor.remove(['environment', 'flutter']);
  }

  return editor.toString();
}

/// Lists the workspace members that a workspace root [pubspec] declares.
List<String> workspaceMembers(String pubspec) {
  final document = loadYaml(pubspec);
  if (document is! Map) return const [];
  final members = document['workspace'];
  if (members is! List) return const [];

  return members.map((member) => '$member').toList();
}

/// Reports whether the package described by [pubspec] needs the Flutter SDK.
bool requiresFlutter(String pubspec) {
  final document = loadYaml(pubspec);
  if (document is! Map) return false;
  final environment = document['environment'];
  if (environment is Map && environment.containsKey('flutter')) return true;
  for (final section in const ['dependencies', 'dev_dependencies']) {
    final dependencies = document[section];
    if (dependencies is! Map) continue;
    for (final dependency in dependencies.values) {
      if (dependency is Map && dependency['sdk'] == 'flutter') return true;
    }
  }

  return false;
}

/// Returns the names in [candidates] that [pubspec] depends on directly.
List<String> directDependenciesAmong(String pubspec, List<String> candidates) {
  final document = loadYaml(pubspec);
  if (document is! Map) return const [];
  final names = <String>{};
  for (final section in const ['dependencies', 'dev_dependencies']) {
    final dependencies = document[section];
    if (dependencies is Map) {
      names.addAll(dependencies.keys.map((key) => '$key'));
    }
  }

  return candidates.where(names.contains).toList();
}

/// Reads the `version` field of [pubspec], or `null` when it declares none.
String? readPubspecVersion(String pubspec) {
  final document = loadYaml(pubspec);
  if (document is! Map) return null;
  final version = document['version'];

  return version == null ? null : '$version';
}

Object? _valueAt(YamlEditor editor, List<String> path) =>
    editor.parseAt(path, orElse: () => wrapAsYamlNode(null)).value;
