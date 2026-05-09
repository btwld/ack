# ACK Bidirectional Codec — Implementation Milestones & Executability Report

**Companion to:** `codec-bidirectional-requirements.md`
**Status:** Synthesized from a planning agent and a codebase-validation agent. Both agents agree the plan is executable; this document records the milestone breakdown, the gaps that need maintainer decision, and the breaking-change checklist.

---

## Executability Verdict

**YES, with conditions.** All file areas in §15 of the requirements doc exist except three new files (`codec_schema.dart`, `default_schema.dart`, `instance_schema.dart`). The base `AckSchema` already has the right hooks (`parseAndValidate`, `applyConstraintsAndRefinements`, `handleNullInput`) to extend; `SchemaContext` already tracks JSON-Pointer paths; `SchemaError` is extensible.

## Locked Decisions (from `codec-open-questions.md`)

All blocking and non-blocking questions are resolved. Three decisions diverge from the original recommendations and change scope or strictness:

1. **A1 (b) — `Ack.double()` strict everywhere.** Parse no longer accepts `int` as `double`. Affects M11 (primitive encode) **and** parse-side behaviour: `IntegerSchema`/`DoubleSchema` `_validateRuntime` and `parseAndValidate` both require exact runtime type. Adds two coercion-removal entries to the CHANGELOG (`Ack.double().parse(42)` no longer succeeds). Existing `strictPrimitiveParsing` flag becomes effectively a no-op for the int↔double case.
2. **A3 (b) — `Ack.datetime()` rejects non-UTC.** Encode error message must explicitly point at `.toUtc()`. Affects M14. Adds a CHANGELOG entry that callers must call `.toUtc()` before encoding.
3. **B4 (b) — Ship `Ack.intFromString()`, `Ack.doubleFromString()`, `Ack.boolFromString()` with the MVP.** Adds a new milestone **M14a** between M14 and M15 (see updated table below).

All other decisions match the original recommendations. The `parseAndValidate` shared-helper warning in §D of the open-questions doc is unchanged: M6 must add a separate `encodeBoundary` traversal, not a shared helper.

## Critical Structural Finding

Every schema file (`object_schema.dart`, `transformed_schema.dart`, etc.) is `part of 'schema.dart'`, not a standalone library. The §15 file-area table reads as if each is independent — it isn't. New files (`codec_schema.dart`, `default_schema.dart`, `instance_schema.dart`) must use the same `part`/`part of` convention so the sealed `AckSchema` hierarchy stays compileable.

## Files Not in §15 That Also Need Touching

- `packages/ack/lib/src/ack.dart` — `Ack.codec`, `Ack.instance`, rewritten `date/datetime/uri/duration` factories.
- `packages/ack/lib/src/converters/ack_to_json_schema_model.dart` — existing `is TransformedSchema` branch must also handle `CodecSchema` and `DefaultSchema`.
- `packages/ack/lib/src/schemas/extensions/datetime_schema_extensions.dart` and `duration_schema_extensions.dart` — currently typed `extension … on TransformedSchema<…>`; must retype to `CodecSchema<…>` (or rely on the typedef alias).
- Downstream test packages — `ack_firebase_ai`, `ack_json_schema_builder`, `ack_generator/test_utils/test_assets.dart` reference `x-transformed` and pin the migration surface.

---

## Milestone Order

Plumbing → hooks → leaves → composites → defaults → transform unification → built-ins → converters → migration. Each milestone is sized for a single reviewable PR.

```
M1  context.dart op flag           ─┐
M2  SchemaEncodeError              ─┴─→ M3 base hooks (encode/safeEncode + _validateRuntime/decodeBoundary/encodeBoundary)
                                          │
                                          ├─→ M4  CodecSchema + Ack.codec
                                          │     └─→ M5  InstanceSchema + Ack.instance
                                          ├─→ M6  ObjectSchema encode
                                          ├─→ M7  ListSchema encode
                                          ├─→ M8  EnumSchema encode
                                          ├─→ M9  AnyOfSchema encode
                                          ├─→ M10 DiscriminatedObjectSchema encode + unwrap helper
                                          ├─→ M11 Any/primitive encode (strict, no coercion)
                                          └─→ M12 DefaultSchema + .withDefault migration
                                                  └─→ M13 .transform → one-way CodecSchema
                                                          └─→ M14 built-in date/datetime/uri/duration as codecs
                                                                  └─→ M15 converters + downstream test updates
                                                                          └─→ M16 deprecation, CHANGELOG, README, llms.txt
                                                                                  └─→ M17 test matrix sweep (§14)
```

### Milestone Summary

| ID | Title | Key files | AC covered |
|---|---|---|---|
| M1 | `SchemaOperation` direction flag in `SchemaContext` | `context.dart` | enables AC-11, AC-12 |
| M2 | `SchemaEncodeError` class | `validation/schema_error.dart` | AC-06, AC-09, AC-10, AC-12 |
| M3 | Base hooks: `encode`/`safeEncode` + `_validateRuntime`/`decodeBoundary`/`encodeBoundary` | `schemas/schema.dart` | AC-01, AC-02, AC-04, AC-19 |
| M4 | `CodecSchema<I, O>` + `Ack.codec` | new `codec_schema.dart`, `ack.dart` | AC-01..AC-06, AC-16, AC-17 |
| M5 | `InstanceSchema<T>` + `Ack.instance` | new `instance_schema.dart`, `ack.dart` | AC-18, AC-20 |
| M6 | `ObjectSchema` recursive encode | `object_schema.dart` | AC-07, AC-09, AC-10, AC-17 |
| M7 | `ListSchema` recursive encode | `list_schema.dart` | AC-08, AC-17 |
| M8 | `EnumSchema` runtime/boundary split | `enum_schema.dart` | AC-13 |
| M9 | `AnyOfSchema` encode | `any_of_schema.dart` | AC-14, AC-17 |
| M10 | `DiscriminatedObjectSchema` encode + extend `unwrapDiscriminatedBranchSchema` for `CodecSchema`/`DefaultSchema` | `discriminated_object_schema.dart`, `utils/discriminated_branch_utils.dart` | AC-15, AC-17 |
| M11 | Any + primitive identity encode (strict — no coercion) | `any_schema.dart`, `string_schema.dart`, `num_schema.dart`, `boolean_schema.dart` | AC-19 |
| M12 | `DefaultSchema<T>` wrapper + `.withDefault` | new `default_schema.dart`, `fluent_schema.dart`, `object_schema.dart`, `converters/ack_to_json_schema_model.dart` | AC-11 |
| M13 | `.transform(...)` becomes one-way `CodecSchema<T, R>`; `TransformedSchema` becomes typedef | `transformed_schema.dart`, `extensions/ack_schema_extensions.dart`, datetime/duration extensions | AC-12 |
| M14 | Built-in codecs: `Ack.date()/datetime()/uri()/duration()` as `CodecSchema` | `ack.dart`, datetime/duration extensions | AC-18, AC-07, AC-08 |
| M14a | Convenience coercion codecs: `Ack.intFromString()`, `Ack.doubleFromString()`, `Ack.boolFromString()` (per B4 decision) | `ack.dart`, new `extensions/coercion_codecs.dart` or inline in `ack.dart` | AC-19 migration examples |
| M15 | Converter + downstream package updates | `converters/ack_to_json_schema_model.dart`, downstream tests | AC-16, AC-20 |
| M16 | Deprecation polish, CHANGELOG, README, llms.txt | `CHANGELOG.md`, `README.md`, `transformed_schema.dart` | AC-20 |
| M17 | New test files matching §14 | `packages/ack/test/schemas/...` | AC-01..AC-20 sweep |

---

## Recommendations on §18 Open Decisions

| # | Decision | Recommendation | Rationale |
|---|---|---|---|
| 1 | JSON Schema marker | Emit **both** `x-transformed` and `x-ack-codec` for one beta cycle; deprecate `x-transformed` at 1.0.0. | Downstream packages may key off the existing marker; double-emission gives a transition window with zero downstream breakage. |
| 2 | Decode error class | **Defer.** Keep `SchemaTransformError` for decode; add only `SchemaEncodeError` now. | Symmetry is cosmetic; failure paths are still distinguishable today. File a follow-up. |
| 3 | Codec equality and closures | **Ignore closure identity.** Document the policy; add an explicit regression test. | Closures are not stably hashable; structural equality over input/output is deterministic. |
| 4 | Built-in coercion factories (`Ack.intFromString()` etc.) | **Defer to a follow-up minor release.** Provide migration-guide examples. | Cosmetic; users can build them with `Ack.codec`. Avoids locking API names too early. |
| 5 | Release versioning | Ship as **`1.0.0-beta.12`** with `BREAKING:` callouts. Stay in beta until downstream catches up. | Already in `1.0.0-beta.x` per CHANGELOG. A `2.0.0-pre` jump is unnecessary. |

---

## Breaking Changes — CHANGELOG Checklist

1. `Ack.integer().parse('42')` no longer succeeds (AC-19).
2. `Ack.boolean().parse('true')` no longer succeeds.
3. `Ack.string().parse(42)` no longer succeeds.
3a. `Ack.double().parse(42)` (int input) no longer succeeds — strict per A1 (b).
3b. `Ack.datetime().encode(localDateTime)` no longer succeeds — must pass `value.toUtc()` per A3 (b). Error message points at `.toUtc()`.
4. `copyWith(defaultValue: x)` deprecated; use `.withDefault(x)`.
5. `AckSchema.defaultValue` field deprecated; defaults move to `DefaultSchema` wrapper.
6. `Ack.date()/datetime()/uri()/duration()` return `CodecSchema<…>` instead of `TransformedSchema<…>`. Source-compatible via typedef; JSON Schema marker may differ.
7. `TransformedSchema<I,O>(schema, transformer, …)` positional constructor removed. The typedef `TransformedSchema = CodecSchema` remains.
8. `TransformedSchema.schema` and `TransformedSchema.transformer` removed. Replaced by `inputSchema`, `outputSchema`, `decoder`, `encoder`.
9. `.transform(...).safeEncode(...)` now fails with `SchemaEncodeError`.
10. JSON Schema marker may add `x-ack-codec: true` alongside `x-transformed: true`.
11. `DiscriminatedObjectSchema` branch unwrap now drills through `CodecSchema` and `DefaultSchema`. Manual inspectors should use `unwrapDiscriminatedBranchSchema`.
12. New `SchemaEncodeError` class — `switch (error)` exhaustiveness on `SchemaError` may break.
13. `SchemaContext` gains a non-default field `operation` (default `SchemaOperation.parse`).
14. `Ack.instance<T>()` and `Ack.codec<I,O>(...)` are new public API (not breaking but ship-blocking).

---

## Ambiguities to Resolve Before / During Implementation

Blocking (resolve before starting the affected milestone):

1. **`Ack.double()` runtime policy (§7.1).** Is `42` (int) an acceptable runtime double for encode? Recommend strict-double on `_validateRuntime`/encode; lenient on parse if compatible with `strictPrimitiveParsing`.
2. **`Ack.date()` UTC/local rule (§8.1).** Pin unconditionally: encode rejects UTC and rejects non-midnight components.
3. **`Ack.datetime()` UTC requirement (§8.2).** Choose: (a) encode `value.toUtc().toIso8601String()` (lossless) and accept non-UTC inputs, or (b) strictly reject non-UTC. Recommend (a).
4. **EnumSchema integer index (§7.6).** Keep for parse, reject for `_validateRuntime`/encode.
5. **AnyOf encode determinism (§7.4.2).** First branch where the **full** encode pipeline succeeds end-to-end. Document.
6. **Object encode pass-through of additional properties (§7.2.7).** Pass through unchanged (no child schema available). Document.
7. **`DefaultSchema` + nullable inner.** `encode(null)` returns `null` via the inner nullable encode; the default is irrelevant on encode.

Non-blocking (resolve inline as each milestone lands):

8. JSON Schema marker scope on nested codecs (§10.2): emit at field level only, not at root.
9. Default serialization through codec encode (§10.3) when codec is one-way: skip boundary-encoded default; emit nothing or runtime value as fallback with a debug warning.
10. `parseAs` / `safeParseAs` retention (§5.4 implicitly drops them — confirm).
11. `SchemaResult` generic-erasure helper (§9.1): add a static `SchemaResult.castFail<U>(SchemaError)` helper.
12. `Ack.instance<T>` constraints surface (§7.8): just `.constrain` / `.refine`.
13. Equality test specifics (§11): add a regression test asserting two codecs with equal input/output schemas but different closures compare equal.
14. Sealed-class hierarchy: every `switch (schema)` and `is TransformedSchema` site needs an audit (notably in `ack_to_json_schema_model.dart` and `ack_generator/lib/src/analyzer/schema_ast_analyzer.dart`).
15. `Ack.list(Ack.instance<Foo>())` produces a non-JSON-serializable boundary — document.

---

## One Contradiction Worth Flagging

§7.2.10 requires object-level constraints/refinements to run on the **runtime** map, not the encoded map. Today's `ObjectSchema.parseAndValidate` synthesizes defaults into the missing-optional path and runs constraints over that synthesized map. The encode path must take a **separate** code path that does not synthesize defaults (§7.2.5). Reusing `parseAndValidate` directly during encode would silently violate the spec. M6 must add a separate `encodeBoundary` traversal; do not refactor `parseAndValidate` into a shared helper.

---

## Risks Cross-Cutting All Milestones

- **Sealed class hierarchy.** `AckSchema` is `sealed`. Adding `CodecSchema`, `InstanceSchema`, `DefaultSchema` requires they live in the same library (the `part of 'schema.dart'` convention) and that all `switch (schema)` and `is TransformedSchema` sites are updated.
- **Test footprint.** ~25 existing test files need updates; ~15–20 new test files are required for codec functionality, defaults, and built-in codec round-trips.
- **CI matrix.** Three downstream packages (`ack`, `ack_firebase_ai`, `ack_json_schema_builder`, `ack_generator`) each have their own tests; every breaking change needs coordinated updates.
- **Release artefacts.** `llms.txt`, `README`, and any tutorial sample apps reference `Ack.date().transform(...)`-shaped APIs. Audit before release.

---

## Next Step

Before kicking off M1, the maintainer should resolve the seven blocking ambiguities listed above. Each is small but materially changes encode behaviour or error semantics in a way that's painful to revisit later.
