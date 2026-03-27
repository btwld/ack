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
- Compatibility with new schema equality implementation

## [1.0.0-beta.4] - 2025-12-29

### Fixed
- Complete JSON schema conversion coverage (#45)

### Improved
- Consolidated JSON schema utilities and reduced duplication (#40)

## [1.0.0-beta.1] - 2025-11-01

### Added
- Initial release of ack_json_schema_builder package
- Extension method `.toJsonSchemaBuilder()` for converting ACK schemas
- Support for all basic schema types (string, integer, double, boolean, object, array)
- Support for enum schemas
- Constraint mapping (minLength, maxLength, minimum, maximum, uniqueItems)
- Optional field support
- Comprehensive test suite with 17+ tests
- Full documentation and examples

### Supported
- String constraints (minLength, maxLength, pattern, format)
- Numeric constraints (minimum, maximum)
- Object schemas with required/optional fields
- Array schemas with minItems, maxItems, uniqueItems
- Enum value validation
- AnyOf union types
- Discriminated object schemas
- Nested schemas

### Limitations
- Custom refinements (`.refine()`) not supported
- Default values not included in JSON Schema
- TransformedSchema metadata overrides limited due to immutable Schema objects

[1.0.0-beta.5]: https://github.com/btwld/ack/releases/tag/ack_json_schema_builder-v1.0.0-beta.5
[1.0.0-beta.1]: https://github.com/btwld/ack/releases/tag/ack_json_schema_builder-v1.0.0-beta.1