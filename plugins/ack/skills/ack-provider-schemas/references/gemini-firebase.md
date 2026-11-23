# Gemini structured output via Firebase AI (ack_firebase_ai)

Source: [Firebase AI adapter README](https://github.com/btwld/ack/blob/v2.0.0-beta.3/packages/ack_firebase_ai/README.md). Flutter only; replace `<constraint>` with the matching 2.x constraint from [the Ack version check](../../using-ack/SKILL.md#1-check-the-installed-version-first).

```bash
flutter pub add 'ack:<constraint>' 'ack_firebase_ai:<constraint>' firebase_ai firebase_core http
flutter pub add --dev firebase_core_platform_interface   # setupFirebaseCoreMocks for tests
```

`schema.toFirebaseAiResponseJsonSchema()` returns `schema.toJsonSchema()` **unchanged** (a `Map<String, Object?>`) for `GenerationConfig.responseJsonSchema`. It doesn't produce Firebase's `Schema` class, doesn't build function declarations, and doesn't drop keywords Gemini ignores.

Use [`leafErrors`](../../using-ack/SKILL.md#3-parse-at-the-boundary) from `using-ack` in the same library or import it.

```dart
import 'dart:convert';
import 'package:ack/ack.dart';
import 'package:ack_firebase_ai/ack_firebase_ai.dart';
import 'package:firebase_ai/firebase_ai.dart';

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

GenerativeModel reportModel(String modelName) =>
    FirebaseAI.googleAI().generativeModel(
  model: modelName, // the caller's choice
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
2. **The request itself** (a `flutter_test` test): call `TestWidgetsFlutterBinding.ensureInitialized()` and `setupFirebaseCoreMocks()` (from `package:firebase_core_platform_interface/test.dart`), then `await Firebase.initializeApp()` **with no options**. The mock already registers `[DEFAULT]`, and passing `FirebaseOptions` throws `[core/duplicate-app]`. Use `http.runWithClient(() => askReport(reportModel(name), prompt), () => MockClient(...))` with imports from `package:http/http.dart` and `package:http/testing.dart`. Have the mock record the POST and answer with a canned body. Assert that `generationConfig.responseJsonSchema` in the request equals `reportSchema.toJsonSchema()` and that the refine-breaking reply makes `askReport` throw:

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
