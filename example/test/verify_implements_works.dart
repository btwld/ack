import 'package:ack_example/schema_types_simple.dart';
import 'package:ack_example/schema_types_edge_cases.dart';
import 'package:test/test.dart';

void main() {
  group('Extension type with implements Map<String, Object?>', () {
    test('can use Map operator[]', () {
      final user = UserType.parse({'name': 'John', 'age': 30, 'active': true});

      // Both accessors work
      expect(user.name, 'John'); // Custom getter
      expect(user['name'], 'John'); // Map operator from implements
    });

    test('can use Map.keys', () {
      final user = UserType.parse({'name': 'John', 'age': 30, 'active': true});

      expect(user.keys, containsAll(['name', 'age', 'active']));
    });

    test('can use Map.values', () {
      final user = UserType.parse({'name': 'John', 'age': 30, 'active': true});

      expect(user.values, containsAll(['John', 30, true]));
    });

    test('can use Map.forEach', () {
      final user = UserType.parse({'name': 'John', 'age': 30, 'active': true});

      final collected = <String, dynamic>{};
      user.forEach((key, value) {
        collected[key] = value;
      });

      expect(collected, {'name': 'John', 'age': 30, 'active': true});
    });

    test('can use Map.containsKey', () {
      final user = UserType.parse({'name': 'John', 'age': 30, 'active': true});

      expect(user.containsKey('name'), true);
      expect(user.containsKey('missing'), false);
    });

    test('can be passed to function expecting Map', () {
      void processMap(Map<String, Object?> map) {
        expect(map['name'], 'John');
      }

      final user = UserType.parse({'name': 'John', 'age': 30, 'active': true});

      // Can pass UserType where Map is expected!
      processMap(user);
    });

    test('rejects map mutation at runtime', () {
      final user = UserType.parse({'name': 'John', 'age': 30, 'active': true});

      final Map<String, Object?> map = user;
      expect(() => map['name'] = 'Jane', throwsA(isA<UnsupportedError>()));
    });

    test('rejects nested wrapper map mutation at runtime', () {
      final person = PersonType.parse({
        'name': 'John',
        'email': 'john@example.com',
        'address': {
          'street': 'Main St',
          'city': 'Quito',
          'zipCode': '17000',
          'country': 'Ecuador',
        },
        'age': 30,
      });

      final Map<String, Object?> addressMap = person.address;
      expect(
        () => addressMap['city'] = 'Guayaquil',
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('rejects nested map mutation via raw Map access at runtime', () {
      final person = PersonType.parse({
        'name': 'John',
        'email': 'john@example.com',
        'address': {
          'street': 'Main St',
          'city': 'Quito',
          'zipCode': '17000',
          'country': 'Ecuador',
        },
        'age': 30,
      });

      final Map<String, Object?> map = person;
      final Map<String, Object?> addressMap =
          map['address'] as Map<String, Object?>;

      expect(
        () => addressMap['city'] = 'Guayaquil',
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('safeParse returns SchemaResult<UserType>', () {
      final result = UserType.safeParse({
        'name': 'John',
        'age': 30,
        'active': true,
      });

      expect(result.isOk, true);

      // The result should be UserType, not Map!
      final user = result.getOrNull();
      expect(user, isA<UserType>());
      expect(user?.name, 'John');
      expect(user?.age, 30);
    });

    test('safeParse fail returns correct type', () {
      final result = UserType.safeParse({
        'name': 'John',
        // Missing 'age' - should fail
      });

      expect(result.isFail, true);
      expect(result.getOrNull(), isNull);
    });
  });
}
