---
name: ack-provider-schemas
description: Hand Ack 2.0 schemas to AI providers and validate what comes back. Use when exposing an MCP tool from Dart with ack_mcp_dart (registerAckTool, tool input or output schemas), requesting Gemini structured output through Firebase AI (ack_firebase_ai, responseJsonSchema), or building plain Gemini API function declarations (parametersJsonSchema) or responseJsonSchema from an Ack schema's toJsonSchema().
---

# Ack provider schemas

Before adding packages, follow [the Ack version check](../using-ack/SKILL.md#1-check-the-installed-version-first).

## The rule: the schema is a hint, `safeParse` is the gate

You send the provider a JSON Schema exported from an Ack schema. The provider uses it to **shape** what it generates or sends: tool arguments, a structured response. It enforces only part of it:

- Refinements, codec logic, and date ranges never reach the export.
- Providers silently ignore keywords they don't support. Gemini ignores `minLength`, `maxLength`, and `uniqueItems`, for example.
- A model or a remote client can still send anything.

So every payload coming in from a provider or client goes through `safeParse` on **the same Ack schema** you exported, before any of your code uses it. Treat a `Fail` as an expected outcome: return a tool error, retry, or report it. Never cast it away.

## Steps

1. **Pick the service and read its reference.** Read only the one that matches:
   - MCP tool (server or client, `ack_mcp_dart`): [references/mcp.md](references/mcp.md)
   - Gemini via Firebase AI in a Flutter app (`firebase_ai`, `ack_firebase_ai`): [references/gemini-firebase.md](references/gemini-firebase.md)
   - Gemini API over REST or another SDK, with function declarations or a response schema: [references/gemini-api.md](references/gemini-api.md)

   Done when you have read the matching reference.
2. **Shape the schema for the provider.** The root is an `Ack.object` (tools and function parameters require an object root, and a discriminated or nullable root exports as `anyOf`). Keep it focused, because schema size costs input tokens. Add `.describe(...)` or `/// @description` on fields the model has to fill in. A `@Schemable` class's `Model.schema` works anywhere a schema does. Done when `schema.toJsonSchema()['type'] == 'object'`, you have reviewed warnings from all [reachable model nodes](../using-ack/references/json-schema.md#export), and you have checked lazy targets separately for runtime rules missing from the export.
3. **Export it the way the reference says, and send it.** Use the adapter call or the `toJsonSchema()` map unchanged. Don't hand-edit the map to fit a provider unless the reference says to.
4. **Gate what comes back.** Decode the JSON, then call `schema.safeParse(decoded)` (for a generated class, use `Model.schema.safeParse`). Use the parsed value, never the raw map. On `Fail`, report `path: message` using [`leafErrors`](../using-ack/SKILL.md#3-parse-at-the-boundary). Never surface the top error's `toString()` or an `AckException`, which echo the whole payload. `ack_mcp_dart` already reports leaf lines.

## Done when

- A test stubs the provider or client (no network) and asserts that the request carries `schema.toJsonSchema()` (or the adapter's output) in the right field.
- A test feeds a payload that **matches the exported JSON Schema but breaks an Ack-only rule** (a refine, a `minLength` the provider ignores, a codec) and asserts that the gate rejects it. You watched that test fail before the gate existed.
- A valid stubbed payload parses to the typed value your code uses.
- `dart analyze` is clean, and the model id comes from the caller or config, not a literal in library code.

Adding a service means adding one file under `references/` and one line to step 1.

Siblings: `using-ack` (schemas, errors, JSON Schema export), `build-data-classes-with-ack` (`@Schemable` models to pass as `Model.schema`).
