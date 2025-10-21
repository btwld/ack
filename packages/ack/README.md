# Ack

[![pub package](https://img.shields.io/pub/v/ack.svg)](https://pub.dev/packages/ack)
[![documentation](https://img.shields.io/badge/docs.page-documentation-blue)](https://docs.page/btwld/ack)

Ack is a schema validation library for Dart and Flutter that helps you validate data with a simple, fluent API. Ack is short for "acknowledge".

## Features

- **Simple & Fluent API**: Chain validation rules with an intuitive builder pattern
- **Type Safety**: Full support for Dart's type system
- **Comprehensive Validation**: Built-in validators for strings, numbers, booleans, lists, objects, and more
- **Custom Validation**: Easy to extend with custom validators
- **Detailed Error Messages**: Get clear, actionable validation errors
- **JSON Schema Support**: Generate JSON Schema specifications from your schemas
- **No Dependencies**: Zero runtime dependencies beyond Dart SDK

## Installation

Add Ack to your project:

```bash
dart pub add ack
```

Or add to your `pubspec.yaml`:

```yaml
dependencies:
  ack: ^1.0.0  # Check pub.dev for latest version
```

## Quick Start

```dart
import 'package:ack/ack.dart';

// Define a schema for a user object
final userSchema = Ack.object({
  'name': Ack.string().minLength(2).maxLength(50),
  'email': Ack.string().email(),
  'age': Ack.integer().min(0).max(120).optional(),
});

// Validate data against the schema
final result = userSchema.safeParse({
  'name': 'John Doe',
  'email': 'john@example.com',
  'age': 30
});

// Check if validation passed
if (result.isOk) {
  final validData = result.getOrThrow();
  print('Valid user: $validData');
} else {
  final error = result.getError();
  print('Validation failed: $error');
}
```

## Schema Types

Ack supports all common data types:

### Primitives
- **String**: `Ack.string()` with validators like `minLength()`, `maxLength()`, `email()`, `url()`, `pattern()`
- **Number**: `Ack.integer()` and `Ack.double()` with `min()`, `max()`, `positive()`, `negative()`
- **Boolean**: `Ack.boolean()`
- **Null**: `Ack.null_()`

### Collections
- **List**: `Ack.list(elementSchema)` with `minLength()`, `maxLength()`, `notEmpty()`
- **Object**: `Ack.object({...})` for structured data

### Special Types
- **Literal**: `Ack.literal(value)` for exact value matching
- **Enum**: `Ack.string().enumString([...])` for string enums
- **Any**: `Ack.any()` accepts any value
- **Union**: `Ack.anyOf([...])` for union types
- **Discriminated Union**: `Ack.discriminated(...)` for tagged unions

## Validation Rules

Chain validation rules for precise data validation:

```dart
// String validation
final username = Ack.string()
  .minLength(3)
  .maxLength(20)
  .pattern(r'^[a-zA-Z0-9_]+$');

// Number validation
final price = Ack.double()
  .positive()
  .max(999.99);

// List validation
final tags = Ack.list(Ack.string())
  .minLength(1)
  .maxLength(5);

// Complex object validation
final orderSchema = Ack.object({
  'id': Ack.string().uuid(),
  'customer': Ack.object({
    'name': Ack.string().minLength(2),
    'email': Ack.string().email(),
  }),
  'items': Ack.list(Ack.object({
    'product': Ack.string(),
    'quantity': Ack.integer().positive(),
    'price': Ack.double().positive(),
  })).minLength(1),
  'total': Ack.double().positive(),
});
```

## Optional and Nullable

Control whether fields are required, optional, or nullable:

```dart
final schema = Ack.object({
  'required': Ack.string(),                    // Required, not null
  'optional': Ack.string().optional(),         // Can be omitted
  'nullable': Ack.string().nullable(),         // Required, can be null
  'both': Ack.string().optional().nullable(),  // Can be omitted or null
});
```

## Custom Validation

Add custom validation logic with `.refine()`:

```dart
final passwordSchema = Ack.string()
  .minLength(8)
  .refine(
    (value) => value.contains(RegExp(r'[A-Z]')),
    message: 'Password must contain at least one uppercase letter',
  )
  .refine(
    (value) => value.contains(RegExp(r'[0-9]')),
    message: 'Password must contain at least one number',
  );
```

## Error Handling

Ack provides detailed error information:

```dart
final result = schema.safeParse(data);

if (!result.isOk) {
  final error = result.getError();
  print('Error name: ${error.name}');
  print('Error message: ${error.message}');
  print('Error path: ${error.path}');
  print('Full error: ${error.toString()}');
}
```

## Data Transformation

Transform validated data:

```dart
final trimmedString = Ack.string()
  .transform((value) => value.trim());

final uppercaseString = Ack.string()
  .transform((value) => value.toUpperCase());
```

## Documentation

For detailed documentation, guides, and examples, visit:

**[https://docs.page/btwld/ack](https://docs.page/btwld/ack)**

### Topics
- [Getting Started](https://docs.page/btwld/ack/getting-started/installation)
- [Core Concepts](https://docs.page/btwld/ack/core-concepts/schemas)
- [Validation Rules](https://docs.page/btwld/ack/core-concepts/validation)
- [Error Handling](https://docs.page/btwld/ack/core-concepts/error-handling)
- [Custom Validation](https://docs.page/btwld/ack/guides/custom-validation)
- [Flutter Integration](https://docs.page/btwld/ack/guides/flutter-form-validation)
- [JSON Schema Integration](https://docs.page/btwld/ack/guides/json-schema-integration)

## Related Packages

- **[ack_generator](../ack_generator)**: Code generator for creating schemas from annotated Dart classes
- **[ack_annotations](../ack_annotations)**: Annotations for schema code generation

## Contributing

Contributions are welcome! Please see the [main repository](https://github.com/btwld/ack) for contribution guidelines.

## License

MIT License - see [LICENSE](../../LICENSE) for details.
