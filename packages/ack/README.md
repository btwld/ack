# Ack

[![CI/CD](https://github.com/btwld/ack/actions/workflows/ci.yml/badge.svg)](https://github.com/btwld/ack/actions/workflows/ci.yml)
[![pub package](https://img.shields.io/pub/v/ack.svg)](https://pub.dev/packages/ack)
[![docs.page](https://img.shields.io/badge/docs.page-documentation-blue)](https://docs.page/btwld/ack)

A schema validation library for Dart and Flutter with a simple, fluent API. Inspired by [Zod](https://zod.dev).

## Installation

```bash
dart pub add ack
```

## Quick Start

```dart
import 'package:ack/ack.dart';

// Define a schema
final userSchema = Ack.object({
  'name': Ack.string().minLength(2).maxLength(50),
  'email': Ack.string().email(),
  'age': Ack.integer().min(0).max(120).optional(),
});

// Validate data
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

## Features

- **Fluent API** — chain `.minLength()`, `.email()`, `.positive()`, `.nullable()`, `.optional()` and more
- **Type-safe** — schemas are generic (`AckSchema<String>`, `AckSchema<int>`, etc.)
- **Strict or lenient parsing** — coerce `"42"` → `42` in lenient mode, reject in strict mode
- **Transformations** — `.transform<DateTime>((s) => DateTime.parse(s!))` to change output types
- **Refinements** — `.refine((v) => v.isEven, message: 'Must be even')` for custom business rules
- **JSON Schema export** — `.toJsonSchema()` produces Draft-7 compatible output
- **Composable** — `Ack.anyOf(...)`, `Ack.discriminated(...)`, nested objects and lists

## Available Schemas

| Factory | Type | Key Extensions |
|---------|------|---------------|
| `Ack.string()` | `StringSchema` | `.minLength()`, `.maxLength()`, `.email()`, `.url()`, `.uuid()`, `.matches()` |
| `Ack.integer()` | `IntegerSchema` | `.min()`, `.max()`, `.positive()`, `.negative()`, `.multipleOf()` |
| `Ack.double()` | `DoubleSchema` | `.min()`, `.max()`, `.positive()`, `.negative()` |
| `Ack.boolean()` | `BooleanSchema` | |
| `Ack.object({...})` | `ObjectSchema` | `.strict()`, `.passthrough()`, `.merge()`, `.partial()`, `.pick()`, `.omit()` |
| `Ack.list(schema)` | `ListSchema` | `.minItems()`, `.maxItems()`, `.uniqueItems()` |
| `Ack.enum_(values)` | `EnumSchema` | |
| `Ack.enumString([...])` | `StringSchema` | Constrained to allowed values |
| `Ack.literal(value)` | `StringSchema` | Exact string match |
| `Ack.anyOf([...])` | `AnyOfSchema` | First-match-wins semantics |
| `Ack.discriminated(...)` | `DiscriminatedObjectSchema` | Key-based union dispatch |
| `Ack.any()` | `AnySchema` | Accepts all non-null values |

## Optional vs Nullable

```dart
final schema = Ack.object({
  'required': Ack.string(),                        // must exist, must be non-null
  'optional': Ack.string().optional(),              // may be omitted entirely
  'nullable': Ack.string().nullable(),              // must exist, may be null
  'both': Ack.string().optional().nullable(),       // may be omitted or null
});
```

## Ecosystem

| Package | Description |
|---------|------------|
| [ack](https://pub.dev/packages/ack) | Core validation library |
| [ack_annotations](https://pub.dev/packages/ack_annotations) | Annotations for code generation |
| [ack_generator](https://pub.dev/packages/ack_generator) | Code generator for schema classes |
| [ack_firebase_ai](https://pub.dev/packages/ack_firebase_ai) | Firebase AI (Gemini) schema converter |
| [ack_json_schema_builder](https://pub.dev/packages/ack_json_schema_builder) | JSON Schema Builder converter |

## Documentation

Full documentation at [docs.page/btwld/ack](https://docs.page/btwld/ack).

## License

MIT — see [LICENSE](LICENSE).
