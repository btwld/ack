import 'package:ack_generator/src/builder.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

const _source = r'''
import 'package:ack/ack.dart';
part 'models.g.dart';

@Schemable()
final baseSchema = Ack.object({'name': Ack.string()});
final changed = (baseSchema.extend({'age': Ack.integer()}));
''';

Future<void> _build(
  String suffix,
  Map<String, Object> outputs, {
  void Function(String)? onError,
}) async {
  final readerWriter = TestReaderWriter(rootPackage: 'test_pkg');
  await readerWriter.testing.loadIsolateSources();
  await testBuilder(
    ackModelBuilder(BuilderOptions.empty),
    {'test_pkg|lib/models.dart': '$_source\n$suffix'},
    generateFor: const {'test_pkg|lib/models.dart'},
    readerWriter: readerWriter,
    outputs: outputs,
    onLog: (log) {
      if (log.level.name == 'SEVERE') onError?.call(log.message);
    },
  );
}

void main() {
  test(
    'rejects shape changes hidden behind unannotated schema aliases',
    () async {
      final errors = <String>[];
      await _build(
        r'''
final intermediate = changed;
@Schemable()
final aliasSchema = intermediate;
''',
        const {},
        onError: errors.add,
      );
      expect(errors, contains(contains('aliasSchema')));
      expect(errors, contains(contains('changed')));
      expect(errors, contains(contains('extend')));
      expect(errors, contains(contains('shape')));
    },
  );

  test('stops alias shape inspection at an outer value codec', () async {
    await _build(
      r'''
final wrapped = changed.codec<int>(
  decode: (value) => value['age'] as int,
  encode: (value) => {'name': 'Ada', 'age': value},
);
@Schemable()
final aliasSchema = wrapped;
''',
      {
        'test_pkg|lib/models.g.dart': decodedMatches(
          allOf([contains('final class Alias'), contains('final int value;')]),
        ),
      },
    );
  });

  test(
    'inspects type-owned schema calls without self-referencing AST recursion',
    () async {
      await _build(
        r'''
final class Token {
  const Token(this.value);
  final String value;
  static AckSchema<String, Token> schema<T>() => Ack.string().codec<Token>(
    decode: Token.new, encode: (token) => token.value,
  );
}
@Schemable()
final aliasSchema = Ack.object({'token': Token.schema<String>()});
''',
        {
          'test_pkg|lib/models.g.dart': decodedMatches(
            contains('final Token token;'),
          ),
        },
      );
    },
  );
}
