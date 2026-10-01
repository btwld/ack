import 'package:ack_generator/src/builder.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

const _head = '''
import 'package:ack/ack.dart';

part 'model.ack.dart';
part 'model.ack.g.dart';
''';

Future<String> _generate(String body) async {
  final readerWriter = TestReaderWriter(rootPackage: 'test_pkg');
  await readerWriter.testing.loadIsolateSources();
  late String output;
  await testBuilder(
    ackModelBuilder(BuilderOptions.empty),
    {'test_pkg|lib/model.dart': '$_head\n$body'},
    generateFor: const {'test_pkg|lib/model.dart'},
    readerWriter: readerWriter,
    outputs: {
      'test_pkg|lib/model.ack.dart': decodedMatches(
        predicate<String>((generated) {
          output = generated;
          return true;
        }),
      ),
    },
  );
  return output;
}

Future<List<String>> _errors(String body) async {
  final readerWriter = TestReaderWriter(rootPackage: 'test_pkg');
  await readerWriter.testing.loadIsolateSources();
  final errors = <String>[];
  await testBuilder(
    ackModelBuilder(BuilderOptions.empty),
    {'test_pkg|lib/model.dart': '$_head\n$body'},
    generateFor: const {'test_pkg|lib/model.dart'},
    readerWriter: readerWriter,
    outputs: const {},
    onLog: (LogRecord log) {
      if (log.level == Level.SEVERE) errors.add(log.message);
    },
  );
  return errors;
}

const _classModel = r'''
@ANNOTATION(caseStyle: AckCaseStyle.snake, description: 'An account.')
final class Account with _$AccountAck {
  const Account({required this.displayName, this.tags = const []});

  final String displayName;
  final List<String> tags;
}
''';

const _schemaModel = '''
@ANNOTATION(name: 'Profile')
final profileSchema = Ack.object({
  'handle': Ack.string().minLength(2),
  'bio': Ack.string().optional(),
});
''';

void main() {
  test(
    '@AckModel generates the same class-first output as @Schemable',
    () async {
      final schemable = await _generate(
        _classModel.replaceFirst('ANNOTATION', 'Schemable'),
      );
      final deprecated = await _generate(
        _classModel.replaceFirst('ANNOTATION', 'AckModel'),
      );

      expect(schemable, contains('abstract final class AccountSchema'));
      expect(deprecated, schemable);
    },
  );

  test(
    '@AckInfer generates the same schema-first output as @Schemable',
    () async {
      final schemable = await _generate(
        _schemaModel.replaceFirst('ANNOTATION', 'Schemable'),
      );
      final deprecated = await _generate(
        _schemaModel.replaceFirst('ANNOTATION', 'AckInfer'),
      );

      expect(schemable, contains('@Schemable.generatedJson'));
      expect(deprecated, schemable);
    },
  );

  test(
    'class-first diagnostics name the annotation that was written',
    () async {
      const body = r'''
@ANNOTATION()
final class _Hidden with _$_HiddenAck {
  const _Hidden();
}
''';

      expect(
        await _errors(body.replaceFirst('ANNOTATION', 'Schemable')),
        contains(contains('@Schemable requires a public class')),
      );
      expect(
        await _errors(body.replaceFirst('ANNOTATION', 'AckModel')),
        contains(contains('@AckModel requires a public class')),
      );
    },
  );

  test(
    'schema-first diagnostics name the annotation that was written',
    () async {
      const body = '''
@ANNOTATION(name: 'lower')
final userSchema = Ack.object({'id': Ack.string()});
''';

      expect(
        await _errors(body.replaceFirst('ANNOTATION', 'Schemable')),
        contains(contains('Invalid @Schemable name "lower"')),
      );
      expect(
        await _errors(body.replaceFirst('ANNOTATION', 'AckInfer')),
        contains(contains('Invalid @AckInfer name "lower"')),
      );
    },
  );

  test('@AckInfer on a class points to @Schemable', () async {
    final errors = await _errors('''
@AckInfer()
final class Account {}
''');

    expect(
      errors,
      contains(
        contains(
          '@AckInfer can only be applied to top-level schema variables or '
          'getters, not classes. Use @Schemable() on the class.',
        ),
      ),
    );
  });
}
