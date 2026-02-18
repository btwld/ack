# Ack Generator

Code generator for the Ack validation library that automatically creates schema validation code from annotated Dart classes.

## Overview

Ack Generator analyzes your Dart models and produces corresponding `Ack.object()` schemas. You annotate your classes with `@AckModel()`, and the generator creates schema variables that you can use for runtime validation.

The generator handles:
- Basic schema generation from class fields
- Nested models and complex types
- Discriminated types for polymorphic validation
- Field-level constraints and customization
- Additional properties support

## Installation

Add the following dependencies to your `pubspec.yaml` (check [pub.dev](https://pub.dev/packages/ack) for the latest versions):

```yaml
dependencies:
  ack: ^1.0.0-beta.6
  ack_annotations: ^1.0.0-beta.6

dev_dependencies:
  ack_generator: ^1.0.0-beta.6
  build_runner: ^2.4.0
```

Or use the Dart CLI:

```bash
dart pub add ack ack_annotations
dart pub add --dev ack_generator build_runner
```

Run `dart pub get` to install the packages.

## Basic usage

### 1. Annotate your model

Create a Dart class and annotate it with `@AckModel()`:

```dart
// user.dart
import 'package:ack_annotations/ack_annotations.dart';

part 'user.g.dart';

@AckModel()
class User {
  final String name;
  final String email;
  final int? age;

  User({required this.name, required this.email, this.age});
}
```

### 2. Generate the schema

Run the build_runner to generate the schema code:

```bash
dart run build_runner build
```

This creates a `user.g.dart` file containing the generated schema:

```dart
// user.g.dart (generated)

final userSchema = Ack.object({
  'name': Ack.string(),
  'email': Ack.string(),
  'age': Ack.integer().optional(),
});
```

### 3. Use the generated schema

Import the generated part file and use the schema for validation:

```dart
import 'user.dart';

void main() {
  final userData = {'name': 'Alice', 'email': 'alice@example.com', 'age': 30};

  final result = userSchema.safeParse(userData);

  if (result.isOk) {
    final validatedData = result.getOrThrow();
    final user = User(
      name: validatedData['name'] as String,
      email: validatedData['email'] as String,
      age: validatedData['age'] as int?,
    );
    print('User created: ${user.name}');
  } else {
    print('Validation failed: ${result.getError()}');
  }
}
```

## Features

### Automatic schema generation

The generator creates schemas based on your class fields and their types:

```dart
@AckModel()
class Product {
  final String name;
  final double price;
  final bool inStock;
  final List<String> tags;

  Product({
    required this.name,
    required this.price,
    required this.inStock,
    required this.tags,
  });
}

// Generated schema
final productSchema = Ack.object({
  'name': Ack.string(),
  'price': Ack.double(),
  'inStock': Ack.boolean(),
  'tags': Ack.list(Ack.string()),
});
```

### Field constraints

Use `@AckField` to add validation constraints:

```dart
@AckModel()
class User {
  @AckField(constraints: ['minLength(1)', 'maxLength(50)'])
  final String name;

  @AckField(constraints: ['email'])
  final String email;

  @AckField(constraints: ['min(0)', 'max(150)'])
  final int? age;

  User({required this.name, required this.email, this.age});
}

// Generated schema includes constraints
final userSchema = Ack.object({
  'name': Ack.string().minLength(1).maxLength(50),
  'email': Ack.string().email(),
  'age': Ack.integer().min(0).max(150).optional(),
});
```

### Custom JSON keys

Map class fields to different JSON property names:

```dart
@AckModel()
class User {
  @AckField(jsonKey: 'full_name')
  final String name;

  @AckField(jsonKey: 'email_address')
  final String email;

  User({required this.name, required this.email});
}

// Generated schema uses custom keys
final userSchema = Ack.object({
  'full_name': Ack.string(),
  'email_address': Ack.string(),
});
```

### Additional properties

Allow or disallow extra fields in validated objects:

```dart
@AckModel(additionalProperties: true)
class FlexibleModel {
  final String id;

  FlexibleModel({required this.id});
}

// Generated schema allows additional properties
final flexibleModelSchema = Ack.object({
  'id': Ack.string(),
}, additionalProperties: true);
```

By default, `additionalProperties` is `false`, which means the schema rejects any fields not explicitly defined in the class.

### Nested models

The generator handles nested model references:

```dart
@AckModel()
class Address {
  final String street;
  final String city;

  Address({required this.street, required this.city});
}

@AckModel()
class User {
  final String name;
  final Address address;

  User({required this.name, required this.address});
}

// Generated schemas
final addressSchema = Ack.object({
  'street': Ack.string(),
  'city': Ack.string(),
});

final userSchema = Ack.object({
  'name': Ack.string(),
  'address': addressSchema,
});
```

## Advanced features

### Discriminated types

Use discriminated types to validate polymorphic data structures. Define a base class with a discriminator key, then create subclasses with specific discriminator values:

```dart
@AckModel(discriminatedKey: 'type')
abstract class Shape {
  String get type;
}

@AckModel(discriminatedValue: 'circle')
class Circle extends Shape {
  @AckField(constraints: ['positive()'])
  final double radius;

  Circle({required this.radius});

  @override
  String get type => 'circle';
}

@AckModel(discriminatedValue: 'rectangle')
class Rectangle extends Shape {
  @AckField(constraints: ['positive()'])
  final double width;

  @AckField(constraints: ['positive()'])
  final double height;

  Rectangle({required this.width, required this.height});

  @override
  String get type => 'rectangle';
}
```

The generator creates a discriminated schema that validates based on the discriminator field:

```dart
// Generated schemas
final circleSchema = Ack.object({
  'type': Ack.literal('circle'),
  'radius': Ack.double().positive(),
});

final rectangleSchema = Ack.object({
  'type': Ack.literal('rectangle'),
  'width': Ack.double().positive(),
  'height': Ack.double().positive(),
});

final shapeSchema = Ack.discriminated(
  discriminatorKey: 'type',
  schemas: {
    'circle': circleSchema,
    'rectangle': rectangleSchema,
  },
);
```

Use the discriminated schema to validate different shape types:

```dart
final circleData = {'type': 'circle', 'radius': 5.0};
final rectangleData = {'type': 'rectangle', 'width': 10.0, 'height': 20.0};

final circleResult = shapeSchema.safeParse(circleData);
final rectangleResult = shapeSchema.safeParse(rectangleData);

if (circleResult.isOk) {
  final data = circleResult.getOrThrow();
  final circle = Circle(radius: data['radius'] as double);
  print('Circle with radius: ${circle.radius}');
}

if (rectangleResult.isOk) {
  final data = rectangleResult.getOrThrow();
  final rectangle = Rectangle(
    width: data['width'] as double,
    height: data['height'] as double,
  );
  print('Rectangle: ${rectangle.width} x ${rectangle.height}');
}
```

### Supported constraints

You can use the following constraints with `@AckField`:

**String constraints:**
- `minLength(n)` - Minimum string length
- `maxLength(n)` - Maximum string length
- `email` - Email format validation
- `url` - URL format validation
- `notEmpty` - Non-empty string

**Number constraints:**
- `min(n)` - Minimum value
- `max(n)` - Maximum value
- `positive()` - Positive numbers only
- `negative()` - Negative numbers only
- `nonNegative()` - Zero or positive numbers
- `nonPositive()` - Zero or negative numbers

**List constraints:**
- `minLength(n)` - Minimum list length
- `maxLength(n)` - Maximum list length
- `notEmpty` - Non-empty list

```dart
final priceSchema = Ack.double().nonNegative().max(100);
```
Use `nonNegative()` / `nonPositive()` as concise aliases for `.min(0)` / `.max(0)` while keeping consistent error messages.

## Usage examples

### Validating API request data

```dart
@AckModel()
class CreateUserRequest {
  @AckField(constraints: ['minLength(1)', 'maxLength(100)'])
  final String username;

  @AckField(constraints: ['email'])
  final String email;

  @AckField(constraints: ['minLength(8)'])
  final String password;

  CreateUserRequest({
    required this.username,
    required this.email,
    required this.password,
  });
}

// In your API handler
void handleCreateUser(Map<String, dynamic> requestBody) {
  final result = createUserRequestSchema.safeParse(requestBody);

  if (!result.isOk) {
    return sendError(400, result.getError().toString());
  }

  final validatedData = result.getOrThrow();
  final request = CreateUserRequest(
    username: validatedData['username'] as String,
    email: validatedData['email'] as String,
    password: validatedData['password'] as String,
  );

  // Create user with validated data
  createUser(request);
}
```

### Validating configuration files

```dart
@AckModel()
class DatabaseConfig {
  @AckField(constraints: ['minLength(1)'])
  final String host;

  @AckField(constraints: ['min(1)', 'max(65535)'])
  final int port;

  @AckField(constraints: ['minLength(1)'])
  final String database;

  final String? username;
  final String? password;

  DatabaseConfig({
    required this.host,
    required this.port,
    required this.database,
    this.username,
    this.password,
  });
}

// Load and validate configuration
void loadConfig(String jsonString) {
  final json = jsonDecode(jsonString) as Map<String, dynamic>;
  final result = databaseConfigSchema.safeParse(json);

  if (!result.isOk) {
    throw ConfigurationError('Invalid database config: ${result.getError()}');
  }

  final validatedData = result.getOrThrow();
  final config = DatabaseConfig(
    host: validatedData['host'] as String,
    port: validatedData['port'] as int,
    database: validatedData['database'] as String,
    username: validatedData['username'] as String?,
    password: validatedData['password'] as String?,
  );

  connectToDatabase(config);
}
```

## Development

### Regenerating code

If you modify your annotated models or add new constraints, regenerate the schemas:

```bash
# Clean previous builds
dart run build_runner clean

# Generate fresh code
dart run build_runner build

# Or use watch mode during development
dart run build_runner watch
```

### Troubleshooting

**Part directive missing:**
If you see errors about missing generated code, ensure your model file includes the part directive:

```dart
part 'your_file_name.g.dart';
```

**Build conflicts:**
If the generator reports conflicts, run the build with the delete flag:

```bash
dart run build_runner build --delete-conflicting-outputs
```

**Type resolution errors:**
Ensure all referenced types have `@AckModel()` annotations or are built-in Dart types that Ack supports.

## Contributing

Contributions are welcome. Follow these guidelines:

1. Check existing issues before creating new ones
2. Follow the existing code style and patterns
3. Add tests for new features
4. Update documentation for public API changes
5. Run `melos test` to ensure all tests pass

## License

This project is licensed under the MIT License. See the LICENSE file for details.
