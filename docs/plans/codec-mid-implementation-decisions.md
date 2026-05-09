# Codec Mid-Implementation Decisions

**Status:** Decided 2026-05-09. Locked. Apply before continuing M6.
**Branch:** `claude/install-dart-7RrSY`
**Position:** After M5 (`InstanceSchema` + `Ack.codec`/`Ack.instance` factories).

## Purpose

Three open items surfaced after M1–M5 landed. None of them were resolved by `codec-open-questions.md` (DEC-A is recorded there but had not been *applied* in the implementation; DEC-B and DEC-C are new). This doc records the resolution, the reasoning, and the cost.

The maintainer's standing instruction is: **breaking changes are acceptable when measurably beneficial**. That standard is what tipped DEC-B and DEC-C.

---

## DEC-A — `CodecSchema` closure equality

### Current state

`packages/ack/lib/src/schemas/codec_schema.dart:220-221`:

```dart
identical(decoder, other.decoder) && identical(encoder, other.encoder)
```

Two `CodecSchema` instances built from the same `Ack.codec(...)` call site — but in different scopes — currently compare unequal because the closures have different identity.

### Recorded position

`docs/plans/codec-open-questions.md:185` already records option **(a)** — ignore closure identity entirely. This decision was made but never applied to the code.

### Decision

**Apply (a).** Equality becomes:

```dart
baseFieldsEqual(other) &&
    inputSchema == other.inputSchema &&
    outputSchema == other.outputSchema
```

`hashCode` drops the `identityHashCode(decoder)` / `identityHashCode(encoder)` terms.

### Reasoning

- Closures are opaque — equality on them tells you nothing about behaviour.
- Codec equality is load-bearing for caching, dedup, discriminated-branch comparison, and value-equal schema fixtures in tests. Closure-identity equality silently breaks all of those.
- Anyone who wants identity comparison still has `identical(a, b)`.
- No down-side: no behaviour relies on `==` distinguishing two codecs that share the same schemas but were constructed at different sites.

### Cost

Test (1) + 5-line patch.

---

## DEC-B — `decodeBoundary` symmetric hook

### Current state

After M3:

- **Parse path:** `parseAndValidate(input, ctx)` does null + default + coerce + validate + decode in one method per schema.
- **Encode path:** `_validateRuntime(value, ctx)` → `encodeBoundary(value, ctx)`. Two hooks.

That asymmetry is `@protected`-only — subclass implementers see it; users don't.

### Options considered

1. **Skip.** Document the asymmetry, move on.
2. **Shim.** Add `decodeBoundary` whose default delegates to `parseAndValidate`. Existing overrides keep working. Permanently leaves both hooks in the codebase.
3. **Full migration.** Move null/default handling to a base-class dispatcher; every schema's parse logic moves to `decodeBoundary`. Result: three symmetric protected hooks (`_validateRuntime` / `decodeBoundary` / `encodeBoundary`).

### Decision

**Option 3 — full migration**, scheduled as a dedicated prep milestone **M5.5** before M6.

### Reasoning

- Every remaining milestone (M6–M11) touches each schema for encode work. Adding a parse-side rename in the same touch is marginal incremental cost, no separate migration risk.
- Null/default handling currently duplicates across every `parseAndValidate` override. Consolidating to one dispatcher kills a class of bugs (e.g. a subclass forgetting to skip default synthesis on encode).
- `CodecSchema.parseAndValidate` currently juggles boundary→runtime by hand: applies default → calls `inputSchema.parseAndValidate` → calls `decoder` → calls `outputSchema._validateRuntime`. With `decodeBoundary` it becomes `inputSchema.decodeBoundary` → `decoder` → `outputSchema._validateRuntime`. Default and null handling fall out of the base dispatcher. Approx 30 lines simpler.
- Permanent API symmetry. Subclass implementers don't have to remember "encode is two hooks, parse is one."
- M5.5 is a pure refactor: no behaviour change, no test changes, all 1049 existing tests stay green. Risk is therefore bounded.
- Option 2 (shim) is the worst long-term outcome: two hooks doing the same job with a fuzzy "which one do I override" answer.

### Cost

One refactor milestone (M5.5). Touches every schema's `parseAndValidate` override:

- `string_schema.dart`
- `num_schema.dart` (covers `IntegerSchema` + `DoubleSchema`)
- `boolean_schema.dart`
- `object_schema.dart`
- `list_schema.dart`
- `enum_schema.dart`
- `any_of_schema.dart`
- `discriminated_object_schema.dart`
- `any_schema.dart`
- `transformed_schema.dart`
- `codec_schema.dart`
- `instance_schema.dart`

Plus the base dispatcher in `schema.dart`. All existing tests must continue to pass without modification.

### Public API impact

None. `parse` / `safeParse` / `encode` / `safeEncode` keep the same signatures. The change is `@protected`.

### Subsequent milestone impact

M6 onward use `decodeBoundary` + `encodeBoundary` symmetrically. Cleaner per-schema diffs, smaller PRs, no special-casing.

---

## DEC-C — `decode`/`encode` vs `decoder`/`encoder` naming

### Current state

- `CodecSchema` fields: `decoder` (`O Function(I)`), `encoder` (`I Function(O)?`) — `codec_schema.dart:32,36`.
- `Ack.codec(...)` factory params: `decode`, `encode` — `ack.dart:92-93`.

The split exists because the field name `encode` would collide with the inherited `AckSchema.encode()` method added in M3. The workaround was introduced silently in M4 — no maintainer sign-off.

### Options considered

1. **Keep the split.** Public factory takes `decode`/`encode`; fields are `decoder`/`encoder`.
2. **Unify on `decoder`/`encoder`.** Factory becomes `Ack.codec(decoder: ..., encoder: ...)`.
3. **Unify on `decode`/`encode`.** Rename `AckSchema.encode()` to e.g. `encodeValue` so the field can be called `encode`.

### Decision

**Option 2 — unify on `decoder`/`encoder` everywhere.**

### Reasoning

- Dart's own `dart:convert` library uses exactly this convention. `Codec<S, T>` has *methods* `encode()` / `decode()` (verbs) and *getters* `encoder` / `decoder` returning `Converter` objects (nouns). That's literally what we have today on the field side; we should match it on the factory side.
- The verb/noun split is meaningful: `schema.encode(value)` is "do the encoding"; `codec.encoder` is "the function that does the encoding." Conflating them (option 3) loses information.
- `schema.encode(value)` is the obvious public API. Renaming it (option 3) makes every caller site worse forever to save four characters in one factory call.
- The spec wording (`Ack.codec(decode: ..., encode: ...)`) is prose, not API design. Updating the docs to `decoder`/`encoder` brings the docs into line with `dart:convert` rather than diverging from it.
- Keeping the split (option 1) is a load-bearing inconsistency between the public factory and the constructor — anyone reaching for `CodecSchema(...)` directly hits the asymmetry.

### Cost

- `Ack.codec(...)` factory params: `decode` → `decoder`, `encode` → `encoder` (`ack.dart`).
- Doc-comment example block in the factory.
- Tests using `Ack.codec(decode: ..., encode: ...)` — small grep.
- Spec doc updates: `codec-bidirectional-requirements.md` examples, `codec-implementation-milestones.md` examples.

Approx 10–15 lines.

### Public API impact

Breaking change to the factory call signature. Acceptable per maintainer's standing instruction; no users yet (codec work is on a feature branch, no beta release).

---

## Application order

1. **DEC-C first** (rename factory params + tests). One commit.
2. **DEC-A second** (closure equality + regression test). One commit.
3. **DEC-B third** as M5.5 (symmetric hook migration). One refactor commit. All 1049 tests stay green.
4. **Resume M6** (ObjectSchema recursive encode) using the new symmetric pattern.

After application, the milestones doc adds M5.5 between M5 and M6. The requirements doc gets `decoder`/`encoder` substitutions in the API examples. The open-questions doc gains a back-reference to this file under DEC-B and DEC-C.

## Out of scope

- Renaming `parseAndValidate` → `_parse` (the dispatcher) is *not* a separate decision — it falls out of DEC-B and is the natural name. If it turns out to be confusing, fix in the same commit.
- No public method renames. `parse`, `safeParse`, `encode`, `safeEncode` stay.
- No reflow of the milestones doc — M5.5 is appended as an inline addendum, the original ordering stays intact.
