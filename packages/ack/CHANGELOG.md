## Unreleased

### Features

* **Codecs**: Add `Ack.codec(...)` and `CodecSchema<I, O>` for bidirectional
  transformations between a boundary type and a runtime type. Mirrors Zod 4.1's
  `z.codec`. New `safeEncode` / `encode` surface on every `AckSchema`.
* **Codec recipes**: `Ack.codecs.*` catalogue ports Zod's "Useful codecs" —
  `isoStringToDateTime`, `epochMillisToDateTime`, `stringToUri`,
  `intMillisToDuration`, `stringToInt`, `stringToDouble`, `stringToBigInt`, and
  `json<T>(schema)`.
* **Custom schemas**: `Ack.custom<T>()` validates an arbitrary runtime type.
  Recommended as the output side of a codec for non-JSON runtime values.
* **Top-level shortcuts**: `Ack.encode(schema, v)` / `Ack.decode(schema, v)` /
  `Ack.safeEncode` / `Ack.safeDecode` mirror `z.encode` / `z.decode`.
* **Codec inverse**: `CodecSchema.inverse()` swaps input/output and
  decode/encode, mirroring `z.invertCodec`.
* **Encode dispatch on unions**: `AnyOfSchema` and `DiscriminatedObjectSchema`
  recurse correctly during encode.

### Behavior changes

* `ObjectSchema.encodeValue` now rejects an explicit `null` for an optional
  non-nullable field with a `SchemaEncodeError` instead of silently dropping
  the key. Nullable fields are unaffected.
* Encoding a schema graph that contains a unidirectional `.transform(...)` —
  including `Ack.datetime()`, `Ack.uri()`, `Ack.duration()`, `.trim()`,
  `.toLowerCase()`, `.toUpperCase()` — fails with a new
  `SchemaUnidirectionalEncodeError` (subclass of `SchemaEncodeError`). The
  dartdoc on each helper now points at the round-trippable `Ack.codecs.*`
  recipe.
* `CodecSchema` no longer exposes `decoder` / `encoder` as constructor
  parameters or `copyWith` keys — the closures are now passed in as `decode`
  and `encode` (matching the public `Ack.codec(...)` factory). This is a
  pre-release rename that affects only direct `CodecSchema(...)` callers;
  user code that goes through `Ack.codec(...)` is unaffected.
* `SchemaError` is now a `sealed` class hierarchy. Callers can use Dart 3
  exhaustive switch patterns over the seven concrete subclasses. External
  subclassing of `SchemaError` is no longer supported.

### Improvements

* `CodecSchema.safeEncode` / `encode` are typed `SchemaResult<I>` / `I?`
  instead of `Object`-typed.
* `CodecSchema.toJsonSchema` encodes the default through the codec so it lands
  in the boundary form. Codec-level constraints typed against the runtime side
  are no longer merged into the input JSON tree.
* `CustomSchema.toJsonSchema` no longer serializes runtime-typed defaults.

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