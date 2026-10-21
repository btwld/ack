import 'package:ack_generator/src/builder.dart';
import 'package:build/build.dart';
import 'package:build/experiments.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

Future<void> _expectCollision(String member) async {
  final readerWriter = TestReaderWriter(rootPackage: 'test_pkg');
  await readerWriter.testing.loadIsolateSources();
  final errors = <String>[];
  await testBuilder(
    ackModelBuilder(BuilderOptions.empty),
    {
      'test_pkg|lib/model.dart':
          '''
import 'package:ack/ack.dart';
part 'model.g.dart';
@Schemable()
final class Account {
  const Account();
  $member
}
''',
    },
    readerWriter: readerWriter,
    onLog: (log) {
      if (log.level.name == 'SEVERE') errors.add(log.message);
    },
  );
  expect(errors, contains(contains('conflicts with a generated member')));
}

Future<void> _build(
  String source,
  Matcher output, {
  Map<String, String> extraSources = const {},
}) async {
  final readerWriter = TestReaderWriter(rootPackage: 'test_pkg');
  await readerWriter.testing.loadIsolateSources();
  final errors = <String>[];
  await withEnabledExperiments(
    () => testBuilder(
      ackModelBuilder(BuilderOptions.empty),
      {
        'test_pkg|lib/model.dart':
            '''
// @dart=3.14
import 'package:ack/ack.dart';
${extraSources.isEmpty ? '' : "import 'exports.dart';"}
part 'model.g.dart';
$source
''',
        for (final entry in extraSources.entries)
          'test_pkg|lib/${entry.key}': entry.value,
      },
      onLog: (log) {
        if (log.level.name == 'SEVERE') errors.add(log.message);
      },
      generateFor: const {'test_pkg|lib/model.dart'},
      readerWriter: readerWriter,
      outputs: {
        'test_pkg|lib/model.g.dart': decodedMatches(output),
        if (extraSources.containsKey('account.dart'))
          'test_pkg|lib/account.g.dart': decodedMatches(anything),
      },
    ),
    ['augmentations'],
  );
  expect(errors, isEmpty);
}

// Parent and child both emit `id`. Only the child carries minLength(4).
Matcher _idSchema(String expression) => predicate<String>((source) {
  final found = [
    for (final match in RegExp(r"'id':\s*([^,}]+)").allMatches(source))
      match.group(1)!.replaceAll(RegExp(r'\s+'), ''),
  ].where((item) => item.contains('minLength(4)'));
  return found.length == 1 && found.single == expression;
}, "id schema exactly '$expression'");

Future<void> _expectInvalid(
  String source,
  String diagnostic, {
  String imports = "import 'package:ack/ack.dart';",
}) async {
  final readerWriter = TestReaderWriter(rootPackage: 'test_pkg');
  await readerWriter.testing.loadIsolateSources();
  final errors = <String>[];
  await testBuilder(
    ackModelBuilder(BuilderOptions.empty),
    {
      'test_pkg|lib/model.dart':
          '''
$imports
part 'model.g.dart';
$source
''',
    },
    readerWriter: readerWriter,
    onLog: (log) {
      if (log.level.name == 'SEVERE') errors.add(log.message);
    },
  );
  expect(errors, contains(contains(diagnostic)));
}

void main() {
  for (final member in [
    'static final fromJson = AccountSchema.fromJson;',
    'factory Account.fromJson(Map<String, dynamic> json) => const Account();',
    'static Account parse(Object? value) => const Account();',
    'static int get safeParse => 1;',
    'int get fromJson => 1;',
    'static final schema = AccountSchema.schema;',
    'const Account.schema();',
    'static set schema(int value) {}',
  ]) {
    test('rejects a generated API collision: $member', () {
      return _expectCollision(member);
    });
  }

  test('primary model gets parsing and value members without source glue', () {
    return _build(
      '''
@Schemable()
final class const Account({
  @AckKey('display_name') required final String name,
  final String? nickname,
  final int age = 18,
});
''',
      allOf([
        contains('augment final class Account'),
        contains('factory Account.fromJson('),
        contains('static Account parse('),
        contains('static _AckSchemaResult<Account> safeParse('),
        contains('get schema =>'),
        contains('_AckMap<_AckString, _AckDynamic> toJson()'),
        contains('get copyWith =>'),
        contains("'display_name': Ack.string()"),
        contains('Ack.integer().withDefault(18)'),
        isNot(contains(r'_$AccountAck')),
        isNot(contains('this as Account')),
      ]),
    );
  });

  test('conventional constructors also need no mixin or static forwarder', () {
    return _build(
      '''
@Schemable()
final class Account {
  const Account(this.name);
  final String name;
}
''',
      allOf(
        contains('augment final class Account'),
        contains('factory Account.fromJson('),
        isNot(contains(r'_$AccountAck')),
      ),
    );
  });

  test('primary parameter constraints are applied exactly once', () {
    return _build(
      '''
@Schemable()
final class const Account({
  @Validate.minLength(2) required final String name,
});
''',
      allOf(
        contains("'name': Ack.string().minLength(2)"),
        isNot(contains('.minLength(2).minLength(2)')),
      ),
    );
  });

  test('distinct field and parameter annotations are both retained', () {
    return _build('''
@Schemable()
final class Account {
  const Account({@Validate.minLength(2) required this.name});
  @Validate.minLength(2)
  final String name;
}
''', contains("'name': Ack.string().minLength(2).minLength(2)"));
  });

  for (final primaryChild in [true, false]) {
    for (final annotatedParent in [true, false]) {
      test(
        '${primaryChild ? 'primary' : 'conventional'} super parameters retain '
        'constraints with ${annotatedParent ? 'annotated' : 'unannotated'} '
        'primary fields',
        () => _build(
          '''
@Schemable()
final class const Parent({
  ${annotatedParent ? "@AckKey('id') @Validate.maxLength(6)" : ''}
  required final String id,
});
@Schemable()
${primaryChild ? '''
final class const Child({
  @Validate.minLength(4) required super.id,
}) extends Parent;
''' : '''
final class Child extends Parent {
  const Child({@Validate.minLength(4) required super.id});
}
'''}
''',
          _idSchema(
            'Ack.string()'
            '${annotatedParent ? '.maxLength(6)' : ''}.minLength(4)',
          ),
        ),
      );
    }
  }

  test('sealed unions preserve class modifiers in every augmentation', () {
    return _build(
      '''
@Schemable(discriminatorKey: 'kind')
sealed class const Pet();
final class const Cat({required final String name}) extends Pet;
final class const Dog({required final bool good}) extends Pet;
''',
      allOf(
        contains('augment sealed class Pet'),
        contains('factory Pet.fromJson('),
        contains('augment final class Cat'),
        contains('factory Cat.fromJson('),
        contains('augment final class Dog'),
        isNot(contains('mixin ')),
      ),
    );
  });

  test(
    'schema-first collections reference same-library generated Model.schema',
    () {
      return _build(
        '''
@Schemable()
final class const Account({required final String name});
@Schemable()
final teamSchema = Ack.object({'members': Ack.list(Account.schema)});
''',
        allOf(
          contains('final List<Account> members;'),
          contains('augment final class Account'),
        ),
      );
    },
  );

  test(
    'a model-only barrel import supports fields and schema-first collections',
    () {
      return _build(
        '''
@Schemable()
final class const Team({required final Account owner});
@Schemable()
final teamListSchema = Ack.object({'members': Ack.list(Account.schema)});
''',
        allOf(
          contains("'owner': Account.schema"),
          contains('final List<Account> members;'),
          isNot(contains('AccountSchema.schema')),
        ),
        extraSources: {
          'exports.dart': "export 'account.dart' show Account;",
          'account.dart': '''
import 'package:ack/ack.dart';
part 'account.g.dart';
@Schemable()
final class const Account({required final String name});
''',
        },
      );
    },
  );
  test('rejects generic models even when no field uses the parameter', () {
    return _expectInvalid(
      '@Schemable() final class const Account<T>({final int count = 0});',
      'class-first models must not declare type parameters',
    );
  });

  test('rejects implicit generic union branches', () {
    return _expectInvalid('''
@Schemable(discriminatorKey: 'kind')
sealed class const Pet();
final class const Cat<T>({final int lives = 9}) extends Pet;
''', 'class-first models must not declare type parameters');
  });

  for (final name in ['schema', 'parse', 'safeParse']) {
    test('rejects inherited instance $name conflicts', () {
      return _expectInvalid('''
class Base { const Base(); int get $name => 1; }
@Schemable()
final class const Account() extends Base;
''', 'inherits Base.$name');
    });
  }

  test('private superclass members in another library cannot collide', () {
    return _build(
      '''
@Schemable()
final class const Account({required final String name}) extends Base;
''',
      contains('augment final class Account'),
      extraSources: {
        'exports.dart': r'''
class Base {
  const Base();
  int get _AckObject => 1;
  int get _$AccountSchemaApi => 1;
}
''',
      },
    );
  });

  test('private superclass members in the same library still collide', () {
    return _expectInvalid(r'''
class Base { const Base(); int get _AckObject => 1; }
@Schemable()
final class const Account() extends Base;
''', 'inherits Base._AckObject');
  });

  test('diagnoses legacy generated mixins without fallback generation', () {
    return _expectInvalid(
      r'@Schemable() final class Account with _$AccountAck { const Account(); }',
      r'Remove the with clause',
    );
  });

  test('diagnoses an import prefix shadowed by the generated schema API', () {
    return _expectInvalid(
      '@schema.Schemable() final class const Account();',
      'Import prefix "schema" conflicts with a generated member',
      imports: "import 'package:ack/ack.dart' as schema;",
    );
  });
}
