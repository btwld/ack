import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('Object Extensions with Transformation', () {
    test('should transform extended objects', () {
      final baseSchema = Ack.object({
        'firstName': Ack.string(),
        'lastName': Ack.string(),
      });

      final extendedSchema = baseSchema
          .extend({'age': Ack.integer().min(0), 'email': Ack.string().email()})
          .transform<Map<String, dynamic>>((data) {
            return {
              ...data!,
              'fullName': '${data['firstName']} ${data['lastName']}',
              'isAdult': (data['age'] as int) >= 18,
            };
          });

      final result = extendedSchema.parse({
        'firstName': 'John',
        'lastName': 'Doe',
        'age': 25,
        'email': 'john@example.com',
      });

      expect(result!['fullName'], equals('John Doe'));
      expect(result['isAdult'], isTrue);
      expect(result['email'], equals('john@example.com'));
    });

    test('should handle pick/omit with transformations', () {
      final schema = Ack.object({
        'id': Ack.string(),
        'password': Ack.string(),
        'email': Ack.string(),
        'profile': Ack.object({'name': Ack.string(), 'bio': Ack.string()}),
      });

      // Create public view by omitting sensitive data and transforming
      final publicSchema = schema
          .omit(['password'])
          .transform<Map<String, dynamic>>((data) {
            final profile = data!['profile'] as Map<String, Object?>;
            return {
              ...data,
              'displayName': profile['name'],
              'profileUrl': '/users/${data['id']}',
            };
          });

      final result = publicSchema.parse({
        'id': '123',
        'email': 'user@example.com',
        'profile': {'name': 'Jane User', 'bio': 'Developer'},
      });

      expect(result!.containsKey('password'), isFalse);
      expect(result['displayName'], equals('Jane User'));
      expect(result['profileUrl'], equals('/users/123'));
    });
  });
}
