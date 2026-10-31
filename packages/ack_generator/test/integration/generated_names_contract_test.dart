import 'package:ack_generator/src/builder.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

Future<void> _expectFailure(String source, List<String> messages) async {
  final readerWriter = TestReaderWriter(rootPackage: 'test_pkg');
  await readerWriter.testing.loadIsolateSources();
  final errors = <String>[];
  await testBuilder(
    ackModelBuilder(BuilderOptions.empty),
    {'test_pkg|lib/models.dart': source},
    generateFor: const {'test_pkg|lib/models.dart'},
    readerWriter: readerWriter,
    outputs: const {},
    onLog: (log) {
      if (log.level.name == 'SEVERE') errors.add(log.message);
    },
  );
  for (final message in messages) {
    expect(errors, contains(contains(message)));
  }
}

const _head = '''
import 'package:ack/ack.dart';
part 'models.g.dart';
''';

void main() {
  for (final name in [r'$TitleCopyWith', r'_$TitleCopyWith']) {
    test('rejects value-model helper collision $name', () async {
      await _expectFailure(
        '''
$_head
@Schemable()
final titleSchema = Ack.string();
final class $name {}
''',
        ['Generated helper "$name"', 'conflicts'],
      );
    });
  }

  for (final model in ['User', 'Renamed']) {
    test('rejects field matching generated class $model', () async {
      await _expectFailure(
        '''
$_head
@Schemable(name: '$model')
final userSchema = Ack.object({'$model': Ack.string()});
''',
        ['userSchema.$model', 'class name'],
      );
    });
  }

  test('checks inherited fields against an alias model name', () async {
    await _expectFailure(
      '''
$_head
@Schemable()
final originalSchema = Ack.object({'Alias': Ack.string()});
@Schemable()
final aliasSchema = originalSchema;
''',
      ['aliasSchema.Alias', 'class name'],
    );
  });

  for (final alias in [
    'final openSchema = baseSchema.passthrough();',
    'final openSchema = baseSchema.copyWith(additionalProperties: true);',
    'ObjectSchema get openSchema => baseSchema.passthrough();',
    '''final middleSchema = baseSchema;
@Schemable()
final openSchema = middleSchema.passthrough();''',
  ]) {
    test('rejects inherited capture-member collisions: $alias', () async {
      await _expectFailure(
        '''
$_head
@Schemable()
final baseSchema = Ack.object({'additionalProperties': Ack.string()});
@Schemable()
$alias
''',
        ['openSchema.additionalProperties', 'additional-properties member'],
      );
    });
  }

  for (final overrides in [
    '.passthrough().strict()',
    '.copyWith(additionalProperties: true).copyWith(additionalProperties: false)',
  ]) {
    test('permits inherited additionalProperties after $overrides', () async {
      final readerWriter = TestReaderWriter(rootPackage: 'test_pkg');
      await readerWriter.testing.loadIsolateSources();
      await testBuilder(
        ackModelBuilder(BuilderOptions.empty),
        {
          'test_pkg|lib/models.dart':
              '''
$_head
@Schemable()
final baseSchema = Ack.object({'additionalProperties': Ack.string()});
@Schemable()
final aliasSchema = baseSchema$overrides;
''',
        },
        readerWriter: readerWriter,
        outputs: {
          'test_pkg|lib/models.g.dart': decodedMatches(
            allOf(
              contains('class Alias'),
              contains('final String additionalProperties;'),
              isNot(contains('Map<String, Object?> additionalProperties')),
            ),
          ),
        },
      );
    });
  }

  for (final discriminator in ['Pet', 'Cat']) {
    test('rejects discriminator matching class $discriminator', () async {
      await _expectFailure(
        '''
$_head
@Schemable()
final catSchema = Ack.object({});
@Schemable()
final petSchema = Ack.discriminated(
  discriminatorKey: '$discriminator', schemas: {'cat': catSchema},
);
''',
        [discriminator, 'class name'],
      );
    });
  }

  test(
    'rejects duplicate fields before generating duplicate members',
    () async {
      await _expectFailure(
        '''
$_head
@Schemable()
final userSchema = Ack.object({'name': Ack.string(), 'name': Ack.integer()});
''',
        ['userSchema.name', 'duplicate'],
      );
    },
  );
}
