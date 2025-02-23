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

- **Type-Safe Schema Definitions:** Use static members like `Ack.string`, `Ack.int`, and `Ack.boolean` to define schemas.
- **Built-In Validators:** Out-of-the-box validators for common patterns such as:
  - Email addresses (`isEmail`)
  - URLs (`isUrl`)
  - Hex colors (`isHexColor`)
  - POSIX paths (`isPosixPath`)
  - String length and emptiness checks (`minLength`, `maxLength`, `isNotEmpty`, `isEmpty`)
  - Numeric range checks (`minValue`, `maxValue`, `range`)
  - List validations (e.g., `uniqueItems`, `minItems`, `maxItems`)
- **Composite Schemas:** Validate complex data structures with `ObjectSchema` and `ListSchema`.
- **Discriminated Schemas:** Handle polymorphic data using discriminator keys with `DiscriminatedMapSchema`.
- **Custom Constraint Support:** Easily extend functionality by adding your own constraints.

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

  final errors = emailSchema.validate(email);
  if (errors.isEmpty) {
    print('Valid email!');
  } else {
    print('Validation errors:');
    for (final error in errors) {
      print(error.message);
    }
  }
}
```
### Object Validation

Validate a user object with required fields and nested structures:

```dart
import 'package:ack/ack.dart';

void main() {
  final userSchema = Ack.object({
    'name': Ack.string.isNotEmpty(),
    'email': Ack.string.isEmail(),
    'age': Ack.int.constraints([MinValueValidator(18)]),
    'roles': Ack.string.list.minItems(1),
  }).extend({
    'address': Ack.object({
      'street': Ack.string,
      'city': Ack.string,
      'zip': Ack.string,
    }),
  }, additionalProperties: true);

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

  final errors = userSchema.validate(userData);
  if (errors.isEmpty) {
    print('User data is valid!');
  } else {
    print('Validation errors:');
    for (final error in errors) {
      print(error.message);
    }
  }
}
```

### List Validation

Validate a list of numbers ensuring that each value adheres to specific constraints:

```dart
import 'package:ack/ack.dart';

void main() {
  final numbersSchema = Ack.double.list.constraints([UniqueItemsValidator()]);
  final numbers = [1.1, 2.2, 3.3];

  final errors = numbersSchema.validate(numbers);
  if (errors.isEmpty) {
    print('Numbers are valid!');
  } else {
    print('Validation errors:');
    for (final error in errors) {
      print(error.message);
    }
  }
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

API Overview
- Ack: The primary interface to create and modify schemas. Access types via static members:
- Ack.string, Ack.int, Ack.boolean, Ack.double
- Ack.object for maps/objects
- Ack.discriminated for polymorphic validations
- Ack.string.list (and similar) for lists of values
- Schema: The underlying class representing a validation schema.
- ObjectSchema & ListSchema: Specialized schemas for validating maps and lists.
- Validators: A suite of built-in constraint validators (e.g., EmailValidator, MinValueValidator) that can be added via extension methods.

Use Cases
- Form Validation: Ensure user inputs meet required formats and constraints in Flutter forms.
- API Data Validation: Validate JSON responses to safeguard data integrity.
- Configuration Validation: Enforce structure and rules in configuration files.
- Business Logic Enforcement: Apply custom rules to maintain consistency and correctness in data processing.

## Contributing

Contributions, suggestions, and improvements are welcome! Feel free to open an issue or submit a pull request on the repository.