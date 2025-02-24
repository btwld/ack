# ack

ack is a lightweight, extensible Dart schema validation library that makes it simple to define and enforce data contracts. Whether you're validating user input in Flutter forms, ensuring API response integrity, or parsing configuration files, ack provides an intuitive, type-safe API to declare schemas and apply a rich set of built-in as well as custom validation rules.

## Introduction

With ack you can:
- **Define Schemas:** Create type-safe schemas for strings, numbers, booleans, objects, and lists.
- **Enforce Constraints:** Apply built-in validators (such as email, URL, or range validators) or add custom constraints.
- **Compose Schemas:** Build complex, nested validations with object and list schemas.
- **Handle Errors Gracefully:** Receive detailed error messages and use exceptions to manage validation failures.

This library is designed for developers who need a clear, concise way to validate data in their Dart and Flutter applications.

## Features
- **Type-Safe Schema Definitions**
  - Use static members like `Ack.string`, `Ack.int`, and `Ack.boolean` to define schemas

- **Built-In Validators** 
  - Email addresses (`isEmail`)
  - URLs (`isUrl`) 
  - Hex colors (`isHexColor`)
  - String validations:
    - Length checks (`minLength`, `maxLength`)
    - Empty checks (`isEmpty`, `isNotEmpty`)
  - Numeric validations:
    - Range checks (`minValue`, `maxValue`, `range`)
  - List validations:
    - Uniqueness (`uniqueItems`)
    - Size constraints (`minItems`, `maxItems`)

- **Composite Schemas**
  - Validate complex data structures with `ObjectSchema`
  - Handle arrays and lists with `ListSchema`

- **Discriminated Schemas**
  - Support polymorphic data validation using discriminator keys
  - Implemented via `DiscriminatedMapSchema`

- **Custom Constraint Support**
  - Easily extend functionality by adding custom constraints
  - Build your own validation rules

## Installation

Add ack to your `pubspec.yaml`:
```bash
dart pub add ack
```

## Usage

### Basic Example

Validate a simple email string:

```dart
import 'package:ack/ack.dart';

void main() {
  final emailSchema = Ack.string.isEmail();
  const email = 'test@example.com';

  final result = emailSchema.validate(email);
  result.match(
    onOk: (data) => print('Valid email!'),
    onFail: (error) => print('Validation errors: ${error.toMap()}'),
  );
}
```
### Object Validation

Validate a user object with required fields and nested structures:
```dart
  final addressSchema = Ack.object({
    'street': Ack.string(),
    'city': Ack.string(),
    'zip': Ack.string(),
  });
  final userSchema = Ack.object({
    'name': Ack.string.isNotEmpty(),
    'email': Ack.string.isEmail(),
    'age': Ack.int.minValue(18),
    'roles': Ack.string.list.minItems(1),
  });

  final userWithAddressSchema = userSchema.extend({'address': addressSchema()});

  final userData = {
    'name': 'John Doe',
    'email': 'john.doe@example.com',
    'age': 25,
    'roles': ['admin', 'user'],
    'address': {
      'street': '123 Main St',
      'city': 'Springfield',
      'zip': '12345',
    },
  };

  final result = userWithAddressSchema.validate(userData);

  result.match(
    onOk: (data) => print('User data is valid!'),
    onFail: (errors) =>
        print('Validation errors: ${errors.map((e) => e.toMap()).toList()}'),
  );
```

### List Validation

Validate a list of numbers ensuring that each value adheres to specific constraints:

```dart
import 'package:ack/ack.dart';

void main() {
  final numbersSchema = Ack.double.list.uniqueItems();
  final numbers = [1.1, 2.2, 3.3];

  final result = numbersSchema.validate(numbers);

  result.match(
    onOk: (data) {
      print('Numbers are valid!');
    },
    onFail: (error) {
      print('Validation errors: ${error.toMap()}');
    },
  );
}
```

### Error Handling

For cases where you prefer exceptions over manual error handling, use validateOrThrow:

```dart
try {
  Ack.string.isEmail().validateOrThrow('invalid-email');
} catch (e) {
  print('Validation failed: $e');
}
```

## Contributing

Contributions, suggestions, and improvements are welcome! Feel free to open an issue or submit a pull request on the repository.
