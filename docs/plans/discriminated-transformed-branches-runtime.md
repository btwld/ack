# Runtime Support for Transformed Discriminated Branches

## Summary

Implement the first slice in `packages/ack` only: `Ack.discriminated(...)` should accept object-backed transformed child branches and return the matched branch output directly at runtime.

Defaults locked:

- Keep the public class name `DiscriminatedObjectSchema`
- Do the transforms-only slice now
- Defer discriminator auto-injection and all `ack_generator` / `@AckType` changes
- Preserve the current public constructor shape; do not add eager construction-time validation in this slice

## Public API Changes

- Change `Ack.discriminated` in `packages/ack/lib/src/ack.dart` to a generic factory:
  - `Ack.discriminated<T extends Object>({ required String discriminatorKey, required Map<String, AckSchema<T>> schemas })`
  - Return `DiscriminatedObjectSchema<T>`
- Change `DiscriminatedObjectSchema` in `packages/ack/lib/src/schemas/discriminated_object_schema.dart` to:
  - `final class DiscriminatedObjectSchema<T extends Object> extends AckSchema<T>`
  - `with FluentSchema<T, DiscriminatedObjectSchema<T>>`
  - `final Map<String, AckSchema<T>> schemas`
- Keep the existing name even when `T != MapValue`; this is a compatibility choice for this slice.

## Implementation Changes

- Parsing:
  - Keep current dispatch flow: validate input is a map, read `discriminatorKey`, select branch by string value, then delegate parsing to the selected branch schema.
  - The selected branch schema’s own `.transform()` must run normally, so `safeParse()` / `parse()` return the branch output type `T`.
  - Union-level constraints/refinements continue to run after the selected branch returns `T`.
- Object-backed branch invariant:
  - Add an internal helper that recursively unwraps `TransformedSchema.schema` until it reaches the base schema.
  - Accept only branches whose base schema is `ObjectSchema`.
  - Do not validate this eagerly at construction time in this slice.
  - On parse of a selected invalid branch, return a deterministic schema failure explaining that discriminated branches must be object-backed, instead of falling through to a confusing primitive type mismatch.
- JSON Schema / converter behavior:
  - Update both:
    - `DiscriminatedObjectSchema.toJsonSchema()` in `packages/ack/lib/src/schemas/discriminated_object_schema.dart`
    - `_discriminated(...)` in `packages/ack/lib/src/converters/ack_to_json_schema_model.dart`
  - In both paths, inspect transformed branches via the recursively unwrapped base schema:
    - If the base schema is not `ObjectSchema`, throw a deterministic `ArgumentError`.
    - Discriminator key conflict: `toJsonSchema()` silently overwrites the discriminator property with the canonical `{'type': 'string', 'const': value}` form (correct — users commonly include the discriminator as a branch property for parse-time validation). `_discriminated()` throws `ArgumentError` on conflict (unchanged from its original behavior). These two paths intentionally differ because `toJsonSchema()` serves user-facing map output while `_discriminated()` serves the stricter model conversion.
  - For `toJsonSchema()` map output, preserve transformed metadata (for example `x-transformed`) by converting from the original branch schema while injecting discriminator property/required entries.
  - For `toJsonSchemaModel()`, preserve discriminator semantics (`oneOf` + `discriminator`) for transformed branches; custom vendor keys like `x-transformed` are not representable in the current `JsonSchema` model and are intentionally not preserved there.
- Default values:
  - The base class `handleNullInput` (`schema.dart:191-208`) clones the default via `cloneDefault()` then **re-enters `parseAndValidate`** with the cloned value. `cloneDefault` (`default_utils.dart:18-46`) deep-clones Maps/Lists but returns all other objects as-is (no JSON round-trip).
  - For `T = MapValue` (untransformed case), this re-parse is correct: the cloned Map goes through discriminator routing and branch validation. Existing tests depend on this (`composite_default_test.dart:288-307`).
  - For `T != MapValue` (transformed case), the default is already an output type (e.g., `Animal`). Re-parsing an `Animal` through `parseAndValidate` would fail at the `inputValue is! Map` type guard because the output type is not a Map.
  - Override `handleNullInput`: when the cloned default is not a `Map` (i.e., it's already a post-transform output value), bypass re-parsing and route directly through `applyConstraintsAndRefinements`. When the cloned default *is* a `Map`, preserve the current re-parse behavior for branch validation.
- Equality / hashCode:
  - Update `MapEquality<String, AckSchema<MapValue>>` to `MapEquality<String, AckSchema<T>>`.
  - Keep erased type matching in `operator==` (`other is! DiscriminatedObjectSchema`) so that equality compares structural content, not the reified `T`. Two schemas with identical branches/discriminator are equal regardless of how `T` was inferred.
- Non-goals for this slice:
  - No runtime auto-injection of missing discriminator literals into branch parsing
  - No `ack_generator` / `@AckType` support changes
  - No renaming to `DiscriminatedSchema`

## Test Plan

- Add/replace integration coverage for transformed child branches:
  - Per-branch `.transform()` returns distinct subtypes (`Cat`, `Dog`) and the discriminated schema returns the matched subtype.
  - Implicit type inference works for a common base type; also include one explicit `<Animal>` example.
  - An outer `.transform()` on the discriminated schema still works after child transforms.
- Validation/error coverage:
  - Invalid discriminator still fails before any branch transform runs.
  - Invalid selected branch payload fails before transform output is returned.
  - Branch transform exceptions are still wrapped as `SchemaTransformError`.
  - A non-object-backed branch composition produces a deterministic failure message in parse and a deterministic `ArgumentError` in both JSON Schema conversion paths (`toJsonSchema()` and `toJsonSchemaModel()`).
  - Multi-layer transformed branches (`Ack.object(...).transform(...).transform(...)`) still dispatch correctly.
- Default value coverage:
  - `withDefault` on a `DiscriminatedObjectSchema<T>` where `T` is a non-`MapValue` type (post-transform output) applies constraints without re-parsing through branch dispatch.
  - `withDefault` on untransformed `DiscriminatedObjectSchema<MapValue>` continues to re-parse through branch dispatch as before (`composite_default_test.dart:288-307` must still pass).
  - A MapValue default on a transformed discriminated schema that fails branch validation still reports the branch error (not a type mismatch).
- Regression coverage:
  - Existing untransformed discriminated behavior stays unchanged.
  - Existing equality/copyWith/nullable tests continue to compile with the generic class.
  - `toJsonSchema()` emission for discriminated transformed branches includes the discriminator field and preserves transformed markers.
  - `toJsonSchemaModel()` emission for discriminated transformed branches includes `oneOf` + `discriminator` with the discriminator field injected into each branch.
  - Sealed exhaustiveness: a `switch` on `AckSchema` with a `DiscriminatedObjectSchema()` case still compiles after the generic change.

## Call Sites to Update

These locations encode the old `MapValue`-only contract and must be updated in this slice:

- `packages/ack/lib/src/schemas/discriminated_object_schema.dart:8-24` — inline dartdoc that says child branches must return `Map<String, Object?>`. Update to document transformed branch support.
- `packages/ack/test/integration/discriminated_child_transform_test.dart:23-38` — integration test that documents transformed child branches as a compile-time error. Replace with tests for the new working behavior.
- `docs/api-reference/index.mdx:21,292` — public API docs hard-code the old `AckSchema<Map<String, Object?>>` signature. Update to reflect the generic `<T>`.
- Downstream converter packages have discriminated conversion test suites that should gain transformed-branch coverage:
  - `packages/ack_json_schema_builder/test/to_json_schema_builder_test.dart`
  - `packages/ack_firebase_ai/test/to_firebase_ai_schema_test.dart`

## Assumptions

- This phase may update runtime docs/examples in `ack` to reflect transformed branch support, but must explicitly state that `@AckType` discriminated constraints remain unchanged until a later generator-focused phase.
- Raw `DiscriminatedObjectSchema` annotations in existing tests/examples may remain raw; no repo-wide generic annotation cleanup is required for this slice.
- Auto-injection is intentionally deferred because it requires coordinated runtime parsing, JSON-schema emission, and generator changes, which are out of scope for this first pass.
