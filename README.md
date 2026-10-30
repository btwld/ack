# Ack

[![CI](https://github.com/btwld/ack/actions/workflows/ci.yml/badge.svg)](https://github.com/btwld/ack/actions/workflows/ci.yml)
[![pub package](https://img.shields.io/pub/v/ack.svg)](https://pub.dev/packages/ack)

Ack validates data in Dart and Flutter. This branch documents **2.0.0-beta.1**;
see the [migration guide](docs/getting-started/migration-guide.mdx) for 1.x changes.

## Core concepts

- Schemas define accepted boundary data and the Dart values it becomes.
- Parsing validates input; `safeParse` returns a result. Codecs also encode
  runtime values back to the boundary.
- Presence and null differ: `optional` permits omission, `nullable` permits
  null, and `JsonMaybe` preserves both states.
- Generation is optional: `@Schemable` turns schemas into models or
  hand-written classes into schemas, using one `.g.dart` part.
- Generated model constructors are unchecked; use parsing for untrusted input
  and JSON encoding for validated output.
- Native schemas export Draft-7; imported 2020-12 resources retain their
  dialect unless explicitly lowered.
- Adapters reuse schemas for Firebase AI, MCP inputs, and
  `json_schema_builder`; Ack still validates the data.

## Start here

Install the version documented on this branch:

```bash
dart pub add ack:^2.0.0-beta.1
```

```dart
import 'package:ack/ack.dart';

final userSchema = Ack.object({
  'name': Ack.string().minLength(2),
  'nickname': Ack.string().optional().nullable(),
});

final result = userSchema.safeParse({'name': 'Ada'});
if (result.isOk) {
  print(result.getOrThrow());
} else {
  print(result.getError());
}
```

See [installation](docs/getting-started/installation.mdx) for SDK requirements,
[model generation](docs/core-concepts/typesafe-schemas.mdx) for `@Schemable`, and
[codecs](docs/core-concepts/codecs.mdx) for encoding and callback failure semantics.

## Packages

| Package | Purpose |
|---|---|
| [ack](packages/ack) | Runtime schemas, codecs, JSON Schema import/export, annotations |
| [ack_generator](packages/ack_generator) | Models from schemas and schemas from classes |
| [ack_firebase_ai](packages/ack_firebase_ai) | Firebase AI response JSON Schema maps |
| [ack_json_schema_builder](packages/ack_json_schema_builder) | Bidirectional `json_schema_builder` bridge |
| [ack_mcp_dart](packages/ack_mcp_dart) | MCP input schemas and typed argument validation |

[Examples](example) demonstrate the packages together.

## Documentation and contributing

- [Guides](docs/index.mdx) and the branch-local [agent API index](llms.txt)
- [Architecture decisions](ARCHITECTURE.md): rationale and superseded choices
- [CONTRIBUTING.md](CONTRIBUTING.md): setup, checks, and generator resource limits
- [PUBLISHING.md](PUBLISHING.md): coordinated releases and tag-only publication
- [SUPPORT.md](SUPPORT.md), [SECURITY.md](SECURITY.md), and
  [Code of Conduct](CODE_OF_CONDUCT.md)
