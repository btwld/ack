# **ACK**

ACK provides a fluent, unified schema-building solution for Dart and Flutter applications. It delivers clear constraints, descriptive error feedback, and powerful utilities for validating forms, AI-driven outputs, and JSON or CLI arguments.

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

Ack provides schema types to validate different kinds of data. You can customize each schema with constraints, nullability, strict parsing, default values, and more using a fluent API.


### String Schema

Validates string data, with constraints like minimum length, maximum length, non-empty checks, regex patterns, and more.

**Example**:

```dart
import 'package:ack/ack.dart';

final schema = Ack.string
    .minLength(5)
    .maxLength(10)
    .isNotEmpty()
    .nullable(); // Accepts null

final result = schema.validate("hello");
if (result.isOk) {
  print(result.getOrNull()); // "hello"
}
```

### Integer Schema

Validates integer data. Constraints include min/max values, exclusive bounds, and multiples.

**Example**:

```dart
final schema = Ack.int
    .minValue(0)
    .maxValue(100)
    .multipleOf(5);

final result = schema.validate(25);
```

### Double Schema

Similar to IntegerSchema, but for doubles:

```dart
final schema = Ack.double
    .minValue(0.0)
    .maxValue(100.0)
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
final listSchema = Ack.list(itemSchema).minItems(2).uniqueItems();

final result = listSchema.validate(["abc", "def"]);
```

### Object Schema

Validates `Map<String, Object?>` with property definitions and constraints on required fields, additional properties, etc.

**Example**:

```dart
final schema = Ack.object({
    "name": Ack.string.minLength(3),
    "age": Ack.int.minValue(0).nullable(),
  }, required: ["name"],
);

final result = schema.validate({"name": "John"});
```

This schema requires a "name" property (string, min length 3) and allows an optional "age" property (integer >= 0), with at least one property.

#$1

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
  defaultValue: "Guest",
  nullable: true,
).minLength(3);

// This fails the minLength check, but returns the default "Guest"
final result = schema.validate("hi");
print(result.getOrNull()); // "Guest"

final nullResult = schema.validate(null);
print(nullResult.getOrNull()); // "Guest"
```

> **Important**: If the parsed value is invalid or null, but a defaultValue is present, ACK will return Ok(defaultValue) instead of failing.

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
  .minValue(0)
  .maxValue(100)
  .multipleOf(5)
  .nullable() // accept null
  .strict();  // require actual int type
```

### Validation and SchemaResult

Calling `schema.validate(value)` returns a `SchemaResult<T>`, which can be:
- `Ok<T>`: Access the validated value with `getOrNull()` or `getOrThrow()`.
- `Fail<T>`: Contains `List<SchemaError>` with messages describing which constraints failed.

```dart
final result = schema.validate(120);
if (result.isOk) {
  print("Valid: ${result.getOrNull()}");
} else {
  print("Errors: ${result.getErrors()}");
}

// You can also use validateOrThrow:
try {
  schema.validateOrThrow(120);
} catch (e) {
  print(e); // AckException with details
}
```

### OpenAPI Integration

ACK can generate OpenAPI schema definitions from your schemas, aiding in API documentation or code generation.

```dart
final schema = Ack.string.minLength(5);
final converter = OpenApiSchemaConverter(schema: schema);
final openApiSchema = converter.toSchema();
print(openApiSchema); // {type: string, minLength: 5, ...}

// You can also produce a JSON string or a response-delimited format:
print(converter.toJson());
// or
print(converter.toResponsePrompt());
```

### Error Handling with SchemaResult

Every call to `.validate(value)` returns a `SchemaResult<T>` object, which is either `Ok<T>` or `Fail<T>`:
- `Ok`: Access the data via `getOrNull()` or `getOrThrow()`
- `Fail`: Inspect `getErrors()` for a list of `SchemaError` describing the failures

### Quick Reference

1. Fluent Methods:
   - `nullable()`
   - `strict()`
   - `withConstraints([ ... ])`
   - `validate(value)` → `SchemaResult<T>`
   - `validateOrThrow(value)` → throws `AckException` on errors
2. Default Values: Provide `defaultValue: T?` directly in the schema constructor or via `.call(defaultValue: X)`.
3. Custom Constraints: Extend `ConstraintValidator<T>` or `OpenApiConstraintValidator<T>` to add your own logic.
4. OpenAPI: Use `OpenApiSchemaConverter(schema: yourSchema).toSchema()` (or `.toJson()`) to generate specs.

Happy validating with ACK!

