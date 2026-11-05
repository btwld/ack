import 'dart:io';

import 'package:test/test.dart';

/// The migration guide section whose mapping table keeps the deprecated names.
const _migrationGuide = 'docs/getting-started/migration-guide.mdx';
const _mappingHeading = '### Validation Annotations';

final _deprecatedAnnotation = RegExp(r'@Validate\.');

/// A `schema` or `fromJson` static whose value starts with a private
/// identifier, such as `static final schema = _accountSchema;` or
/// `static final fromJson = _accountSchema.parse;`. A local variable such as
/// `final schema = _build();` is not a static line.
final _privateStatic = RegExp(
  r'\bstatic\s+(?:late\s+)?(?:final|const)\s+(?:[^=;]*\s)?'
  r'(?:schema|fromJson)\s*=\s*_[\w$]+\s*[;.]',
);

/// Docs, README files, every example directory, and `llms.txt`.
List<File> _guidance() {
  const skipped = {'.dart_tool', 'build', 'node_modules', '.git', '.context'};
  bool kept(FileSystemEntity entity) =>
      !entity.uri.pathSegments.any(skipped.contains);
  Iterable<File> files(String directory) => Directory(
    directory,
  ).listSync(recursive: true).whereType<File>().where(kept);
  final examples = [
    'example',
    for (final package in Directory(
      'packages',
    ).listSync().whereType<Directory>())
      if (Directory('${package.path}/example').existsSync())
        '${package.path}/example',
  ];

  return [
    ...files(
      'docs',
    ).where((file) => file.path.endsWith('.md') || file.path.endsWith('.mdx')),
    for (final example in examples)
      ...files(example).where((file) => !file.path.endsWith('.g.dart')),
    ...files('.').where((file) => file.uri.pathSegments.last == 'README.md'),
    File('llms.txt'),
  ];
}

/// Blanks the rows of the migration guide's mapping table, which names the
/// old annotations on purpose. The rest of the guide is checked.
String _withoutExemptions(File file) {
  final text = file.readAsStringSync();
  if (file.path != _migrationGuide) return text;
  final lines = text.split('\n');
  final heading = lines.indexOf(_mappingHeading);
  expect(heading, isNot(-1), reason: '$_migrationGuide lost its mapping table');
  var row = heading + 1;
  while (row < lines.length && !lines[row].startsWith('|')) {
    row++;
  }
  // Blank the rows in place so reported line numbers stay accurate.
  for (; row < lines.length && lines[row].startsWith('|'); row++) {
    lines[row] = '';
  }

  return lines.join('\n');
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
      _matches(_privateStatic),
      isEmpty,
      reason:
          'Write `static final schema = <Name>Schema.schema;` and '
          '`static final fromJson = <Name>Schema.fromJson;` instead of '
          'naming a private declaration.',
    );
  });

  test('the static-line guard matches private values only on statics', () {
    for (final line in const [
      'static final schema = _accountSchema;',
      'static final fromJson = _accountSchema.parse;',
      r'static final fromJson = _$AccountFromJson;',
      'static final AckSchema<Object, Account> schema = _accountSchema;',
    ]) {
      expect(_privateStatic.hasMatch(line), isTrue, reason: line);
    }
    for (final line in const [
      'static final schema = AccountSchema.schema;',
      'static final fromJson = AccountSchema.fromJson;',
      'final schema = _build();',
      'final schema = _accountSchema;',
    ]) {
      expect(_privateStatic.hasMatch(line), isFalse, reason: line);
    }
  });

  test('the scan covers every example directory', () {
    final scanned = _guidance().map((file) => file.path).toSet();

    expect(scanned, contains('packages/ack_generator/example/example.dart'));
    expect(scanned, contains('example/lib/class_first_models.dart'));
  });

  test('the exemption covers only the mapping table rows', () {
    final guide = File(_migrationGuide).readAsStringSync();
    final checked = _withoutExemptions(File(_migrationGuide));
    final blanked = [
      for (final (index, line) in guide.split('\n').indexed)
        if (line != checked.split('\n')[index]) line,
    ];

    expect(guide, contains('| `@Validate.minLength(n)` |'));
    expect(blanked, everyElement(startsWith('|')));
    // The header, the separator, and one row per deprecated constructor.
    expect(blanked, hasLength(2 + 24));
    expect(checked, contains('The top-level 1.x validation'));
  });
}
