# ack_firebase_ai

Firebase AI (Gemini) schema converter for the [ACK](https://pub.dev/packages/ack) validation library.

[![pub package](https://img.shields.io/pub/v/ack_firebase_ai.svg)](https://pub.dev/packages/ack_firebase_ai)

## Overview

Converts ACK schemas to Firebase AI Schema format via `.toFirebaseAiSchema()`. Assumes familiarity with [ACK](https://pub.dev/packages/ack) and [firebase_ai](https://pub.dev/packages/firebase_ai).

## Installation

```yaml
dependencies:
  ack: ^1.0.0
  ack_firebase_ai: ^1.0.0
  firebase_ai: ^3.4.0  # Required peer dependency
```

### Compatibility

Requires `firebase_ai: >=3.4.0 <5.0.0` as a peer dependency. Report [compatibility issues](https://github.com/btwld/ack/issues).

## Limitations ⚠️

**Read this first** - Firebase AI schema conversion has important constraints:

### 1. Gemini Doesn't Enforce Schemas

Firebase AI schemas are **hints**, not validation. Always validate output with ACK.

```dart
// Gemini may ignore constraints
final schema = Ack.integer().min(0).max(10);
final geminiSchema = schema.toFirebaseAiSchema();

final model = FirebaseAI.instance.generativeModel(
  model: 'gemini-1.5-pro',
  generationConfig: GenerationConfig(
    responseMimeType: 'application/json',
    responseSchema: geminiSchema,
  ),
);

final response = await model.generateContent([...]);
// Response may contain values outside 0-10 range!

// ALWAYS validate with ACK
final result = schema.safeParse(response.data);
if (!result.isOk) {
  // Handle validation failure
}
```

### 2. String Length Not Enforced

Firebase AI Schema (as of firebase_ai v3.6.0) does not expose `minLength`/`maxLength` properties in the serialized JSON schema. These constraints exist in ACK schemas but cannot be passed to Gemini. Always validate AI output with ACK after generation.

**Why:** This is a limitation of the Firebase AI Dart SDK's Schema API, not the Gemini API itself. The underlying Gemini API supports string constraints, but they're not yet surfaced in the typed Schema class.

**Workaround:** Validate all AI responses with your ACK schema to enforce length constraints client-side.

```dart
final schema = Ack.string().minLength(5).maxLength(20);
final geminiSchema = schema.toFirebaseAiSchema();
// Length constraints not included in geminiSchema.toJson()
// Validate with ACK: schema.safeParse(aiResponse)
```

### 3. Refinements Unsupported

Custom validation logic cannot be expressed in Firebase AI schemas.

```dart
// Cannot convert
final schema = Ack.string().refine((s) => s.startsWith('ACK_'));

// Validate AI output with ACK schema
final result = schema.safeParse(aiResponse);
```

### 4. Regex Patterns Limited

Patterns not supported - use enums or post-validation.

```dart
// Not convertible
final schema = Ack.string().matches(r'^[A-Z]{3}-\d{5}$');

// Alternative: enum or validate after
final schema = Ack.enumString(['ABC-12345', 'DEF-67890']);
```

### 5. Default Values Not Passed

Defaults are ACK-only. Apply after parsing.

```dart
final schema = Ack.string().withDefault('default');
schema.toFirebaseAiSchema(); // Default not included
// Apply defaults after parsing AI response
```

### 6. oneOf Converted to anyOf

Firebase AI API only supports `anyOf`. Schemas using `oneOf` (exactly-one-of semantics via discriminated unions) are converted to `anyOf` (at-least-one-of), which may accept additional values.

```dart
// oneOf semantics: exactly one branch should match
final schema = Ack.discriminated(
  discriminatorKey: 'type',
  schemas: {
    'circle': Ack.object({'radius': Ack.double()}),
    'square': Ack.object({'side': Ack.double()}),
  },
);
final geminiSchema = schema.toFirebaseAiSchema();
// Converted to anyOf - exclusivity not enforced
// Always validate with ACK to ensure single branch match
```

### 7. Transformed Schemas

Supported - metadata overrides (description, title, nullable) work correctly.

```dart
final dateSchema = Ack.date(); // TransformedSchema
final geminiSchema = dateSchema.toFirebaseAiSchema(); // Works
```

## Usage

```dart
import 'package:ack/ack.dart';
import 'package:ack_firebase_ai/ack_firebase_ai.dart';
import 'package:firebase_ai/firebase_ai.dart';

// 1. Define schema
final userSchema = Ack.object({
  'name': Ack.string().minLength(2).maxLength(50),
  'email': Ack.string().email(),
  'age': Ack.integer().min(0).max(120).optional(),
});

// 2. Convert to Firebase AI
final geminiSchema = userSchema.toFirebaseAiSchema();

// 3. Use with Gemini
final model = FirebaseAI.instance.generativeModel(
  model: 'gemini-1.5-pro',
  generationConfig: GenerationConfig(
    responseMimeType: 'application/json',
    responseSchema: geminiSchema,
  ),
);

final response = await model.generateContent([
  Content.text('Generate a user'),
]);

// 4. ALWAYS validate with ACK (Gemini may violate schema)
final result = userSchema.safeParse(response.data);
if (result.isOk) {
  final user = result.getOrThrow();
  print('Valid: $user');
} else {
  print('Invalid: ${result.getError()}');
}
```

## Schema Mapping

### Supported Types

| ACK Type | Firebase AI Type | Conversion details |
|----------|-----------------|-------------------|
| `Ack.string()` | `string` | Full support |
| `Ack.integer()` | `integer` | Full support |
| `Ack.double()` | `number` | Full support |
| `Ack.boolean()` | `boolean` | Full support |
| `Ack.object({...})` | `object` | Full support |
| `Ack.list(...)` | `array` | Full support |
| `Ack.enumString([...])` | `string` with `enum` | Full support |
| `Ack.anyOf([...])` | `anyOf` array | Full support |
| `Ack.any()` | `object` | Converts to empty object |

### Supported Constraints

| ACK Constraint | Firebase AI | Notes |
|----------------|-------------|-------|
| `.minLength()` / `.maxLength()` | `minItems` / `maxItems` (arrays only) | String length not surfaced - validate with ACK |
| `.min()` / `.max()` | `minimum` / `maximum` | Numeric bounds |
| `.email()` / `.uuid()` / `.url()` | `format` | Format hints (enforcement varies by model) |
| `.nullable()` | `nullable: true` | Null support |
| `.optional()` | Excluded from `required` | Optional fields |
| `.describe()` | `description` | Descriptions |

## Testing

Requires Flutter (firebase_ai dependency). Use `flutter test`, not `dart test`.

```bash
cd packages/ack_firebase_ai
flutter test
```

## Contributing

For contribution guidelines, see [CONTRIBUTING.md](../../CONTRIBUTING.md) in the root repository.

## License

This package is part of the [ACK](https://github.com/btwld/ack) monorepo.

## Related Packages

- [ack](https://pub.dev/packages/ack) - Core validation library
- [ack_generator](https://pub.dev/packages/ack_generator) - Code generator for schemas
- [firebase_ai](https://pub.dev/packages/firebase_ai) - Firebase AI SDK for Flutter
