# ack_firebase_ai

Firebase AI (Gemini) structured-output adapter for the [ACK](https://pub.dev/packages/ack) validation library.

[![pub package](https://img.shields.io/pub/v/ack_firebase_ai.svg)](https://pub.dev/packages/ack_firebase_ai)

## Overview

`ack_firebase_ai` converts ACK schemas to the JSON-compatible map accepted by Firebase AI's `GenerationConfig.responseJsonSchema`.

The adapter is intentionally thin:

```text
AckSchema
  -> AckSchemaModel
  -> JSON Schema map
  -> GenerationConfig.responseJsonSchema
```

Always validate model output with the same ACK schema after generation. Firebase response schemas guide generation, but ACK remains the runtime validator.

## Installation

```yaml
dependencies:
  ack: ^1.0.0-beta.12
  ack_firebase_ai: ^1.0.0-beta.12
  firebase_ai: ^3.12.1
```

This package targets Firebase AI's map-based `responseJsonSchema` API for models that support JSON Schema structured output.

## Usage

In a Flutter app that has initialized Firebase:

```dart
import 'dart:convert';

import 'package:ack/ack.dart';
import 'package:ack_firebase_ai/ack_firebase_ai.dart';
import 'package:firebase_ai/firebase_ai.dart';

Future<void> main() async {
  final userSchema = Ack.object({
    'name': Ack.string().minLength(2).maxLength(50),
    'email': Ack.string().email(),
    'age': Ack.integer().min(0).max(120).optional(),
  });

  // Assumes Firebase.initializeApp() has already run in your app startup.
  final model = FirebaseAI.googleAI().generativeModel(
    model: 'gemini-3.5-flash',
    generationConfig: GenerationConfig(
      responseMimeType: 'application/json',
      responseJsonSchema: userSchema.toFirebaseAiResponseJsonSchema(),
    ),
  );

  final response = await model.generateContent([
    Content.text(
      'Generate a JSON user profile with name, email, and optional age.',
    ),
  ]);

  final decoded = jsonDecode(response.text ?? 'null');
  final result = userSchema.safeParse(decoded);

  if (result.isOk) {
    final user = result.getOrThrow();
    print('Valid user: $user');
    return;
  }

  throw StateError(
    'Generated response did not match schema: ${result.getError()}',
  );
}
```

## Schema Mapping

The adapter returns ACK's generic Draft-7 JSON Schema renderer output. That
means adapter behavior matches `AckSchema.toJsonSchema()`, which renders
`AckSchema.toSchemaModel().toJsonSchema()`.

| ACK schema | JSON Schema output |
| --- | --- |
| `Ack.string()` | `type: string` |
| `Ack.integer()` | `type: integer` |
| `Ack.double()` | `type: number` |
| `Ack.boolean()` | `type: boolean` |
| `Ack.object({...})` | `type: object`, `properties`, `required` |
| `Ack.list(...)` | `type: array`, `items` |
| `Ack.enumString([...])` / `Ack.enumValues(...)` | `enum` |
| `Ack.literal(...)` | `const` |
| `Ack.anyOf([...])` | `anyOf` |
| `Ack.discriminated(...)` | `anyOf` with exact discriminator `const` branches |
| `Ack.any()` | JSON-compatible primitive/object/array branches |

Supported ACK constraints are preserved when they can be represented in JSON
Schema, including string length and pattern keywords, numeric bounds,
`multipleOf`, array length, `uniqueItems`, nullability, defaults, and additional
properties policy.

Firebase serializes `responseJsonSchema` as a map, but Gemini supports a subset
of JSON Schema and may ignore unsupported keywords. Treat the generated schema
as model guidance and ACK validation as the authoritative runtime check.

## Discriminated Unions

`Ack.discriminated(...)` owns the discriminator. Branch schemas may omit the
discriminator property; the schema model injects an exact `const`
discriminator into each branch export.

```dart
final shapeSchema = Ack.discriminated<Map<String, Object?>>(
  discriminatorKey: 'type',
  schemas: {
    'circle': Ack.object({'radius': Ack.double().positive()}),
    'square': Ack.object({'side': Ack.double().positive()}),
  },
);

final jsonSchema = shapeSchema.toFirebaseAiResponseJsonSchema();
```

The generated map contains `anyOf` branches with exact `type` literals. It does
not emit OpenAPI-style `discriminator` metadata.

## Limitations

Firebase AI response schemas are generation guidance, not a substitute for validation. Validate generated JSON with ACK before using it.

Custom refinements and transforms that cannot be represented as JSON Schema are not enforceable by Firebase AI. ACK still enforces them after parsing.

Schema size counts toward the model input token budget. Keep response schemas focused on the shape you need back.

## Live Contract Test

The normal test suite does not call Firebase. To verify the adapter against a real Firebase AI project, run the opt-in live test with Firebase app credentials:

```bash
firebase projects:list
firebase apps:list --project <project-id>
gcloud services enable firebasevertexai.googleapis.com --project <project-id>
```

Use a Firebase Web app's SDK config for the environment values below. The project also needs Firebase AI Logic configured for the selected backend.

```bash
ACK_FIREBASE_AI_LIVE=1 \
ACK_FIREBASE_AI_BACKEND=google_ai \
ACK_FIREBASE_AI_MODEL=gemini-3.5-flash \
FIREBASE_API_KEY=... \
FIREBASE_PROJECT_ID=... \
FIREBASE_APP_ID=... \
FIREBASE_MESSAGING_SENDER_ID=... \
flutter test test/live_firebase_ai_response_json_schema_test.dart
```

The test uses `GenerationConfig.responseJsonSchema`, sends real Gemini requests,
decodes each response, and validates it with the same ACK schema. It covers
nested objects/lists, `anyOf`, nullable fields, transformed date output,
union-owned discriminators, and `Ack.any()` payloads. By default it uses
Firebase AI's Gemini Developer API backend with `gemini-3.5-flash`. Set
`ACK_FIREBASE_AI_MODEL` to test a different 3.x model, for example
`gemini-3-flash-preview` when the default model is temporarily high-demand.

The same values can also be passed with `flutter test --dart-define=...`. Use the Firebase app values from your FlutterFire-generated `DefaultFirebaseOptions.currentPlatform` or Firebase console app settings. To run the live test against the Vertex AI backend, set:

```bash
ACK_FIREBASE_AI_BACKEND=vertex_ai \
FIREBASE_AI_LOCATION=global
```

## Fixture Golden Tests

The committed fixture tests are the normal adapter contract and do not require
Firebase credentials. They compare ACK conversion output against JSON fixtures
under `test/fixtures/firebase_ai_response_json_schema/`, capture Firebase SDK
`Schema.toJson()` and `JSONSchema.toJson()` native fixture output, and verify
the same maps serialize through Firebase AI's
`GenerationConfig.responseJsonSchema`.

Regenerate the fixtures after an intentional schema-output change:

```bash
dart run tool/generate_firebase_ai_response_json_schema_fixtures.dart
```

From the workspace root, the same generator is available through Melos:

```bash
melos run firebase-ai-fixtures
```
