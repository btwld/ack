import 'package:ack_generator/src/builder.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import 'isolate_sources.dart';

void main() {
  test('preserves every visible dependency asset and its bytes', () async {
    final original = TestReaderWriter(rootPackage: 'test_pkg');
    await original.testing.loadIsolateSources();
    final readerWriter = await createTestReaderWriter();

    expect(original.testing.assets, isNotEmpty);
    expect(
      readerWriter.testing.assets,
      unorderedEquals(original.testing.assets),
    );
    for (final id in original.testing.assets) {
      expect(
        readerWriter.testing.readBytes(id),
        original.testing.readBytes(id),
        reason: 'Dependency bytes changed for $id',
      );
    }
    expect(readerWriter.testing.assetsRead, isEmpty);
    expect(readerWriter.testing.assetsWritten, isEmpty);
  });

  test('reader mutations, outputs and tracking stay in their case', () async {
    final first = await createTestReaderWriter();
    final dependency = AssetId('ack', 'lib/ack.dart');
    final removed = AssetId('ack', 'lib/annotations.dart');
    final fixture = AssetId('test_pkg', 'lib/schema.dart');
    final output = AssetId('test_pkg', 'lib/schema.ack.dart');
    final originalBytes = List<int>.of(first.testing.readBytes(dependency));

    await first.readAsBytes(dependency);
    first.testing.readBytes(dependency)[0] ^= 0xff;
    first.testing.delete(removed);
    first.testing.writeString(fixture, 'final fixture = 1;');
    await first.writeAsString(output, 'generated in the first case');
    expect(first.testing.assetsRead, contains(dependency));
    expect(first.testing.assetsWritten, contains(output));

    final second = await createTestReaderWriter();
    expect(second, isNot(same(first)));
    expect(second.testing.readBytes(dependency), originalBytes);
    expect(second.testing.exists(removed), isTrue);
    expect(second.testing.exists(fixture), isFalse);
    expect(second.testing.exists(output), isFalse);
    expect(second.testing.assetsRead, isEmpty);
    expect(second.testing.assetsWritten, isEmpty);
  });

  test(
    'concurrent requests get independent readers and byte buffers',
    () async {
      final readers = await Future.wait([
        createTestReaderWriter(),
        createTestReaderWriter(),
      ]);
      final dependency = AssetId('ack', 'lib/ack.dart');
      final originalBytes = List<int>.of(
        readers[1].testing.readBytes(dependency),
      );
      readers[0].testing.readBytes(dependency)[0] ^= 0xff;

      expect(readers[0], isNot(same(readers[1])));
      expect(readers[1].testing.readBytes(dependency), originalBytes);
      final later = await createTestReaderWriter();
      expect(later.testing.readBytes(dependency), originalBytes);
    },
  );

  for (final validFirst in [true, false]) {
    test('resolves fresh fixtures and outputs with valid case '
        '${validFirst ? 'before' : 'after'} a missing JSON part', () async {
      for (final valid in [validFirst, !validFirst]) {
        final readerWriter = await createTestReaderWriter();
        final errors = <String>[];
        expect(
          readerWriter.testing.assets.where((id) => id.package == 'test_pkg'),
          isEmpty,
        );
        expect(readerWriter.testing.assetsRead, isEmpty);
        expect(readerWriter.testing.assetsWritten, isEmpty);

        await testBuilder(
          ackModelBuilder(BuilderOptions.empty),
          {
            'test_pkg|lib/schema.dart': valid
                ? _source
                : _source.replaceFirst("part 'schema.ack.g.dart';", ''),
          },
          generateFor: const {'test_pkg|lib/schema.dart'},
          readerWriter: readerWriter,
          outputs: valid
              ? {
                  'test_pkg|lib/schema.ack.dart': decodedMatches(
                    contains('final class User'),
                  ),
                }
              : const {},
          onLog: (log) {
            if (log.level.name == 'SEVERE') errors.add(log.message);
          },
        );
        expect(
          errors,
          valid ? isEmpty : contains(contains("part 'schema.ack.g.dart';")),
        );
      }
    });
  }
}

const _source = '''
import 'package:ack/ack.dart';
import 'package:ack/annotations.dart';

part 'schema.ack.dart';
part 'schema.ack.g.dart';

@Schemable()
final userSchema = Ack.object({'name': Ack.string()});
''';
