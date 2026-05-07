## Unreleased

### Added

* **Bidirectional codecs**: `Ack.codec<I, O>(...)` for explicit bidirectional conversion between a boundary type `I` and a runtime type `O`.
* **Runtime instance schema**: `Ack.instance<T>()` validates `value is T` for use as the runtime side of a codec or as a standalone runtime type guard.
* **Encode methods**: `encode(...)` and `safeEncode(...)` on every `AckSchema`. Encode is the inverse of parse — it converts a runtime value back into the boundary representation the schema validates as input.
* **`SchemaEncodeError`**: new error type raised when an encode operation fails (type mismatch, missing required field, one-way `.transform`, encode closure throw, etc.).

### Changed

* **`.transform(fn)`** now returns a `CodecSchema<T, R>` (one-way: `decoder = fn`, `encoder = null`). Calling `encode(...)` on a transformed schema fails with `SchemaEncodeError` whose message points at `Ack.codec(...)`.
* **Transformers no longer receive `null`.** On nullable schemas, `null` short-circuits to `null` without invoking the decoder. Previously `Ack.string().nullable().transform((v) => v.toUpperCase()).parse(null)` would call the transformer with `null`; it now returns `null` directly.
* **Built-in transforms are now bidirectional codecs.** `Ack.date()`, `Ack.datetime()`, `Ack.uri()`, and `Ack.duration()` round-trip cleanly through `parse` and `encode`. Boundary forms: `YYYY-MM-DD` for `date()`, UTC ISO-8601 for `datetime()`, `Uri.toString()` for `uri()`, milliseconds for `duration()`.
* **`EnumSchema.encode(...)`** emits the enum's `.name` (string) so JSON round-trips are stable.
* **Primitive schemas no longer coerce.** `Ack.integer().parse('42')`, `Ack.double().parse('3.14')`, `Ack.boolean().parse('true')`, and `Ack.string().parse(42)` now fail. Use `Ack.codec(...)` when boundary strings need conversion.
* **Defaults are wrapper-based.** Use `schema.withDefault(value)` instead of constructor/copyWith `defaultValue` arguments.
* **Codec encode is strictly typed.** `encode(value)` validates `value` against the runtime side of the codec without primitive coercion.
* `TransformedSchema` is now an internal `CodecSchema<I, O>` — schemas previously typed `TransformedSchema<I, O>` are now `CodecSchema<I, O>`.

### Deprecated

* `TransformedSchema<I, O>` is now a `@Deprecated` typedef alias for `CodecSchema<I, O>`. **Type annotations** like `TransformedSchema<String, DateTime>` continue to work, but the class's previous positional constructor `TransformedSchema(schema, transformer)` and the fields `.schema` / `.transformer` are no longer available — migrate to `CodecSchema(inputSchema: ..., outputSchema: ..., decoder: ..., encoder: ...)` and `.inputSchema` / `.decoder` / `.outputSchema` / `.encoder`. The alias will be removed in a future release.

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
