## Unreleased

### Changed

* Imports inherit the expanded Draft 2020-12 runtime validator. Formats are
  annotations by default; the bridge's public API is unchanged.

## 1.7.0-beta.6

### Changed

* When paired with `ack` 1.7.0-beta.6 or later, imported builder schemas report
  `keywordLocation` on validation errors and report `uniqueItems` failures at
  the array. The bridge's public API and compatible dependency minimum are
  unchanged.

## 1.7.0-beta.5

### Changed

* When paired with `ack` 1.7.0-beta.5 or later, imported builder schemas inherit
  `contains` and conditional support, structured keyword errors, and Unicode
  regex semantics. Review patterns when upgrading; see the Ack beta.5 migration
  notes. The bridge's public API and compatible dependency minimum are unchanged.

## 1.7.0-beta.4

### Changed

* When paired with `ack` 1.7.0-beta.4 or later, builder models with
  `format: date-time` validate timestamps on import. The bridge's public API
  and compatible `ack` dependency minimum are unchanged.

## 1.7.0-beta.3

### Changed

* Align with the coordinated Ack 1.7.0-beta.3. This package has no source or
  public API changes from 1.7.0-beta.2; compatible dependency minimums are
  preserved.

## 1.7.0-beta.2

### Changed

* Align with the coordinated Ack 1.7.0 beta. This package has no source or
  public API changes from 1.6.2; compatible dependency minimums are preserved.

## 1.6.2

### Changed

* Align with the coordinated Ack 1.6.2 release. This package has no source or
  public API changes from 1.6.1; compatible dependency minimums are preserved.

## 1.6.1

### Changed

* Align with the coordinated Ack 1.6.1 release. This package has no source or
  public API changes from 1.6.0; compatible dependency minimums are preserved.

## 1.6.0

### Added

* Add strict `Schema.toAckSchema()` returning `AckSchema<Object, Object>`, with
  supplied reference bundles. It complements the existing
  `AckSchema.toJsonSchemaBuilder()` export bridge.

### Changed

* Require `ack: ^1.6.0`, because imports use `Ack.fromJsonSchema()`.

## 1.5.0

### Changed

* Align with the coordinated Ack 1.5 release; this package has no runtime or
  public API changes from 1.4.0.

## 1.4.0

### Changed

* Align with the coordinated Ack 1.4 release; this package has no runtime or
  public API changes from 1.3.0.

## 1.3.0

### Changed

* Align with the coordinated Ack 1.3 release introducing `ack_mcp_dart`;
  this package has no runtime or public API changes from 1.2.0.

## 1.2.0

### Changed

* Align the converter with Ack 1.2 and raise the minimum Dart SDK to 3.9.

## 1.1.0

* See [release notes](https://github.com/btwld/ack/releases/tag/v1.1.0) for details.

## 1.0.1

* See [release notes](https://github.com/btwld/ack/releases/tag/v1.0.1) for details.

## 1.0.0

* See [release notes](https://github.com/btwld/ack/releases/tag/v1.0.0) for details.

## 1.0.0-beta.12

### Changed

* Route conversion through ACK's sealed `AckSchemaModel` boundary and generic
  Draft-7 JSON Schema renderer.
* Preserve model defaults, const values, extension keywords, transformed
  metadata, and composition.
* Require `ack` `^1.0.0-beta.12` for the sealed `AckSchemaModel`
  adapter boundary.

### Removed

* Remove the retired JSON Schema DTO converter path.

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

* See [release notes](https://github.com/btwld/ack/releases/tag/ack_json_schema_builder-v1.0.0-beta.1) for details.

[1.0.0-beta.5]: https://github.com/btwld/ack/releases/tag/ack_json_schema_builder-v1.0.0-beta.5
[1.0.0-beta.1]: https://github.com/btwld/ack/releases/tag/ack_json_schema_builder-v1.0.0-beta.1
