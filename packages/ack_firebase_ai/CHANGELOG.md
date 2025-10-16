# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
- Transformed schemas (`.transform()`) throw `UnsupportedError`
- Default values are not sent to Firebase AI
- AnyOf schemas use first schema only
- Discriminated unions have limited support

[1.0.0-beta.1]: https://github.com/btwld/ack/releases/tag/ack_firebase_ai-v1.0.0-beta.1
