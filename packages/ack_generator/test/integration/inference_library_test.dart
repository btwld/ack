import 'package:ack_generator/inference.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

final class _InferenceProbe implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => const {
    '.dart': ['.probe'],
  };

  @override
  Future<void> build(BuildStep step) async {
    final library = await step.resolver.libraryFor(step.inputId);
    final parameter = library.topLevelFunctions
        .singleWhere((function) => function.name == 'widget')
        .formalParameters
        .single;
    const inference = AckSchemaInference();
    final base = await inference.inferType(
      parameter.type,
      visibleTypeName: (type) => type.element.name!,
      renderType: (type) => type.getDisplayString(),
      resolveNamed: (_) async => null,
      unsupported: (type) => throw StateError('Unsupported $type'),
      rejectNullableCollectionElement: (type) =>
          throw StateError('Nullable item $type'),
      validateMapKey: (_) {},
    );
    final constrained = inference.applyConstraints(
      base,
      parameter,
      parameter.type,
    );
    final described = inference.applyDescription(
      constrained,
      parameter,
      sourceComment: '/// The item title.',
    );
    await step.writeAsString(step.inputId.changeExtension('.probe'), described);
  }
}

void main() {
  test('a second generator infers an annotated parameter', () async {
    final readerWriter = TestReaderWriter(rootPackage: 'test_pkg');
    await readerWriter.testing.loadIsolateSources();
    await testBuilder(
      _InferenceProbe(),
      {
        'test_pkg|lib/widget.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

void widget({
  /// The item title.
  @MinLength(2)
  required String title,
}) {}
''',
      },
      generateFor: const {'test_pkg|lib/widget.dart'},
      readerWriter: readerWriter,
      outputs: {
        'test_pkg|lib/widget.probe': decodedMatches(
          "Ack.string().minLength(2).describe('The item title.')",
        ),
      },
    );
  });
}
