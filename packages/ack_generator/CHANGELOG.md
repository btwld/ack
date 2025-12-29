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