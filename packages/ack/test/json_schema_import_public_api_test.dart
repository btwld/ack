@TestOn('vm')
library;

import 'dart:io';

import 'package:test/test.dart';

Future<ProcessResult> _compileFixture(String name) {
  final temporary = Directory.systemTemp.createTempSync('ack-import-api-');
  addTearDown(() => temporary.deleteSync(recursive: true));
  final source = File(
    'test/fixtures/public_api/$name.dart.txt',
  ).copySync('${temporary.path}/consumer.dart');

  return Process.run(Platform.resolvedExecutable, [
    'compile',
    'kernel',
    '--packages=${File('../../.dart_tool/package_config.json').absolute.path}',
    '-o',
    '${temporary.path}/consumer.dill',
    source.path,
  ]);
}

void main() {
  test(
    'public barrel does not expose the removed top-level importer',
    () async {
      final result = await _compileFixture(
        'json_schema_import_function_hidden',
      );
      expect(result.exitCode, isNot(0));
      expect(result.stderr, contains('importJsonSchema'));
    },
  );

  test('public barrel does not expose the imported runtime type', () async {
    final result = await _compileFixture('imported_runtime_hidden');
    expect(result.exitCode, isNot(0));
    expect(result.stderr, contains("'ImportedJsonSchema' isn't a type"));
  });

  test(
    'public barrel does not add a redundant JSON Schema value type',
    () async {
      final result = await _compileFixture('json_schema_value_type_absent');
      expect(result.exitCode, isNot(0));
      expect(result.stderr, contains("'JsonSchema' isn't a type"));
    },
  );
}
