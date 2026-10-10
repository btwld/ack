import 'dart:io';

import 'package:ack_generator/src/builder.dart';
import 'package:ack_generator/src/json/helper_names.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('build.yaml encodes the single-builder Ack 2.0 contract', () {
    var directory = Directory.current;
    if (!File(p.join(directory.path, 'build.yaml')).existsSync()) {
      directory = Directory(
        p.join(directory.path, 'packages', 'ack_generator'),
      );
    }
    final yaml = File(p.join(directory.path, 'build.yaml')).readAsStringSync();
    expect(yaml, contains('ack_generator:'));
    expect(yaml, contains('builder_factories: ["ackGenerator"]'));
    expect(yaml, contains('build_extensions: {".dart": [".ack.g.part"]}'));
    expect(yaml, contains('build_to: cache'));
    expect(
      yaml,
      contains('applies_builders: ["source_gen|combining_builder"]'),
    );
    expect(yaml, isNot(contains('ack_model_json')));
    expect(yaml, isNot(contains('.ack.g.dart')));
  });

  test('derived helper names stay deterministic', () {
    expect(ackClassFromRuntimeName('User'), r'_$UserFromRuntime');
    expect(ackClassToRuntimeName('User'), r'_$UserToRuntime');
    expect(ackCopyWithInterfaceName('User'), r'$UserCopyWith');
    expect(ackCopyWithImplementationName('User'), r'_$UserCopyWith');
    expect(ackCopyWithUnsetTypeName('User'), '_UserCopyWithUnset');
  });

  test('Ack model builder exits immediately for ordinary libraries', () async {
    final readerWriter = TestReaderWriter(rootPackage: 'test_pkg');
    await readerWriter.testing.loadIsolateSources();
    await testBuilder(
      ackModelBuilder(BuilderOptions.empty),
      {'test_pkg|lib/plain.dart': 'final value = 1;'},
      generateFor: const {'test_pkg|lib/plain.dart'},
      readerWriter: readerWriter,
      outputs: const {},
    );
  });
}
