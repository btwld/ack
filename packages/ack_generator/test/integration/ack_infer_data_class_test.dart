// Modern schema-first data-class tests.
import 'package:ack_generator/src/builder.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

Future<void> _build(
  String source, {
  required Map<String, Object> outputs,
}) async {
  final readerWriter = TestReaderWriter(rootPackage: 'test_pkg');
  await readerWriter.testing.loadIsolateSources();
  await testBuilder(
    ackModelBuilder(BuilderOptions.empty),
    {'test_pkg|lib/model.dart': source},
    generateFor: const {'test_pkg|lib/model.dart'},
    readerWriter: readerWriter,
    outputs: outputs,
  );
}

Future<void> _expectFailure(String body, List<String> messages) async {
  final readerWriter = TestReaderWriter(rootPackage: 'test_pkg');
  await readerWriter.testing.loadIsolateSources();
  final seen = <String>{};
  await testBuilder(
    ackModelBuilder(BuilderOptions.empty),
    {'test_pkg|lib/model.dart': '$_imports\n$body'},
    generateFor: const {'test_pkg|lib/model.dart'},
    readerWriter: readerWriter,
    onLog: (LogRecord log) {
      if (log.level.name != 'SEVERE') return;
      for (final message in messages) {
        if (log.message.contains(message)) seen.add(message);
      }
    },
  );
  expect(seen, containsAll(messages));
}

const _imports = '''
import 'package:ack/ack.dart';
import 'package:ack/annotations.dart';

part 'model.g.dart';
''';

void main() {
  test(
    'class-first mixin reconstructs positional and named parameters',
    () async {
      await _build(
        '''
$_imports
@Schemable()
final class Point with _\$PointAck {
  const Point(this.x, {required this.y, this.label = 'origin'});
  final int x;
  final int y;
  final String label;
}
''',
        outputs: {
          'test_pkg|lib/model.g.dart': decodedMatches(
            allOf([
              contains(r'mixin _$PointAck'),
              contains(r'$PointCopyWith<Point> get copyWith'),
              contains('x ?? _source.x'),
              contains('y: y ?? _source.y'),
              contains('label: label ?? _source.label'),
              contains('get wireSchema'),
              contains('_pointObject'),
            ]),
          ),
        },
      );
    },
  );

  test('unknown-property modes emit reject, discard, and args capture', () async {
    await _build(
      '''
$_imports
@Schemable()
final class Strict with _\$StrictAck {
  const Strict({required this.name});
  final String name;
}

@Schemable(unknownProperties: AckUnknownPropertyPolicy.discard)
final class Loose with _\$LooseAck {
  const Loose({required this.name});
  final String name;
}

@Schemable(
  unknownProperties: AckUnknownPropertyPolicy.capture,
  captureField: 'args',
)
final class Bag with _\$BagAck {
  const Bag({required this.name, this.args = const {}});
  final String name;
  final Map<String, Object?> args;
}
''',
      outputs: {
        'test_pkg|lib/model.g.dart': decodedMatches(
          allOf([
            contains('final _strictObject = Ack.object({'),
            isNot(
              contains(
                "final _strictObject = Ack.object({'name': Ack.string()}, additionalProperties: true)",
              ),
            ),
            contains('additionalProperties: true'),
            contains('args: deepUnmodifiableJsonMap('),
            contains('Map<String, Object?>.fromEntries('),
            contains('model.args.entries'),
            contains('self.args'),
            isNot(contains('_ackClassImmutableCopyValue')),
            isNot(contains('_ackClassImmutableCopyMap')),
          ]),
        ),
      },
    );
  });

  test(
    'presence overrides and required mixin collisions are diagnosed',
    () async {
      await _expectFailure(
        '''
@Schemable()
final class User with _\$UserAck {
  const User({required this.name});
  User copyWith({String? name}) => User(name: name ?? this.name);
  final String name;
}
''',
        ['User.copyWith', 'override'],
      );
    },
  );

  test(
    'presence overrides and super parameters reconstruct in order',
    () async {
      await _build(
        '''
$_imports
@Schemable()
final class User with _\$UserAck {
  const User({this.nickname});
  @Required()
  final String? nickname;
}

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
        outputs: {
          'test_pkg|lib/model.g.dart': decodedMatches(
            allOf([
              contains("'nickname': Ack.string().nullable()"),
              isNot(contains("'nickname': Ack.string().nullable().optional()")),
              contains('Cat call({'),
              contains('id: id ?? _source.id'),
              contains('lives: lives ?? _source.lives'),
            ]),
          ),
        },
      );
    },
  );

  test(
    'optional presence accepts a required nullable normalization input',
    () async {
      await _build(
        '''
$_imports
@Schemable()
final class Normalized with _\$NormalizedAck {
  const Normalized(String? value) : value = value ?? '';

  @Optional()
  final String value;
}
''',
        outputs: {
          'test_pkg|lib/model.g.dart': decodedMatches(
            allOf([
              contains("'value': Ack.string().optional()"),
              contains('Normalized call({Object? value = _ackCopyWithUnset})'),
              contains(
                'identical(value, _ackCopyWithUnset) '
                '? _source.value '
                ': value as String?',
              ),
            ]),
          ),
        },
      );
    },
  );

  test('schema-first models emit copy, equality, and string members', () async {
    await _build(
      '''
$_imports
@Schemable()
final userSchema = Ack.object({
  'name': Ack.string(),
  'tags': Ack.list(Ack.string()),
});
''',
      outputs: {
        'test_pkg|lib/model.g.dart': decodedMatches(
          allOf([
            contains('// ignore_for_file: type=lint'),
            contains('// coverage:ignore-file'),
            contains('/// Creates a model without validating it.'),
            contains('/// Validates [input] and creates the model.'),
            contains('/// Validates decoded [json] and creates the model.'),
            contains('/// Validates this model and encodes it for JSON.'),
            contains('/// The Ack adapter that parses and encodes this model.'),
            contains(
              '/// Creates copies of [User] with selected fields replaced.',
            ),
            contains(
              '/// Creates a copy of this model with selected fields replaced.',
            ),
            contains('User call({'),
            contains('deepEquals(name, other.name)'),
            contains('deepHashCode(tags)'),
            contains("toString() => 'User("),
            isNot(contains('class UserType')),
          ]),
        ),
      },
    );
  });
}
