## Unreleased

### Added
- Added `toFirebaseAiResponseJsonSchema()` for Firebase AI's
  `GenerationConfig.responseJsonSchema` path.
- Added an opt-in live Firebase AI contract test for real
  `responseJsonSchema` generation and ACK validation.
- Added live-test configuration for Gemini Developer API vs Vertex AI
  backends, Firebase app credentials, location, and model override.
- Added committed Firebase AI `responseJsonSchema` golden fixtures and a
  fixture generator so converter coverage runs without Firebase credentials.
- Added Firebase SDK `Schema.toJson()` and `JSONSchema.toJson()` native
  fixture corpora with adapter capability classifications.

### Changed
- Target Firebase AI `^3.12.1` and models that support JSON Schema
  structured output.
- Default Firebase AI examples and live tests to `gemini-3.5-flash`.
- Require `ack` `^1.0.0-beta.12-wip` for the sealed `AckSchemaModel`
  adapter boundary.
- Update schema-model fixture coverage to use the renamed `SchemaModel` API.
- Keep `firebase_ai` and Flutter as explicit package dependencies so package
  tests and workspace orchestration use the Firebase AI SDK runtime.

### Removed
- Removed typed Firebase AI `Schema` conversion APIs. Use
  `toFirebaseAiResponseJsonSchema()` with
  `GenerationConfig.responseJsonSchema`.

## 1.0.0-beta.11

* See [release notes](https://github.com/btwld/ack/releases/tag/v1.0.0-beta.11) for details.

## 1.0.0-beta.10

* See [release notes](https://github.com/btwld/ack/releases/tag/v1.0.0-beta.10) for details.

## 1.0.0-beta.9

* See [release notes](https://github.com/btwld/ack/releases/tag/v1.0.0-beta.9) for details.

## 1.0.0-beta.8

* See [release notes](https://github.com/btwld/ack/releases/tag/v1.0.0-beta.8) for details.

## [1.0.0-beta.7]

* See [release notes](https://github.com/btwld/ack/releases/tag/v1.0.0-beta.7) for details.

## [1.0.0-beta.6]

### Changed
- Updated dependency on ack to v1.0.0-beta.6

## [1.0.0-beta.5] - 2026-01-14

### Changed
- Updated dependency on ack to v1.0.0-beta.5
- Updated `meta` and `test` dependencies to latest versions (#56)

## [1.0.0-beta.4] - 2025-12-29

### Fixed
- Preserve nullable metadata in firebase ai converter (#36)

## [1.0.0-beta.3] - 2025-10-24

### Changed
- **Major refactoring**: Consolidated package structure from 3 files to 1 file (`ack_firebase_ai.dart`)
- Removed `src/` directory - all implementation now in single library file
- Removed `ConversionContext` class - cyclic detection unnecessary for immutable schemas
- Removed `FirebaseAiSchemaConverter` class wrapper - now uses top-level functions
- Improved `TransformedSchema` handling with direct override application
- Better JSON Schema integration - convert once and reuse metadata
- Package complexity reduced by 26% (379 lines to 280 lines to 352 lines final)
- Inlined nullable checks for clarity

### Fixed
- `TransformedSchema` conversion now works correctly with proper override handling
- Union types (`anyOf`) now fully supported via updated JSON Schema implementation
- Discriminated unions (`DiscriminatedObjectSchema`) now properly supported
- Typeless schemas now handled correctly
- `additionalProperties` parsing fixed to accept `{}` as `true`

### Removed
- `schema_from_json.dart` and related tests (unused functionality)
- `ConversionContext` class (86 lines)
- Complex `overrideJson` parameter pattern
- Separate extension and converter files

### Improved
- **Performance**: Fewer JSON Schema conversions, more direct conversion path
- **Maintainability**: Simpler structure (3 files to 1), easier to navigate
- **Code quality**: Removed unnecessary abstractions and indirection
- **Test coverage**: All 82 tests passing (was 45+)
- **Documentation**: Single source of truth with comprehensive inline docs

## [1.0.0-beta.2] - 2025-10-16

### Changed
- Updated Firebase AI converter output to match the SDK integration style at the time.
- Added direct dependency on `firebase_ai` and aligned converter/tests with that SDK API.
- Updated test suite and documentation to reflect Firebase AI schema limitations at the time.

### Fixed
- Preserve enum and optional property metadata.

## [1.0.0-beta.1] - 2025-01-16

* See [release notes](https://github.com/btwld/ack/releases/tag/ack_firebase_ai-v1.0.0-beta.1) for details.

[1.0.0-beta.5]: https://github.com/btwld/ack/releases/tag/ack_firebase_ai-v1.0.0-beta.5
[1.0.0-beta.1]: https://github.com/btwld/ack/releases/tag/ack_firebase_ai-v1.0.0-beta.1
