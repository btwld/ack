import 'package:ack/ack.dart';
import 'package:ack_example/schema_types_simple.dart';
import 'package:test/test.dart';

void main() {
  group('Schema variable models', () {
    test('User parses valid data', () {
      final data = {'name': 'Alice', 'age': 30, 'active': true};

      final user = User.parse(data);

      expect(user.name, 'Alice');
      expect(user.age, 30);
      expect(user.active, true);
    });

    test('User validates data through schema', () {
      final invalidData = {
        'name': 'Alice',
        'age': 'not a number', // Invalid type
        'active': true,
      };

      expect(() => User.parse(invalidData), throwsA(isA<AckException>()));
    });

    test('User serializes to a JSON map', () {
      final user = User.parse({'name': 'Alice', 'age': 30, 'active': true});

      final json = user.toJson();

      expect(json, {'name': 'Alice', 'age': 30, 'active': true});
      expect(json['name'], 'Alice');
      expect(json['age'], 30);
    });

    test('User safeParse returns success for valid data', () {
      final result = User.safeParse({
        'name': 'Alice',
        'age': 30,
        'active': true,
      });

      expect(result.isOk, true);
      expect(result.getOrNull(), isA<User>());
    });

    test('User safeParse returns failure for invalid data', () {
      final result = User.safeParse({
        'name': 'Alice',
        'age': 'not a number',
        'active': true,
      });

      expect(result.isOk, false);
      expect(result.isFail, true);
    });
  });
}
