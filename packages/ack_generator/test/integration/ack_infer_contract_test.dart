// Modern schema-first contract tests.
import 'package:ack_generator/src/builder.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

Future<TestBuilderResult> _generate(
  String source, {
  void Function(LogRecord log)? onLog,
  Map<String, Object>? outputs,
}) async {
  final readerWriter = TestReaderWriter(rootPackage: 'test_pkg');
  await readerWriter.testing.loadIsolateSources();
  return testBuilder(
    ackModelBuilder(BuilderOptions.empty),
    {'test_pkg|lib/schema.dart': source},
    generateFor: const {'test_pkg|lib/schema.dart'},
    readerWriter: readerWriter,
    outputs: outputs,
    onLog: onLog,
  );
}

const _imports = '''
import 'package:ack/ack.dart';
import 'package:ack/annotations.dart';

part 'schema.g.dart';
''';

const _schemaShorthand = r'static final schema = $ack.modelSchema;';

/// Matches generated source whose `className` declaration has, or lacks, the
/// static `schema` shorthand.
Matcher _schemaShorthandOn(String className, {required bool present}) =>
    predicate<String>((source) {
      final start = RegExp(
        'class ${RegExp.escape(className)}\\b',
      ).firstMatch(source)?.start;
      if (start == null) return false;
      final end = source.indexOf('\n}\n', start);
      final body = source.substring(start, end == -1 ? null : end);
      return body.contains(_schemaShorthand) == present;
    }, '$className ${present ? 'declares' : 'omits'} the schema shorthand');

void main() {
  test(
    'object models expose only the Schemable parse and JSON contract',
    () async {
      await _generate(
        '''
$_imports
@Schemable()
final userSchema = Ack.object({
  'name': Ack.string(),
  'nickname': Ack.string().optional(),
  'middleName': Ack.string().nullable(),
  'role': Ack.string().withDefault('member'),
});
''',
        outputs: {
          'test_pkg|lib/schema.g.dart': decodedMatches(
            allOf([
              contains('final class User'),
              isNot(contains('generatedJson')),
              contains('factory User.parse(Object? input)'),
              contains('factory User.fromJson(Map<String, dynamic> json)'),
              contains(r'static final $ack = AckModelAdapter'),
              contains('Map<String, dynamic> toJson()'),
              contains('SchemaResult<Map<String, Object?>> safeToJson()'),
              contains(r'$UserCopyWith<User> get copyWith'),
              contains('deepEquals('),
              contains('deepHashCode('),
              isNot(contains('fromMap')),
              isNot(contains('toMap')),
              isNot(contains('safeToMap')),
              contains('required this.name'),
              contains('this.nickname'),
              contains('required this.middleName'),
              contains('required this.role'),
              contains('_fromAckRuntime'),
              contains('_toAckRuntime'),
              contains("value['name'] as String"),
              contains("value['nickname'] as String?"),
              contains("value['middleName'] as String?"),
              contains("value['role'] as String"),
              contains("'nickname': ?nickname"),
              contains("'middleName': middleName"),
              isNot(contains(r'_$UserFromJson')),
              isNot(contains(r'_$UserToJson')),
              isNot(contains('_ackFromRuntimeName')),
              isNot(contains('_ackToRuntimeName')),
            ]),
          ),
        },
      );
    },
  );

  test('value roots use their schema boundary type for JSON', () async {
    await _generate(
      '''
$_imports
@Schemable()
final occurredAtSchema = Ack.datetime();
''',
      outputs: {
        'test_pkg|lib/schema.g.dart': decodedMatches(
          allOf([
            contains('final DateTime value;'),
            isNot(contains('generatedJson')),
            contains('factory OccurredAt.fromJson(String json)'),
            contains('String toJson()'),
            contains('SchemaResult<String> safeToJson()'),
            contains(
              'static OccurredAt _fromAckRuntime(DateTime value) => OccurredAt(value);',
            ),
            contains('DateTime _toAckRuntime() => value;'),
            isNot(contains(r'_$OccurredAtFromJson')),
            isNot(contains(r'_$OccurredAtToJson')),
          ]),
        ),
      },
    );
  });

  test('derived and custom names are exact', () async {
    await _generate(
      '''
$_imports
@Schemable()
final memberTypeSchema = Ack.string();

@Schemable(name: 'IntentionalType')
final customSchema = Ack.string();
''',
      outputs: {
        'test_pkg|lib/schema.g.dart': decodedMatches(
          allOf([
            contains('final class MemberType'),
            contains('final class IntentionalType'),
            isNot(contains('MemberTypeType')),
          ]),
        ),
      },
    );
  });

  test('every model kind declares a static schema shorthand', () async {
    await _generate(
      '''
$_imports
@Schemable()
final userSchema = Ack.object({'name': Ack.string()});

@Schemable()
final occurredAtSchema = Ack.datetime();

@Schemable()
final catSchema = Ack.object({'lives': Ack.integer()});

@Schemable()
final petSchema = Ack.discriminated(
  discriminatorKey: 'kind',
  schemas: {'cat': catSchema},
);
''',
      outputs: {
        'test_pkg|lib/schema.g.dart': decodedMatches(
          allOf([
            _schemaShorthandOn('User', present: true),
            _schemaShorthandOn('OccurredAt', present: true),
            _schemaShorthandOn('Pet', present: true),
            _schemaShorthandOn('Cat', present: true),
            contains(r'static final $ack = AckModelAdapter'),
          ]),
        ),
      },
    );
  });

  test('the schema shorthand yields to colliding members', () async {
    await _generate(
      '''
$_imports
@Schemable()
final documentSchema = Ack.object({'schema': Ack.string()});

@Schemable(name: 'Settings')
final schema = Ack.object({'theme': Ack.string()});

@Schemable()
final draftSchema = Ack.object({'body': Ack.string()});

@Schemable()
final revisionSchema = Ack.discriminated(
  discriminatorKey: 'schema',
  schemas: {'draft': draftSchema},
);

@Schemable()
final circleSchema = Ack.object({'radius': Ack.integer()});

@Schemable()
final ruleSchema = Ack.object({'schema': Ack.string()});

@Schemable()
final shapeSchema = Ack.discriminated(
  discriminatorKey: 'type',
  schemas: {'circle': circleSchema, 'rule': ruleSchema},
);
''',
      outputs: {
        'test_pkg|lib/schema.g.dart': decodedMatches(
          allOf([
            // A field named `schema`.
            _schemaShorthandOn('Document', present: false),
            // The shorthand would shadow the `schema` declaration.
            _schemaShorthandOn('Settings', present: false),
            // The discriminator getter is named `schema`.
            _schemaShorthandOn('Revision', present: false),
            _schemaShorthandOn('Draft', present: false),
            // Only the branch with a `schema` field loses the shorthand.
            _schemaShorthandOn('Shape', present: true),
            _schemaShorthandOn('Circle', present: true),
            _schemaShorthandOn('Rule', present: false),
          ]),
        ),
      },
    );
  });

  test('an import prefix named schema suppresses the shorthand', () async {
    await _generate(
      '''
import 'package:ack/ack.dart' as schema;
import 'package:ack/annotations.dart';

part 'schema.g.dart';

@Schemable()
final userSchema = schema.Ack.object({'name': schema.Ack.string()});
''',
      outputs: {
        'test_pkg|lib/schema.g.dart': decodedMatches(
          allOf([
            contains('schema.AckModelAdapter'),
            _schemaShorthandOn('User', present: false),
          ]),
        ),
      },
    );
  });

  test('rejects one-way transforms anywhere in the graph', () async {
    var sawError = false;
    await _generate(
      '''
$_imports
@Schemable()
final userSchema = Ack.object({
  'age': Ack.string().transform(int.parse),
});
''',
      outputs: const {},
      onLog: (log) {
        if (log.level.name == 'SEVERE' &&
            log.message.contains('userSchema.age') &&
            log.message.contains('.codec()')) {
          sawError = true;
        }
      },
    );
    expect(sawError, isTrue);
  });

  test('rejects whitespace-altered custom names', () async {
    var sawError = false;
    await _generate(
      '''
$_imports
@Schemable(name: ' User')
final userSchema = Ack.string();
''',
      outputs: const {},
      onLog: (log) {
        if (log.level.name == 'SEVERE' &&
            log.message.contains('UpperCamelCase')) {
          sawError = true;
        }
      },
    );
    expect(sawError, isTrue);
  });
}
