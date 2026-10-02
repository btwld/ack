import 'package:ack/annotations.dart' show AckCaseStyle;
import 'package:ack_generator/src/builder.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

Future<void> _expectJsonOutput(String source, Matcher matcher) async {
  final readerWriter = TestReaderWriter(rootPackage: 'test_pkg');
  await readerWriter.testing.loadIsolateSources();
  await testBuilder(
    ackModelJsonBuilder(BuilderOptions.empty),
    {
      'test_pkg|lib/model.dart': source,
      'test_pkg|lib/model.ack.dart': "part of 'model.dart';",
    },
    generateFor: const {'test_pkg|lib/model.dart'},
    readerWriter: readerWriter,
    outputs: {'test_pkg|lib/model.ack.g.dart': decodedMatches(matcher)},
  );
}

const _head = '''
import 'package:ack/annotations.dart';

part 'model.ack.dart';
part 'model.ack.g.dart';
''';

void main() {
  test(
    'class-first JSON uses top-level bridges and pinned case style',
    () async {
      await _expectJsonOutput(
        '''
$_head
@Schemable(caseStyle: AckCaseStyle.snake)
final class User {
  const User({required this.firstName, this.nickname});

  final String firstName;
  final String? nickname;
}

String _ackUserFromRuntimeFirstName(Object? value) => value as String;
Object? _ackUserToRuntimeFirstName(String value) => value;
String? _ackUserFromRuntimeNickname(Object? value) => value as String?;
Object? _ackUserToRuntimeNickname(String? value) => value;
''',
        allOf([
          contains(
            "firstName: _ackUserFromRuntimeFirstName(json['first_name'])",
          ),
          contains("nickname: _ackUserFromRuntimeNickname(json['nickname'])"),
          contains(
            "'first_name': _ackUserToRuntimeFirstName(instance.firstName)",
          ),
          contains("'nickname': ?_ackUserToRuntimeNickname(instance.nickname)"),
          isNot(contains('User._ackFromRuntime')),
        ]),
      );
    },
  );

  test(
    'JSON phase auto-includes unannotated concrete sealed branches',
    () async {
      await _expectJsonOutput(
        '''
$_head
@Schemable(discriminatorKey: 'type')
sealed class Pet {
  const Pet({required this.id});
  final String id;
}

final class Cat extends Pet {
  const Cat({required super.id, required this.lives});
  final int lives;
}

String _ackCatFromRuntimeId(Object? value) => value as String;
Object? _ackCatToRuntimeId(String value) => value;
int _ackCatFromRuntimeLives(Object? value) => value as int;
Object? _ackCatToRuntimeLives(int value) => value;
''',
        allOf([
          contains(r'Cat _$CatFromJson'),
          contains("id: _ackCatFromRuntimeId(json['id'])"),
          contains("lives: _ackCatFromRuntimeLives(json['lives'])"),
          contains("'id': _ackCatToRuntimeId(instance.id)"),
          contains("'lives': _ackCatToRuntimeLives(instance.lives)"),
          isNot(contains(r'Pet _$PetFromJson')),
        ]),
      );
    },
  );

  test('JSON phase applies an annotated branch case style', () async {
    await _expectJsonOutput(
      '''
$_head
@Schemable(discriminatorKey: 'type')
sealed class Pet {
  const Pet();
}

@Schemable(caseStyle: AckCaseStyle.snake)
final class Cat extends Pet {
  const Cat({required this.livesLeft});
  final int livesLeft;
}

int _ackCatFromRuntimeLivesLeft(Object? value) => value as int;
Object? _ackCatToRuntimeLivesLeft(int value) => value;
''',
      allOf([
        contains("livesLeft: _ackCatFromRuntimeLivesLeft(json['lives_left'])"),
        contains("'lives_left': _ackCatToRuntimeLivesLeft(instance.livesLeft)"),
      ]),
    );
  });

  for (final style in AckCaseStyle.values) {
    test('JSON phase renames keys for caseStyle ${style.name}', () async {
      final key = switch (style) {
        AckCaseStyle.none => 'firstName',
        AckCaseStyle.snake => 'first_name',
        AckCaseStyle.kebab => 'first-name',
        AckCaseStyle.pascal => 'FirstName',
        AckCaseStyle.screamingSnake => 'FIRST_NAME',
      };
      await _expectJsonOutput(
        '''
$_head
@Schemable(caseStyle: AckCaseStyle.${style.name})
final class User {
  const User({required this.firstName});

  final String firstName;
}

String _ackUserFromRuntimeFirstName(Object? value) => value as String;
Object? _ackUserToRuntimeFirstName(String value) => value;
''',
        allOf([
          contains("firstName: _ackUserFromRuntimeFirstName(json['$key'])"),
          contains("'$key': _ackUserToRuntimeFirstName(instance.firstName)"),
        ]),
      );
    });
  }
}
