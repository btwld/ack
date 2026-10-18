import 'dart:io';

import 'package:path/path.dart' as p;

/// Runs fixture commands with the test suite's SDK, not a global Dart install.
///
/// The VM/analyzer and build_runner's resolver each need the augmentation flag
/// while the pinned Dart 3.14 SDK keeps this feature experimental.
Future<ProcessResult> runDart(Directory directory, List<String> arguments) {
  // The analyzer does not inherit the VM's experiment flag. Give each temporary
  // consumer the same analyzer setting required by the documented setup.
  final options = File(p.join(directory.path, 'analysis_options.yaml'));
  var source = options.existsSync() ? options.readAsStringSync() : '';
  if (!source.contains('enable-experiment:')) {
    const experiments = '  enable-experiment:\n    - augmentations\n';
    final analyzer = RegExp(r'^analyzer:\s*$', multiLine: true);
    source = analyzer.hasMatch(source)
        ? source.replaceFirst(analyzer, 'analyzer:\n$experiments')
        : 'analyzer:\n$experiments$source';
    options.writeAsStringSync(source);
  }
  return Process.run(
    p.join(
      p.dirname(Platform.resolvedExecutable),
      Platform.isWindows ? 'dart.exe' : 'dart',
    ),
    [
      '--enable-experiment=augmentations',
      ...arguments,
      if (arguments.length >= 3 &&
          arguments[0] == 'run' &&
          arguments[1] == 'build_runner')
        '--enable-experiment=augmentations',
    ],
    workingDirectory: directory.path,
  );
}
