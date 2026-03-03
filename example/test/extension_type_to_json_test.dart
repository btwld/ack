import 'package:ack_example/schema_types_primitives.dart';
import 'package:ack_example/schema_types_simple.dart';
import 'package:test/test.dart';

void main() {
  group('Extension type toJson', () {
    test('object extension type returns map data', () {
      final user = UserType.parse({'name': 'Alice', 'age': 30, 'active': true});

      expect(user.toJson(), {'name': 'Alice', 'age': 30, 'active': true});
      expect(user.toJson(), isA<Map<String, Object?>>());
    });

    test('object extension type toJson map is immutable', () {
      final user = UserType.parse({'name': 'Alice', 'age': 30, 'active': true});
      final json = user.toJson();

      expect(() => json['name'] = 'Bob', throwsA(isA<UnsupportedError>()));
    });

    test('primitive extension type returns wrapped value', () {
      final password = PasswordType.parse('mySecurePassword123');

      expect(password.toJson(), 'mySecurePassword123');
      expect(password.toJson(), isA<String>());
    });

    test('collection extension type returns wrapped list', () {
      final tags = TagsType.parse(['dart', 'ack']);

      expect(tags.toJson(), ['dart', 'ack']);
      expect(tags.toJson(), isA<List<String>>());
    });
  });
}
