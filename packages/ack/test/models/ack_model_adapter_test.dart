import 'package:ack/ack.dart';
import 'package:test/test.dart';

final _userSchema = Ack.object({'name': Ack.string(), 'age': Ack.integer()});

final _userAdapter = AckModelAdapter<JsonMap, JsonMap, _User>(
  schema: () => _userSchema,
  fromRuntime: _User.fromRuntime,
  toRuntime: (user) => user.toRuntime(),
);

final _boomAdapter = AckModelAdapter<JsonMap, JsonMap, _User>(
  schema: () => _userSchema,
  fromRuntime: (_) => throw TypeError(),
  toRuntime: (user) => user.toRuntime(),
);

final class _User {
  const _User({required this.name, required this.age});

  final String name;
  final int age;

  _User.fromRuntime(JsonMap value)
    : name = value['name'] as String,
      age = value['age'] as int;

  JsonMap toRuntime() => {'name': name, 'age': age};
}

void main() {
  group('AckModelAdapter', () {
    test('parses boundary input into a model', () {
      final user = _userAdapter.parse({'name': 'Ada', 'age': 36});

      expect(user.name, 'Ada');
      expect(user.age, 36);
    });

    test('encodes a model through the source schema', () {
      final encoded = _userAdapter.encode(const _User(name: 'Ada', age: 36));

      expect(encoded, {'name': 'Ada', 'age': 36});
    });

    test('exposes direct runtime conversion for nested models', () {
      final runtime = <String, Object?>{'name': 'Ada', 'age': 36};
      final user = _userAdapter.fromRuntime(runtime);

      expect(_userAdapter.toRuntime(user), runtime);
    });

    test('preserves safe parse failures', () {
      final result = _userAdapter.safeParse({'name': 'Ada', 'age': '36'});

      expect(result.isFail, isTrue);
    });

    test('parse wraps validation failures as AckException', () {
      expect(
        () => _userAdapter.parse({'name': 'Ada', 'age': '36'}),
        throwsA(isA<AckException>()),
      );
    });

    test('fromRuntime TypeError propagates from parse and safeParse', () {
      expect(
        () => _boomAdapter.parse({'name': 'Ada', 'age': 36}),
        throwsA(isA<TypeError>()),
      );
      expect(
        () => _boomAdapter.safeParse({'name': 'Ada', 'age': 36}),
        throwsA(isA<TypeError>()),
      );
    });
  });
}
