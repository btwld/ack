## Unreleased

### Added

* Add strict `Ack.fromJsonSchema()` returning `AckSchema<Object, Object>` for a
  documented draft 2020-12 subset. The runtime implementation is internal;
  failures expose immutable diagnostics through `JsonSchemaImportException`.
  Supports supplied reference bundles, recursion, JSON-specific null/presence
  semantics, and exact `allOf`, `oneOf`, and `not` composition. Exports are
  self-contained and reflect only enforced assertions.
* Verify imports against 600 pinned upstream JSON Schema cases and the A2UI
  v0.9 protocol bundle. Support catalog JSON Pointer targets outside `$defs`,
  normalize enums for valid Draft-7 output, and report unsupported assertions
  only when they are reachable from the imported root.

### Fixed

* Reject conflicting bundle documents with the same resolved retrieval URI,
  including conflicting copies of the root document.
* Accept the draft 2020-12 meta-schema URI with an empty fragment (`#`).
* Reject generated-definition name collisions between imported schemas and
  `Ack.lazy()` targets instead of exporting a reference to the wrong schema.
* Report duplicate anchors at the conflicting `$anchor` keyword rather than at
  the enclosing resource identifier.
* Correct the executable reference-bundle example in the JSON Schema guide.
* Preserve imported JSON Schema definitions without adding an import-specific
  variant to the sealed `AckSchemaModel` hierarchy. Imported roots use the
  existing composition and reference models.

## 1.5.0

### Added

* Add `Ack.map(valueSchema)` and `MapSchema` for JSON objects with arbitrary
  string keys whose values all match one schema. Values may be `null` only
  when the value schema is nullable, so `Ack.map(Ack.any().nullable())` models
  a `JsonMap`. JSON Schema export emits `additionalProperties: <value schema>`.

### Changed

* `Ack.any()` parsing now returns a detached, recursively unmodifiable
  snapshot of the input instead of the caller's own object, matching the
  unmodifiable results of `Ack.object()` and `Ack.list()`. Encoding still
  returns the validated runtime value unchanged.

## 1.4.0

### Changed

* Align with the coordinated Ack 1.4 release adding class-first field
  annotations; this package has no runtime or public API changes from 1.3.0.

## 1.3.0

### Changed

* Align with the coordinated Ack 1.3 release introducing `ack_mcp_dart`;
  this package has no runtime or public API changes from 1.2.0.

## 1.2.0

### Added

* Add `AckModelAdapter` as the non-nullable runtime bridge used by generated
  immutable Ack models. The adapter keeps schema parse/encode around model
  mapping so public JSON methods remain schema-backed.
* Add `Ack.preserveBoundary`, which validates through a schema while returning
  the original wire value instead of values decoded by nested codecs.
* Add `deepUnmodifiableJsonMap`, which creates detached, recursively
  unmodifiable snapshots of nested maps, lists, and sets without validation.

### Fixed

* Preserve propagated `Error` objects during validation instead of converting
  programming defects into recoverable schema failures.
* Compare collection contents independently of growable or unmodifiable wrapper
  implementations. Numerically equal `int` and `double` values now compare and
  hash equally on native and web runtimes; other scalar types remain distinct.
* Keep deep map-key equality consistent with `deepHashCode`, and apply JSON
  Schema Draft 7 numeric equality to `uniqueItems` (including nested values).
* Reject the native minimum integer from `.safe()` without overflowing `abs()`.

### Changed

* Export `deepEquals`, `deepHashCode`, and `deepUnmodifiableJsonMap` for
  generated Ack data classes and class-first constructors.
* `Ack.integer()` accepts losslessly representable numbers with no fractional
  part and normalizes them to `int`. `Ack.double()` accepts exactly
  representable numeric inputs and normalizes them to `double`. Numeric
  `anyOf` branches can therefore overlap; the first matching branch determines
  the runtime representation. Use `Ack.number()` to preserve the input's
  numeric representation and `.safe()` to require JavaScript's portable
  integer range.
* Raise the minimum Dart SDK to 3.9.

## 1.1.0

### Fixed

* Keep `safeParse` non-throwing when refinements or constraints throw
  recoverable `Exception`s, while preserving `Error` values such as
  `StateError` so programming defects are not masked as validation failures.
* Decode RFC 3339 lowercase `t`/`z` separators in `Ack.datetime()`, which its
  own string validation already accepts (previously they failed at the decode
  step with a misleading "Codec decode failed" message).
* Bound direct, indirect, wrapper-mediated, and fluent-copy lazy-schema alias
  recursion (previously unbounded and prone to stack overflow).
* Snapshot factory collections so a caller mutating the passed list or map can no
  longer corrupt a constructed schema.
* Correct behavior-based schema and deep-collection equality.

### Behavior changes

No public API changed (verified with `dart_apitool` against 1.0.1); the following
now reject inputs that previously passed or misbehaved silently.

* Validate numeric `multipleOf`, IPv6, and RFC 3339 date-time values strictly.
  Announced leap seconds are preserved by `Ack.string().datetime()` but rejected
  by `Ack.datetime()`, where Dart cannot represent them. *(migration: some
  previously-accepted strings and numbers now fail validation.)*
* Reject invalid constraint configuration at construction — negative
  lengths/item counts, non-finite numeric bounds, `min > max` ranges,
  `multipleOf <= 0`, empty unions, empty or duplicate enum inputs, and unions
  that can yield nullable list items — all throw `ArgumentError`. *(migration:
  fix the schema definition; put nullability on the list via
  `Ack.list(item).nullable()`.)*
* `toJsonSchema()` merges conflicting duplicate keywords into `allOf` and emits
  `min/maxItems` and `min/maxProperties` for exact counts. *(migration: refresh
  snapshot or golden tests of exported schemas.)*
* `parse()` throws `AckException` — instead of the raw callback error — when a
  constraint or refinement throws.

## 1.0.1

* See [release notes](https://github.com/btwld/ack/releases/tag/v1.0.1) for details.

## 1.0.0

* See [release notes](https://github.com/btwld/ack/releases/tag/v1.0.0) for details.

## 1.0.0-beta.12

### Breaking Changes

* `DoubleSchema` and `NumberSchema` now reject non-finite values (`NaN`,
  `Infinity`, `-Infinity`) during runtime validation by default, aligning
  numeric schemas with JSON-safe values.
* Remove the retired JSON Schema DTO converter APIs.
* Replace the interim JSON Schema model kind API with sealed
  `AckSchemaModel` variants and canonical `AckSchema.toSchemaModel()`
  adapter conversion.

### Added

* `Ack.enumCodec<T extends Enum>(List<T> values)` returns a
  `CodecSchema<String, T>` wrapping `EnumSchema<T>`. Use this when downstream
  code expects every value-shape to be a `CodecSchema` (e.g. a registry of
  codecs). Decode/encode are identity since `EnumSchema` already maps between
  `T` and the enum's `.name`.
* `NumberSchemaExtensions` adds fluent numeric constraints to `Ack.number()`:
  `.min`, `.max`, `.greaterThan`, `.lessThan`, `.positive`, `.negative`, and
  `.multipleOf`.

### Changed

* Project discriminated schemas through union-owned discriminator branches.
* Preserve defaults, const values, extension keywords, transformed metadata,
  composition, and JSON Schema constraints through the schema model boundary.

### Migration

* Re-run tests for code paths that parse or encode `double`/`num` values. If a
  boundary must accept `NaN` or infinities, model that value outside the JSON
  numeric schema path before validation.

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

* **Format metadata**: Reduced built-in format guidance to 7 core formats (`email`, `uri`, `uuid`, `date`, `dateTime`, `ipv4`, `ipv6`). Custom format strings are still supported via the `format` property.
* **`withDescription` deprecated**: Use `describe()` instead for setting schema descriptions.

### Bug Fixes

* **JSON Schema output**: Now correctly adds null branch to `anyOf`/`oneOf` compositions when `nullable: true`, producing valid JSON Schema Draft-07 format.

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
