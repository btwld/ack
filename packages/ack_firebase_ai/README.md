# ack_firebase_ai

Firebase AI (Gemini) schema converter for the [ACK](https://pub.dev/packages/ack) validation library.

[![pub package](https://img.shields.io/pub/v/ack_firebase_ai.svg)](https://pub.dev/packages/ack_firebase_ai)

## Overview

Convert ACK validation schemas to Firebase AI Schema format for use with Gemini's structured output generation. Define your schemas once in ACK and use them with Firebase AI, dart_mcp, and other systems.

## Features

- ✅ **Simple API** - Single extension method `.toFirebaseAiSchema()`
- ✅ **Type-safe conversion** - All ACK schema types supported
- ✅ **Constraint mapping** - Numeric bounds, array lengths, and formats preserved (string length metadata currently limited by Firebase AI Schema)
- ✅ **Semantic validation** - Converted schemas validate the same data
- ✅ **Well-tested** - 45+ tests including behavioral equivalence tests

## Installation

```yaml
dependencies:
  ack: ^1.0.0-beta.2
  ack_firebase_ai: ^1.0.0-beta.2
  firebase_ai: ^3.4.0  # Required - see compatibility table below
```

### Firebase AI Version Compatibility

This package is compatible with `firebase_ai` versions `>=3.4.0 <5.0.0`.

**Important:** You must include `firebase_ai` in your own dependencies, as this package returns `Schema` objects from the firebase_ai package.

The converter uses the `Schema` class from firebase_ai, which has remained stable across major versions. We actively monitor firebase_ai releases and will update this constraint if the Schema API changes significantly.

#### Tested Versions

| ack_firebase_ai | firebase_ai | Status |
|----------------|-------------|--------|
| 1.0.0-beta.2   | 3.4.0       | ✅ Fully tested |
| 1.0.0-beta.2   | 3.5.0+      | ⚠️ Should work (uses stable Schema API) |
| 1.0.0-beta.2   | 4.0.0+      | ⚠️ Expected to work when released |
| 1.0.0-beta.2   | 5.0.0+      | ❌ Not supported - check for package updates |

If you encounter compatibility issues with a specific firebase_ai version, please [open an issue](https://github.com/btwld/ack/issues).

## Usage

### Basic Example

```dart
import 'package:ack/ack.dart';
import 'package:ack_firebase_ai/ack_firebase_ai.dart';

// Define your schema in ACK
final userSchema = Ack.object({
  'name': Ack.string().minLength(2).maxLength(50),
  'email': Ack.string().email(),
  'age': Ack.integer().min(0).max(120).optional(),
});

// Convert to Firebase AI format
final geminiSchema = userSchema.toFirebaseAiSchema();

// Use with Firebase AI SDK
import 'package:firebase_ai/firebase_ai.dart';

final model = FirebaseAI.instance.generativeModel(
  model: 'gemini-1.5-pro',
  generationConfig: GenerationConfig(
    responseMimeType: 'application/json',
    responseSchema: geminiSchema,
  ),
);

final response = await model.generateContent([
  Content.text('Generate a sample user'),
]);

// Validate the response with your ACK schema
final result = userSchema.safeParse(response.data);
if (result.isOk) {
  final validUser = result.getOrThrow();
  print('Generated valid user: $validUser');
}
```

### Complex Nested Example

```dart
final blogSchema = Ack.object({
  'title': Ack.string().minLength(5).maxLength(100),
  'content': Ack.string().minLength(10),
  'author': Ack.object({
    'name': Ack.string(),
    'email': Ack.string().email(),
  }),
  'tags': Ack.list(Ack.string()).minLength(1).maxLength(5),
  'metadata': Ack.object({
    'views': Ack.integer().min(0),
    'likes': Ack.integer().min(0),
  }).optional(),
});

final geminiSchema = blogSchema.toFirebaseAiSchema();
// Ready to use with Gemini for structured blog post generation
```

### Use with dart_mcp

```dart
import 'package:mcp_dart/mcp_dart.dart';
import 'package:ack/ack.dart';
import 'package:ack_firebase_ai/ack_firebase_ai.dart';

// Define schema once
final toolInputSchema = Ack.object({
  'query': Ack.string().minLength(1),
  'maxResults': Ack.integer().min(1).max(100).optional(),
});

// Convert for MCP tool definition
final mcpTool = Tool(
  name: 'search',
  description: 'Search for items',
  inputSchema: toolInputSchema.toFirebaseAiSchema(),
);
```

## Schema Mapping

### Supported Types

| ACK Type | Firebase AI Type | Notes |
|----------|-----------------|-------|
| `Ack.string()` | `string` | ✅ Full support |
| `Ack.integer()` | `integer` | ✅ Full support |
| `Ack.double()` | `number` | ✅ Full support |
| `Ack.boolean()` | `boolean` | ✅ Full support |
| `Ack.object({...})` | `object` | ✅ Full support |
| `Ack.list(...)` | `array` | ✅ Full support |
| `Ack.enumString([...])` | `string` with `enum` | ✅ Full support |
| `Ack.anyOf([...])` | `anyOf` array | ✅ Full support |
| `Ack.any()` | `object` | ⚠️ Fallback to empty object |

### Supported Constraints

| ACK Constraint | Firebase AI | Example |
|----------------|-------------|---------|
| `.minLength(n)` | `minItems` (arrays), string metadata not yet surfaced | Array length enforced; track string length in ACK |
| `.maxLength(n)` | `maxItems` (arrays), string metadata not yet surfaced | Array length enforced; track string length in ACK |
| `.min(n)` | `minimum` | Numeric minimum |
| `.max(n)` | `maximum` | Numeric maximum |
| `.email()` | `format: "email"` | Email format |
| `.uuid()` | `format: "uuid"` | UUID format |
| `.url()` | `format: "uri"` | URL format |
| `.nullable()` | `nullable: true` | Nullable field |
| `.optional()` | Excluded from `required` | Optional field |
| `.describe(...)` | `description` | Human-readable description |

## Limitations

Some ACK features cannot be converted to Firebase AI format:

### 1. Custom Refinements

```dart
// ❌ Refinements not supported
final schema = Ack.string().refine(
  (s) => s.startsWith('ACK_'),
  message: 'Must start with ACK_',
);

// ✅ Solution: Validate after AI response
final result = schema.safeParse(aiResponse);
```

### 2. Regex Patterns

```dart
// ❌ Regex patterns not fully supported
final schema = Ack.string().matches(r'^[A-Z]{3}-\d{5}$');

// ✅ Solution: Use enum or validate after
final schema = Ack.enumString(['ABC-12345', 'DEF-67890']);
// Or validate after generation
```

### 3. Transformed Schemas

```dart
// ❌ Transforms not supported
final dateSchema = Ack.date(); // TransformedSchema

// ✅ Solution: Convert underlying schema
final stringSchema = Ack.string().date();
final geminiSchema = stringSchema.toFirebaseAiSchema();
```

### 4. Default Values

```dart
// Default values are not sent to Gemini
final schema = Ack.string().withDefault('default value');
final geminiSchema = schema.toFirebaseAiSchema();
// Gemini doesn't use defaults - apply them after parsing
```

### 5. String Length Constraints

```dart
// Firebase AI Schema objects currently omit string min/max length metadata
final schema = Ack.string().minLength(5).maxLength(20);
final geminiSchema = schema.toFirebaseAiSchema();
// geminiSchema.toJson() does not include minLength/maxLength keys yet.
// Enforce these constraints with ACK during response validation.
```

## Testing

The package includes comprehensive tests:

### Conversion Tests

Verify structure of converted schemas:

```bash
flutter test test/converter_test.dart
```

> **Note:** The `firebase_ai` dependency pulls in Flutter-only APIs.
> Run tests with `flutter test` (not `dart test`) so `dart:ui` is available.

### Semantic Validation Tests

Verify that converted schemas validate the same data as ACK schemas:

```bash
flutter test test/semantic_validation_test.dart
```

### Run All Tests

```bash
cd packages/ack_firebase_ai
flutter test
```

## Why Use This Package?

1. **Single Source of Truth** - Define schemas once in ACK, use everywhere
2. **Type Safety** - ACK provides compile-time validation
3. **Validation Reuse** - Same schema validates both input and AI output
4. **Tested** - Behavioral equivalence tests ensure correctness
5. **Simple** - Single extension method, no complex configuration

## Example: Full Workflow

```dart
import 'package:ack/ack.dart';
import 'package:ack_firebase_ai/ack_firebase_ai.dart';
import 'package:firebase_ai/firebase_ai.dart';

void main() async {
  // 1. Define schema once
  final productSchema = Ack.object({
    'id': Ack.string().uuid(),
    'name': Ack.string().minLength(1).maxLength(100),
    'price': Ack.double().positive(),
    'inStock': Ack.boolean(),
    'tags': Ack.list(Ack.string()).maxLength(5),
  });

  // 2. Convert for Gemini
  final geminiSchema = productSchema.toFirebaseAiSchema();

  // 3. Use with Gemini
  final model = FirebaseAI.instance.generativeModel(
    model: 'gemini-1.5-pro',
    generationConfig: GenerationConfig(
      responseMimeType: 'application/json',
      responseSchema: geminiSchema,
    ),
  );

  final response = await model.generateContent([
    Content.text('Generate a sample product'),
  ]);

  // 4. Validate response with ACK
  final result = productSchema.safeParse(response.data);

  if (result.isOk) {
    final product = result.getOrThrow();
    print('✅ Generated valid product: $product');
  } else {
    print('❌ Validation failed: ${result.getError()}');
  }
}
```

## Contributing

See [CONTRIBUTING.md](../../CONTRIBUTING.md) in the root repository.

## License

This package is part of the [ACK](https://github.com/btwld/ack) monorepo.

## Related Packages

- [ack](https://pub.dev/packages/ack) - Core validation library
- [ack_generator](https://pub.dev/packages/ack_generator) - Code generator for schemas
- [firebase_ai](https://pub.dev/packages/firebase_ai) - Firebase AI SDK for Flutter
