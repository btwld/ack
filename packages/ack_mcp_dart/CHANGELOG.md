## 2.0.0-beta.1

### Changed

* Require `ack: ^2.0.0-beta.1` so consumers receive the corrected runtime
  nullability, discriminated validation, and imported JSON Schema contracts.

### Documentation

* Correct the Dart SDK floor and document the current typed-input registration
  API and callback-owned output validation in the ecosystem guide.

## 2.0.0-alpha.1

### Breaking

* Requires `ack: ^2.0.0-alpha.1` and aligns with the coordinated Ack 2.0.0-alpha.1
  release.
* Remove `registerAckModelTool` from `AckMcpServer`; pass `Model.schema` (or
  `model.modelSchema`) directly to `registerAckTool(name, input: Model.schema, ...)`.

## 1.7.0

### Changed

* Align with the coordinated Ack 1.7.0 release. This package has no source or
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

### Changed

* Align with the coordinated Ack 1.6 release; this package has no runtime or
  public API changes from 1.5.0.

## 1.5.0

### Changed

* Align with the coordinated Ack 1.5 release; this package has no runtime or
  public API changes from 1.4.0.

## 1.4.0

### Changed

* Align with the coordinated Ack 1.4 release; this package has no runtime or
  public API changes from 1.3.0.

## 1.3.0

### Added

* Initial release: convert ACK object schemas into `mcp_dart` tool input schemas.
* Parse tool arguments with defaults, codecs, refinements, and typed models.
* Register schema and model tools with validation error results and optional
  custom error handling.
* Cover MCP 2026-07-28 discovery and 2025-11-25 / 2025-06-18 initialization.

* Redact exception-backed validation messages in default tool error responses.
