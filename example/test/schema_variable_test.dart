import 'package:ack/ack.dart';
import 'package:test/test.dart';

import '../lib/schema_types_simple.dart';

void main() {
  group('Schema Variable Extension Types', () {
    test('UserType parses valid data', () {
      final data = {'name': 'Alice', 'age': 30, 'active': true};

      final user = UserType.parse(data);

      expect(user.name, 'Alice');
      expect(user.age, 30);
      expect(user.active, true);
    });

    test('UserType validates data through schema', () {
      final invalidData = {
        'name': 'Alice',
        'age': 'not a number', // Invalid type
        'active': true,
      };

      expect(() => UserType.parse(invalidData), throwsA(isA<AckException>()));
    });

    test('UserType copyWith works', () {
      final user = UserType.parse({'name': 'Alice', 'age': 30, 'active': true});

      final updated = user.copyWith(name: 'Bob', age: 35);

      expect(updated.name, 'Bob');
      expect(updated.age, 35);
      expect(updated.active, true);
    });

    test('UserType can be used as Map (implements Map)', () {
      final user = UserType.parse({'name': 'Alice', 'age': 30, 'active': true});

      // Extension type implements Map<String, Object?>, so it can be used directly as a map
      final Map<String, Object?> json = user;

      expect(json, {'name': 'Alice', 'age': 30, 'active': true});
      expect(json['name'], 'Alice');
      expect(json['age'], 30);
    });

    test('UserType safeParse returns success for valid data', () {
      final result = UserType.safeParse({
        'name': 'Alice',
        'age': 30,
        'active': true,
      });

      expect(result.isOk, true);
      expect(result.getOrNull(), isA<Map<String, dynamic>>());
    });

    test('UserType safeParse returns failure for invalid data', () {
      final result = UserType.safeParse({
        'name': 'Alice',
        'age': 'not a number',
        'active': true,
      });

      expect(result.isOk, false);
      expect(result.isFail, true);
    });
  });
}
