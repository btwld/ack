# ack_mcp_dart

Define an MCP tool's input contract once with ACK. Use it to advertise a
`mcp_dart` tool schema and parse incoming arguments into validated Dart values.

```text
AckSchema → AckSchemaModel → JSON Schema → ToolInputSchema
    │
    └─ safeParse(arguments) → defaults, codecs, refinements → tool callback
```

Transport, negotiation, cancellation, and lifecycle remain in `mcp_dart`.

## Install

```yaml
dependencies:
  ack: ^1.2.0
  ack_mcp_dart: ^1.6.0
  mcp_dart: ^2.4.2
```

## Register a tool

```dart
import 'package:ack/ack.dart';
import 'package:ack_mcp_dart/ack_mcp_dart.dart';
import 'package:mcp_dart/mcp_dart.dart';

final searchInput = Ack.object({
  'query': Ack.string().minLength(1).refine(
    (query) => query.trim().isNotEmpty,
    message: 'Query must contain non-whitespace characters.',
  ),
  'limit': Ack.integer().min(1).max(100).optional().withDefault(5),
});

final server = McpServer(
  const Implementation(name: 'search-server', version: '1.0.0'),
);

void registerTools() {
  server.registerAckTool(
    'search',
    input: searchInput,
    description: 'Search documents',
    callback: (args, extra) {
      final query = args['query'] as String;
      final limit = args['limit'] as int; // 5 when omitted; 2.0 parses to int 2.
      return CallToolResult(
        content: [TextContent(text: 'Searching for $query (limit $limit)')],
      );
    },
  );
}
```

Both registration helpers return `RegisteredTool` and forward `title`,
`description`, `annotations`, and `meta`. Callbacks may be synchronous or
asynchronous and receive the original `RequestHandlerExtra`.

Use `server.registerAckModelTool('search', model: SearchSchema.model,
callback: (args, extra) { ... })` with an `AckModelAdapter<JsonMap, Object, M>`
(such as a generated model adapter) to receive a typed `M` instead of a map.
The model is constructed after ACK parses defaults and codecs.

## Bare conversion and parsing

Apps that own registration can use the helpers independently:

```dart
server.registerTool(
  'search',
  inputSchema: searchInput.toMcpToolInputSchema(),
  callback: (args, extra) {
    final parsed = parseMcpToolArguments(searchInput, args, debugName: 'search');
    if (parsed case Fail(:final error)) {
      return ackValidationErrorToCallToolResult(error, toolName: 'search');
    }
    return CallToolResult(
      content: [TextContent(text: '${parsed.getOrThrow()}')],
    );
  },
);
```

`describeAckValidationError(error)` returns leaf JSON Pointer paths and messages.
The default tool error looks like:

```text
Invalid arguments for tool 'search':
#/query: Query must contain non-whitespace characters.
```

The helpers do not append input values, error causes, or stack traces.
Cause-backed messages (for example a codec throwing `FormatException`) become
`Argument validation failed.` because exception text can contain input data.
Other messages from ACK and your refinements are preserved verbatim and may
contain values; use safe custom messages or `onInvalidArguments` when inputs
are sensitive. Pass `onInvalidArguments`
to either registration helper to customize ACK failures. It receives the full
`SchemaError`; its returned `CallToolResult` is used unchanged.

## Advertised schema vs runtime validation

`mcp_dart` validates the advertised schema **before** invoking the ACK wrapper.
ACK then applies defaults, codecs, and refinements. An ACK failure returns
`isError: true`, skips the application callback, and leaves the session usable.
It does not throw `McpError`. A parsed null is also rejected by the wrapper.

| Behavior | Advertised schema | Runtime |
| --- | --- | --- |
| Optional default | `default` annotation; field may be omitted | ACK fills the value during parse |
| Refinement | Predicate is not exported | ACK runs the predicate |
| Codec / transform | Boundary shape and `x-transformed` metadata | ACK produces typed values, e.g. `DateTime` |
| Integer | JSON Schema integer semantics | `2.0` becomes `int 2`; `2.5` fails |
| Structural failure | Rejected by `mcp_dart` | ACK and custom invalid handler are not reached |

Structural failures produce an error tool result on MCP 2025-11-25 and
2026-07-28. MCP 2025-06-18 reports JSON-RPC `invalidParams` instead. This is
`mcp_dart` behavior; ACK-only failures produce tool results in all tested modes.

### JSON Schema dialect

ACK renders Draft-7 keywords without a `$schema` declaration. `mcp_dart` uses
2020-12 when that declaration is absent. The adapter does not stamp `$schema`
or strip extensions: the tested ACK keyword subset works in both dialects.
Recursive `definitions` and local `$ref` are retained, and annotated references
are wrapped by ACK in `allOf`. Schema maps round-trip exactly; JSON object key
order may change when `mcp_dart` serializes them.

Tests pin the supported keyword set: `type`, `properties`, `required`,
`additionalProperties`, `minimum`, `maximum`, `exclusiveMinimum`,
`exclusiveMaximum`, `multipleOf`, `minLength`, `maxLength`, `pattern`, `format`,
`enum`, `const`, `items`, `minItems`, `maxItems`, `uniqueItems`, `anyOf`, `oneOf`,
`allOf`, `$ref`, `definitions`, `title`, `description`, `default`, and `x-*`.
New emitted keywords require revisiting this dialect assumption.

## Supported versions

| Component | Supported / exercised |
| --- | --- |
| Dart | `>=3.9.0 <4.0.0` |
| ACK | `^1.2.0` |
| mcp_dart | `^2.4.2` (tests resolved against 2.4.2) |
| MCP stable discovery | `2026-07-28` |
| MCP initialization | `2025-11-25`, `2025-06-18` |

## Limitations

| Input / feature | Support |
| --- | --- |
| Plain object root (`type: object`) | Supported, including empty objects |
| Nullable or discriminated root | Rejected at registration; renders as composition (`anyOf` in ACK 1.2) |
| Primitive, list, or other composition root | Rejected at registration |
| Nullable, union, discriminated, recursive, or codec **fields** | Supported inside an object |
| Output schemas | Out of scope |
| Transport and session controls | Use `mcp_dart` directly |

## Runnable example

From the repository root:

```sh
dart run packages/ack_mcp_dart/example/example.dart
```

The stdio server provides `search` and an empty-object `validate` tool. Calling
`search` with `{"query":"dart"}` returns a limit of `5`. Calling it with
`{"query":" "}` returns an ACK refinement error; a limit of `0` is rejected by
MCP's structural validator. `validate` accepts `{}` or omitted arguments.
