@TestOn('vm')
library;

import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('public barrel does not expose the imported runtime type', () async {
    final temporary = Directory.systemTemp.createTempSync('ack-import-api-');
    addTearDown(() => temporary.deleteSync(recursive: true));
    final fixture = File(
      'test/fixtures/public_api/imported_runtime_hidden.dart.txt',
    );
    final source = fixture.copySync('${temporary.path}/consumer.dart');
    final result = await Process.run(Platform.resolvedExecutable, [
      'compile',
      'kernel',
      '--packages=${File('../../.dart_tool/package_config.json').absolute.path}',
      '-o',
      '${temporary.path}/consumer.dill',
      source.path,
    ]);
    expect(result.exitCode, isNot(0));
    expect(result.stderr, contains("'ImportedJsonSchema' isn't a type"));
  });

  test('public barrel does not add a redundant JSON Schema value type', () async {
    final temporary = Directory.systemTemp.createTempSync('ack-schema-api-');
    addTearDown(() => temporary.deleteSync(recursive: true));
    final fixture = File(
      'test/fixtures/public_api/json_schema_value_type_absent.dart.txt',
    );
    final source = fixture.copySync('${temporary.path}/consumer.dart');
    final result = await Process.run(Platform.resolvedExecutable, [
      'compile',
      'kernel',
      '--packages=${File('../../.dart_tool/package_config.json').absolute.path}',
      '-o',
      '${temporary.path}/consumer.dill',
      source.path,
    ]);
    expect(result.exitCode, isNot(0));
    expect(result.stderr, contains("'JsonSchema' isn't a type"));
  });
}
