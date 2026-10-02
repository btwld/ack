import 'package:ack_generator/inference.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

final class _PatternProbe implements Builder {
  const _PatternProbe();

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
    final expression = const AckSchemaInference().applyConstraints(
      'Ack.string()',
      parameter,
      parameter.type,
    );
    await step.writeAsString(
      step.inputId.changeExtension('.probe'),
      expression,
    );
  }
}

final class _StringValues extends RecursiveAstVisitor<void> {
  final values = <String>[];

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    values.add(node.value);
  }
}

void main() {
  final cases = <({String name, String literal, String expected})>[
    (
      name: 'regular expression escapes',
      literal: r"r'^\d+\.\d+$'",
      expected: r'^\d+\.\d+$',
    ),
    (
      name: 'line endings',
      literal: r"'first\nsecond\r\nthird'",
      expected: 'first\nsecond\r\nthird',
    ),
    (
      name: 'quotes, backslashes, and interpolation markers',
      literal: r"""'quote\' slash\\ dollar\$ \${notInterpolation}'""",
      expected: "quote' slash\\ dollar\$ \${notInterpolation}",
    ),
    (
      name: 'control characters and Unicode line separators',
      literal: r"'\u0000\t\b\f\u001f\u2028\u2029'",
      expected: '\u0000\t\b\f\u001f\u2028\u2029',
    ),
  ];

  for (final example in cases) {
    test('pattern literal preserves ${example.name}', () async {
      final readerWriter = TestReaderWriter(rootPackage: 'test_pkg');
      await readerWriter.testing.loadIsolateSources();
      await testBuilder(
        const _PatternProbe(),
        {
          'test_pkg|lib/widget.dart':
              '''
import 'package:ack/annotations.dart';

void widget({@Matches(${example.literal}) required String value}) {}
''',
        },
        generateFor: const {'test_pkg|lib/widget.dart'},
        readerWriter: readerWriter,
        outputs: {
          'test_pkg|lib/widget.probe': decodedMatches(
            predicate<String>((expression) {
              final parsed = parseString(
                content: 'final schema = $expression;',
                throwIfDiagnostics: false,
              );
              expect(parsed.errors, isEmpty);
              final strings = _StringValues();
              parsed.unit.accept(strings);
              expect(strings.values, [example.expected]);
              return true;
            }, 'valid Dart with the original annotation value'),
          ),
        },
      );
    });
  }

  test('the deprecated @Pattern spelling still adds matches', () async {
    final readerWriter = TestReaderWriter(rootPackage: 'test_pkg');
    await readerWriter.testing.loadIsolateSources();
    await testBuilder(
      const _PatternProbe(),
      {
        'test_pkg|lib/widget.dart': '''
import 'package:ack/annotations.dart';

void widget({@Pattern('^a') required String value}) {}
''',
      },
      generateFor: const {'test_pkg|lib/widget.dart'},
      readerWriter: readerWriter,
      outputs: {
        'test_pkg|lib/widget.probe': decodedMatches(
          "Ack.string().matches('^a')",
        ),
      },
    );
  });
}
