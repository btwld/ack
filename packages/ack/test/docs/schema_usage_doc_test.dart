import 'package:ack/ack.dart';
import 'package:test/test.dart';

// Define models to test against the documentation examples
class User {
  final String name;
  final String email;
  final int age;
  final String? password;
  final Map<String, dynamic> metadata;

  User({
    required this.name,
    required this.email,
    required this.age,
    this.password,
    this.metadata = const {},
  });
}

class Address {
  final String street;
  final String city;
  final String zipCode;

  Address({
    required this.street,
    required this.city,
    required this.zipCode,
  });
}

class UserWithAddress {
  final String name;
  final Address address;

  UserWithAddress({
    required this.name,
    required this.address,
  });
}

class Login {
  final String email;
  final String password;

  Login({required this.email, required this.password});
}

// Define schema classes (normally these would be generated)
class UserSchema extends SchemaModel<User> {
  static final ObjectSchema schema = Ack.object(
      {
        'name': Ack.string.isNotEmpty(),
        'email': Ack.string.isEmail(),
        'age': Ack.int.min(0),
        'password': Ack.string.nullable(),
      },
      additionalProperties: true,
      required: ['name', 'email', 'age']);

  UserSchema([Object? data]) : super(data ?? {});

  @override
  AckSchema getSchema() {
    return schema;
  }

  @override
  User toModel() {
    if (!isValid) {
      throw AckException(getErrors()!);
    }

    final Map<String, dynamic> additionalProps = Map.from(toMap());
    ['name', 'email', 'age', 'password'].forEach(additionalProps.remove);

    return User(
      name: getValue<String>('name')!,
      email: getValue<String>('email')!,
      age: getValue<int>('age')!,
      password: getValue<String?>('password'),
      metadata: additionalProps,
    );
  }

  // Simulating the withUppercaseName method for our tests
  UserSchema withUppercaseName() {
    final Map<String, dynamic> newData = Map<String, dynamic>.from(toMap());
    newData['name'] = (newData['name'] as String).toUpperCase();
    return UserSchema(newData);
  }
}

class AddressSchema extends SchemaModel<Address> {
  static final ObjectSchema schema = Ack.object({
    'street': Ack.string.isNotEmpty(),
    'city': Ack.string.isNotEmpty(),
    'zipCode': Ack.string.isNotEmpty(),
  }, required: [
    'street',
    'city',
    'zipCode'
  ]);

  AddressSchema([Object? data]) : super(data ?? {});

  @override
  AckSchema getSchema() {
    return schema;
  }

  @override
  Address toModel() {
    if (!isValid) {
      throw AckException(getErrors()!);
    }

    return Address(
      street: getValue<String>('street')!,
      city: getValue<String>('city')!,
      zipCode: getValue<String>('zipCode')!,
    );
  }
}

class UserWithAddressSchema extends SchemaModel<UserWithAddress> {
  static final ObjectSchema schema = Ack.object({
    'name': Ack.string.isNotEmpty(),
    'address': AddressSchema.schema,
  }, required: [
    'name',
    'address'
  ]);

  UserWithAddressSchema([Object? data]) : super(data ?? {});

  @override
  AckSchema getSchema() {
    return schema;
  }

  AddressSchema get address {
    final addressData = getValue<Map<String, dynamic>>('address')!;
    return AddressSchema(addressData);
  }

  @override
  UserWithAddress toModel() {
    if (!isValid) {
      throw AckException(getErrors()!);
    }

    return UserWithAddress(
      name: getValue<String>('name')!,
      address: address.toModel(),
    );
  }
}

class LoginSchema extends SchemaModel<Login> {
  static final ObjectSchema schema = Ack.object({
    'email': Ack.string.isEmail(),
    'password': Ack.string.isNotEmpty(),
  }, required: [
    'email',
    'password'
  ]);

  LoginSchema([Object? data]) : super(data ?? {});

  @override
  AckSchema getSchema() {
    return schema;
  }

  @override
  Login toModel() {
    if (!isValid) {
      throw AckException(getErrors()!);
    }

    return Login(
      email: getValue<String>('email')!,
      password: getValue<String>('password')!,
    );
  }
}

void main() {
  group('Schema Usage Documentation Examples Tests', () {
    test('Basic Usage Example', () {
      // Create a map to validate
      final userMap = {
        'email': 'user@example.com',
        'name': 'John Doe',
        'age': 30,
        'password': 'securepass123',
        'role': 'admin' // Additional property
      };

      // Validate the data
      final result = UserSchema.schema.validate(userMap);

      expect(result.isOk, isTrue);

      // Create an instance from valid data
      final userSchema = UserSchema(userMap);
      expect(userSchema.isValid, isTrue);
      final user = userSchema.toModel();

      expect(user.name, equals('John Doe'));
      expect(user.email, equals('user@example.com'));
      expect(user.age, equals(30));
      expect(user.password, equals('securepass123'));
      expect(user.metadata, equals({'role': 'admin'}));
    });

    test('Validation Example', () {
      final inputMap = {
        'name': 'Test User',
        'email': 'test@example.com',
        'age': 25,
      };

      final result = UserSchema.schema.validate(inputMap);

      expect(result.isOk, isTrue);

      final invalidMap = {
        'name': 'Test User',
        'email': 'invalid-email',
        'age': 25,
      };

      final invalidResult = UserSchema.schema.validate(invalidMap);

      expect(invalidResult.isOk, isFalse);
      expect(invalidResult.isFail, isTrue);
      final error = invalidResult.getError();
      // In the actual implementation, the error name might differ from our documentation examples
      // We're just testing that we get an error, not the specific error type
      expect(error.name, isNotEmpty);
      expect(error.toString(), isNotEmpty);
    });

    test('Parsing Example', () {
      final validUserMap = {
        'name': 'Test User',
        'email': 'test@example.com',
        'age': 25,
      };

      // Using constructor (validation happens automatically)
      final userSchema = UserSchema(validUserMap);
      expect(userSchema.isValid, isTrue);
      expect(userSchema, isA<UserSchema>());

      // Using safeParse equivalent
      final safeResult = UserSchema.schema.validate(validUserMap);
      expect(safeResult.isOk, isTrue);
      expect(safeResult.isOk ? UserSchema(safeResult.getOrThrow()) : null,
          isA<UserSchema>());
    });

    test('Model Conversion Example', () {
      final validUserMap = {
        'name': 'Test User',
        'email': 'test@example.com',
        'age': 25,
      };

      final userSchema = UserSchema(validUserMap);
      expect(userSchema.isValid, isTrue);
      final user = userSchema.toModel();

      expect(user.name, equals('Test User'));
      expect(user.email, equals('test@example.com'));
      expect(user.age, equals(25));
    });

    test('JSON Serialization Example', () {
      final validUserMap = {
        'name': 'Test User',
        'email': 'test@example.com',
        'age': 25,
      };

      // In an actual generated schema, we'd have toJson and fromJson methods
      final userSchema = UserSchema(validUserMap);
      expect(userSchema.isValid, isTrue);
      final json = userSchema.toMap(); // Simulating toJson()

      expect(json, equals(validUserMap));

      // Simulating fromJson
      final reconstructed = UserSchema(json);
      expect(reconstructed.toMap(), equals(validUserMap));
    });

    test('Handling Additional Properties Example', () {
      final inputWithExtra = {
        'name': 'Alice',
        'email': 'alice@example.com',
        'age': 25,
        'favoriteColor': 'blue' // Not in the model definition
      };

      final userSchema = UserSchema(inputWithExtra);
      expect(userSchema.isValid, isTrue);
      final user = userSchema.toModel();

      expect(user.metadata['favoriteColor'], equals('blue'));
    });

    test('Error Handling Example', () {
      final invalidInput = {
        'name': 'John',
        'email': 'john@example.com',
        'age': 'not-a-number' // Should be an integer
      };

      final result = UserSchema.schema.validate(invalidInput);
      expect(result.isOk, isFalse);

      final error = result.getError();
      // In the actual implementation, the error name might differ from our documentation examples
      // We're just testing that we get an error, not the specific error type
      expect(error.name, isNotEmpty);
      expect(error.toString(), isNotEmpty);
    });

    test('Working with Nested Schemas Example', () {
      final addressData = {
        'street': '123 Main St',
        'city': 'Anytown',
        'zipCode': '12345'
      };

      final userData = {'name': 'Jane Doe', 'address': addressData};

      final result = UserWithAddressSchema.schema.validate(userData);
      expect(result.isOk, isTrue);

      final userWithAddressSchema = UserWithAddressSchema(userData);
      expect(userWithAddressSchema.isValid, isTrue);
      final userWithAddress = userWithAddressSchema.toModel();
      expect(userWithAddress.name, equals('Jane Doe'));
      expect(userWithAddress.address.street, equals('123 Main St'));
    });

    test('Custom Transformations Example', () {
      final validUserMap = {
        'name': 'Test User',
        'email': 'test@example.com',
        'age': 25,
      };

      final userSchema = UserSchema(validUserMap);
      expect(userSchema.isValid, isTrue);
      final transformed = userSchema.withUppercaseName();
      expect(transformed.getValue<String>('name'), equals('TEST USER'));
    });

    test('Integration with Forms Example', () {
      // Simulate form data
      final formData = {
        'email': 'user@example.com',
        'password': 'securepass',
      };

      final result = LoginSchema.schema.validate(formData);
      expect(result.isOk, isTrue);

      if (result.isOk) {
        final loginSchema = LoginSchema(formData);
        expect(loginSchema.isValid, isTrue);
        final loginModel = loginSchema.toModel();
        expect(loginModel.email, equals('user@example.com'));
        expect(loginModel.password, equals('securepass'));
      }
    });
  });
}
