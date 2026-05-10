## 1.0.0-beta.12

### Features

- **Bidirectional codecs.** New `CodecSchema<I, O>` is the core
  abstraction for explicit boundary↔runtime conversion. Use
  `Ack.codec(input:, output:, decoder:, encoder:)` for bidirectional
  codecs.
- **Encode pipeline.** Every schema now exposes `encode(value)` (throws
  on failure) and `safeEncode(value)` (never throws, returns
  `SchemaResult<Object>`). Encoding traverses runtime values back to
  their boundary form recursively through object, list, anyOf, and
  discriminated schemas.
- **`Ack.instance<T>()`** — a runtime-side schema for non-JSON Dart
  types (e.g. `DateTime`, `Uri`, user classes). Most useful as the
  `output` of a codec.
- **`DefaultSchema<T>`** — explicit parse-only default wrapper.
  `schema.withDefault(value)` now returns `DefaultSchema<T>(inner: schema,
  defaultValue: value)`. Defaults are synthesized only on parse and are
  never injected on encode (per requirements §5.5).
- **Built-in codecs.** `Ack.date()`, `Ack.datetime()`, `Ack.uri()`, and
  `Ack.duration()` are now real bidirectional codecs with explicit
  encode policies (see Breaking Changes).
- **Discriminator unwrap.** `unwrapDiscriminatedBranchSchema` now
  follows `CodecSchema.inputSchema` and `DefaultSchema.inner`, so a
  discriminated branch can be wrapped in either layer and still
  resolve to the underlying object schema.

### Breaking Changes

- `Ack.codec(...)` requires both `decoder` and `encoder`. The factory
  is bidirectional by definition; for one-way decoding use
  `schema.transform(...)` (or construct `CodecSchema` directly with
  `encoder: null` for advanced cases).
- `.transform<R>(...)` now returns a one-way `CodecSchema<T, R>`.
  Encoding through a transformed schema fails with
  `SchemaEncodeError.oneWayTransform`; the message points at
  `Ack.codec` for bidirectional behaviour.
- `TransformedSchema<I, O>` is now a deprecated `typedef` alias for
  `CodecSchema<I, O>`. The legacy positional constructor
  (`TransformedSchema(schema, transformer, ...)`) and the `.schema` /
  `.transformer` fields are removed; use `.inputSchema` and `.decoder`
  on `CodecSchema`.
- `.withDefault(...)` now returns `DefaultSchema<T>` rather than a
  type-specific schema. Apply type-specific fluent methods **before**
  `.withDefault(...)`:
  ```dart
  Ack.string().minLength(3).withDefault('guest'); // ok
  // Ack.string().withDefault('guest').minLength(3); // won't type-check
  ```
- `Ack.double()` is strict. `Ack.double().parse(42)` (int) and
  `Ack.double().parse('42.0')` (string) now fail. `Ack.integer()`,
  `Ack.boolean()`, and `Ack.string()` retain their existing legacy
  primitive coercion in this beta — the broader strictness sweep is
  scheduled for a follow-up release.
- `Ack.date()` rejects UTC `DateTime` and any value with non-zero
  hour/minute/second/millisecond/microsecond. Date is a calendar date,
  not an instant — for instants/timestamps use `Ack.datetime()`.
- `Ack.datetime()` rejects non-UTC `DateTime`. The encode error
  message advises calling `value.toUtc()` to canonicalize.
- `Ack.uri()` rejects URIs without scheme **and** authority on encode
  (matching the existing parse rule).
- `Ack.duration()` rejects sub-millisecond durations on encode rather
  than silently truncating microseconds.

### Decisions resolved

The full decision list is in `docs/plans/codec-open-questions.md`
(every entry now has a recorded `Decision:` line). Highlights:

- A1: `Ack.double()` strict parse + encode.
- A2 (a): `Ack.date()` is local midnight DateTime; rejects UTC.
- A3 (b): `Ack.datetime()` is UTC instant; rejects non-UTC.
- A4: enum parse keeps legacy integer-index input; encode requires the
  enum value and emits `.name`.
- A5: AnyOf encode chooses the first branch whose **full** encode
  pipeline succeeds (validate + encode end-to-end).
- A6: ObjectSchema with `additionalProperties: true` passes unknown
  keys through as-is.
- A7: defaults are parse-only — `DefaultSchema(nullableInner).encode(
  null)` returns `null` via the inner nullability, not the default.
- B1: `CodecSchema.toJsonSchema` emits both `x-ack-codec` (canonical)
  and `x-transformed` (legacy compat) for one beta cycle.
- B3: codec equality ignores decoder/encoder closure identity but
  distinguishes one-way from bidirectional codecs.
- B4 (a): no `Ack.intFromString()` / `Ack.doubleFromString()` /
  `Ack.boolFromString()`. Use tested migration recipes in
  `packages/ack/test/migration_recipes_test.dart` and `Ack.codec(...)`.

### Migration notes

- **Custom string→int/double/bool conversion:** there is no
  `Ack.intFromString()` API. Build a codec with `Ack.codec(...)`. See
  the runnable recipes in `packages/ack/test/migration_recipes_test.dart`.
- **Defaults:** `schema.withDefault(value)` is the preferred API.
  `copyWith(defaultValue: ...)` continues to work for one beta cycle
  but is soft-deprecated.
- **Existing transforms** (`schema.transform<R>(...)`) keep parsing as
  before. They now fail on encode — wrap with `Ack.codec(...)` if
  you need bidirectional behaviour.

## 1.0.0-beta.11

* See [release notes](https://github.com/btwld/ack/releases/tag/v1.0.0-beta.11) for details.

## 1.0.0-beta.10

* See [release notes](https://github.com/btwld/ack/releases/tag/v1.0.0-beta.10) for details.

## 1.0.0-beta.9

* See [release notes](https://github.com/btwld/ack/releases/tag/v1.0.0-beta.9) for details.

## 1.0.0-beta.8

* See [release notes](https://github.com/btwld/ack/releases/tag/v1.0.0-beta.8) for details.

## 1.0.0-beta.7

* See [release notes](https://github.com/btwld/ack/releases/tag/v1.0.0-beta.7) for details.

## 1.0.0-beta.6

### Features

* **Discriminated unions**: Enforce Map-returning child schemas in discriminated unions (#67).
* **Schema mapping API**: Add `AckSchema.parseAs` and `AckSchema.safeParseAs` for validated-value mapping with consistent `SchemaTransformError` handling.

### Improvements

* **Schemas**: Centralize null/default handling and extract ObjectSchema helpers (#65).

### Bug Fixes

* **Schemas**: Fixes to schema correctness including transformed schema defaults and list unique items constraint (#50).

## 1.0.0-beta.5 (2026-01-14)

### Features

* **Equality**: Implement value-based equality for schemas and constraints (#63). All schema and constraint classes now properly implement `==` and `hashCode` for structural comparison.

### Improvements

* **Dependencies**: Updated `meta` and `test` dependencies to latest versions (#56).

## 1.0.0-beta.4 (2025-12-29)

### Breaking Changes

* **WellKnownFormat**: Reduced to 7 core formats (`email`, `uri`, `uuid`, `date`, `dateTime`, `ipv4`, `ipv6`). Removed formats: `hostname`, `idn_email`, `idn_hostname`, `uri_reference`, `uri_template`, `iri`, `iri_reference`, `time`, `duration`, `int32`, `int64`, `float`, `double`, `json_pointer`, `relative_json_pointer`, `regex`, `enum_`, `byte`, `binary`. Custom format strings are still supported via the `format` property.
* **`withDescription` deprecated**: Use `describe()` instead for setting schema descriptions.

### Bug Fixes

* **JsonSchema.toJson**: Now correctly adds null branch to `anyOf`/`oneOf` compositions when `nullable: true`, producing valid JSON Schema Draft-07 format.

### Improvements

* **DRY refactoring**: Consolidated duplicate primitive schema parsers into one.
* **Hardened schema type handling**: Improved map validation and schema type handling.
* **Consolidated JSON schema utilities**: Reduced duplication across JSON schema utilities.

## 1.0.0-beta.3 (2025-10-27)

* See [release notes](https://github.com/btwld/ack/releases/tag/v1.0.0-beta.3) for details.

## 1.0.0-beta.2 (2025-10-09)

* See [release notes](https://github.com/btwld/ack/releases/tag/v1.0.0-beta.2) for details.

## 1.0.0-beta.1 (2025-10-06)

* See [release notes](https://github.com/btwld/ack/releases/tag/v1.0.0-beta.1) for details.