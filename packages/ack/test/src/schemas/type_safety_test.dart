import 'package:ack/ack.dart';
import 'package:test/test.dart';

// Test schema to verify type safety
class UserSchema extends BaseSchema<UserSchema> {
  const UserSchema() : super();
  const UserSchema._valid(Map<String, Object?> data) : super.valid(data);

  @override
  ObjectSchema get definition => Ack.object({
        'name': Ack.string.minLength(2),
        'email': Ack.string.email(),
        'age': Ack.int.min(0).nullable(),
      }, required: [
        'name',
        'email'
      ]);

  @override
  UserSchema parse(Object? data) {
    final result = definition.validate(data);
    if (result.isOk) {
      final validatedData = Map<String, Object?>.from(
        result.getOrThrow(),
      );
      return UserSchema._valid(validatedData);
    }
    throw AckException(result.getError());
  }

  String get name => getValue<String>('name')!;
  String get email => getValue<String>('email')!;
  int? get age => getValue<int>('age');
}

void main() {
  group('Type Safety Tests', () {
    test('parse returns correct concrete type', () {
      final data = {
        'name': 'John Doe',
        'email': 'john@example.com',
        'age': 30,
      };

      // This should return UserSchema, not BaseSchema
      final user = const UserSchema().parse(data);

      // Verify it's the correct type
      expect(user, isA<UserSchema>());
      expect(user.runtimeType, equals(UserSchema));

      // Verify properties work
      expect(user.name, equals('John Doe'));
      expect(user.email, equals('john@example.com'));
      expect(user.age, equals(30));
    });

    test('tryParse returns correct concrete type or null', () {
      final validData = {
        'name': 'Jane Doe',
        'email': 'jane@example.com',
      };

      final invalidData = {
        'name': 'J', // Too short
        'email': 'invalid-email',
      };

      // Valid data should return UserSchema
      final validUser = const UserSchema().tryParse(validData);
      expect(validUser, isA<UserSchema?>());
      expect(validUser, isNotNull);
      expect(validUser!.name, equals('Jane Doe'));

      // Invalid data should return null
      final invalidUser = const UserSchema().tryParse(invalidData);
      expect(invalidUser, isNull);
    });

    test('parser instance vs validated instance', () {
      final data = {
        'name': 'Test User',
        'email': 'test@example.com',
      };

      // Parser instance (no data)
      const parser = UserSchema();
      expect(parser.isValid, isFalse);
      expect(() => parser.name, throwsA(isA<StateError>()));

      // Validated instance (with data)
      final validated = parser.parse(data);
      expect(validated.isValid, isTrue);
      expect(validated.name, equals('Test User'));
      expect(validated.email, equals('test@example.com'));
    });

    test('const parser can be reused', () {
      const parser = UserSchema();

      final data1 = {'name': 'User 1', 'email': 'user1@example.com'};
      final data2 = {'name': 'User 2', 'email': 'user2@example.com'};

      final user1 = parser.parse(data1);
      final user2 = parser.parse(data2);

      expect(user1.name, equals('User 1'));
      expect(user2.name, equals('User 2'));

      // Parser itself remains unchanged
      expect(parser.isValid, isFalse);
    });
  });
}
