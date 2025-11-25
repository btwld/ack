## Unreleased

### Breaking Changes

* **WellKnownFormat**: Reduced to 7 core formats (`email`, `uri`, `uuid`, `date`, `dateTime`, `ipv4`, `ipv6`). Removed formats: `hostname`, `idn_email`, `idn_hostname`, `uri_reference`, `uri_template`, `iri`, `iri_reference`, `time`, `duration`, `int32`, `int64`, `float`, `double`, `json_pointer`, `relative_json_pointer`, `regex`, `enum_`, `byte`, `binary`. Custom format strings are still supported via the `format` property.

### Bug Fixes

* **JsonSchema.toJson**: Now correctly adds null branch to `anyOf`/`oneOf` compositions when `nullable: true`, producing valid JSON Schema Draft-07 format.

## 1.0.0-beta.3 (2025-10-27)

* See [release notes](https://github.com/btwld/ack/releases/tag/v1.0.0-beta.3) for details.

## 1.0.0-beta.2 (2025-10-09)

* See [release notes](https://github.com/btwld/ack/releases/tag/v1.0.0-beta.2) for details.

## 1.0.0-beta.1 (2025-10-06)

* See [release notes](https://github.com/btwld/ack/releases/tag/v1.0.0-beta.1) for details.