# Ack Generator

[![Pub Version](https://img.shields.io/pub/v/ack_generator?label=version&style=for-the-badge&logo=dart&logoColor=3DB0F3&labelColor=white&color=3DB0F3)](https://pub.dev/packages/ack_generator/changelog)
[![Pub Points](https://img.shields.io/pub/points/ack_generator?style=for-the-badge&logo=dart&logoColor=3DB0F3&label=Points&labelColor=white&color=3DB0F3)](https://pub.dev/packages/ack_generator/score)

A code generator that creates validation schema classes from annotated Dart classes. This package is built on top of the [ack](https://pub.dev/packages/ack) validation library.

See the full documentation at [docs.page/btwld/ack/guides/code-generation](https://docs.page/btwld/ack/guides/code-generation.mdx).

## Features

- Generates schema classes from annotated Dart models
- Automatically infers validation rules from constructor parameters
- Supports all Ack constraints via focused annotations
- Handles additional properties with configurable storage
- Generated schemas can validate before instance creation (class-validator style)

## Installation

Add ack_generator to your pubspec.yaml:

```yaml
dependencies:
  ack: ^0.1.2
  
dev_dependencies:
  ack_generator: ^0.1.0
  build_runner: ^2.3.0
```

Then run the following command to fetch the dependencies:

```bash
dart pub get
# or for Flutter projects
flutter pub get
```

## Usage

### 1. Annotate your model classes

Create your model class with validation annotations:

```dart
import 'package:ack_generator/ack_generator.dart';

@Schema(
  description: 'A user model with validation',
  additionalProperties: true,
  additionalPropertiesField: 'metadata',
)
class User {
  @IsEmail()
  final String email;
  
  @IsNotEmpty()
  @MinLength(3)
  final String name;
  
  @Min(18)
  final int? age;
  
  @Pattern(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$') // At least 8 chars, 1 letter and 1 number
  final String? password;
  
  final Map<String, dynamic> metadata;
  
  User({
    required this.email,
    required this.name,
    this.age,
    this.password,
    Map<String, dynamic>? metadata,
  }) : metadata = metadata ?? {};
}
```

### 2. Generate schema classes

Run the build_runner command to generate the schema files:

```bash
# One-time build
dart run build_runner build

# Watch mode for continuous generation during development
dart run build_runner watch

# For Flutter projects
flutter pub run build_runner build
```

This will generate a `user.schema.dart` file next to your model file.

### 3. Use the generated schema

```dart
import 'package:ack/ack.dart';
import 'user.dart';
import 'user.schema.dart'; // Generated schema file

void main() {
  // Create a map to validate
  final userMap = {
    'email': 'user@example.com',
    'name': 'John Doe',
    'age': 30,
    'password': 'securepass123',
    'role': 'admin' // Additional property
  };
  
  // Validate the data
  final result = UserSchema.validate(userMap);
  
  if (result.isOk) {
    // Create an instance from valid data
    final user = UserSchema.parse(userMap);
    
    print('Valid user: ${user.name}, ${user.email}');
    print('Additional properties: ${user.metadata}'); // Contains {'role': 'admin'}
  } else {
    // Handle validation errors
    print('Validation failed: ${result.getError().name}');
  }
}
```

## Annotations

### Class Annotations

- `@Schema(...)` - Marks a class for schema generation
  - `description` - Schema description
  - `additionalProperties` - Whether to allow additional properties
  - `additionalPropertiesField` - Field to store additional properties
  - `schemaClassName` - Custom name for the generated schema class

### Property Annotations

#### Basic Annotations
- `@Required()` - Mark a property as required in the schema
- `@Nullable()` - Mark a property as nullable (optional)
- `@Description(text)` - Add a description to a property
- `@FieldType(Type)` - Specify the type when inference might not work

#### String Constraints
- `@IsEmail()` - Validate email format
- `@MinLength(length)` - Minimum string length
- `@MaxLength(length)` - Maximum string length
- `@Pattern(pattern)` - Regex pattern validation
- `@IsNotEmpty()` - String cannot be empty
- `@EnumValues([...])` - String must be one of the specified values

#### Number Constraints
- `@Min(value)` - Minimum numeric value
- `@Max(value)` - Maximum numeric value
- `@MultipleOf(value)` - Number must be a multiple of the value

#### List Constraints
- `@MinItems(count)` - Minimum number of items
- `@MaxItems(count)` - Maximum number of items
- `@UniqueItems()` - Items must be unique

## Generated Schema Classes

Each annotated class gets a corresponding schema class with:

- Singleton instance for efficient reuse
- Static validation methods
- Instance conversion methods
- Additional properties support

## License

MIT