## 2.0.0-alpha.2

### Fixed

* Honor explicit boundary-wrapper nullability consistently during parse and
  encode. Preserve non-null restrictions on wrappers and lazy references when
  exporting nullable primitives, unions, and imported JSON Schema resources.
* Validate discriminated codec output against its selected map branch or a
  matching typed runtime branch, including required fields and refinements,
  without decoding runtime values again or adding encode callback passes.
* Reject duration millisecond inputs that overflow the platform's `Duration`
  representation instead of silently decoding to a different duration.
* Respect custom JSON Schema vocabularies during import and export: keep
  inactive keywords inert, preserve annotation payloads and explicit format
  assertions, and apply fluent nullability under an active assertion dialect.
  Identical caller-supplied standard meta-schemas can replace offline fallbacks
  without relaxing duplicate-ID checks between caller resources.

## 2.0.0-alpha.1

### Breaking

* Remove legacy 1.x generator annotations (`@AckType`, `@AckInfer`, `@AckModel`,
  `@AckField`, `JsonKeyCaseStyle`, `AckFieldPresence`, and
  `@Schemable.generatedJson`). Use `@Schemable()` on both top-level schemas and
  hand-written classes/unions (`#188`, `#189`).
* Remove top-level presence annotations (`@Optional`, `@Required`, `@NotNull`),
  the 18 `@Deprecated` 1.x top-level constraint classes (`@Min`, `@Max`,
  `@MultipleOf`, `@Positive`, `@Negative`, `@MinLength`, `@MaxLength`,
  `@Matches`, `@NotEmpty`, `@Email`, `@Url`, `@Uuid`, `@Date`, `@DateTime`,
  `@Uri`, `@Ip`, `@Ipv4`, `@Ipv6`, `@MinItems`, `@MaxItems`, `@UniqueItems`), and
  `package:ack/format_annotations.dart` in favor of `@Validate.*` (`#191`).
* Remove `Ack.enumCodec` in favor of `Ack.enumValues` and remove unused
  `StandardSchemaV1` (`#129`).
* Seal `SchemaError` and `AckSchema` so pattern matching across all error and
  schema subtypes is exhaustive without a wildcard branch.
* Rethrow programmer `Error`s (`TypeError`, `StateError`, etc.) with their
  original stack trace during `CodecSchema` decode (`parse` / `safeParse`),
  matching `encode` / `safeEncode` (`#163`).
* `Ack.fromJsonSchema()` now defaults to `assertFormats: false` to match JSON
  Schema Draft 2020-12's default Core/Applicator/Validation vocabularies; pass
  `assertFormats: true` (or declare the `format-assertion` vocabulary in
  `$vocabulary`) to enforce format assertions (`#171`, `#186`).
* `schema.toJsonSchema()` and `schema.toSchemaModel()` now preserve imported
  Draft 2020-12 resources by default (`$defs`, `$dynamicRef`,
  `unevaluatedProperties`, `prefixItems`, etc.). Use `toJsonSchemaDraft7()` or
  `toSchemaModelDraft7()` for legacy Draft-07 `definitions` lowering (`#171`).

### Added

* Add unified `@Validate.*` presence and constraint annotation namespace
  (`final class Validate`, including `@Validate.optional()`,
  `@Validate.required()`, and `@Validate.notNull()`) exported from both
  `package:ack/ack.dart` and `package:ack/annotations.dart` (`#191`).
* Add `sealed class JsonMaybe<T>` (`JsonAbsent<T>`, `JsonValue<T>`) with
  `JsonMaybe.absent()`, `JsonMaybe.value(T? value)`, and `JsonMaybe.nullValue()`
  for PATCH tri-state presence (`#148`).
* Add `@Schemable(schemas: [...])` (supported on classes, sealed unions, and
  `library;` directives) and `@AckKey('...')` for custom schema registration and
  field wire-name overrides (`#185`, `#189`).
* Make `.trim()`, `.toLowerCase()`, and `.toUpperCase()` two-way normalizers
  directly on `StringSchema` that execute in declaration order alongside
  constraints during both `parse` and `encode`, preserve `StringSchema`
  chaining, and export as `type: 'string'` without `'x-transformed': true`.
* Support the complete JSON Schema Draft 2020-12 validation runtime in
  `Ack.fromJsonSchema()`, including `$dynamicRef`, `$dynamicAnchor`,
  `unevaluatedProperties`, `unevaluatedItems`, `prefixItems`,
  `dependentRequired`, `dependentSchemas`, `patternProperties`, `minContains`,
  `maxContains`, bundled offline 2020-12 meta-schemas, and the full Draft
  2020-12 format suite (`#171`, `#186`).

### Fixed

* Explicit Draft-7 export (`toJsonSchemaDraft7()` / `toSchemaModelDraft7()`)
  rejects unsupported Draft 2020-12 assertions rather than emitting keywords
  that Draft-7 validators ignore.
* Imported schema exports preserve JSON Pointer targets through retrieval URI
  aliases and opt-in format assertions in nested resources.
* Composed imports share identical identified resources, retain occurrence-level
  nullability and constraints (including source `allOf` when layering
  conflicting constraints), and reject conflicting resource definitions.

## 1.7.0

### Breaking

* Remove `ack_annotations`; annotations now ship in `ack`:
  * `package:ack/ack.dart` exports `@Schemable()` and core model annotations
    (`AckField`, `Optional`, `Required`, `NotNull`, `AckCaseStyle`,
    `AckUnknownPropertyPolicy`).
  * `package:ack/annotations.dart` exports model and constraint annotations
    (plus deprecated aliases).
  * `package:ack/format_annotations.dart` exports string format annotations.
* Rename `@Pattern` to `@Matches` (`Pattern` remains a deprecated alias in
  `package:ack/annotations.dart`).
* Remove the `json_annotation` dependency and `JsonKey` re-export from `ack`.
* Compile imported JSON Schema `pattern` expressions in ECMA-262 Unicode mode
  (`u`). Invalid Unicode-mode patterns (such as `\-` outside a character class)
  now fail import with `invalid_schema`. Native `Ack.string().matches()` retains
  Dart regex semantics.

### Added

* Add `@Schemable()` as the unified annotation for schema-first and class-first
  code generation, `AckModelAdapter.modelSchema`, and `CodecSchema.canEncode`.
* Expand `Ack.fromJsonSchema()` with:
  * `contains`, `if`/`then`/`else`, and `multipleOf` (sharing exact decimal
    division with native `.multipleOf()`).
  * Built-in string formats (`date-time`, `date`, `email`, `uuid`, `uri`,
    `ipv4`, `ipv6`) and numeric formats (`int32`, `int64`, `uint32`, `uint64`,
    `float`, `double`).
  * `x-*` vendor extension annotations (including `x-transformed`) and Draft-07
    `$schema` URIs.
* Add `JsonSchemaValidationError` (`keyword`, `keywordLocation`, `documentUri`,
  `pointer`) for imported JSON Schema validation failures.

### Changed

* Speed up `safeParse`, `safeEncode`, `toJsonSchema()`, imported JSON Schema
  compilation/validation, and `Ack.object()` / `Ack.list()` / `Ack.map()`
  unmodifiable result views.

### Fixed

* Accept lowercase `t` and `z` on announced leap seconds in RFC 3339 date-time
  validation.
* Percent-encode URI fragments in imported JSON Schema error locations and
  report the array path on imported `uniqueItems` failures.

### Deprecated

* Deprecate `@AckInfer()` and `@AckModel()` in favor of `@Schemable()`.

## 1.6.2

### Fixed

* `Ack.fromJsonSchema()` now compiles the `pattern` keyword, restoring import
  of schemas exported from Ack. It uses an unanchored ECMA-262 search on
  strings and rejects invalid regular expressions at import time.

### Added

* `Ack.fromJsonSchema()` now accepts the standard `propertyNames` keyword to
  validate every key of an object instance against its subschema. Both
  keywords round-trip through the Draft-7 export unchanged, raising the pinned
  upstream conformance selection to 631 cases.

## 1.6.1

### Fixed

* Correct the `safeParseAs` documentation: mapper `Exception`s become
  `SchemaTransformError` failures, while mapper `Error`s are rethrown with
  their original stack trace (the documented behavior never matched the code).
* Encode now honors *effective* nullability instead of a schema's own
  `isNullable` flag. A union with a nullable branch, and any `DefaultSchema`,
  `BoundarySchema`, or codec wrapping one, now encodes `null` wherever it
  already parsed `null`: at the root, as an object property, and when nested
  in another union. `.transform()`, `.codec()`, and `Ack.codec()` no longer
  reject `null` on parse or encode when their input schema accepts it, which
  matches the `type: null` branch their export already advertised.

### Changed

* An optional object property whose schema effectively accepts `null` now
  encodes a present `null` as `{"key": null}` instead of omitting the key. A
  missing key is still omitted.
* `Ack.list(...)` now throws its existing "nullable item schemas"
  `ArgumentError` for item schemas whose null acceptance was previously hidden
  behind a wrapper — a nested nullable union, or a codec, `withDefault(...)`,
  or `Ack.preserveBoundary(...)` over a nullable union.
* A codec or `Ack.preserveBoundary(...)` over a nullable union now exports an
  outer `{"type": "null"}` branch, matching the `null` it accepts. The branch
  is redundant with the union's own nullable branch but remains valid Draft-7.
* An `Error` thrown by an encoder now propagates out of `safeEncode` with its
  original stack trace at every nesting level. Previously only a root codec
  rethrew: nested in `Ack.object`, `Ack.list`, `Ack.map`, or
  `Ack.discriminated` the `Error` became a `SchemaEncodeError` failure, and in
  `Ack.anyOf` it was swallowed entirely so a later branch could return `ok`. A
  union no longer tries later branches once a branch encoder raises an
  `Error`. To signal a value a codec cannot encode, throw an `Exception` or
  express the rule with an `output:` schema; do not catch `Error`.
* Constraints added to a codec are no longer projected onto its exported wire
  schema, because they validate runtime values the encoder may map to a
  different shape — a seconds codec's `.min(Duration(seconds: 5))` used to
  export `minimum: 5000` while encoding `5`. They are still enforced at
  runtime, and the export now carries a
  `codec_runtime_constraint_not_exported` warning naming the omitted
  constraint keys. Move rules the wire should advertise onto the input schema
  (`Ack.string().minLength(5).codec(...)`). `Ack.duration().min()`/`.max()`
  still export `minimum`/`maximum` in milliseconds.

## 1.6.0

### Added

* Add strict `Ack.fromJsonSchema()` returning `AckSchema<Object, Object>` for a
  documented draft 2020-12 subset. The runtime implementation is internal;
  failures expose immutable diagnostics through `JsonSchemaImportException`.
  Supports supplied reference bundles, recursion, JSON-specific null/presence
  semantics, and exact `allOf`, `oneOf`, and `not` composition. Exports are
  self-contained and reflect only enforced assertions.
* Verify imports against 600 pinned upstream JSON Schema cases and selected
  A2UI v0.9 protocol schemas. Support catalog JSON Pointer targets outside
  `$defs`, normalize enums for valid Draft-7 output, and report unsupported
  assertions only when they are reachable from the imported root.

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
