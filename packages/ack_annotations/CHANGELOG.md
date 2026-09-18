## 1.6.0

### Changed

* Align with the coordinated Ack 1.6 release; this package has no runtime or
  public API changes from 1.5.0.

## 1.5.0

### Changed

* Align with the coordinated Ack 1.5 release; this package has no runtime or
  public API changes from 1.4.0.

## 1.4.0

### Added

* Add `@Optional()`, `@Required()`, and `@NotNull()` field annotations for
  class-first key presence and JSON null rejection.

### Deprecated

* Deprecate `AckField.presence` and `AckFieldPresence`. Use `@Optional()` or
  `@Required()`; they will be removed in Ack 2.0.0.

## 1.3.0

### Changed

* Align with the coordinated Ack 1.3 release introducing `ack_mcp_dart`;
  this package has no runtime or public API changes from 1.2.0.

## 1.2.0

### Added

* Add `@AckInfer()` for immutable schema-first model generation. Custom names
  are exact and annotated libraries declare `.ack.dart` plus `.ack.g.dart`.
* Add class-first `@AckModel()`, `@AckField`, constraint annotations,
  unknown-property modes, exact schema facade names, and the generated JSON
  marker used by Ack-owned output.

### Deprecated

* Deprecate only `@AckType()`. It will be removed in Ack 2.0.0; use
  `@AckInfer()` for schema-first models or `@AckModel()` for class-first
  models. Its Ack 1.1 name suffixing and generated extension-type APIs remain
  unchanged until removal.

### Changed

* Raise the minimum Dart SDK to 3.9.
* Make the new `AckInfer` and internal JSON marker annotation classes final.
* Finalize the pre-release class-first API as `AckUnknownPropertyPolicy`,
  `unknownProperties`, and `captureField`, with no deprecated aliases.

## 1.1.0

* See [release notes](https://github.com/btwld/ack/releases/tag/v1.1.0) for details.

## 1.0.1

* See [release notes](https://github.com/btwld/ack/releases/tag/v1.0.1) for details.

## 1.0.0

* See [release notes](https://github.com/btwld/ack/releases/tag/v1.0.0) for details.

## 1.0.0-beta.12

### Breaking

* Remove `AckModel`, `AckField`, and decorator annotations. `ack_annotations`
  now exposes only `@AckType()`.

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

### Improvements

* **AckType**: Refined annotation parameters and improved type handling (#50).
* **AckField**: Improved field annotation correctness (#50).
* **Breaking**: `AckField.required` was replaced by `requiredMode` (`AckFieldRequiredMode.auto|required|optional`). Migrate `@AckField(required: true)` to `@AckField(requiredMode: AckFieldRequiredMode.required)` and `required: false` to `requiredMode: AckFieldRequiredMode.optional`.

## 1.0.0-beta.5 (2026-01-14)

### Improvements

* **Documentation**: Fixed broken links and added missing API documentation (#57).
* **Dependencies**: Updated `meta` dependency to latest version (#56).

## 1.0.0-beta.4 (2025-12-29)

* Dependency version bump to align with ack v1.0.0-beta.4.

## 1.0.0-beta.3 (2025-10-27)

* See [release notes](https://github.com/btwld/ack/releases/tag/v1.0.0-beta.3) for details.

## 1.0.0-beta.2 (2025-10-09)

* See [release notes](https://github.com/btwld/ack/releases/tag/v1.0.0-beta.2) for details.

## 1.0.0-beta.1 (2025-10-06)

* See [release notes](https://github.com/btwld/ack/releases/tag/v1.0.0-beta.1) for details.
