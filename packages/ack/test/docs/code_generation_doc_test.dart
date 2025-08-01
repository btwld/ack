import 'package:ack/ack.dart';
import 'package:test/test.dart';

// Mock classes to simulate generated code
class User {
  final String email;
  final String name;
  final int? age;
  final Map<String, dynamic> metadata;

  User({
    required this.email,
    required this.name,
    this.age,
    Map<String, dynamic>? metadata,
  }) : metadata = metadata ?? {};
}

class UserSchema extends SchemaModel<UserSchema> {
  const UserSchema() : super();
  const UserSchema._valid(Map<String, Object?> data) : super.valid(data);

  static final ObjectSchema schema = Ack.object({
    'email': Ack.string.email(),
    'name': Ack.string.minLength(3).maxLength(50),
    'age': Ack.int.min(13).nullable(),
  }, required: [
    'email',
    'name'
  ], additionalProperties: true);

  static SchemaResult validateData(Map<String, Object?> data) {
    return schema.validate(data);
  }

  @override
  ObjectSchema get definition => schema;

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

  String get email => getValue<String>('email')!;
  String get name => getValue<String>('name')!;
  int? get age => getValue<int?>('age');

  Map<String, dynamic> get metadata {
    final map = toMap();
    map.removeWhere((key, _) => ['email', 'name', 'age'].contains(key));
    return Map<String, dynamic>.from(map);
  }
}

class Address {
  final String street;
  final String city;

  Address({required this.street, required this.city});
}

class AddressSchema extends SchemaModel<AddressSchema> {
  const AddressSchema() : super();
  const AddressSchema._valid(Map<String, Object?> data) : super.valid(data);

  static final ObjectSchema schema = Ack.object({
    'street': Ack.string,
    'city': Ack.string,
  }, required: [
    'street',
    'city'
  ]);

  @override
  ObjectSchema get definition => schema;

  @override
  AddressSchema parse(Object? data) {
    final result = definition.validate(data);
    if (result.isOk) {
      final validatedData = Map<String, Object?>.from(
        result.getOrThrow(),
      );
      return AddressSchema._valid(validatedData);
    }
    throw AckException(result.getError());
  }

  String get street => getValue<String>('street')!;
  String get city => getValue<String>('city')!;
}

void main() {
  group('Code Generation Documentation Examples', () {
    test('Validating Data', () {
      // Create a map to validate
      final userData = {
        'email': 'user@example.com',
        'name': 'John Doe',
        'age': 25,
        'role': 'admin' // Additional property
      };

      // Validate the data
      final result = UserSchema.validateData(userData);

      expect(result.isOk, isTrue);

      // Test invalid data
      final invalidData = {
        'email': 'invalid-email',
        'name': 'Jo', // Too short
        'age': 10, // Too young
      };

      final invalidResult = UserSchema.validateData(invalidData);
      expect(invalidResult.isOk, isFalse);
    });

    test('Creating Models from Data', () {
      final userData = {
        'email': 'user@example.com',
        'name': 'John Doe',
        'age': 25,
        'role': 'admin' // Additional property
      };

      // Create a schema object from the data
      final userSchema = const UserSchema().parse(userData);
      expect(userSchema.isValid, isTrue);

      // Access the strongly-typed properties directly
      expect(userSchema.name, equals('John Doe'));
      expect(userSchema.email, equals('user@example.com'));
      expect(userSchema.age, equals(25));

      // Access additional properties through metadata
      expect(userSchema.metadata['role'], equals('admin'));
    });

    test('Creating Schema from Data', () {
      // Create schema from raw data
      final userData = {
        'email': 'new@example.com',
        'name': 'New User',
        'age': 30,
      };

      final schema = const UserSchema().parse(userData);
      expect(schema.isValid, isTrue);

      // Get back to JSON
      final json = schema.toMap();

      expect(json['email'], equals('new@example.com'));
      expect(json['name'], equals('New User'));
      expect(json['age'], equals(30));
    });

    test('Working with Nested Models', () {
      final addressData = {
        'street': '123 Main St',
        'city': 'Anytown',
      };

      final addressSchema = const AddressSchema().parse(addressData);
      expect(addressSchema.isValid, isTrue);
      expect(addressSchema.street, equals('123 Main St'));
      expect(addressSchema.city, equals('Anytown'));
    });
  });
}
