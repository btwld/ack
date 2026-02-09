## 1.0.0-beta.6

### Bug Fixes

* **Primitives**: Comprehensive fixes for primitives and correctness (#50).

### Improvements

* **Analyzer**: Refactored field analyzer, model analyzer, and schema AST analyzer for correctness (#50).
* **Builders**: Improved type builder, field builder, and schema builder (#50).
* **Generator**: Centralized null/default handling in generator output (#65).

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
