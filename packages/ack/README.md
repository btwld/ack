# ack

Schema validation for Dart and Flutter with a fluent API.

[![pub package](https://img.shields.io/pub/v/ack.svg)](https://pub.dev/packages/ack)
[![CI](https://github.com/btwld/ack/actions/workflows/ci.yml/badge.svg)](https://github.com/btwld/ack/actions/workflows/ci.yml)

## Install

```bash
dart pub add ack
```

Or in `pubspec.yaml`:

```yaml
dependencies:
  ack: ^1.0.0-beta.8
```

## Quick Start

```dart
import 'package:ack/ack.dart';

final userSchema = Ack.object({
  'id': Ack.string().minLength(1),
  'email': Ack.string().email(),
  'age': Ack.integer().min(0).optional(),
});

final result = userSchema.safeParse({
  'id': 'usr_1',
  'email': 'hello@example.com',
  'age': 42,
});

if (result.isOk) {
  final user = result.getOrThrow();
  print(user?['email']);
} else {
  print(result.getError());
}
```

## Parse APIs

Use the API that matches your error-handling style:

- `safeParse(...)`: never throws, returns `SchemaResult<T>`.
- `parse(...)`: throws `AckException` on failure.
- `safeParseAs(...)`: validates, then maps to another type without throwing.
- `parseAs(...)`: validates, maps, and throws on failures.

```dart
final schema = Ack.string().minLength(3);

final ok = schema.safeParse('ack');
final value = schema.parse('ack');

final len = schema.parseAs('ack', (s) => s!.length); // 3
```

## Strict vs Loose Parsing

Ack supports coercion by default for compatible primitives (for example string to int). Use strict parsing when coercion is not allowed.

```dart
final loose = Ack.integer();
final strict = Ack.integer().strictParsing();

print(loose.safeParse('42').isOk);  // true
print(strict.safeParse('42').isOk); // false
```

## Object Schemas

Objects are strict by default (`additionalProperties: false`).

```dart
final accountSchema = Ack.object({
  'name': Ack.string().minLength(2),
  'email': Ack.string().email(),
  'nickname': Ack.string().optional(),
});

final result = accountSchema.safeParse({
  'name': 'Leandro',
  'email': 'leo@example.com',
});
```

Use `.passthrough()` when extra keys should be allowed.

## List Schemas

```dart
final tagsSchema = Ack.list(Ack.string().minLength(1))
    .minLength(1)
    .maxLength(10);

final result = tagsSchema.safeParse(['dart', 'ack']);
```

## Discriminated Unions

```dart
final eventSchema = Ack.discriminated(
  discriminatorKey: 'type',
  schemas: {
    'click': Ack.object({
      'type': Ack.literal('click'),
      'x': Ack.integer(),
      'y': Ack.integer(),
    }),
    'scroll': Ack.object({
      'type': Ack.literal('scroll'),
      'deltaY': Ack.double(),
    }),
  },
);

final event = eventSchema.safeParse({
  'type': 'click',
  'x': 100,
  'y': 220,
});
```

## Error Handling

Errors include path and schema context.

```dart
final emailSchema = Ack.string().email();
final result = emailSchema.safeParse('not-an-email');

if (result.isFail) {
  final error = result.getError();
  print(error.toErrorString());
  print(error.toMap());
}
```

## JSON Schema Conversion

Every Ack schema can be exported to JSON Schema Draft-7 data:

```dart
final schema = Ack.object({
  'name': Ack.string().minLength(2),
  'active': Ack.boolean(),
});

final jsonSchema = schema.toJsonSchema();
print(jsonSchema);
```

## Ecosystem

- [`ack_annotations`](https://pub.dev/packages/ack_annotations): annotations for schema generation
- [`ack_generator`](https://pub.dev/packages/ack_generator): build_runner generator for schemas and typed wrappers
- [`ack_json_schema_builder`](https://pub.dev/packages/ack_json_schema_builder): converter to `json_schema_builder`
- [`ack_firebase_ai`](https://pub.dev/packages/ack_firebase_ai): converter for Firebase AI/Gemini schema usage

## Docs and Repository

- Documentation: <https://docs.page/btwld/ack>
- Repository: <https://github.com/btwld/ack>
- Issue tracker: <https://github.com/btwld/ack/issues>
