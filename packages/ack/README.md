# Ack

[![pub package](https://img.shields.io/pub/v/ack.svg)](https://pub.dev/packages/ack)
[![CI/CD](https://github.com/btwld/ack/actions/workflows/ci.yml/badge.svg)](https://github.com/btwld/ack/actions/workflows/ci.yml)
[![docs.page](https://img.shields.io/badge/docs.page-documentation-blue)](https://docs.page/btwld/ack)

Ack is a schema validation library for Dart and Flutter that helps you validate data with a simple, fluent API. Ack is short for "acknowledge".

## Why Use Ack?

- **Simplify Validation**: Easily handle complex data validation logic
- **Validate external payloads**: Guard API and user inputs by validating required fields, types, and constraints at boundaries
- **Single Source of Truth**: Define data structures and rules in one place
- **Reduce Boilerplate**: Minimize repetitive code for validation and JSON conversion
- **Type Safety**: Generate type-safe schema classes from your Dart models

## Quick Start

```bash
dart pub add ack
```

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
  'age': 30,
});

if (result.isOk) {
  final validData = result.getOrThrow();
  print('Valid user: $validData');
} else {
  final error = result.getError();
  print('Validation failed: $error');
}
```

Use `.optional()` when a field may be omitted entirely. Chain `.nullable()` if a present field may hold `null`, or combine both for an optional-and-nullable value.

## Documentation

- [Full documentation](https://docs.page/btwld/ack)
- [AI agent index (llms.txt)](https://docs.page/btwld/ack/llms.txt)

## Related Packages

- [ack_generator](https://pub.dev/packages/ack_generator) — Code generator for creating schema classes from annotated Dart models
- [ack_firebase_ai](https://pub.dev/packages/ack_firebase_ai) — Firebase AI (Gemini) schema converter
- [ack_json_schema_builder](https://pub.dev/packages/ack_json_schema_builder) — JSON Schema converter
