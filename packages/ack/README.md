# Ack

[![pub package](https://img.shields.io/pub/v/ack.svg)](https://pub.dev/packages/ack)
[![CI/CD](https://github.com/conceptadev/ack/actions/workflows/ci.yml/badge.svg)](https://github.com/conceptadev/ack/actions/workflows/ci.yml)
[![Documentation](https://img.shields.io/badge/docs-documentation-blue)](https://concepta.dev/ack)

Ack is a schema validation library for Dart and Flutter that helps you validate data with a simple, fluent API. Ack is short for "acknowledge".

## Why Use Ack?

- **Simplify Validation**: Easily handle complex data validation logic
- **Validate external payloads**: Guard API and user inputs by validating required fields, types, and constraints at boundaries
- **Single Source of Truth**: Define data structures and rules in one place
- **Reduce Boilerplate**: Minimize repetitive code for validation and JSON conversion
- **Type Safety**: Generate immutable models from schemas, or derive validated
  schemas from hand-written classes

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

## Import JSON Schema

Import a decoded draft 2020-12 schema without re-declaring it in Dart:

```dart
import 'package:ack/ack.dart';

final AckSchema<Object, Object> schema = Ack.fromJsonSchema({
  'type': 'object',
  'properties': {'name': {'type': 'string'}},
  'required': ['name'],
});
final value = schema.parse({'name': 'Ada'});
final jsonSchema = schema.toJsonSchema();
```

The source document is a decoded map or boolean, not a JSON string.
`Ack.fromJsonSchema()` returns an executable validator and rejects unsupported
semantics. `importJsonSchema()` returns a `JsonSchemaImportResult` containing
`schema`, immutable `diagnostics`, and `isExact`; partial conversion requires
`allowUnsupported: true`. Supply reference bundles with `documents` and
`baseUri`; no references are fetched automatically.

Exports preserve supported validation behavior, not textual document identity.
Full A2UI coverage is not supported; partial imports must be evaluated using
their diagnostics. MCP registration compatibility remains separate. See the
[JSON Schema guide](https://concepta.dev/documentation/ack/guides/json-schema-integration)
for the supported subset, recursive bundles, and round-trip guarantees.

## Documentation

- [Full documentation](https://concepta.dev/ack)
- [AI agent index (llms.txt)](https://concepta.dev/documentation/ack/reference/llms-txt)

## Related Packages

- [ack_generator](https://pub.dev/packages/ack_generator) — Generates models from `@AckInfer()` schemas and schemas from `@AckModel()` classes
- [ack_firebase_ai](https://pub.dev/packages/ack_firebase_ai) — Firebase AI (Gemini) schema converter
- [ack_json_schema_builder](https://pub.dev/packages/ack_json_schema_builder) — bidirectional JSON Schema bridge
