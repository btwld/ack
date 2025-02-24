# ack

[![pub package](https://img.shields.io/pub/v/ack.svg)](https://pub.dev/packages/ack)
<!-- Add build and coverage badges when available -->

A lightweight, extensible Dart schema validation library that simplifies defining and enforcing rules for your data structures. Perfect for validating forms, API responses, and configuration files with type-safe schemas.

## Features

- **Type-Safe Schema Definitions**
  - Static methods (`Ack.string`, `Ack.int`, `Ack.boolean`) for compile-time safety
  - Fluent API for building complex validations
  - Strong typing support with generics

- **Rich Validation Rules**
  - **Strings**: `isEmail`, `isHexColor`, `minLength`, `maxLength`, `isEmpty`, `isNotEmpty`, `isDateTime`
  - **Numbers**: `minValue`, `maxValue`, `range`
  - **Lists**: `uniqueItems`, `minItems`, `maxItems`
  - **Objects**: Nested validation, optional fields, extensible schemas

- **Advanced Features**
  - Discriminated schemas for polymorphic data
  - Custom validation rules
  - Detailed error reporting
  - Exception-based validation option

## Getting started

```dart
import 'package:ack/ack.dart';

void main() {
  final emailSchema = Ack.string.isEmail();
  const email = 'test@example.com';
  
  emailSchema.validate(email).match(
    onOk: (data) => print('Valid email!'),
    onFail: (errors) => print('Validation errors: $errors'),
  );
}
```

## Installation

Add ack to your `pubspec.yaml`:

```yaml
dependencies:
  ack: ^latest_version
```

Or use:
```bash
dart pub add ack
```

## Usage

### Basic Schema Validation

Create and validate simple schemas:

```dart
// String validation
final emailSchema = Ack.string.isEmail();
final colorSchema = Ack.string.isHexColor();
final nameSchema = Ack.string.isNotEmpty();

// Number validation
final ageSchema = Ack.int.range(0, 120);
final temperatureSchema = Ack.double.minValue(0);

// Boolean validation
final activeSchema = Ack.boolean();

// DateTime validation
final dateSchema = Ack.string.isDateTime();
```

### Object Validation

Validate complex objects with nested structures:

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
  'address': addressSchema(),
});

final result = userSchema.validate({
  'name': 'John Doe',
  'email': 'john@example.com',
  'age': 25,
  'address': {
    'street': '123 Main St',
    'city': 'Springfield',
    'zip': '12345',
  },
});
```

### List Validation

Validate arrays with specific constraints:

```dart
final numbersSchema = Ack.double.list
  .uniqueItems()
  .minItems(1)
  .maxItems(5);

final tagsSchema = Ack.string.list
  .uniqueItems()
  .minItems(1);
```

### Error Handling

Choose between Result-based or Exception-based validation:

```dart
// Result-based validation
schema.validate(data).match(
  onOk: (data) => print('Valid!'),
  onFail: (errors) => print('Validation errors: $errors'),
);

// Exception-based validation
try {
  schema.validateOrThrow(data);
  print('Valid!');
} catch (e) {
  print('Validation failed: $e');
}
```

### Discriminated Schemas

Handle polymorphic data structures:

```dart
// Define individual schemas
final userSchema = Ack.object({
  'type': Ack.string,
  'name': Ack.string,
}, required: ['type'])();

final adminSchema = Ack.object({
  'type': Ack.string,
  'name': Ack.string,
  'level': Ack.int,
}, required: ['type'])();

// Combine them in a discriminated schema
final schema = Ack.discriminated(
  discriminatorKey: 'type',
  schemas: {
    'user': userSchema,
    'admin': adminSchema,
  },
);

// Example usage
final validUser = {
  'type': 'user',
  'name': 'John Doe',
};

final validAdmin = {
  'type': 'admin',
  'name': 'Admin User',
  'level': 1,
};

// Validate user data
schema.validate(validUser).match(
  onOk: (data) => print('Valid user data!'),
  onFail: (errors) => print('User validation errors: $errors'),
);

// Validate admin data
schema.validate(validAdmin).match(
  onOk: (data) => print('Valid admin data!'),
  onFail: (errors) => print('Admin validation errors: $errors'),
);

// Invalid data example
final invalidData = {
  'type': 'admin',
  'name': 'Invalid Admin',
  // Missing required 'level' field
};

schema.validate(invalidData).match(
  onOk: (data) => print('Valid data!'),
  onFail: (errors) => print('Validation errors: $errors'),
);
```

## Additional Information

### Contributing

Contributions are welcome! Feel free to:
- Open issues for bugs or feature requests
- Submit pull requests
- Improve documentation
- Share examples and use cases
