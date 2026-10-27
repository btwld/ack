## 2.0.0-alpha.2

### Breaking

* Infer JSON numbers in `Ack.preserveBoundary(Ack.map(...))` field values,
  including duration milliseconds, as `num`. A wire value keeps each number as
  decoded, and numeric schemas accept both `1` and `1.0`.

### Changed

* Require `ack: ^2.0.0-alpha.2` so consumers receive the corrected runtime
  nullability, discriminated validation, and imported JSON Schema contracts.

### Fixed

* Validate inherited field names against an alias's final capture policy before
  generation, rejecting collisions with the additional-properties member.
* Reject unproven object-shape changes inside preserved boundaries, including
  aliases and fluent codecs, rather than copying opaque values as JSON.
* Preserve native codec boundary types when inferring the values of
  `Ack.preserveBoundary(Ack.map(...))` fields, including dates, datetimes,
  URIs, enums, explicit codec inputs and statically resolvable nonrecursive
  lazy schemas.
* Resolve preserved JSON boundary nullability through the same effective
  metadata as ordinary fields, including aliases and explicit flag overrides.
* Snapshot nested JSON collections held as `Object` or `Object?` in
  schema-first model constructors and `copyWith`. Reuse Ack's shared deep
  copier; constructors still do not validate data. Opaque codec runtime values
  retain their identity and container types.
* Allow built-in and contextual Dart keywords such as `required` as generated
  field, discriminator, and capture-member names without changing their JSON
  keys. Reserved words such as `class` remain rejected. Member validation now
  follows the analyzer's keyword classification rather than a fixed word list.
  `dynamic` remains rejected because it shadows the type in generated JSON
  methods, not because it is a reserved Dart word.
* Preserve schema flags and object policies when `copyWith` no-op `null`
  arguments are parenthesized.
* Infer `Ack.anyOf(...)` fields whose branches are all native JSON as JSON
  `Object` values, including list items and map values, without an
  `Ack.preserveBoundary(...)` wrapper. A branch may itself be an explicit
  `Ack.preserveBoundary(...)` wire view.
* Reject an `Ack.anyOf(...)` field with a codec, `Ack.instance<T>()`, model
  schema, or nullable branch, naming the field and the offending branch.
  `Ack.anyOf(...)` model roots remain unsupported, including through aliases.
* Preserve schema-first presence, nullability, and default-wrapper behavior
  through aliases and explicit constant flag overrides. Apply the outermost
  strict/passthrough policy to object models and aliases.
* Reject object shape-changing methods that cannot be modeled statically,
  instead of generating fields that disagree with the authored schema.
* Resolve same-build scalar, list, and codec model references using their
  actual runtime types, and generate valid codecs for nullable nested Sets.
* Diagnose value-model helper collisions, class/member name conflicts, and
  duplicate schema-first keys before emission. Resolve same-build models
  declared with annotated getters.
* Preserve application-generic argument nullability when selecting custom
  schemas, and substitute nested generic bounds before validating type-owned
  schema methods.

## 2.0.0-alpha.1

### Breaking

* Requires `ack: ^2.0.0-alpha.1`.
* **Single-pass `.g.dart` builder (`#189`)**: `ack_generator:ack_generator` is
  now a `SharedPartBuilder` that emits `<file>.g.dart` directly with generated
  `toJson()` / `fromJson()` helpers. The two-part `.ack.dart` and `.ack.g.dart`
  builders and runtime `json_serializable` delegation are removed. Replace
  `part '<file>.ack.dart';` and `part '<file>.ack.g.dart';` with a single
  `part '<file>.g.dart';`.
* Remove legacy `@AckType`, `@AckInfer`, `@AckModel`, `@AckField`, `*Type`
  extension-type model generation, top-level `@Optional` / `@Required` /
  `@NotNull` / constraint classes, and the legacy `@JsonKey(name: ...)` fallback
  in favor of `@Schemable()`, `@Validate.*`, and `@AckKey('...')` (`#188`, `#189`, `#191`).

### Added

* Support `@Validate.*` presence and constraint annotations (`@Validate.optional()`,
  `@Validate.required()`, `@Validate.notNull()`, `@Validate.notEmpty()` on
  `String`/`List`/`Set`, etc.) from `package:ack/ack.dart` across field
  declarations and primary/generative constructor parameters, as well as
  `static final schema = _<name>Schema;` on class-first models (`#191`).
* Support `JsonMaybe<T>` fields in `@Schemable()` class-first models for PATCH
  tri-state presence (`#148`).
* Support `@AckKey('...')` directly without `package:json_annotation` (`#189`).
* Support custom schema resolution on `@Schemable()` class fields via:
  1. `@Schemable(schemas: [...])` on the class, enclosing sealed union, current
     `library;` directive, or an imported `library;` directive
  2. Type-owned `T.schema` / `T.schema<...>()`
  3. Automatic detection of a unique top-level `AckSchema<Boundary, T>`
     variable, getter, or zero-argument function in the current library (`#185`).
* Support two-way `StringSchema` normalizers (`.trim()`, `.toLowerCase()`,
  `.toUpperCase()`) in schema-first `@Schemable()` models.
* Add `ack_generator:ack_json_schema` builder and `generateAckSchemaLibrary()`
  API: `ack_generator:ack_json_schema` emits `<name>.schema.dart` from
  `lib/**/*.schema.json` Draft 2020-12 documents, which
  `ack_generator:ack_generator` compiles into `<name>.schema.g.dart` typed
  models or validated value-model libraries (`#167`).
* Apply scalar `@Validate.*` constraints on `List` and `Set` fields and
  parameters to the items, alongside the collection's own constraints:
  `@Validate.min(1) @Validate.minItems(1) List<int>` infers
  `Ack.list(Ack.integer().min(1)).minItems(1)`.
* Resolve non-nullable `Object` fields through a class-level or union-level
  `@Schemable(schemas: [...])` entry whose schema targets `Object`; `Object?`
  fields still infer `Ack.any()`.

### Fixed

* Preserve integral decimal length and item bounds in JSON Schema generation.
  Use validated value models for Unicode regex patterns and named scalar unions
  that the typed model generator cannot represent faithfully.

## 1.7.0

### Breaking

* Require `ack: ^1.7.0` and read annotations from `package:ack` (`ack_annotations`
  is removed). Regenerate models after upgrading (`@Schemable.generatedJson`
  replaces `@AckInfer.jsonSerializable`).
* Reject `JsonConverter` annotations on class-first models and fields so
  `json_serializable` cannot bypass Ack's runtime validation bridge.
* Change generated `copyWith` to a getter returning a typed
  `$ClassCopyWith<Class>` interface, turning mistyped arguments into
  compile-time errors while preserving `model.copyWith(field: value)` call sites
  and explicit `null` clearing.

### Added

* Support `@Schemable()` for both schema-first and class-first generation, and
  emit a `static final schema` shorthand on schema-first models.
* Auto-resolve fields whose types declare a static `schema` getter or generic
  `schema<A>()` factory (including extension types, enums, and per-type-argument
  schema parameters).
* Support explicit `description` options on `@Schemable` and `@AckField`,
  single-line `@description` doc tags, and string format annotations.
* Export shared type and constraint inference from
  `package:ack_generator/inference.dart`.

### Changed

* Require unique JSON boundary items (`uniqueItems: true`) on class-first `Set`
  fields with `@MinItems`, `@MaxItems`, or `@UniqueItems`.
* Emit `// ignore_for_file: type=lint` and `// coverage:ignore-file` headers and
  member doc comments in generated `.ack.dart` and `.ack.g.dart` parts.

### Fixed

* Fail generation with clear diagnostics when field/codec types are not visible
  in the annotated library, when numeric constraints are non-finite, when
  `@Schemable` options target the wrong declaration kind, or when
  `@AckField(schema:)` is generic or returns an incompatible schema type.
* Apply collection constraints on `Set<Set<T>>` to the outer set and escape
  control characters in all generated string literals (#164).

## 1.6.2

### Changed

* Align with the coordinated Ack 1.6.2 release. This package has no source or
  public API changes from 1.6.1; compatible dependency minimums are preserved.

## 1.6.1

### Changed

* Align with the coordinated Ack 1.6.1 release. This package has no source or
  public API changes from 1.6.0; compatible dependency minimums are preserved.

## 1.6.0

### Changed

* Align with the coordinated Ack 1.6 release; this package has no runtime or
  public API changes from 1.5.0.

## 1.5.0

### Added

* Infer open JSON class-first fields from their Dart types: `Object` →
  `Ack.any()`, `Object?` → `Ack.any().nullable()` (with the same presence
  annotations as `String?`), `List<Object>` → `Ack.list(Ack.any())`, and
  `Map<String, T>` → `Ack.map(<schema for T>)`, including
  `Map<String, Object?>`. `Map` fields no longer require `@AckField`, which
  still overrides an inferred schema. `dynamic`, `List<Object?>`, and
  non-`String` map keys stay rejected; the `dynamic` error now suggests
  `Object?`.
* Accept `Ack.any()` and `Ack.map(...)` schema-first fields, inferring
  `Object`/`Object?` and `Map<String, T>`. `Ack.any()` and `Ack.map()` model
  roots stay rejected, including when reached through a variable.

### Changed

* Require `ack: ^1.5.0`, because generated code now uses `Ack.map`.

### Fixed

* Omit the redundant `as Object?` cast in generated `copyWith` bodies for
  `Object?` fields.
* Infer nullable `Ack.map` values when the value schema is a variable declared
  with `.nullable()`, such as `Ack.map(nullableLabel)`.
* Keep generated code clean under `--fatal-infos`: fieldless class-first
  models no longer declare an unused `self` local, and nullable collection
  bridges use null-aware access.
* Generate compiling code for nullable class-first `Set<T>?` fields; the set
  codec now uses the non-null set type and presence adds nullability.

## 1.4.0

### Added

* Add `@Optional()`, `@Required()`, and `@NotNull()` class-first field
  annotations. Key presence stays separate from JSON null acceptance.

### Fixed

* Derive class-first `copyWith` nullability from the constructor parameter type
  so optional non-nullable codec fields compile and do not receive `null`.

### Deprecated

* Accept `@AckField(presence: ...)` during migration with a deprecation warning;
  reject conflicts with `@Optional()` / `@Required()`.

## 1.3.0

### Changed

* Align with the coordinated Ack 1.3 release introducing `ack_mcp_dart`;
  this package has no runtime or public API changes from 1.2.0.

## 1.2.0

### Added

* Add `@AckInfer()` schema-first immutable models with parse/JSON/copy/value
  APIs, named recursion, unions, codecs, defaults, nullability, additional
  properties, immutable collections, and cross-library composition.
* Add `@AckModel()` class-first generation with private backing codecs, public
  schema facades, constructor and field inference, unknown-property policies,
  sealed unions, generated mixins, and inferred static `fromJson` aliases.
* Add dedicated `.ack.dart` and `.ack.g.dart` builders so modern Ack output
  remains separate from legacy and ordinary `.g.dart` generators.

### Deprecated

* Deprecate the `@AckType()` generator path for removal in Ack 2.0.0. Use
  `@AckInfer()` for schema-first models or `@AckModel()` for class-first
  models. Existing Ack 1.1 output remains frozen and supported through 1.x.

### Compatibility

* Restore the Ack 1.1 `@AckType()` analyzer, emitter, tests, and
  `ack_generator` LibraryBuilder. Legacy `*Type`, Map, `.args`,
  `parse`, `safeParse`, naming, getter, union, transform, and additional
  property behavior is frozen until Ack 2.
* Allow unrelated legacy and modern declarations in one library. Reject nested
  graphs that cross the generator boundary with a located migration diagnostic.

### Fixed

* Decode constructor-normalized fields through the constructor parameter type.
* Emit strict-lint-compatible equality guards.
* Keep model equality independent of collection wrapper implementations and
  preserve propagated `Error` objects through runtime validation.
* Keep generated class-first `wireSchema` results in their original boundary
  representation when nested models, collections, enums, or codecs decode.
* Distinguish omitted `copyWith` arguments from explicit `null`, so nullable
  fields can be cleared in both schema-first and class-first models.
* Use a dedicated private sentinel type for nullable `copyWith` arguments so a
  consumer's `const Object()` cannot be mistaken for omission.
* Require concrete class-first models and branches plus all stored fields to be
  final, and recursively freeze parsed collections and captured extras.
* Generate `AckUnknownPropertyPolicy` / `unknownProperties` / `captureField`
  contracts and delegate captured-map snapshots to
  `deepUnmodifiableJsonMap` instead of emitting duplicate recursive helpers.
* Reject unsupported `JsonKey` options and parameter placement, cross-library
  class-first cycles, direct one-way transforms beneath codecs, and legacy
  object fields whose schema expressions cannot be analyzed.
* Reject nullable collection elements consistently for modern schema-first,
  resolved class-first, and same-build future-generated model paths while
  preserving direct nullable fields and explicit `@AckField` codecs.
* Validate generated model/facade visibility through import and barrel export
  combinators, allow valid split imports, and reject cross-direction generated
  class/facade name collisions before emission.
* Use Analyzer 10's typed argument AST APIs instead of dynamic compatibility
  fallbacks outside the declared Analyzer support range.

### Changed

* Raise the Dart floor to 3.9 and constrain Analyzer to
  `>=10.0.0 <11.0.0`.

### Migration

* To opt in a connected legacy graph, rename `@AckType()` to `@AckInfer()`,
  add `.ack.dart` and `.ack.g.dart`, replace `*Type`/Map access with the
  immutable class API, then use `fromJson`/`toJson` at the JSON boundary.
* Keep `@AckType()` and `.g.dart` unchanged when migration is not desired.

## 1.1.0

### Changed

* Use the current source_gen generation error type and keep diagnostic output in
  the build pipeline instead of writing undeclared debug files.
* Remove obsolete exploratory and golden-test utilities.

### Behavior changes

* Reject direct and referenced nullable list element schemas during generation,
  matching the runtime schema contract. *(migration: a previously-succeeding
  `Ack.list(x.nullable())` build now fails; put nullability on the list with
  `Ack.list(x).nullable()`.)*

## 1.0.1

* See [release notes](https://github.com/btwld/ack/releases/tag/v1.0.1) for details.

## 1.0.0

* See [release notes](https://github.com/btwld/ack/releases/tag/v1.0.0) for details.

## 1.0.0-beta.12

### Breaking

* Remove class-based schema generation. `ack_generator` now supports only
  top-level `@AckType()` schema variables and getters.

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

### Bug Fixes

* **Primitives**: Comprehensive fixes for primitives and correctness (#50).

### Improvements

* **Analyzer**: Refactored field analyzer, model analyzer, and schema AST analyzer for correctness (#50).
* **Builders**: Improved type builder, field builder, and schema builder (#50).
* **Generator**: Centralized null/default handling in generator output (#65).
* **AckType factories**: Generate direct `schema.parseAs(...)` / `schema.safeParseAs(...)` calls and stop emitting `_$ackParse` / `_$ackSafeParse` helpers.

## 1.0.0-beta.5 (2026-01-14)

### Features

* **Doc comments**: Support doc comments for schema descriptions (#61). Field and class doc comments are now used to populate schema descriptions.

### Bug Fixes

* **List types**: Resolve list element types with method chain modifiers (#60). Fixed type resolution for complex list schemas with chained method calls.
* **AckType casts**: Fix @AckType schema ref casts and improve nested schema handling (#59).

### Improvements

* **Dependencies**: Updated `ack`, `ack_annotations`, `meta` and `test` dependencies to latest versions (#56).

## 1.0.0-beta.4 (2025-12-29)

### Bug Fixes

* **Primitives**: Comprehensive fixes for primitive schema generation and correctness.
* **Typed list getters**: Support `Ack.list(schemaRef)` for typed list getters (#47).
* **Field descriptions**: Add field descriptions to generated schema output (#44).
* **Extension types**: Generate extension types for all AckType schemas; skip for nullable AckType schemas.

### Improvements

* **Circular dependency handling**: Improved circular dependency handling and reduced duplication.
* **Analyzer compatibility**: Updated for analyzer >=7.x <9 API changes (#41).
* **Consolidated naming utilities**: Removed duplicate naming utility functions.
* **Documentation**: Fixed stale documentation for extension type generation.

## 1.0.0-beta.3 (2025-10-27)

* See [release notes](https://github.com/btwld/ack/releases/tag/v1.0.0-beta.3) for details.

## 1.0.0-beta.2 (2025-10-09)

* See [release notes](https://github.com/btwld/ack/releases/tag/v1.0.0-beta.2) for details.

## 1.0.0-beta.1 (2025-10-06)

* See [release notes](https://github.com/btwld/ack/releases/tag/v1.0.0-beta.1) for details.
