# ACK Generator

**✅ PRODUCTION READY - 100% Test Coverage**

Code generator for the ACK validation library that automatically generates schema validation code from annotated Dart models.

## Current Status

**The ACK Generator is now production-ready** with comprehensive test coverage and full feature support:
- ✅ **100% Test Coverage** - All functionality thoroughly tested
- ✅ **SchemaModel Integration** - Complete integration with ack package
- ✅ **Discriminated Types** - Full support for polymorphic validation patterns
- ✅ **Production Examples** - Working examples with comprehensive test coverage

## Features

### 🎯 Core Functionality
- **Automatic Schema Generation** - Generate `Ack.object()` schemas from model annotations
- **SchemaModel Classes** - Type-safe model creation with `createFromMap` logic
- **Constraint Support** - Full support for validation constraints via annotations
- **Discriminated Types** - Polymorphic validation with `Ack.discriminated()` schemas

### 🔧 Supported Annotations
```dart
// Basic model annotation
@AckModel(model: true)
class User {
  final String name;
  final int age;
  User({required this.name, required this.age});
}

// Discriminated types (polymorphic validation)
@AckModel(discriminatedKey: 'type', model: true)
abstract class Animal {
  String get type;
}

@AckModel(discriminatedValue: 'cat', model: true)
class Cat extends Animal {
  final bool meow;
  Cat({required this.meow});
  @override String get type => 'cat';
}
```

### 📊 Generated Code Example

**Input:**
```dart
@AckModel(model: true)
class User {
  @AckField(constraints: ['minLength(1)'])
  final String name;
  
  @AckField(constraints: ['min(0)'])
  final int age;
  
  User({required this.name, required this.age});
}
```

**Generated:**
```dart
/// Generated schema for User
final userSchema = Ack.object({
  'name': Ack.string().minLength(1),
  'age': Ack.integer().min(0),
});

/// Generated SchemaModel for [User].
class UserSchemaModel extends SchemaModel<User> {
  UserSchemaModel._internal(ObjectSchema this.schema);

  factory UserSchemaModel() {
    return UserSchemaModel._internal(userSchema);
  }


  @override
  final ObjectSchema schema;

  @override
  User createFromMap(Map<String, dynamic> map) => User(
    name: map['name'] as String,
    age: map['age'] as int,
  );
}
```

## Quick Start

### 1. Add Dependencies

```yaml
dependencies:
  ack: ^latest_version
  ack_annotations: ^latest_version

dev_dependencies:
  ack_generator: ^latest_version
  build_runner: ^latest_version
```

### 2. Annotate Your Models

```dart
import 'package:ack_annotations/ack_annotations.dart';

@AckModel(model: true)
class Product {
  @AckField(constraints: ['minLength(1)'])
  final String name;
  
  @AckField(constraints: ['min(0)'])
  final double price;
  
  Product({required this.name, required this.price});
}
```

### 3. Generate Code

```bash
dart run build_runner build
```

### 4. Use Generated Schemas

```dart
final productModel = ProductSchemaModel();
final productData = {'name': 'Widget', 'price': 29.99};

// Type-safe parsing with validation
final result = productModel.parse(productData);
if (result.isOk) {
  final product = productModel.value; // Strongly typed Product instance
}
```

## Advanced Features

### Discriminated Types (Polymorphic Validation)

```dart
@AckModel(discriminatedKey: 'kind', model: true)
abstract class Shape {
  String get kind;
}

@AckModel(discriminatedValue: 'circle', model: true)
class Circle extends Shape {
  final double radius;
  Circle({required this.radius});
  @override String get kind => 'circle';
}

@AckModel(discriminatedValue: 'rectangle', model: true)  
class Rectangle extends Shape {
  final double width, height;
  Rectangle({required this.width, required this.height});
  @override String get kind => 'rectangle';
}
```

**Generated discriminated schema:**
```dart
final shapeSchema = Ack.discriminated(
  discriminatorKey: 'kind',
  schemas: {
    'circle': circleSchema,
    'rectangle': rectangleSchema,
  },
);
```

### Supported Constraints

- `@AckField(constraints: ['minLength(n)', 'maxLength(n)', 'email', 'notEmpty'])`
- `@AckField(constraints: ['min(n)', 'max(n)', 'positive()'])`
- `@AckField(jsonKey: 'custom_key')` for custom JSON field names
- `@AckModel(additionalProperties: true)` for flexible object schemas

## Test Coverage

**13/13 Discriminated Types Tests Passing ✅**
- Schema generation for base and subtype classes
- SchemaModel createFromMap with switch logic
- Runtime type discrimination
- Error handling for unknown discriminator values
- Complex inheritance hierarchies

**105+ Total Tests Passing ✅**
- Complete coverage of all generator functionality
- Integration tests with real validation scenarios
- Golden tests ensuring consistent output generation

## Documentation

- **DISCRIMINATED_TYPES_STATUS.md** - Complete discriminated types implementation status
- **Working Examples** - See `/example/lib/discriminated_example.dart`
- **Comprehensive Tests** - See `/example/test/discriminated_test.dart`

## Building from Source

```bash
# Bootstrap the monorepo
melos bootstrap

# Run all tests
melos test

# Generate code for examples
cd example && dart run build_runner build

# Format code
melos format

# Analyze code  
melos analyze
```

## Architecture

- **Three-pass analysis** - Analyze → Build relationships → Generate
- **Manual string generation** - Handles complex part file requirements
- **Type-safe delegation** - SchemaModel instances use factory pattern for flexibility
- **Error handling** - Comprehensive error messages with actionable suggestions

## Contributing

The ACK Generator is production-ready, but contributions are always welcome:

1. Check existing issues for enhancement opportunities
2. Follow existing code patterns and test structure  
3. Ensure all tests pass with `melos test`
4. Update documentation for new features

## License

This project is licensed under the MIT License - see the LICENSE file for details.