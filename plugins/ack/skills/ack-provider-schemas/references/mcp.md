# MCP tools with ack_mcp_dart

Source: https://github.com/btwld/ack/blob/main/packages/ack_mcp_dart/README.md (verified against `ack_mcp_dart` 2.0.0-beta.3 and `mcp_dart` 2.4.x)

```bash
dart pub add ack:^2.0.0-beta.3 ack_mcp_dart:^2.0.0-beta.3 mcp_dart
```

## Input-only tool: `registerAckTool`

```dart
import 'package:ack/ack.dart';
import 'package:ack_mcp_dart/ack_mcp_dart.dart';
import 'package:mcp_dart/mcp_dart.dart';

final searchInput = Ack.object({
  'query': Ack.string().minLength(1).refine(
    (q) => q.trim().isNotEmpty,
    message: 'Query must contain non-whitespace characters.',
  ),
  'limit': Ack.integer().min(1).max(100).optional().withDefault(5),
});

void registerSearch(McpServer server) {
  server.registerAckTool(
    'search',
    description: 'Search documents',
    input: searchInput, // or Search.schema for a typed `args`
    callback: (args, extra) => CallToolResult(
      content: [TextContent(text: 'limit ${args['limit']}')],
    ),
  );
}
```

- It advertises `input.toMcpToolInputSchema()` and runs `safeParse` before your callback. The callback receives parsed values (defaults filled, codecs decoded, typed model when `input` is `Model.schema`).
- What comes back in each case:
  - **Ack failure:** `CallToolResult(isError: true)` with text `Invalid arguments for tool 'search':` followed by one `#/path: message` line per error. The callback is skipped and the session stays usable.
  - **Exception text:** a failure message built from an exception (for example a codec throwing `FormatException`) becomes `Argument validation failed.`. Other messages, including your refine messages, are passed through as written, so keep them free of input values.
  - **Custom error result:** `onInvalidArguments: (SchemaError e) => CallToolResult(...)` replaces the default.
- `mcp_dart` checks the advertised schema **first**. A structural failure (say `limit: 0` against `minimum: 1`) never reaches Ack or `onInvalidArguments`. Test Ack-only rules (refines, codecs, defaults) through Ack, and structural rules through the client.
- The root has to render `type: object`. A discriminated, nullable, primitive, or list root throws `ArgumentError` at registration. Unions, nullables, and codecs work as **fields**.
- `registerAckTool` has no output-schema parameter.

## Tool with an output schema: `registerTool` and the helpers

```dart
// needs: import 'dart:convert';
final reportInput = Ack.object({'city': Ack.string().minLength(2)});
final reportOutput = Ack.object({'city': Ack.string(), 'tempC': Ack.double()});

server.registerTool(
  'report',
  description: 'Current weather',
  inputSchema: reportInput.toMcpToolInputSchema(),
  outputSchema: reportOutput.toMcpToolInputSchema(), // same JsonObject type; enforces an object root
  callback: (args, extra) {
    final parsed = parseMcpToolArguments(reportInput, args, debugName: 'report');
    if (parsed case Fail(:final error)) {
      return ackValidationErrorToCallToolResult(error, toolName: 'report');
    }
    final input = parsed.getOrThrow()!; // the parsed value, not the raw args
    // encode validates the output and returns Map<String, Object?>, which structuredContent accepts as is.
    final json = reportOutput.encode({'city': input['city'], 'tempC': 21.5})!;
    return CallToolResult(
      content: [TextContent(text: jsonEncode(json))],
      structuredContent: json,
    );
  },
);
```

`mcp_dart` requires `structuredContent` once a tool declares `outputSchema`, and checks it structurally. Ack's `encode` is what enforces the rest.

## Client side

Check results with the same schema: `reportOutput.safeParse(result.structuredContent)` (or `Model.schema.safeParse`). Check `result.isError` first.

## Testing without a network

Wire a server and a client in memory with two crossed streams. Use `McpServer` and `McpClient`; the `Client` / `ClientOptions` typedefs are deprecated.

```dart
// needs: import 'dart:async';
final server = McpServer(const Implementation(name: 'weather', version: '1.0.0'));
registerSearch(server);
final client = McpClient(const Implementation(name: 'test', version: '1.0.0'));

final toServer = StreamController<List<int>>.broadcast();
final toClient = StreamController<List<int>>.broadcast();
await server.connect(IOStreamTransport(stream: toServer.stream, sink: toClient.sink));
await client.connect(IOStreamTransport(stream: toClient.stream, sink: toServer.sink));

final result = await client.callTool(
  CallToolRequest(name: 'search', arguments: {'query': 'dart'}),
);
// ... assertions ...
await client.close();
await server.close();
```

Assert:

- `{"query":"dart"}` comes back with the default limit 5;
- `{"query":" "}` has `isError == true` with the refine message;
- registering a discriminated root throws `ArgumentError`;
- `client.listTools()` shows the output schema;
- `structuredContent` parses with the output schema.

## Dialect note

Ack emits Draft-7 keywords without `$schema`, and `mcp_dart` assumes 2020-12. The keywords Ack emits mean the same in both, so don't stamp `$schema` or rewrite the map. If a particular MCP host rejects a shape, transform a **copy** of the exported map for that host and keep validating with the Ack schema.
