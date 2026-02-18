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
