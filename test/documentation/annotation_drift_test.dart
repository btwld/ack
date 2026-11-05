import 'dart:io';

import 'package:test/test.dart';

const _migrationGuide = 'docs/getting-started/migration-guide.mdx';

/// Docs, READMEs, every example directory, and `llms.txt`, with the rows of
/// the migration guide's mapping table blanked: they name the old annotations
/// on purpose.
Iterable<(String, List<String>)> _guidance() sync* {
  const skipped = {'.dart_tool', 'build', 'node_modules', '.git', '.context'};
  Iterable<File> files(String directory) =>
      Directory(directory)
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => !file.uri.pathSegments.any(skipped.contains));
  final examples = [
    'example',
    for (final package in Directory('packages').listSync())
      if (Directory('${package.path}/example').existsSync())
        '${package.path}/example',
  ];
  for (final file in [
    ...files('docs').where((file) => file.path.contains('.md')),
    for (final example in examples)
      ...files(example).where((file) => !file.path.endsWith('.g.dart')),
    ...files('.').where((file) => file.uri.pathSegments.last == 'README.md'),
    File('llms.txt'),
  ]) {
    final lines = file.readAsLinesSync();
    if (file.path == _migrationGuide) {
      var row = lines.indexOf('### Validation Annotations');
      while (!lines[row].startsWith('|')) {
        row++;
      }
      for (; lines[row].startsWith('|'); row++) {
        lines[row] = '';
      }
    }
    yield (file.path, lines);
  }
}

List<String> _matches(RegExp pattern) => [
  for (final (path, lines) in _guidance())
    for (final (index, line) in lines.indexed)
      if (pattern.hasMatch(line)) '$path:${index + 1}: ${line.trim()}',
];

void main() {
  test('guidance uses the rule annotations, not @Validate.*', () {
    expect(_matches(RegExp(r'@Validate\.')), isEmpty);
  });

  test('class-first static lines use the public facade', () {
    // For example `static final fromJson = _accountSchema.parse;`.
    final private = RegExp(
      r'\bstatic\s+(?:late\s+)?(?:final|const)\s+(?:[^=;]*\s)?'
      r'(?:schema|fromJson)\s*=\s*_[\w$]+\s*[;.]',
    );
    expect(_matches(private), isEmpty);
  });
}
