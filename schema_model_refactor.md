# SchemaModel Refactoring - Removing Self-Referential Generics

## Overview

This document outlines the refactoring of `SchemaModel` to remove the self-referential generic pattern (`SchemaModel<T extends SchemaModel<T>>`) in favor of using Dart's covariant return types. This simplification maintains full type safety while significantly reducing complexity.

## Key Changes

- **Before**: `abstract class SchemaModel<T extends SchemaModel<T>>`
- **After**: `abstract class SchemaModel` (no generic)
- **Mechanism**: Uses Dart's covariant return type feature in method overrides

## Complete SchemaModel Implementation (No Generics)

```dart
// Base SchemaModel class - no generic needed!
abstract class SchemaModel {
  final Map<String, Object?>? _data;
  
  const SchemaModel() : _data = null;
  
  @protected
  const SchemaModel.validated(Map<String, Object?> data) : _data = data;
  
  /// The schema definition for validation
  ObjectSchema get definition;
  
  /// Whether this instance has validated data
  bool get hasData => _data != null;
  
  /// Parse and validate input - returns SchemaModel
  /// Subclasses override this with covariant return type
  SchemaModel parse(Object? input) {
    final result = definition.validate(input);
    if (result.isOk) {
      return createValidated(result.getOrThrow());
    }
    throw AckException(result.getError());
  }
  
  /// Try parse without throwing
  SchemaModel? tryParse(Object? input) {
    try {
      return parse(input);
    } catch (_) {
      return null;
    }
  }
  
  /// Factory method for creating validated instances
  @protected
  SchemaModel createValidated(Map<String, Object?> data);
  
  /// Type-safe value access
  @protected
  T getValue<T>(String key) {
    if (_data == null) {
      throw StateError('No data available - use parse() first');
    }
    return _data![key] as T;
  }
  
  /// Get nullable value
  @protected
  T? getValueOrNull<T>(String key) {
    return _data?[key] as T?;
  }
  
  /// Export validated data
  Map<String, Object?> toMap() {
    if (_data == null) return const {};
    return Map.unmodifiable(_data!);
  }
  
  /// Generate JSON Schema
  Map<String, Object?> toJsonSchema() {
    return JsonSchemaConverter(schema: definition).toSchema();
  }
}
```

## Generated Schema Implementation Example

```dart
/// Generated schema for User
class UserSchema extends SchemaModel {
  const UserSchema();
  const UserSchema._valid(Map<String, Object?> data) : super.validated(data);
  
  @override
  late final definition = Ack.object({
    'id': Ack.string.notEmpty(),
    'name': Ack.string.minLength(3).maxLength(100),
    'email': Ack.string.email(),
    'role': RoleSchema().definition,
    'tags': Ack.list(Ack.string),
  }, required: ['id', 'name', 'email']);
  
  /// Override with covariant return type - returns UserSchema!
  @override
  UserSchema parse(Object? input) {
    return super.parse(input) as UserSchema;
  }
  
  /// Override with covariant return type
  @override
  UserSchema? tryParse(Object? input) {
    return super.tryParse(input) as UserSchema?;
  }
  
  @override
  UserSchema createValidated(Map<String, Object?> data) {
    return UserSchema._valid(data);
  }
  
  // Typed getters
  String get id => getValue<String>('id');
  String get name => getValue<String>('name');
  String get email => getValue<String>('email');
  
  // Nested schema
  RoleSchema get role {
    final data = getValue<Map<String, Object?>>('role');
    return RoleSchema().parse(data);
  }
  
  // Optional list
  List<String>? get tags => getValueOrNull<List>('tags')?.cast<String>();
}

/// Generated schema for Role
class RoleSchema extends SchemaModel {
  const RoleSchema();
  const RoleSchema._valid(Map<String, Object?> data) : super.validated(data);
  
  @override
  late final definition = Ack.object({
    'id': Ack.string,
    'name': Ack.string,
    'permissions': Ack.list(Ack.string),
  });
  
  @override
  RoleSchema parse(Object? input) {
    return super.parse(input) as RoleSchema;
  }
  
  @override
  RoleSchema? tryParse(Object? input) {
    return super.tryParse(input) as RoleSchema?;
  }
  
  @override
  RoleSchema createValidated(Map<String, Object?> data) {
    return RoleSchema._valid(data);
  }
  
  String get id => getValue<String>('id');
  String get name => getValue<String>('name');
  List<String> get permissions => getValue<List>('permissions').cast<String>();
}
```

## Usage Examples

```dart
void main() {
  // Example 1: Basic parsing
  final userData = {
    'id': '123',
    'name': 'John Doe',
    'email': 'john@example.com',
    'role': {
      'id': 'admin',
      'name': 'Administrator',
      'permissions': ['read', 'write', 'delete'],
    },
    'tags': ['vip', 'premium'],
  };
  
  // Parse returns UserSchema type (not SchemaModel)!
  final user = UserSchema().parse(userData);
  
  print(user.id); // '123'
  print(user.name); // 'John Doe'
  print(user.email); // 'john@example.com'
  print(user.role.name); // 'Administrator'
  print(user.tags); // ['vip', 'premium']
  
  // Example 2: Try parse
  final maybeUser = UserSchema().tryParse({'invalid': 'data'});
  print(maybeUser); // null
  
  // Example 3: JSON Schema generation
  final jsonSchema = user.toJsonSchema();
  print(jsonSchema); // Generates JSON Schema representation
}
```

## AI Agent Usage

The refactored SchemaModel still works perfectly with generic constraints:

```dart
class AIAgent<Input extends SchemaModel, Output extends SchemaModel> {
  final Input inputSchema;
  final Output outputSchema;
  
  AIAgent({
    required this.inputSchema,
    required this.outputSchema,
  });
  
  Future<Output> process(Object? data) async {
    // Parse input - returns Input type due to covariant override
    final validInput = inputSchema.parse(data);
    
    // Get schemas for AI context
    final inputJsonSchema = inputSchema.toJsonSchema();
    final outputJsonSchema = outputSchema.toJsonSchema();
    
    // Call AI with validated data
    final result = await callAI(
      input: validInput.toMap(),
      inputSchema: inputJsonSchema,
      outputSchema: outputJsonSchema,
    );
    
    // Parse output - returns Output type
    return outputSchema.parse(result) as Output;
  }
}

// Usage with type constraints
final agent = AIAgent(
  inputSchema: UserSchema(),
  outputSchema: ResponseSchema(),
);

final response = await agent.process(userData);
// response is correctly typed as ResponseSchema
```

## Key Benefits

1. **No Complex Generics**: Clean inheritance without F-bounded polymorphism
2. **Type Safety**: Covariant return types ensure correct typing
3. **Simple Mental Model**: Just override methods, no generic gymnastics
4. **Works with Constraints**: `T extends SchemaModel` is cleaner than `T extends SchemaModel<T>`
5. **Better Error Messages**: No confusing generic type errors
6. **Follows KISS Principle**: Simpler design with same functionality

## Implementation Notes

### What Changes in Generated Code

The only change required in generated code is to override `parse()` and `tryParse()` methods:

```dart
// Each generated schema class needs these overrides
@override
UserSchema parse(Object? input) {
  return super.parse(input) as UserSchema;
}

@override
UserSchema? tryParse(Object? input) {
  return super.tryParse(input) as UserSchema?;
}
```

This is:
- Simple, predictable boilerplate
- Explicitly shows return types
- Following Dart's design patterns
- Easy to generate

### Dart's Covariant Return Types

Dart supports covariant return types in method overrides, meaning:
- A subclass can override a method to return a more specific type
- The return type must be a subtype of the original return type
- This ensures type safety at compile time

Example:
```dart
abstract class Animal {
  Animal makeChild();
}

class Cat extends Animal {
  @override
  Cat makeChild(); // Valid - Cat is a subtype of Animal
}
```

## Migration Path

1. Update `SchemaModel` base class to remove generic parameter
2. Update code generator to:
   - Generate override methods for `parse()` and `tryParse()`
   - Remove generic parameter from class declaration
3. No changes needed to existing usage code
4. AI agent constraints become simpler: `T extends SchemaModel`

## Conclusion

This refactoring maintains all functionality while significantly simplifying the codebase. By leveraging Dart's built-in covariant return types, we achieve the same type safety without the complexity of self-referential generics.