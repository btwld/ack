## 0.0.1-dev.0

Initial dev release reserving the `standard_schema` name on pub.dev.

### Added

- Add the `StandardTyped`, `StandardSchema`, and `StandardJsonSchema`
  contracts, porting the two official Standard Schema interfaces, plus the
  Dart-only `StandardSchemaWithJsonSchema` convenience for combined
  implementers.
- Add standard results/issues, validation options, JSON Schema converter option
  types, and JSON Schema target constants.
- Add the opt-in `utils.dart` library with `getDotPath` (renders an issue path
  in dot notation, e.g. `user.tags.1`) and `StandardSchemaError` (a throwable
  wrapping a failure's issues), porting `@standard-schema/utils`.
