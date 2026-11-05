import 'dart:io';

import 'package:test/test.dart';

/// The migration guide section whose mapping table keeps the deprecated names.
const _migrationGuide = 'docs/getting-started/migration-guide.mdx';
const _mappingHeading = '### Validation Annotations';

final _deprecatedAnnotation = RegExp(r'@Validate\.');
final _privateStaticSchema = RegExp(r'\bschema\s*=\s*_\w*Schema\s*;');

/// Docs, README files, the example package, and `llms.txt`.
List<File> _guidance() {
  const skipped = {'.dart_tool', 'build', 'node_modules', '.git', '.context'};
  bool kept(FileSystemEntity entity) =>
      !entity.uri.pathSegments.any(skipped.contains);
  Iterable<File> files(String directory) => Directory(
    directory,
  ).listSync(recursive: true).whereType<File>().where(kept);

  return [
    ...files(
      'docs',
    ).where((file) => file.path.endsWith('.md') || file.path.endsWith('.mdx')),
    ...files('example').where((file) => !file.path.endsWith('.g.dart')),
    ...files('.').where((file) => file.uri.pathSegments.last == 'README.md'),
    File('llms.txt'),
  ];
}

/// Removes the migration guide's mapping table, which names the old
/// annotations on purpose.
String _withoutExemptions(File file) {
  final text = file.readAsStringSync();
  if (file.path != _migrationGuide) return text;
  final start = text.indexOf(_mappingHeading);
  expect(start, isNot(-1), reason: '$_migrationGuide lost its mapping table');
  final next = RegExp(
    r'^#{2,3} ',
    multiLine: true,
  ).firstMatch(text.substring(start + _mappingHeading.length));
  final end = next == null
      ? text.length
      : start + _mappingHeading.length + next.start;

  // Keep the line count so reported line numbers stay accurate.
  final lines = '\n'.allMatches(text.substring(start, end)).length;

  return text.replaceRange(start, end, '\n' * lines);
}

List<String> _matches(RegExp pattern) => [
  for (final file in _guidance())
    for (final (index, line) in _withoutExemptions(file).split('\n').indexed)
      if (pattern.hasMatch(line)) '${file.path}:${index + 1}: ${line.trim()}',
];

void main() {
  test('guidance uses the rule annotations, not @Validate.*', () {
    expect(
      _matches(_deprecatedAnnotation),
      isEmpty,
      reason:
          'Use the Is/Has rule annotations. Only the migration guide '
          'mapping table and CHANGELOGs may name @Validate.*.',
    );
  });

  test('class-first static lines use the public facade', () {
    expect(
      _matches(_privateStaticSchema),
      isEmpty,
      reason:
          'Write `static final schema = <Name>Schema.schema;` instead of '
          'naming the private codec variable.',
    );
  });

  test('the exemption covers only the mapping table', () {
    final guide = File(_migrationGuide).readAsStringSync();

    expect(guide, contains('| `@Validate.minLength(n)` |'));
    expect(_withoutExemptions(File(_migrationGuide)), contains('## 4.'));
  });
}
