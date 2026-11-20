# Plain Gemini API (no Firebase): function declarations and response schemas

Source: Gemini API reference (ai.google.dev, `generateContent`), checked 2026-11-20. No Ack adapter is needed; send `schema.toJsonSchema()` as-is.

## Request fields (`models/{model}:generateContent`)

- **Function tool:** `tools: [{functionDeclarations: [{name, description, parametersJsonSchema: inputSchema.toJsonSchema()}]}]`. `parametersJsonSchema` must describe an object and can't be combined with the OpenAPI-style `parameters`. A declaration can also carry `responseJsonSchema` for the function's return value.
- **Structured response:** `generationConfig: {responseMimeType: 'application/json', responseJsonSchema: schema.toJsonSchema()}`. Don't combine it with `responseSchema`.
- The model id is the caller's choice. Put it in config and leave it out of the skill's code.

```dart
final createTaskInput = Ack.object({
  'title': Ack.string().minLength(1).describe('Short task title.'), // Gemini ignores minLength
  'dueDate': Ack.date().describe('YYYY-MM-DD, omit when unknown.').optional(),
});

Map<String, Object?> buildRequest(String prompt, AckSchema<Object, Object> toolInput) => {
  'contents': [
    {'role': 'user', 'parts': [{'text': prompt}]},
  ],
  'tools': [
    {
      'functionDeclarations': [
        {
          'name': 'create_task',
          'description': 'Create a task for the user.',
          'parametersJsonSchema': toolInput.toJsonSchema(),
        },
      ],
    },
  ],
};
```

Send it with `package:http` (`dart pub add http`) to `https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent`, with the key in the `x-goog-api-key` header:

```dart
// needs: import 'dart:convert'; import 'package:http/http.dart' as http;
Future<Map<String, Object?>> generate(
  http.Client client, String model, String apiKey, Map<String, Object?> request) async {
  final response = await client.post(
    Uri.https('generativelanguage.googleapis.com', '/v1beta/models/$model:generateContent'),
    headers: {'x-goog-api-key': apiKey, 'content-type': 'application/json'},
    body: jsonEncode(request),
  );
  return jsonDecode(response.body) as Map<String, Object?>;
}
```

## Reading the reply

Function calls arrive as `candidates[0].content.parts[i].functionCall` with `{name, args}`. Text (including JSON for a structured response) arrives in `parts[i].text`. Gate them like this:

```dart
for (final part in (body['candidates'] as List).first['content']['parts'] as List) {
  final call = (part as Map)['functionCall'] as Map?;
  if (call == null || call['name'] != 'create_task') continue;
  final result = createTaskInput.safeParse(call['args']);
  // Ok -> run the tool; Fail -> send a functionResponse listing the leaf path: message lines, or stop.
}
```

After a successful parse, `dueDate` is a local-midnight `DateTime` (not UTC), or absent if Gemini omitted the key.

## Keywords Gemini ignores

Gemini strips `minLength`, `maxLength`, `minProperties`, `maxProperties`, `uniqueItems`, and `contains` without an error. It honors `type`, `properties`, `required`, `additionalProperties`, `enum`, `format`, `minimum`/`maximum`, `minItems`/`maxItems`, `anyOf`, and `description`. Ack's nullable `anyOf: [..., {type: null}]` is accepted. Every ignored keyword and every refine is enforced only by your `safeParse`.

## Newer Interactions API

Google's docs now lead with `POST /v1beta/interactions`. There a tool is `{type: 'function', name, description, parameters}` and a structured response is `response_format: {type: 'text', mime_type: 'application/json', schema}`. Both take the same `toJsonSchema()` map. Use whichever endpoint the project already calls.

## Testing without a network

Pass a `MockClient` (`package:http/testing.dart`) as `client`, or test `buildRequest` as a pure function. Assert:

- the request's `parametersJsonSchema` (or `responseJsonSchema`) equals `schema.toJsonSchema()`;
- a stubbed reply whose `args` breaks an ignored keyword (for example an empty `title` under `minLength(1)`) fails the gate;
- a valid stubbed reply parses.
