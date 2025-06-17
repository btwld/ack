# **ACK**
![GitHub stars](https://img.shields.io/github/stars/btwld/ack?style=for-the-badge&logo=GitHub&logoColor=black&labelColor=white&color=dddddd)
[![Pub Version](https://img.shields.io/pub/v/ack?label=version&style=for-the-badge&logo=dart&logoColor=3DB0F3&labelColor=white&color=3DB0F3)](https://pub.dev/packages/ack/changelog)
[![Pub Points](https://img.shields.io/pub/points/ack?style=for-the-badge&logo=dart&logoColor=3DB0F3&label=Points&labelColor=white&color=3DB0F3)](https://pub.dev/packages/ack/score)
[![All Contributors](https://img.shields.io/github/contributors/btwld/ack?style=for-the-badge&color=018D5B&labelColor=004F32)](https://github.com/btwld/ack/graphs/contributors)
[![MIT License](https://img.shields.io/github/license/btwld/ack?style=for-the-badge&color=FF2E00&labelColor=CB2500)](https://opensource.org/licenses/mit-license.php)
![Codecov](https://img.shields.io/codecov/c/github/btwld/ack?style=for-the-badge&color=FFD43A&labelColor=F3BE00)

ACK provides a fluent, unified schema-building solution for Dart and Flutter applications. It delivers clear constraints, descriptive error feedback, and powerful utilities for validating forms, AI-driven outputs, and JSON or CLI arguments.

See the full documentation at [docs.page/btwld/ack](https://docs.page/btwld/ack).

## Use Cases and Key Benefits

- Validates diverse data types with customizable constraints
- Converts into OpenAPI Specs for LLM function calling and structured response support
- Offers a fluent API for intuitive schema building
- Provides detailed error reporting for validation failures

## Installation

Add ACK to your `pubspec.yaml`:

```bash
dart pub add ack
```

## Usage Overview

ACK provides schema types to validate different kinds of data. You can customize each schema with constraints, nullability, strict parsing, default values, and more using a fluent API.

### String Schema

Validates string data, with constraints like minimum length, maximum length, non-empty checks, regex patterns, and more.

**Example**:

```dart
import 'package:ack/ack.dart';

final schema = Ack.string
  .minLength(5)
  .maxLength(10)
  .notEmpty()
  .nullable(); // Accepts null

final result = schema.validate('hello');
if (result.isOk) {
  print(result.getOrNull()); // "hello"
}
```

### Integer Schema

Validates integer data. Constraints include min/max values, exclusive bounds, and multiples.

**Example**:

```dart
final schema = Ack.int
    .min(0)
    .max(100)
    .multipleOf(5);

final result = schema.validate(25);
```

### Double Schema

Similar to Integer Schema, but for doubles:

```dart
final schema = Ack.double
    .min(0.0)
    .max(100.0)
    .multipleOf(0.5);

final result = schema.validate(25.5);
```

### Boolean Schema

Validates boolean data:

**Example**:

```dart
final schema = Ack.boolean.nullable();

final result = schema.validate(true);
```

This schema accepts boolean values or null.

### List Schema

Validates lists of items, each item validated by an inner schema:

**Example**:

```dart
final itemSchema = Ack.string.minLength(3);
final listSchema = Ack.list(itemSchema)
    .minItems(2)
    .uniqueItems();

final result = listSchema.validate(['abc', 'def']);
```

### Object Schema

Validates `Map<String, Object?>` with property definitions and constraints on required fields, additional properties, etc.

**Example**:

```dart
final schema = Ack.object(
  {
    'name': Ack.string.minLength(3),
    'age': Ack.int.min(0).nullable(),
  },
  required: ['name'],
);

final result = schema.validate({'name': 'John'});
```

This schema requires a "name" property (string, min length 3) and allows an optional "age" property (integer >= 0), with at least one property.

### Discriminated Union Schema

Validates objects where the structure depends on a specific "discriminator" field.

**Example**:

```dart
final schema = Ack.discriminated(
  discriminatorKey: 'type',
  schemas: {
    'user': Ack.object({
      'type': Ack.string,
      'name': Ack.string,
    }),
    'admin': Ack.object({
      'type': Ack.string,
      'level': Ack.int,
    }),
  },
);

final userResult = schema.validate({'type': 'user', 'name': 'Alice'}); // OK
final adminResult = schema.validate({'type': 'admin', 'level': 5});   // OK
final invalidResult = schema.validate({'type': 'guest'});            // Fail
```

## Additional Features

### Strict Parsing

For scalar schemas (String, Integer, Double, Boolean), ACK can parse strings or numbers into the correct type if strict is false (the default). If you set strict, the schema only accepts an already-correct type.

```dart
// By default, Ack.int will accept "123" and parse it to 123.
final looseSchema = Ack.int;
print(looseSchema.validate("123").isOk); // true

// If you require strictly typed ints (no string parsing):
final strictSchema = Ack.int.strict();
print(strictSchema.validate("123").isOk); // false
print(strictSchema.validate(123).isOk);   // true
```

### Default Values

You can set a default value so that if validation fails or if the user provides null, the schema returns the default:

```dart
// Setting default value in the constructor:
final schema = Ack.string(
  defaultValue: 'Guest',
  nullable: true,
).minLength(3);

// This fails the minLength check, but returns the default "Guest"
final result = schema.validate('hi');
print(result.getOrNull()); // "Guest"

final nullResult = schema.validate(null);
print(nullResult.getOrNull()); // "Guest"
```

> **Important**: If the parsed value is invalid or null, but a default value is present, ACK will return Ok(defaultValue) instead of failing.

### Custom Constraints

You can extend `ConstraintValidator<T>` or `OpenApiConstraintValidator<T>` to create your own validation rules. For example:

```dart
class OnlyFooStringValidator extends OpenApiConstraintValidator<String> {
  const OnlyFooStringValidator();

  @override
  String get name => 'only_foo';
  @override
  String get description => 'String must be "foo" only';

  @override
  bool isValid(String value) => value == 'foo';

  @override
  ConstraintError onError(String value) {
    return buildError(
      message: 'Value "$value" is not "foo".',
      context: {'value': value},
    );
  }

  // If you want this constraint to appear in OpenAPI:
  @override
  Map<String, Object?> toSchema() {
    // Typically you'd put `"enum": ["foo"]`, or similar
    return {
      'enum': ['foo'],
      'description': 'Must be exactly "foo"',
    };
  }
}

// Using it:
final schema = Ack.string.withConstraints([OnlyFooStringValidator()]);
final result = schema.validate("bar"); // Fails validation
```

### Custom OpenAPI Constraints

When you implement `OpenApiConstraintValidator<T>`, your custom validator's `toSchema()` output is automatically merged into the final JSON schema. This means you can add fields like `pattern`, `enum`, `minimum`, etc., as recognized by OpenAPI or JSON Schema.

```dart
// Example usage with the built-in OpenApiSchemaConverter
final converter = OpenApiSchemaConverter(schema: schema);
print(converter.toJson());
```

The library merges all constraints' `toSchema()` results, so you get a single cohesive OpenAPI spec for your entire schema.

### Fluent API

ACK's fluent API lets you chain methods:

```dart
final schema = Ack.int
  .min(0)
  .max(100)
  .multipleOf(5)
  .nullable() // accept null
  .strict();  // require actual int type
```

### Validation and Parsing Methods

Ack provides multiple methods for validating and parsing data, each offering different error handling patterns to suit your coding style:

#### validate() - Result Pattern

The `validate()` method uses a Result pattern, returning a `SchemaResult<T>` which can be either:
- `Ok<T>`: Contains the validated value, accessible via `getOrNull()` or `getOrThrow()`
- `Fail<T>`: Contains validation errors, accessible via `getErrors()`

This approach gives you fine-grained control over error handling and access to the full error details.

```dart
// Schema for a user object with validation rules
final userSchema = Ack.object({
  'name': Ack.string.minLength(2),
  'email': Ack.string.email()
}, required: ['name', 'email']);

// Validate user data
final result = userSchema.validate({
  'name': 'John',
  'email': 'not-an-email'
});

if (result.isOk) {
  // Access the validated data
  final validData = result.getOrThrow();
  print("Valid user: ${validData['name']}");
} else {
  // Access detailed validation errors
  final errors = result.getErrors();
  print("Validation failed: ${errors.name}");
  
  // You can inspect specific errors
  for (final issue in errors.issues) {
    print(" - ${issue.path}: ${issue.message}");
  }
}
```

#### parse() - Exception Pattern

The `parse()` method provides a more direct approach using exceptions for error handling. It returns the validated data directly if validation succeeds, or throws an `AckException` if validation fails.

```dart
try {
  // Return the validated data directly
  final validatedData = userSchema.parse({
    'name': 'John Doe',
    'email': 'john@example.com'
  });
  
  // Use the validated data immediately
  print("Valid user: ${validatedData['name']}");
} catch (e) {
  // Handle validation failure with exception
  print("Validation failed: $e");
}
```

#### tryParse() - Null Safety Pattern

The `tryParse()` method uses Dart's null safety for error handling. It returns the validated data if validation succeeds, or `null` if validation fails.

```dart
// Returns validated data or null on validation failure
final maybeData = userSchema.tryParse({
  'name': 'John Doe',
  'email': 'invalid-email' // This will fail validation
});

if (maybeData != null) {
  // Use the validated data
  print("Valid user: ${maybeData['name']}");
} else {
  // Handle validation failure
  print("Validation failed");
}
```

#### validateOrThrow() - Exception with Return Value

The `validateOrThrow()` method throws an exception on error, but also returns the validated data for immediate use:

```dart
try {
  // Validate and get data in one step
  final validData = userSchema.validateOrThrow({
    'name': 'John Doe',
    'email': 'john@example.com'
  });
  
  // Use the validated data immediately
  print("Valid user: ${validData['name']}");
} catch (e) {
  // Handle validation failure with exception
  print("Validation failed: $e");
}
```

#### Choosing the Right Approach

- Use `validate()` when you need detailed error information or want to handle valid and invalid cases in the same code path
- Use `parse()` when you prefer exception-based error handling and want to get the validated data directly
- Use `tryParse()` when you prefer null-safety-based error handling for cleaner code without try/catch blocks
- Use `validateOrThrow()` when you want to use exception handling but also need direct access to the validated data

### OpenAPI Spec

ACK can generate OpenAPI schema definitions from your schemas, aiding in API documentation or code generation.

```dart
final schema = Ack.object({
  'name': Ack.string
    .minLength(2)
    .maxLength(50),
  'age': Ack.int
    .min(0)
    .max(120),
}, required: ['name', 'age']);

final converter = OpenApiSchemaConverter(schema: schema);
final openApiSchema = converter.toSchema();

print(openApiSchema);

/* Returns schema like:
{
  "type": "object",
  "required": ["name", "age"],
  "properties": {
    "name": {
      "type": "string",
      "minLength": 2,
      "maxLength": 50
    },
    "age": {
      "type": "integer",
      "minimum": 0,
      "maximum": 120
    }
  }
}
*/
```

#### Working with Limited LLM OpenAPI Support

> [!TIP]
> When an LLM has limited support for OpenAPI function calling schemas but *can* guarantee valid JSON output, you can embed the schema definition directly within the prompt using `toResponsePrompt()`. This allows you to still validate the LLM's JSON output using `parseResponse()` against your ACK schema.

```dart
final schema = Ack.object(
  {
    'name': Ack.string.minLength(2).maxLength(50),
    'age': Ack.int.min(0).max(120),
  },
  required: ['name', 'age'],
);

final converter = OpenApiSchemaConverter(schema: schema);

// Build a prompt for the LLM that includes the schema
final prompt = '''
You are a helpful assistant. Please provide information about a person following this schema:

${converter.toResponsePrompt()}
''';

/* Will output:
<schema>
{
  "type": "object",
  "required": ["name", "age"],
  "properties": {
    "name": {
      "type": "string",
      "minLength": 2,
      "maxLength": 50
    },
    "age": {
      "type": "integer",
      "minimum": 0,
      "maximum": 120
    }
  },
  "additionalProperties": false
}
</schema>

Your response should be valid JSON, that follows the <schema> and formatted as follows:

<response>
{valid_json_response}
</response>
<stop_response>
*/

// Simulated LLM response
final llmResponse = '''
Here is the person's information:
<response>
{
  "name": "John Smith",
  "age": 35
}
</response>
''';

final jsonPayload = converter.parseResponse(llmResponse);

print(jsonPayload);
```


### Error Handling with SchemaResult

Every call to `.validate(value)` returns a `SchemaResult<T>` object, which is either `Ok<T>` or `Fail<T>`:
- `Ok`: Access the data via `getOrNull()` or `getOrThrow()`
- `Fail`: Inspect `getErrors()` for a list of `SchemaError` describing the failures

### Quick Reference

1. Validation & Parsing Methods:
   - `validate(value)` → `SchemaResult<T>` (Result pattern)
   - `parse(value)` → `T` or throws `AckException` (Exception pattern)
   - `tryParse(value)` → `T?` returns null on validation failure (Null safety pattern)
   - `validateOrThrow(value)` → `T` or throws `AckException` on errors
2. Fluent Methods:
   - `nullable()`
   - `strict()`
   - `withConstraints([ ... ])` 
3. Default Values: Provide `defaultValue: T?` directly in the schema constructor or via `.call(defaultValue: X)`.
4. Custom Constraints: Extend `ConstraintValidator<T>` or `OpenApiConstraintValidator<T>` to add your own logic.
5. OpenAPI: Use `OpenApiSchemaConverter(schema: yourSchema).toSchema()` (or `.toJson()`) to generate specs.

Happy validating with ACK!

## SchemaModel API

ACK provides a `SchemaModel` base class for creating schema-based models with automatic validation.

```dart
// Define a schema model manually (or use code generation)
class UserSchema extends SchemaModel {
  UserSchema(Object? data) : super(data);

  @override
  AckSchema getSchema() {
    return Ack.object({
      'name': Ack.string.minLength(2),
      'email': Ack.string.email(),
      'age': Ack.int.min(0).nullable(),
    }, required: ['name', 'email']);
  }
  
  // Getters for typed access to properties
  String get name => getValue<String>('name')!;
  String get email => getValue<String>('email')!;
  int? get age => getValue<int?>('age');
}

// Using the schema model - Constructor approach
final userData = {
  'name': 'John Doe',
  'email': 'john@example.com',
  'age': 30,
};

final userSchema = UserSchema(userData);

// Check if the schema is valid
if (userSchema.isValid) {
  // Access properties directly from the schema
  print('User: ${userSchema.name}, ${userSchema.email}, ${userSchema.age}');
  
  // Create a model instance manually
  final user = User(
    name: userSchema.name,
    email: userSchema.email,
    age: userSchema.age,
  );
} else {
  // Handle validation errors
  print('Validation errors: ${userSchema.getErrors()}');
}

// Creating and validating schemas
try {
  // Create schema and validate
  final userSchema = UserSchema(userData);
  if (userSchema.isValid) {
    print('User: ${userSchema.name}, ${userSchema.email}, ${userSchema.age}');
  } else {
    print('Validation failed: ${userSchema.getErrors()}');
  }
} catch (e) {
  print('Unexpected error: $e');
}

// Create your model class however you prefer
class User {
  final String name;
  final String email;
  final int? age;
  
  User({required this.name, required this.email, this.age});
}
```


## Documentation

For detailed guides on using Ack effectively, check out the documentation:

- [SchemaModel API](https://docs.page/leofarias/ack/core-concepts/schema-model-class) - Learn how to use the SchemaModel API

## License