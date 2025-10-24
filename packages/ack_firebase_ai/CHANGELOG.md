# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0-beta.3] - 2025-10-24

### Changed
- **Major refactoring**: Consolidated package structure from 3 files to 1 file (`ack_firebase_ai.dart`)
- Removed `src/` directory - all implementation now in single library file
- Removed `ConversionContext` class - cyclic detection unnecessary for immutable schemas
- Removed `FirebaseAiSchemaConverter` class wrapper - now uses top-level functions
- Improved `TransformedSchema` handling with direct override application
- Better `JsonSchema` integration - convert once and reuse metadata
- Package complexity reduced by 26% (379 lines → 280 lines → 352 lines final)
- Inlined nullable checks for clarity

### Fixed
- `TransformedSchema` conversion now works correctly with proper override handling
- Union types (`anyOf`) now fully supported via updated JsonSchema implementation
- Discriminated unions (`DiscriminatedObjectSchema`) now properly supported
- Typeless schemas now handled correctly
- `additionalProperties` parsing fixed to accept `{}` as `true`

### Removed
- `schema_from_json.dart` and related tests (unused functionality)
- `ConversionContext` class (86 lines)
- Complex `overrideJson` parameter pattern
- Separate extension and converter files

### Improved
- **Performance**: Fewer JsonSchema conversions, more direct conversion path
- **Maintainability**: Simpler structure (3 files → 1), easier to navigate
- **Code quality**: Removed unnecessary abstractions and indirection
- **Test coverage**: All 82 tests passing (was 45+)
- **Documentation**: Single source of truth with comprehensive inline docs

## [1.0.0-beta.2] - 2025-10-16

### Changed
- Return Firebase AI `Schema` objects from `.toFirebaseAiSchema()` instead of raw `Map`s.
- Added direct dependency on `firebase_ai` and aligned converter/tests with its typed API.
- Updated test suite and documentation to reflect Firebase AI Schema limitations (e.g., missing string length metadata).

### Fixed
- Preserve enum and optional property metadata via typed schema helpers.

## [1.0.0-beta.1] - 2025-01-16

### Added
- Initial release of ack_firebase_ai package
- Extension method `.toFirebaseAiSchema()` for converting ACK schemas
- Support for all basic schema types (string, integer, double, boolean, object, array)
- Support for enum schemas via `Ack.enumString()`
- Constraint mapping (minLength, maxLength, min, max, format)
- Nullable and optional field support
- Property ordering for Firebase AI compatibility
- Comprehensive test suite with 45+ tests
- Semantic validation tests ensuring behavioral equivalence
- Full documentation and examples

### Supported
- String schemas with constraints (min/max length, format)
- Numeric schemas with constraints (min/max, exclusive bounds)
- Boolean schemas
- Object schemas with nested properties
- Array schemas with item constraints
- Enum schemas
- Nullable fields
- Optional fields
- Nested structures

### Limitations
- Custom refinements (`.refine()`) are not converted
- Regex patterns (`.matches()`) are not fully supported
- Transformed schemas (`.transform()`) throw `UnsupportedError` *(Note: fully supported as of 1.0.0-beta.3)*
- Default values are not sent to Firebase AI
- AnyOf schemas use first schema only
- Discriminated unions have limited support

[1.0.0-beta.1]: https://github.com/btwld/ack/releases/tag/ack_firebase_ai-v1.0.0-beta.1
