# ACK Codec — Open Questions for Maintainer Decision

**Companion to:** `codec-bidirectional-requirements.md` and `codec-implementation-milestones.md`
**Purpose:** Resolve every ambiguity that materially changes encode behaviour or error semantics before implementation begins. Each item has a recommendation, the rationale, and the milestone it blocks.

Maintainer: please reply inline (`Decision:` line per item). Once resolved, this doc becomes the authoritative reference for the implementer.

---

## A. Blocking Questions (must answer before the affected milestone)

### A1. `Ack.double()` runtime type policy

**Spec:** §7.1 says "`double` or selected numeric policy defined by the implementation." Under-specified.

**Question:** During encode, is `42` (int) an acceptable runtime value for `Ack.double()`?

**Options:**
- **(a)** Strict on encode, lenient on parse. `_validateRuntime` requires `value is double`; `parseAndValidate` continues to accept int when `strictPrimitiveParsing` is false.
- **(b)** Strict everywhere. Always require `double`.
- **(c)** Lenient everywhere. Accept int as double on both sides.

**Recommendation:** (a). Encode is the canonicalization side; parse is the boundary side. (a) preserves source-compatible parse and adds strict encode.

**Blocks:** M11.

**Decision:** **(b)** Strict everywhere. `Ack.double()` only accepts `double`; conversions must use codecs.

---

### A2. `Ack.date()` UTC and time-component handling on encode

**Spec:** §8.1 says "Reject UTC `DateTime` values **if the parse side produces local values** and round-trip identity depends on local dates." Conditional on parse behaviour that itself is unspecified.

**Question:** What does `Ack.date()` encode reject?

**Options:**
- **(a)** Reject UTC unconditionally. Reject any `DateTime` whose hour/minute/second/ms/us is non-zero. Output `YYYY-MM-DD` from local fields.
- **(b)** Accept UTC; canonicalize to local for date extraction. Reject non-midnight components.
- **(c)** Accept any `DateTime`; truncate time component silently.

**Recommendation:** (a). `DateTime.parse('2025-01-01')` returns local midnight by default, so rejecting UTC keeps round-trip identity. (c) hides bugs.

**Blocks:** M14.

**Decision:** **(a)** `Ack.date()` rejects UTC values and rejects non-midnight time components.

---

### A3. `Ack.datetime()` UTC requirement on encode

**Spec:** §8.2 says "Reject non-UTC values **if the reference implementation requires UTC-only canonical encoding**." Conditional on a choice that isn't pinned.

**Question:** What does `Ack.datetime()` encode do with a non-UTC `DateTime`?

**Options:**
- **(a)** Encode `value.toUtc().toIso8601String()` and accept non-UTC inputs (lossless; canonical UTC ISO-8601 output).
- **(b)** Strictly reject non-UTC values; require callers to call `.toUtc()` first.
- **(c)** Encode `value.toIso8601String()` as-is (preserves input timezone offset).

**Recommendation:** (a). Lossless and canonical; matches the spirit of "ISO-8601 datetime with timezone" in §8.2.

**Blocks:** M14.

**Decision:** **(b)** `Ack.datetime()` rejects non-UTC `DateTime` values; callers must pass `value.toUtc()` explicitly. The encode error message must mention `.toUtc()`.

---

### A4. `EnumSchema` legacy integer index

**Spec:** §7.6 says "any supported legacy integer index behavior **if maintained**."

**Question:** Does `EnumSchema` continue to accept integer indices (e.g. `0` → `E.values[0]`)?

**Options:**
- **(a)** Keep for parse, reject for `_validateRuntime`/encode.
- **(b)** Drop entirely (breaking change for any caller relying on it).
- **(c)** Keep on both sides.

**Recommendation:** (a). Parse is boundary-tolerant; encode is strict. Avoids a silent breaking change while honouring the "no implicit conversion drift" principle on the encode side.

**Blocks:** M8.

**Decision:** **(a)** `EnumSchema` keeps integer-index parsing for legacy boundary input; encode and `_validateRuntime` require enum values.

---

### A5. AnyOf encode determinism

**Spec:** §7.4.2 says "Return the first successful encode result." Ambiguous: first branch where `_validateRuntime` succeeds, or first whose full encode pipeline succeeds end-to-end?

**Question:** Which order wins?

**Options:**
- **(a)** First branch whose **full encode pipeline** (`_validateRuntime` + `encodeBoundary`) succeeds end-to-end. If `_validateRuntime` passes but `encodeBoundary` fails, try the next branch.
- **(b)** First branch whose `_validateRuntime` passes; if its `encodeBoundary` then fails, fail the whole AnyOf.

**Recommendation:** (a). Matches the spirit of branch trial in §7.5 (discriminated domain-object encode also tries branches until one succeeds end-to-end).

**Blocks:** M9.

**Decision:** **(a)** AnyOf encode chooses the first branch whose full encode pipeline (`_validateRuntime` + `encodeBoundary`) succeeds end-to-end.

---

### A6. Object encode pass-through of additional properties

**Spec:** §7.2.7 says "Pass through additional properties when allowed."

**Question:** When `additionalProperties: true`, does `encodeBoundary` copy unknown keys as-is, or recursively visit them?

**Options:**
- **(a)** Copy unknown keys as-is. No child schema exists, so no encode is possible.
- **(b)** Reject — even with `additionalProperties: true`, encode requires every key to have a schema.
- **(c)** Define an `additionalPropertiesSchema` field for typed pass-through; copy as-is if undefined.

**Recommendation:** (a) for now. (c) is a future enhancement; (b) is unnecessarily strict.

**Blocks:** M6.

**Decision:** **(a)** Object encode copies additional properties as-is when `additionalProperties` is true.

---

### A7. `DefaultSchema` interaction with nullable inner

**Spec:** §5.5 says encode of `null` fails unless schema is nullable. Doesn't say what happens when a `DefaultSchema` wraps a nullable inner.

**Question:** What does `DefaultSchema(SomeSchema.nullable(), defaultValue: x).encode(null)` return?

**Options:**
- **(a)** Returns `null` via the inner nullable encode. Default is parse-only and ignored on encode.
- **(b)** Synthesizes the default, then encodes (violates §5.5 "no hidden default synthesis during encode").
- **(c)** Fails with `SchemaEncodeError.nonNullable` (ignores the inner nullability).

**Recommendation:** (a). Defaults are strictly parse-only; nullability of the inner schema is the only thing that decides encode null behaviour.

**Blocks:** M12.

**Decision:** **(a)** `DefaultSchema(nullableInner).encode(null)` returns `null`; defaults are parse-only.

---

## B. §18 Open Decisions — Recommendations Awaiting Confirmation

### B1. JSON Schema marker

**§18.1.** Keep `x-transformed` for compatibility, or rename to `x-ack-codec`?

**Options:**
- **(a)** Emit **both** `x-transformed: true` and `x-ack-codec: true` for one beta cycle. Deprecate `x-transformed` at 1.0.0.
- **(b)** Keep `x-transformed` only.
- **(c)** Rename to `x-ack-codec` only (breaking for downstream consumers).

**Recommendation:** (a). Zero-breakage transition; downstream packages can migrate at their own pace.

**Decision:** **(a)** Emit both `x-transformed` and `x-ack-codec` for one beta cycle.

---

### B2. Decode-specific error class

**§18.2.** Add `SchemaDecodeError` symmetric to `SchemaEncodeError`, or keep using `SchemaTransformError`?

**Options:**
- **(a)** Defer — keep `SchemaTransformError` for decode; only add `SchemaEncodeError` now.
- **(b)** Add `SchemaDecodeError` immediately for symmetry.

**Recommendation:** (a). Symmetry is cosmetic; failure paths are still distinguishable today. File a follow-up issue.

**Decision:** **(a)** Defer `SchemaDecodeError`; keep `SchemaTransformError` for decode failures.

---

### B3. Codec equality and closures

**§18.3.** Should codec `decode`/`encode` closures be compared in equality, or ignored?

**Options:**
- **(a)** Ignore closure identity. Two `CodecSchema`s with equal `inputSchema` + `outputSchema` compare equal regardless of closures. Document the policy; add a regression test.
- **(b)** Include closure identity. Two `CodecSchema`s only compare equal if `identical(decode, other.decode) && identical(encode, other.encode)`.

**Recommendation:** (a). Closures aren't stably hashable; (b) produces non-deterministic equality.

**Decision:** **(a)** Codec equality ignores `decode`/`encode` closure identity.

---

### B4. Built-in coercion factories

**§18.4.** Ship `Ack.intFromString()`, `Ack.doubleFromString()`, `Ack.boolFromString()` with the codec MVP, or defer?

**Options:**
- **(a)** Defer to a follow-up minor release. Ship migration-guide examples instead.
- **(b)** Ship now as part of the codec MVP.

**Recommendation:** (a). Cosmetic; users can build them with `Ack.codec`. Avoids locking API names too early.

**Decision:** **(b)** Ship `Ack.intFromString()`, `Ack.doubleFromString()`, and `Ack.boolFromString()` with the codec MVP. *(Expands scope — see milestones doc M14a.)*

---

### B5. Release versioning

**§18.5.** Land as `1.0.0-beta.x` with breaking-change notes, or jump to a larger pre-2.0 marker?

**Options:**
- **(a)** Ship as `1.0.0-beta.12` with `BREAKING:` callouts. Stay in beta until downstream catches up. Final `1.0.0` after at least one beta cycle with codec support is published.
- **(b)** Ship as `2.0.0-pre.0` to signal the major transition.

**Recommendation:** (a). Already in `1.0.0-beta.x` per CHANGELOG. The migration is large but bounded; staying in beta gives a transition window.

**Decision:** **(a)** Release as `1.0.0-beta.12` with `BREAKING:` callouts.

---

## C. Non-Blocking Items — Decisions

| # | Item | Decision |
|---|---|---|
| C1 | JSON Schema marker scope on nested codecs (§10.2) | Emit codec markers at the codec schema node only; root marker only when the root schema itself is a codec. |
| C2 | Default serialization through codec encode (§10.3) when codec is one-way | If a default cannot be encoded through a one-way codec, omit the JSON Schema default silently and document the behaviour. |
| C3 | `parseAs` / `safeParseAs` retention | Keep them. |
| C4 | `SchemaResult` generic-erasure helper (§9.1) | Use the `SchemaResult.castFail` extension helper. |
| C5 | `Ack.instance<T>` constraints surface (§7.8) | `Ack.instance<T>()` supports `constrain`/`refine` only. |
| C6 | Equality regression test specifics (§11) | Equal input/output schemas imply codec equality, regardless of closure identity. |
| C7 | `is TransformedSchema` audit | Replace runtime `TransformedSchema` checks with `CodecSchema` checks. |
| C8 | `Ack.list(Ack.instance<Foo>())` produces a non-JSON-serializable boundary | Document that `Ack.instance<T>()` is not structurally JSON-serializable. |

---

## D. One Contradiction with Current Code

**§7.2.10 vs `ObjectSchema.parseAndValidate`.** The spec requires object-level constraints/refinements to run on the **runtime** map, not the encoded map. Today's `ObjectSchema.parseAndValidate` synthesizes defaults into the missing-optional path and runs constraints over that synthesized map. The encode path must take a **separate** code path that does not synthesize defaults (§7.2.5). Reusing `parseAndValidate` directly during encode would silently violate the spec.

**Implementation note:** M6 must add a separate `encodeBoundary` traversal. Do not refactor `parseAndValidate` into a shared helper.

**No maintainer decision required** — this is a flag for the implementer.

---

## How to Use This Doc

1. Maintainer adds `Decision:` lines under each item in §A and §B.
2. Implementer treats §C as "default unless told otherwise" — flag any divergence in the relevant PR.
3. Once §A and §B are answered, M1 can begin.
