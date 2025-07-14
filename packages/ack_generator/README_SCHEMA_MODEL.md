# SchemaModel Generation

The Ack generator now supports generating type-safe `SchemaModel` classes in addition to schema variables.

## Quick Start

Add `model: true` to your `@AckModel` annotation:

```dart
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

part 'user.g.dart';  // Required when using model: true

@AckModel(
  description: 'User model with validation',
  model: true,  // ← Generates both schema variable and SchemaModel class
)
class User {
  final String id;
  final String name;
  final String email;
  final int? age;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.age,
  });
}
```

## What Gets Generated

With `model: true`, the generator creates:

### 1. Schema Variable (as before)
```dart
final userSchema = Ack.object({
  'id': Ack.string(),
  'name': Ack.string(),
  'email': Ack.string(),
  'age': Ack.integer().optional().nullable(),
});
```

### 2. SchemaModel Class (new)
```dart
class UserSchemaModel extends SchemaModel<User> {
  UserSchemaModel._internal(ObjectSchema this.schema);

  factory UserSchemaModel() {
    return UserSchemaModel._internal(userSchema);
  }


  @override
  final ObjectSchema schema;

  @override
  User createFromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      age: map['age'] as int?,
    );
  }
}
```

## Usage

### Schema Variable Approach (returns Map)
```dart
try {
  final result = userSchema.parse(jsonData) as Map<String, dynamic>;
  print('User ID: ${result['id']}');
  print('User Name: ${result['name']}');
} catch (e) {
  print('Validation failed: $e');
}
```

### SchemaModel Approach (returns typed model)
```dart
final userModel = UserSchemaModel();
final result = userModel.parse(jsonData);

if (result.isOk) {
  final user = userModel.value!;
  print('User ID: ${user.id}');      // Type-safe access
  print('User Name: ${user.name}');   // No casting needed
} else {
  print('Validation failed: ${result.getError()}');
}
```

## Features

### Type Safety
SchemaModel provides compile-time type checking and IDE autocomplete:

```dart
final user = userModel.value;  // Type: User?
// Direct property access with full type information
```

### Validation State Protection
```dart
final model = UserSchemaModel();
model.value;  // Throws StateError - must validate first!

model.parse(data);
model.value;  // Now safe to access
```

### Multiple Parsing Methods
```dart
// Parse from Map/dynamic
final result1 = model.parse(mapData);

// Parse from JSON string
final result2 = model.parseJson(jsonString);

// Parse and throw on error
final user = model.parseOrThrow(data);  // Returns User or throws

// Try parse (returns null on error)
final user2 = model.tryParse(data);  // Returns User?
```

### Additional Properties Support
```dart
@AckModel(
  model: true,
  additionalProperties: true,
  additionalPropertiesField: 'metadata',
)
class FlexibleModel {
  final String id;
  final Map<String, dynamic> metadata;
  
  FlexibleModel({required this.id, this.metadata = const {}});
}

// Usage
final data = {
  'id': '123',
  'customField': 'extra data',  // Goes into metadata
};

final model = FlexibleModelSchemaModel();
model.parse(data);
print(model.value!.metadata);  // {'customField': 'extra data'}
```

### Nested Models
```dart
@AckModel(model: true)
class Address {
  final String street;
  final String city;
  Address({required this.street, required this.city});
}

@AckModel(model: true)
class Person {
  final String name;
  final Address address;
  Person({required this.name, required this.address});
}

// Both schema variables and SchemaModel classes work together
final person = PersonSchemaModel().parseOrThrow(data);
print(person.address.city);  // Fully typed nested access
```

## When to Use Each Approach

### Use Schema Variables When:
- You need `Map<String, dynamic>` output
- Working with dynamic JSON APIs
- Gradual migration from untyped code
- Maximum flexibility is needed

### Use SchemaModel When:
- You want type-safe model instances
- You need IDE autocomplete and refactoring support
- You want compile-time type checking
- You're building new features with strong typing

## Important Notes

1. **Part Directive Required**: When using `model: true`, you must use `part` instead of `import`:
   ```dart
   part 'my_model.g.dart';  // ✓ Correct
   import 'my_model.g.dart'; // ✗ Won't work with SchemaModel
   ```

2. **Import Ack Library**: Make sure to import the main Ack library:
   ```dart
   import 'package:ack/ack.dart';
   ```

3. **Factory Pattern**: SchemaModel uses a factory pattern for flexibility:
   ```dart
   final model1 = UserSchemaModel();
   final model2 = UserSchemaModel();
   identical(model1, model2);  // false - different instances
   
   // Fluent methods create new instances with modified schemas
   final describedModel = model1.describe("Custom description");
   final nullableModel = describedModel.nullable(true);
   ```

4. **Clear State**: To reset validation state:
   ```dart
   model.clear();  // Resets value and validation state
   ```

## Migration Guide

To add SchemaModel to existing code:

1. Add `model: true` to your `@AckModel` annotation
2. Change `import 'model.g.dart'` to `part 'model.g.dart'`
3. Add `import 'package:ack/ack.dart'` if not present
4. Regenerate: `dart run build_runner build`

Your existing schema variable code continues to work unchanged!