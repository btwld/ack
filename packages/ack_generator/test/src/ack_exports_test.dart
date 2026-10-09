import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

/// Writes the annotation names that `package:ack/ack.dart` exports.
final class _ExportProbe implements Builder {
  const _ExportProbe();

  @override
  Map<String, List<String>> get buildExtensions => const {
    '.dart': ['.exports'],
  };

  @override
  Future<void> build(BuildStep step) async {
    final ack = await step.resolver.libraryFor(AssetId('ack', 'lib/ack.dart'));
    final names = [
      for (final MapEntry(:key, :value)
          in ack.exportNamespace.definedNames2.entries)
        if (value.library?.uri.toString() case final uri?
            when uri.startsWith('package:ack/src/annotations/') ||
                uri.startsWith('package:json_annotation/'))
          key,
    ]..sort();
    await step.writeAsString(
      step.inputId.changeExtension('.exports'),
      names.join(','),
    );
  }
}

void main() {
  test('package:ack/ack.dart exports only the model annotations', () async {
    final readerWriter = TestReaderWriter(rootPackage: 'test_pkg');
    await readerWriter.testing.loadIsolateSources();
    await testBuilder(
      const _ExportProbe(),
      {'test_pkg|lib/probe.dart': "import 'package:ack/ack.dart';"},
      generateFor: const {'test_pkg|lib/probe.dart'},
      readerWriter: readerWriter,
      outputs: {
        'test_pkg|lib/probe.exports': decodedMatches(
          'AckCaseStyle,AckField,AckUnknownPropertyPolicy,'
          'Check,NotNull,Optional,Required,Schemable',
        ),
      },
    );
  });
}
