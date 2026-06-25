## 0.0.1-dev.0

Initial dev release reserving the `standard_schema` name on pub.dev.

### Added

- Add the `StandardTypedV1`, `StandardSchemaV1`, and `StandardJsonSchemaV1`
  contracts, porting the two official Standard Schema interfaces, plus the
  Dart-only `StandardSchemaWithJsonSchemaV1` convenience for combined
  implementers. Unversioned names remain available as aliases.
- Add standard results/issues, path segments, validation options, JSON Schema
  converter option types, and JSON Schema target constants.
- Add the opt-in `utils.dart` library with `getDotPath` (renders an issue path
  in dot notation, e.g. `user.tags.1`) and `StandardSchemaError` (a throwable
  wrapping a failure's issues), porting `@standard-schema/utils`.
- Make the Standard Schema V1 props final with a fixed `version` marker of
  `1`, matching the upstream `version: 1` contract.
- Store failure issues, issue paths, and schema error issues as unmodifiable
  snapshots.
- Add a package example covering validation, transformed output, JSON Schema
  conversion, and dot-path rendering.
