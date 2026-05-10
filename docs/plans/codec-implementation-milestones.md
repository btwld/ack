# ACK Bidirectional Codec — Implementation Milestones & Executability Report

**Companion to:** `codec-bidirectional-requirements.md`, `codec-open-questions.md`
**Status:** **Historical planning artifact.** Implementation through
M1–M16 is complete and shipped on `claude/install-dart-7RrSY`,
followed by the **C1–C8 pre-1.0 semantic cleanup** that removed every
compatibility shim originally scoped to the beta transition (no
beta.12 release shipped before the cleanup, so no consumer code
depended on the shims). The authoritative state lives in:

- `codec-bidirectional-requirements.md` — the spec, with the §18
  "Resolved Decisions" summary and the §18a traceability table.
- `codec-open-questions.md` — every A1–A7 / B1–B5 decision with its
  `Decision:` line. Decisions superseded by the C-cleanup carry an
  inline **Update** block.
- `codec-mid-implementation-decisions.md` — DEC-A / DEC-B / DEC-C /
  DEC-C2 mid-flight decisions.
- `packages/ack/CHANGELOG.md` (1.0.0-beta.12 entry) — final
  user-facing breaking changes, including the C-cleanup sweep.

This file is preserved for historical context but should not be
treated as a live specification. The "Ambiguities to Resolve" and
"Before kicking off M1" sections were resolved during implementation
— see `codec-open-questions.md`. Items in the breaking-change
checklist marked "deferred" / "soft-deprecated" / "staged" below were
**later applied in full** during the C1–C8 cleanup; check the
CHANGELOG for the final state.

---

## Executability Verdict

**YES, with conditions.** All file areas in §15 of the requirements doc exist except three new files (`codec_schema.dart`, `default_schema.dart`, `instance_schema.dart`). The base `AckSchema` already has the right hooks (`parseAndValidate`, `applyConstraintsAndRefinements`, `handleNullInput`) to extend; `SchemaContext` already tracks JSON-Pointer paths; `SchemaError` is extensible.

## Locked Decisions (from `codec-open-questions.md`)

All blocking and non-blocking questions are resolved. Three decisions diverge from the original recommendations and change scope or strictness:

1. **A1 (b) — `Ack.double()` strict everywhere.** Parse no longer accepts `int` as `double`. Affects M11 (primitive encode) **and** parse-side behaviour: `IntegerSchema`/`DoubleSchema` `_validateRuntime` and `parseAndValidate` both require exact runtime type. Adds two coercion-removal entries to the CHANGELOG (`Ack.double().parse(42)` no longer succeeds). Existing `strictPrimitiveParsing` flag becomes effectively a no-op for the int↔double case.
2. **A3 (b) — `Ack.datetime()` rejects non-UTC.** Encode error message must explicitly point at `.toUtc()`. Affects M14. Adds a CHANGELOG entry that callers must call `.toUtc()` before encoding.
3. ~~**B4 (b) — Ship `Ack.intFromString()`, `Ack.doubleFromString()`, `Ack.boolFromString()` with the MVP.**~~ Superseded during M14a — see the revised B4 (a) decision in `codec-open-questions.md`. Recipes stay; public-API factories do not. M14a is now a docs/tests milestone (`test/migration_recipes_test.dart`) and adds no new entries to `Ack`.

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
| M14a | _Revised:_ migration recipes for `string ↔ int / double / bool` codecs as tested documentation. **No new public API** (per the revised B4 decision in `codec-open-questions.md`). | `test/migration_recipes_test.dart` | AC-19 migration examples |
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

> **Note (M16.1 + C-cleanup).** This list is the original planning
> checklist. After the M1–M16 cycle finished, the **C1–C8 pre-1.0
> semantic cleanup** removed every compatibility shim that had been
> retained for the beta transition. Because no beta.12 release shipped
> before that cleanup, all previously-"deferred" / "soft-deprecated"
> items below were ultimately applied in full. The live, user-facing
> breaking-change list lives in `packages/ack/CHANGELOG.md`
> (1.0.0-beta.12 entry); use that as the authoritative reference.

1. `Ack.integer().parse('42')` no longer succeeds (AC-19). **Shipped in C3.**
2. `Ack.boolean().parse('true')` no longer succeeds. **Shipped in C3.**
3. `Ack.string().parse(42)` no longer succeeds. **Shipped in C3.**
3a. `Ack.double().parse(42)` (int input) no longer succeeds — strict per A1. **Shipped in M11.**
3b. `Ack.datetime().encode(localDateTime)` no longer succeeds — must pass `value.toUtc()` per A3 (b). Error message points at `.toUtc()`. **Shipped in M14.**
3c. `Ack.date().encode(...)` rejects UTC `DateTime` and non-midnight values per A2 (a). Error does NOT advise `.toUtc()` (date is a calendar date, not an instant). **Shipped in M14.**
3d. `Ack.duration().encode(subMillisecondDuration)` now fails — sub-millisecond microseconds are no longer silently truncated. **Shipped in M14.**
3e. `Ack.uri().encode(relativeOrSchemeOnly)` now fails — encode requires scheme + authority. **Shipped in M14.**
4. `copyWith(defaultValue: x)` removed; use `.withDefault(x)`. **Shipped in C2.**
5. `AckSchema.defaultValue` field removed; defaults live exclusively on `DefaultSchema` wrapper. **Shipped in C2.**
6. `Ack.date()/datetime()/uri()/duration()` return `CodecSchema<…>` instead of `TransformedSchema<…>`. **Shipped in M14.**
7. `TransformedSchema<I,O>(schema, transformer, …)` positional constructor removed. The typedef alias itself is also removed (use `CodecSchema<I, O>`). **Shipped in M13 / removed in C5.**
8. `TransformedSchema.schema` and `TransformedSchema.transformer` removed. Replaced by `inputSchema`, `outputSchema`, `decoder`, `encoder`. **Shipped in M13.**
9. `.transform(...).safeEncode(...)` now fails with `SchemaEncodeError`. **Shipped in M13.**
10. `CodecSchema.toJsonSchema` emits `x-ack-codec: true` only. The legacy `x-transformed` marker is gone. **Originally dual-emission per B1; the dual-emit window was removed in C1 before any beta.12 release shipped.**
16a. `strictPrimitiveParsing` / `strictParsing(...)` API removed entirely — primitives are strict by definition. **Shipped in C4.**
11. `DiscriminatedObjectSchema` branch unwrap now drills through `CodecSchema` and `DefaultSchema`. Manual inspectors should use `unwrapDiscriminatedBranchSchema`. **Shipped in M10/M12.**
12. New `SchemaEncodeError` class — `switch (error)` exhaustiveness on `SchemaError` may break. **Shipped in M2.**
13. `SchemaContext` gains a non-default field `operation` (default `SchemaOperation.parse`). **Shipped in M1.**
14. `Ack.instance<T>()` and `Ack.codec<I,O>(...)` are new public API (not breaking but ship-blocking). **Shipped in M5.**
15. `Ack.codec(...)` requires `encoder` (DEC-C2). One-way construction goes through `.transform(...)` or direct `CodecSchema(..., encoder: null)`. **Shipped post-M5.**
16. `withDefault(...)` returns `DefaultSchema<T>` instead of a type-specific schema; type-specific fluent methods must be applied before `.withDefault(...)`. **Shipped in M12.**

---

## Ambiguities to Resolve Before / During Implementation

> **Status (M16.1 + C-cleanup):** all blocking and non-blocking items
> below are resolved. The locked decisions live in
> `codec-open-questions.md` (A1–A7 / B1–B5) and
> `codec-mid-implementation-decisions.md` (DEC-A / DEC-B / DEC-C /
> DEC-C2). The list is preserved here for historical traceability — do
> not treat any item as still open. For `(1)`, the original M11 sweep
> tightened only `Ack.double()`; the C3 cleanup extended strict
> primitive parsing to **all** primitive schemas before any beta.12
> release shipped.

Blocking (resolve before starting the affected milestone) — _all resolved_:

1. ~~**`Ack.double()` runtime policy (§7.1).**~~ → A1 (a), generalised by C3. All primitives are strict on parse and encode; `strictPrimitiveParsing` is gone (C4).
2. ~~**`Ack.date()` UTC/local rule (§8.1).**~~ → A2 (a). Implemented in M14. Encode rejects UTC and non-midnight; error does NOT advise `.toUtc()`.
3. ~~**`Ack.datetime()` UTC requirement (§8.2).**~~ → A3 (b). Implemented in M14. Strictly rejects non-UTC; error advises `value.toUtc()`.
4. ~~**EnumSchema integer index (§7.6).**~~ → A4. Implemented in M8. Parse keeps integer-index; `_validateRuntime`/encode require enum values.
5. ~~**AnyOf encode determinism (§7.4.2).**~~ → A5. Implemented in M9. First branch whose full `_validateRuntime` + `encodeBoundary` pipeline succeeds end-to-end wins.
6. ~~**Object encode pass-through of additional properties (§7.2.7).**~~ → A6. Implemented in M6. `additionalProperties: true` passes unknown keys through as-is.
7. ~~**`DefaultSchema` + nullable inner.**~~ → A7. Implemented in M12. `DefaultSchema(nullableInner).encode(null)` returns `null` via inner nullability; default never synthesized on encode.

Non-blocking — _all resolved_:

8. ~~JSON Schema marker scope on nested codecs (§10.2)~~ → emitted on every codec level (input-shape based per M15 converter rule).
9. ~~Default serialization through codec encode (§10.3) when codec is one-way~~ → omit `default` silently when `inner.safeEncode` fails (M12 patch).
10. ~~`parseAs` / `safeParseAs` retention~~ → retained (no migration required).
11. ~~`SchemaResult` generic-erasure helper~~ → `castFail` is in place.
12. ~~`Ack.instance<T>` constraints surface (§7.8)~~ → `.constrain` / `.refine` on `FluentSchema` mixin.
13. ~~Equality test specifics (§11)~~ → DEC-A applied; closure identity ignored, one-way vs bidirectional kept distinct. Regression test in `codec_schema_test.dart`.
14. ~~Sealed-class hierarchy audit~~ → `is TransformedSchema` is now `is CodecSchema` in production code (M13/M15); downstream packages re-tested clean in M15.
15. ~~`Ack.list(Ack.instance<Foo>())` non-JSON-serializable boundary~~ → documented at the `Ack.instance` factory and in the JSON-safety check inside `DefaultSchema.toJsonSchema`.

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

_(Historical — see the doc header for live status.)_

Implementation through M1–M16 is complete, followed by the C1–C8
pre-1.0 semantic cleanup. The seven blocking ambiguities listed above
were resolved before / during the milestones they affected; see
`codec-open-questions.md` for the locked decisions (with `Update`
blocks where C-cleanup superseded the original B-decision) and the
cross-references back to the milestone where each landed. Remaining
deferred work tracked elsewhere:

- `ack_generator` does not yet emit typed wrappers for `Ack.codec`,
  `Ack.instance`, or `DefaultSchema`. This is documented in
  `llms.txt` under "Supported AckType schema shapes".
