# Gemini structured output via Firebase AI (ack_firebase_ai)

Source: https://github.com/btwld/ack/blob/main/packages/ack_firebase_ai/README.md and docs/guides/ecosystem-integrations.mdx. Flutter only (Flutter >=3.47).

```bash
flutter pub add ack:^2.0.0-beta.3 ack_firebase_ai:^2.0.0-beta.3 firebase_ai firebase_core http
flutter pub add --dev firebase_core_platform_interface   # setupFirebaseCoreMocks for tests
```

`schema.toFirebaseAiResponseJsonSchema()` returns `schema.toJsonSchema()` **unchanged** (a `Map<String, Object?>`) for `GenerationConfig.responseJsonSchema`. It doesn't produce Firebase's `Schema` class, doesn't build function declarations, and doesn't drop keywords Gemini ignores.

```dart
import 'dart:convert';
import 'package:ack/ack.dart';
import 'package:ack_firebase_ai/ack_firebase_ai.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:http/http.dart' as http;
// leafErrors: the helper from this skill's "Gate what comes back" step

final reportSchema = Ack.object({
  'city': Ack.string().minLength(2),
  'lowC': Ack.double(),
  'highC': Ack.double(),
}).refine((r) => (r['lowC'] as double) <= (r['highC'] as double),
    message: 'lowC must not exceed highC');

Future<Map<String, Object?>> askReport(GenerativeModel model, String prompt) async {
  final response = await model.generateContent([Content.text(prompt)]);
  final result = reportSchema.safeParse(jsonDecode(response.text ?? 'null'));
  return switch (result) {
    Ok(:final value) => value!,
    Fail(:final error) => throw FormatException('Gemini report rejected: ${leafErrors(error).map((e) => '${e.path}: ${e.message}').join('; ')}'),
  };
}

GenerativeModel reportModel(String modelName, {http.Client? httpClient}) =>
    FirebaseAI.googleAI().generativeModel(
  model: modelName, // the caller's choice
  httpClient: httpClient, // tests pass a recording client
  generationConfig: GenerationConfig(
    responseMimeType: 'application/json',
    responseJsonSchema: reportSchema.toFirebaseAiResponseJsonSchema(),
  ),
);
```

- Gemini sees the shape, `minimum`/`maximum`, `format`, and `enum`. It never sees the refine, and it ignores `minLength` / `maxLength` / `uniqueItems`. Only `safeParse` enforces those.
- `responseSchema` (Firebase's `Schema` class) and `responseJsonSchema` are mutually exclusive. Use `responseJsonSchema`.
- A generated class works too: `Report.schema.toFirebaseAiResponseJsonSchema()`, then `Report.schema.safeParse(decoded)`.
- **Function calling** through `firebase_ai`'s `FunctionDeclaration` takes Firebase `Schema` objects, not a raw map, and `ack_firebase_ai` doesn't convert to them. If the user needs tools, say so and choose with them. One option is a small `FunctionDeclaration` subclass whose `toJson()` emits `'parametersJsonSchema': schema.toJsonSchema()` (an app-side workaround, not an Ack API). Gate `functionCall.args` with `safeParse` either way.

## Testing without a network

1. **Plain Dart, no Firebase:** `reportSchema.toFirebaseAiResponseJsonSchema()` equals `reportSchema.toJsonSchema()`; a fixture that is schema-valid but breaks the refine (`{"city":"Oslo","lowC":9,"highC":3}`) fails `safeParse` with a `SchemaValidationError`; a valid fixture parses.
2. **The request itself** (a `flutter_test` test): call `TestWidgetsFlutterBinding.ensureInitialized()` and `setupFirebaseCoreMocks()` (from `package:firebase_core_platform_interface/test.dart`), then `await Firebase.initializeApp()` **with no options**. The mock already registers `[DEFAULT]`, and passing `FirebaseOptions` throws `[core/duplicate-app]`. Build `reportModel(name, httpClient: MockClient(...))` (`package:http/testing.dart`), have the mock record the POST and answer with a canned body, and assert that the decoded body's `generationConfig.responseJsonSchema` equals `reportSchema.toJsonSchema()` and that this canned refine-breaking reply makes `askReport` throw:

```dart
final cannedBody = jsonEncode({
  'candidates': [
    {
      'content': {
        'role': 'model',
        'parts': [
          {'text': jsonEncode({'city': 'Oslo', 'lowC': 9, 'highC': 3})},
        ],
      },
      'finishReason': 'STOP',
    },
  ],
});
// MockClient((request) async { recorded = request; return http.Response(cannedBody, 200); })
```

Live calls need a configured Firebase project. Keep them opt-in behind an environment flag.
