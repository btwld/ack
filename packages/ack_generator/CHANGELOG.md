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
