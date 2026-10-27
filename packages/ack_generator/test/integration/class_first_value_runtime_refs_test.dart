import 'package:ack_generator/src/builder.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

Future<void> _expectOutput(String source, Matcher matcher) async {
  final readerWriter = TestReaderWriter(rootPackage: 'test_pkg');
  await readerWriter.testing.loadIsolateSources();
  await testBuilder(
    ackModelBuilder(BuilderOptions.empty),
    {'test_pkg|lib/models.dart': source},
    generateFor: const {'test_pkg|lib/models.dart'},
    readerWriter: readerWriter,
    outputs: {'test_pkg|lib/models.g.dart': decodedMatches(matcher)},
  );
}

void main() {
  test(
    'same-build value models use their actual schema runtime types',
    () async {
      await _expectOutput(
        r'''
import 'package:ack/ack.dart';
part 'models.g.dart';

final class Token {
  const Token(this.value);
  final String value;
}

@Schemable()
final scalarSchema = Ack.integer();
@Schemable()
final stringsSchema = Ack.list(Ack.string());
@Schemable()
final encodedSchema = Ack.string().codec<Token>(
  decode: Token.new,
  encode: (token) => token.value,
);

@Schemable()
final class Holder with _$HolderAck {
  const Holder({required this.scalar, required this.strings, required this.encoded});
  final Scalar scalar;
  final Strings strings;
  final Encoded encoded;
}
''',
        allOf([
          contains(r"Scalar.$ack.fromRuntime(value['scalar'] as int)"),
          contains(
            r"Strings.$ack.fromRuntime(value['strings'] as List<String>)",
          ),
          contains(r"Encoded.$ack.fromRuntime(value['encoded'] as Token)"),
        ]),
      );
    },
  );

  test('nullable nested Sets use non-nullable codec type arguments', () async {
    await _expectOutput(
      r'''
import 'package:ack/ack.dart';
part 'models.g.dart';

@Schemable()
final class Holder with _$HolderAck {
  const Holder({required this.values, required this.nested});
  final Map<String, Set<int>?> values;
  final Map<String, Map<String, Set<String>?>?> nested;
}
''',
      allOf([
        contains('.codec<Set<int>>('),
        contains('.codec<Set<String>>('),
        isNot(contains('.codec<Set<int>?>(')),
        isNot(contains('.codec<Set<String>?>(')),
      ]),
    );
  });
}
