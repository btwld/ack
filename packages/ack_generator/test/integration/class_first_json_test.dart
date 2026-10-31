import 'package:ack/annotations.dart' show AckCaseStyle;
import 'package:ack_generator/src/builder.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

Future<void> _expectGeneratedPart(String source, Matcher matcher) async {
  final readerWriter = TestReaderWriter(rootPackage: 'test_pkg');
  await readerWriter.testing.loadIsolateSources();
  await testBuilder(
    ackModelBuilder(BuilderOptions.empty),
    {'test_pkg|lib/model.dart': source},
    generateFor: const {'test_pkg|lib/model.dart'},
    readerWriter: readerWriter,
    outputs: {'test_pkg|lib/model.g.dart': decodedMatches(matcher)},
  );
}

const _head = '''
import 'package:ack/ack.dart';
import 'package:ack/annotations.dart';

part 'model.g.dart';
''';

void main() {
  test(
    'class-first runtime mapping uses direct constructor and map literals with pinned case style',
    () async {
      await _expectGeneratedPart(
        '''
$_head
@Schemable(caseStyle: AckCaseStyle.snake)
final class User with _\$UserAck {
  const User({required this.firstName, this.nickname});

  final String firstName;
  final String? nickname;
}
''',
        allOf([
          contains(r'User _$UserFromRuntime(Map<String, Object?> value)'),
          contains("firstName: value['first_name'] as String"),
          contains("nickname: value['nickname'] as String?"),
          contains(r'Map<String, Object?> _$UserToRuntime(User model)'),
          contains("'first_name': model.firstName"),
          contains("'nickname': ?model.nickname"),
          isNot(contains(r'_$UserFromJson')),
          isNot(contains(r'_$UserToJson')),
        ]),
      );
    },
  );

  test(
    'runtime emission auto-includes unannotated concrete sealed branches',
    () async {
      await _expectGeneratedPart(
        '''
$_head
@Schemable(discriminatorKey: 'type')
sealed class Pet with _\$PetAck {
  const Pet({required this.id});
  final String id;
}

final class Cat extends Pet with _\$CatAck {
  const Cat({required super.id, required this.lives});
  final int lives;
}
''',
        allOf([
          contains(r'Cat _$CatFromRuntime'),
          contains("id: value['id'] as String"),
          contains("lives: value['lives'] as int"),
          contains("'id': model.id"),
          contains("'lives': model.lives"),
          isNot(contains(r'Pet _$PetFromRuntime')),
        ]),
      );
    },
  );

  test('runtime emission applies an annotated branch case style', () async {
    await _expectGeneratedPart(
      '''
$_head
@Schemable(discriminatorKey: 'type')
sealed class Pet with _\$PetAck {
  const Pet();
}

@Schemable(caseStyle: AckCaseStyle.snake)
final class Cat extends Pet with _\$CatAck {
  const Cat({required this.livesLeft});
  final int livesLeft;
}
''',
      allOf([
        contains("livesLeft: value['lives_left'] as int"),
        contains("'lives_left': model.livesLeft"),
      ]),
    );
  });

  for (final style in AckCaseStyle.values) {
    test('runtime emission renames keys for caseStyle ${style.name}', () async {
      final key = switch (style) {
        AckCaseStyle.none => 'firstName',
        AckCaseStyle.snake => 'first_name',
        AckCaseStyle.kebab => 'first-name',
        AckCaseStyle.pascal => 'FirstName',
        AckCaseStyle.screamingSnake => 'FIRST_NAME',
      };
      await _expectGeneratedPart(
        '''
$_head
@Schemable(caseStyle: AckCaseStyle.${style.name})
final class User with _\$UserAck {
  const User({required this.firstName});

  final String firstName;
}
''',
        allOf([
          contains("firstName: value['$key'] as String"),
          contains("'$key': model.firstName"),
        ]),
      );
    });
  }
}
