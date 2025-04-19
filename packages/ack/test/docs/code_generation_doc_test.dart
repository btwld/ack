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

class UserSchema extends SchemaModel<User> {
  static final ObjectSchema schema = Ack.object({
    'email': Ack.string.isEmail(),
    'name': Ack.string.minLength(3).maxLength(50),
    'age': Ack.int.min(13).nullable(),
  }, required: [
    'email',
    'name'
  ], additionalProperties: true);

  UserSchema([Map<String, Object?>? data]) : super(data ?? {});

  static SchemaResult validateData(Map<String, Object?> data) {
    return schema.validate(data);
  }

  static UserSchema parse(Map<String, Object?> data) {
    final result = schema.validate(data);
    if (result.isFail) {
      throw AckException(result.getError());
    }
    return UserSchema(data);
  }

  @override
  User toModel() {
    return User(
      email: getValue<String>('email')!,
      name: getValue<String>('name')!,
      age: getValue<int?>('age'),
      metadata: Map<String, dynamic>.from(toMap())
        ..removeWhere((key, _) => ['email', 'name', 'age'].contains(key)),
    );
  }

  static UserSchema fromModel(User user) {
    return UserSchema({
      'email': user.email,
      'name': user.name,
      if (user.age != null) 'age': user.age,
      ...user.metadata,
    });
  }

  @override
  SchemaResult validate() {
    return schema.validate(toMap());
  }

  @override
  void initialize() {}
}

class Address {
  final String street;
  final String city;

  Address({required this.street, required this.city});
}

class AddressSchema extends SchemaModel<Address> {
  static final ObjectSchema schema = Ack.object({
    'street': Ack.string,
    'city': Ack.string,
  }, required: [
    'street',
    'city'
  ]);

  AddressSchema([Map<String, Object?>? data]) : super(data ?? {});

  static AddressSchema parse(Map<String, Object?> data) {
    final result = schema.validate(data);
    if (result.isFail) {
      throw AckException(result.getError());
    }
    return AddressSchema(data);
  }

  @override
  Address toModel() {
    return Address(
      street: getValue<String>('street')!,
      city: getValue<String>('city')!,
    );
  }

  static AddressSchema fromModel(Address address) {
    return AddressSchema({
      'street': address.street,
      'city': address.city,
    });
  }

  @override
  SchemaResult validate() {
    return schema.validate(toMap());
  }

  @override
  void initialize() {}
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

      // Parse the map into a schema object
      final userSchema = UserSchema.parse(userData);

      // Convert schema to model
      final user = userSchema.toModel();

      // Access the strongly-typed properties
      expect(user.name, equals('John Doe'));
      expect(user.email, equals('user@example.com'));
      expect(user.age, equals(25));

      // Access additional properties
      expect(user.metadata['role'], equals('admin'));
    });

    test('Converting Models to Schema Objects', () {
      // Create a model instance
      final user = User(
        email: 'new@example.com',
        name: 'New User',
        age: 30,
      );

      // Convert to schema for validation or serialization
      final schema = UserSchema.fromModel(user);

      // Convert back to JSON
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

      final address = AddressSchema.parse(addressData).toModel();
      expect(address.street, equals('123 Main St'));
      expect(address.city, equals('Anytown'));
    });
  });
}
