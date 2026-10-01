import 'package:ack_generator/src/builder.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

void main() {
  test(
    'pinned JSON phase generates inherited fields through super parameters',
    () async {
      final readerWriter = TestReaderWriter(rootPackage: 'test_pkg');
      await readerWriter.testing.loadIsolateSources();

      await testBuilder(
        ackModelJsonBuilder(BuilderOptions.empty),
        {
          'test_pkg|lib/pet.dart': r'''
import 'package:ack/ack_generator_support.dart';

part 'pet.ack.g.dart';

sealed class Pet {
  const Pet({required this.id});

  final String id;
}

@AckGeneratedJson()
final class Cat extends Pet {
  const Cat({required super.id, required this.lives, this.nickname});

  final int lives;
  final String? nickname;

  static String _ackFromRuntimeId(Object? value) => value as String;
  static Object? _ackToRuntimeId(String value) => value;
  static int _ackFromRuntimeLives(Object? value) => value as int;
  static Object? _ackToRuntimeLives(int value) => value;
  static String? _ackFromRuntimeNickname(Object? value) => value as String?;
  static Object? _ackToRuntimeNickname(String? value) => value;
}
''',
        },
        generateFor: const {'test_pkg|lib/pet.dart'},
        readerWriter: readerWriter,
        outputs: {
          'test_pkg|lib/pet.ack.g.dart': decodedMatches(
            allOf([
              contains('Cat('),
              contains("id: Cat._ackFromRuntimeId(json['id'])"),
              contains("lives: Cat._ackFromRuntimeLives(json['lives'])"),
              contains(
                "nickname: Cat._ackFromRuntimeNickname(json['nickname'])",
              ),
              contains("'id': Cat._ackToRuntimeId(instance.id)"),
              contains("'lives': Cat._ackToRuntimeLives(instance.lives)"),
              contains(
                "'nickname': ?Cat._ackToRuntimeNickname(instance.nickname)",
              ),
            ]),
          ),
        },
      );
    },
  );
}
