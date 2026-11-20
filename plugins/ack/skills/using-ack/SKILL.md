---
name: using-ack
description: Ack 2.0 runtime schemas for Dart. Use when validating JSON or maps with package:ack (Ack.object, Ack.string, parse/safeParse, SchemaError), choosing optional/nullable/withDefault, writing refine or codecs, exporting or importing JSON Schema, installing or pinning ack, or migrating Ack 1.x code (@AckModel, @AckInfer, ack_annotations, .ack.dart parts) to 2.0.
---

# Using Ack

> **Ack 2.0 card.** Pin `ack: ^2.0.0-beta.3` and the same pin for every `ack_*` package; a bare `dart pub add ack` selects the stable release. Dart >=3.13, Flutter >=3.47. Use the [repository API index](https://github.com/btwld/ack/blob/main/llms.txt) and check that examples match your installed version. Untrusted JSON goes through `safeParse`; constructors and schema exports do not run validation. Native `toJsonSchema()` emits Draft-7.

## 1. Check the installed version first

Run `dart pub deps --style=compact | grep -E '^- ack'` (or read `pubspec.lock`).

- **Already 2.0.0-beta.3:** continue.
- **No ack yet:** `dart pub add ack:^2.0.0-beta.3` (`flutter pub add` in a Flutter app).
- **On 1.x or an earlier 2.0 prerelease:** ask the user to confirm the move to `2.0.0-beta.3` and its SDK requirements before changing dependencies or source. A request like “update to the latest Ack” is not approval to switch from stable to a major prerelease. Wait for their answer; after they confirm, follow [references/migrate-1x.md](references/migrate-1x.md).

Done when `dart pub deps` shows `ack 2.0.0-beta.3`, or the user declined the upgrade and you are working within their version.

## 2. Build the schema

`Ack` is a factory; every schema is `AckSchema<Boundary, Runtime>`: the wire value in, the Dart value out.

- **Scalars:** `Ack.string()`, `integer()`, `double()`, `number()`, `boolean()`, `literal(v)`, `enumString([...])`, `enumValues(MyEnum.values)`. Primitives are strict: `'42'` is not an integer. `integer()` accepts a lossless `42.0` and returns `42`; `double()` accepts a JSON integer (`9` becomes `9.0`).
- **Containers:** `Ack.object({...})` rejects unknown keys by default (`additionalProperties: true` to allow them); `Ack.list(item)`; `Ack.map(valueSchema)` for arbitrary string keys; `Ack.any()` for any non-null JSON value; `Ack.map(Ack.any().nullable())` for an object of anything.
- **Constraints** chain on the schema: strings `minLength`, `maxLength`, `matches` (unanchored, so write `^...$`), `email`, `url`, `uuid`, `date`, `datetime`, plus the two-way normalizers `trim`, `toLowerCase`; numbers `min`, `max`, `greaterThan`, `lessThan`, `positive`, `negative`, `multipleOf`; lists `minItems`, `maxItems`, `unique`. `.describe('...')` sets the exported description.
- **Composition:** `Ack.anyOf([...])` (first matching branch wins); `Ack.discriminated(discriminatorKey: 'type', schemas: {'a': objA, 'b': objB})`, where the union owns the key and branches omit it; `Ack.lazy('Name', () => schema)` for recursion; `obj.extend({...})`, `pick`, `omit`, `partial()`.
- **Custom rules:** `.refine((v) => ..., message: '...')` for a rule across fields; it runs after the shape passes. Use `.constrain(...)` for a reusable `Constraint`.

### Presence rules

| Schema | Key omitted | Present `null` |
|---|---|---|
| `s` | fails | fails |
| `s.optional()` | ok, key stays absent | fails |
| `s.nullable()` | fails | ok |
| `s.optional().nullable()` | ok | ok |
| `s.withDefault(v)` | becomes `v` | fails |
| `s.nullable().withDefault(v)` | becomes `v` | becomes `v` |

`withDefault(v)` without `nullable()` rejects an explicit `null` on parse; encoding writes `v` for a missing or `null` value either way. To keep omitted versus explicit `null` on a raw map, use `map.containsKey`. Generated classes use `JsonMaybe<T>` instead (`.absent()`, `.value(x)`, `.value(null)`).

`Ack.list(item)` throws `ArgumentError` when `item` accepts null. Make the list nullable, not its items.

### Codecs: values that are not JSON

`Ack.datetime()` (ISO string to UTC `DateTime`), `Ack.date()` (`YYYY-MM-DD` to local midnight, `isUtc` false), `Ack.uri()`, `Ack.duration()` (ms `int`), and custom `Ack.string().codec<T>(decode: ..., encode: ...)` decode on parse and encode back. `.transform(fn)` only goes one way: encoding it fails, and generated models reject it. Put the wire rules on the input schema, before `.codec(...)`, so they export. `min`/`max` on `Ack.datetime()` / `Ack.date()` are enforced by `safeParse` only: the export drops them, so state the bound in `.describe(...)` for anyone reading the JSON Schema. A decoder that hits bad data throws an `Exception`; a thrown `Error` is treated as a bug and propagates out of `safeParse`.

## 3. Parse at the boundary

```dart
final result = schema.safeParse(jsonDecode(body));
switch (result) {
  case Ok(:final value): use(value!); // value is Runtime?
  case Fail(:final error):
    for (final leaf in leafErrors(error)) log(leaf.path, leaf.message); // #/address/city
}

Iterable<SchemaError> leafErrors(SchemaError error) sync* {
  switch (error) {
    case SchemaNestedError(:final errors):
      for (final child in errors) yield* leafErrors(child);
    default:
      yield error;
  }
}
```

A failing field comes back wrapped: the top error is a `SchemaNestedError` at `#`, and the field errors (`#/address/city`, `#/tags/1`, `#/secret` for an unknown key) sit in `.errors`. Report leaf paths and messages. A leaf message can quote that field's value (`got "2026-13-45"`), so drop it for sensitive fields. The top error's `toString()` (and the `AckException` from `parse`) echoes the whole input, so keep it out of logs and user-facing text.

- `parse` throws `AckException`. `safeParse` returns the sealed `SchemaResult<T>` (one type argument, the `Runtime` type): `isOk`, `getOrThrow()`, `getOrNull()`, `getError()` (throws on success), `match(onOk:, onFail:)`. `Ok.value`, raw `AckSchema.parse`, and `getOrThrow()` are typed `Runtime?`, hence the `!`.
- `SchemaError` is sealed: `TypeMismatchError`, `SchemaConstraintsError` (`.constraints`), `SchemaNestedError` (`.errors`, one child per failing field), `SchemaValidationError` (a `refine` failure, at the path of the refined schema), `SchemaTransformError` (`.cause`, a codec decoder threw; a malformed `Ack.date()` / `Ack.datetime()` string fails its format check first, as a `SchemaConstraintsError`), `SchemaEncodeError` (`.kind`). Switch on them exhaustively.
- Validate outgoing data with `encode` / `safeEncode`.

## 4. Branches

- **Exporting a schema** (`toJsonSchema()`, export warnings) or **importing** one (`Ack.fromJsonSchema`): read [references/json-schema.md](references/json-schema.md).
- **Migrating 1.x code** or meeting an annotation or API that is not in this file: read [references/migrate-1x.md](references/migrate-1x.md) before writing it.

## Done when

- `dart analyze` reports no issues and no deprecation warnings from ack.
- Every schema you wrote or changed has a test that parses one valid payload and, for each rule (constraint, presence choice, refine, codec), one payload that breaks it and asserts the expected leaf path in `leafErrors(error)` (the top `error.path` is `#` for any field failure). Make sure each failing test actually fails before you count it.
- If you exported a schema, you read every warning in its schema model (walk the tree, see [references/json-schema.md](references/json-schema.md)) and acted on each one.

Siblings: `build-data-classes-with-ack` (generated `@Schemable` models), `ack-provider-schemas` (schemas for MCP and Gemini).
