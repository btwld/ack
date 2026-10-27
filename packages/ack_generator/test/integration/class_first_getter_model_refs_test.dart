import 'package:ack_generator/src/builder.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

void main() {
  test(
    'class-first fields resolve same-build getter-generated models',
    () async {
      final readerWriter = TestReaderWriter(rootPackage: 'test_pkg');
      await readerWriter.testing.loadIsolateSources();
      await testBuilder(
        ackModelBuilder(BuilderOptions.empty),
        {
          'test_pkg|lib/models.dart': r'''
import 'package:ack/ack.dart';
part 'models.g.dart';

@Schemable()
StringSchema get labelSchema => Ack.string();

@Schemable()
final class Holder with _$HolderAck {
  const Holder({required this.label, required this.history});
  final Label label;
  final List<Label> history;
}
''',
        },
        generateFor: const {'test_pkg|lib/models.dart'},
        readerWriter: readerWriter,
        outputs: {
          'test_pkg|lib/models.g.dart': decodedMatches(
            allOf([
              contains('final class Label'),
              contains(r"Label.$ack.fromRuntime(value['label'] as String)"),
              contains(r'Label.$ack.fromRuntime(item as String)'),
            ]),
          ),
        },
      );
    },
  );
}
