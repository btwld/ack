# Codec Mid-Implementation Decisions

**Status:** Decided 2026-05-09. Updated 2026-05-09 with maintainer review clarifications. Locked. Apply before continuing M6.
**Branch:** `claude/install-dart-7RrSY`
**Position:** After M5 (`InstanceSchema` + `Ack.codec`/`Ack.instance` factories).

## Purpose

Three open items surfaced after M1–M5 landed. None of them were resolved by `codec-open-questions.md` (DEC-A is recorded there but had not been *applied* in the implementation; DEC-B and DEC-C are new). This doc records the resolution, the reasoning, and the cost.

The maintainer's standing instruction is: **breaking changes are acceptable when measurably beneficial**. That standard is what tipped DEC-B and DEC-C.

A maintainer review of these decisions surfaced additional clarifications and bug fixes. They are folded into this doc as DEC-C2 and "Pre-M5.5 fixes" below.

---

## DEC-A — `CodecSchema` closure equality

### Current state

`packages/ack/lib/src/schemas/codec_schema.dart:220-221`:

```dart
identical(decoder, other.decoder) && identical(encoder, other.encoder)
```

Two `CodecSchema` instances built from the same `Ack.codec(...)` call site — but in different scopes — currently compare unequal because the closures have different identity.

### Recorded position

`docs/plans/codec-open-questions.md:185` already records option **(a)** — ignore closure identity entirely. The wording there is broader than needed: it implies equal input/output schemas alone determine equality. The maintainer review tightened this — see "Refinement" below. The decision below is the version actually applied.

### Decision

Equality ignores **closure identity** but still distinguishes one-way codecs from bidirectional codecs. The applied form:

```dart
baseFieldsEqual(other) &&
    inputSchema == other.inputSchema &&
    outputSchema == other.outputSchema &&
    (encoder == null) == (other.encoder == null)
```

`hashCode` includes `encoder == null` (a `bool`), not the closure identity.

### Refinement (from maintainer review)

The earlier wording in `codec-open-questions.md:185` ("ignore closure identity entirely") would have made one-way and bidirectional codecs equal. That is wrong: a one-way codec fails on encode and a bidirectional codec succeeds — they are observably different and should compare unequal. The applied form preserves the *capability* distinction (`encoder == null` vs. `encoder != null`) while still ignoring closure value identity.

### Reasoning

- Closures are opaque — equality on them tells you nothing about behaviour.
- Codec equality is load-bearing for caching, dedup, discriminated-branch comparison, and value-equal schema fixtures in tests. Closure-identity equality silently breaks all of those.
- One-way vs. bidirectional is a capability distinction visible at the API boundary; equality must respect it.
- Anyone who wants identity comparison still has `identical(a, b)`.

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

## DEC-C2 — `Ack.codec(...)` requires `encoder`

### Current state (after DEC-C)

```dart
static CodecSchema<I, O> codec<I extends Object, O extends Object>({
  required AckSchema<I> input,
  required AckSchema<O> output,
  required O Function(I) decoder,
  I Function(O)? encoder,  // optional → public one-way codecs allowed
});
```

A user can write `Ack.codec(input:, output:, decoder:)` and get back a one-way codec. That contradicts the reference design: `Ack.codec(...)` is the bidirectional construction; `.transform(...)` and direct `CodecSchema(...)` construction are the only one-way paths.

### Decision

Make `encoder` `required` on the public factory:

```dart
static CodecSchema<I, O> codec<I extends Object, O extends Object>({
  required AckSchema<I> input,
  required AckSchema<O> output,
  required O Function(I) decoder,
  required I Function(O) encoder,
});
```

The internal `CodecSchema(...)` constructor keeps `encoder` nullable, so `.transform(...)` (M13) and any other internal one-way wiring still work.

### Reasoning

- "Codec" implies bidirectional. A factory called `Ack.codec` that silently produces one-way values is a semantic trap.
- `.transform(...)` is the named, documented path for one-way conversion. Funnel users there for one-way intent.
- Direct `CodecSchema(...)` construction stays available for advanced/internal use; it is not the recommended public API.

### Cost

- `Ack.codec(...)` signature in `packages/ack/lib/src/ack.dart`.
- One-way test in `test/instance_schema_test.dart` ("produces a one-way codec when encoder is omitted") — rewrite to construct `CodecSchema(...)` directly, since the public factory no longer permits this.
- Doc-comment update.

### Public API impact

Breaking. Acceptable per maintainer's standing instruction.

---

## Pre-M5.5 fixes (folded in from maintainer review)

These are not behavior-preserving — they are real bug fixes that must land **before** M5.5 begins, because M5.5 is itself a behavior-preserving refactor and these defects would survive it otherwise.

### Fix 1 — `SchemaEncodeError.typeMismatch` must not throw

`schema_error.dart:160-171` calls `AckSchema.getSchemaType(actualValue)` to format the error message. `SchemaType.of(...)` (the underlying call) throws `ArgumentError('Unknown schema type for value: $value')` for any value outside the JSON primitives — `DateTime`, `Uri`, `Duration`, user classes (`schema_type.dart:127-137`).

That makes `safeEncode(...)` throw while constructing the error, defeating the safety guarantee.

**Fix:** replace the `SchemaType expectedType` parameter with `Type expected`. Use `Object?.runtimeType` for the actual side. Result: format is always derivable, never throws.

```dart
factory SchemaEncodeError.typeMismatch({
  required Type expected,
  required Object? actual,
  required SchemaContext context,
}) {
  final actualLabel = actual == null ? 'null' : '${actual.runtimeType}';
  return SchemaEncodeError._(
    message: 'Encode failed: expected $expected, got $actualLabel.',
    context: context,
  );
}
```

Update the call sites in `schema.dart`. Add a regression test that calls `safeEncode(DateTime.now())` against an `Ack.string()` and verifies the result is `Fail(SchemaEncodeError)` — not a thrown exception.

### Fix 2 — Operation-aware errors in `_validateRuntime`

`_validateRuntime` was added in M3 with the encode pipeline in mind. It emits `SchemaEncodeError.nonNullable` and `SchemaEncodeError.typeMismatch` directly. But `CodecSchema.parseAndValidate` calls `outputSchema._validateRuntime(decoded, context)` during *parse* (to runtime-check the decoded output). When that fails on the parse path, the user sees a `SchemaEncodeError` for what was actually a parse-side failure.

**Fix:** branch on `context.operation`. When the operation is `parse`, emit parse-side errors (`NonNullableConstraint` / `SchemaValidationError` style); when it is `encode`, emit `SchemaEncodeError`. Add helpers:

```dart
SchemaError _failNullForRuntime(SchemaContext context) =>
    context.operation == SchemaOperation.encode
        ? SchemaEncodeError.nonNullable(context: context)
        : NonNullableConstraint(...).buildError(context: context);

SchemaError _failTypeMismatchForRuntime(Object? value, SchemaContext context) =>
    context.operation == SchemaOperation.encode
        ? SchemaEncodeError.typeMismatch(...)
        : InvalidTypeConstraint<DartType>(...).buildError(context: context);
```

Add a regression test: a codec with an output schema that rejects the decoded type, parsed (not encoded), produces a parse-side error class, not `SchemaEncodeError`.

### Fix 3 — `CodecSchema` applies refinements to the validated output value

`codec_schema.dart` currently runs:

```dart
final outputResult = outputSchema._validateRuntime(decoded, context);
if (outputResult.isFail) return outputResult;
return applyConstraintsAndRefinements(decoded, context);   // <-- decoded, not the validated value
```

This is wrong if `_validateRuntime` ever returns a canonical/transformed form (e.g. unmodifiable maps from `ObjectSchema` once it gets a runtime validator). Refinements must run on the value that came back from validation, not the raw decoded value.

**Fix:**

```dart
final outputResult = outputSchema._validateRuntime(decoded, context);
if (outputResult.isFail) return outputResult.castFail<O>();
final validated = outputResult.getOrThrow();
return applyConstraintsAndRefinements(validated as O, context);
```

Add a regression test: an output schema whose `_validateRuntime` produces a transformed value, used inside a codec, and a refinement that observes the *validated* value (not the raw decoded one).

### Out of scope for the pre-M5.5 fix bundle

- Object/list runtime canonicalization (unmodifiable maps/lists) — M6/M7.
- Strict primitive coercion — M11.
- DefaultSchema migration — M12.
- TransformedSchema unification — M13.
- Built-in codecs — M14.

---

## Application order (revised)

1. ~~**DEC-C**~~ — done in `d1b1594`.
2. ~~**DEC-A**~~ — done in `a5fe65a` (and the implementation already includes the one-way vs bidirectional refinement).
3. **DEC-C2** — make `encoder` required on `Ack.codec`. One commit.
4. **Pre-M5.5 fix bundle** — three TDD'd fixes (typeMismatch safety, operation-aware runtime errors, validated-output refinement). One commit.
5. **M5.5 (DEC-B)** — symmetric `decodeBoundary` hook migration. Behavior-preserving refactor. One commit. All tests stay green without test-side changes.
6. **Resume M6** (ObjectSchema recursive encode) using the new symmetric pattern.

## M5.5 implementation contract (locked)

```dart
// AckSchema base (final dispatcher; do not override).
SchemaResult<DartType> _parse(Object? input, SchemaContext context) {
  final nullResult = handleParseNull(input, context);
  if (nullResult != null) return nullResult;
  final decoded = decodeBoundary(input, context);
  if (decoded.isFail) return decoded;
  final value = decoded.getOrThrow();
  return applyConstraintsAndRefinements(value, context);
}

@protected
SchemaResult<DartType>? handleParseNull(Object? input, SchemaContext context);

@protected
SchemaResult<DartType> decodeBoundary(Object? input, SchemaContext context);
```

The base dispatcher owns the lifecycle. Individual schemas own boundary decoding semantics inside `decodeBoundary`. Coercion, default synthesis, and any other per-schema concerns stay inside each schema's `decodeBoundary` body — *do not* lift them into the dispatcher; that risks breaking `EnumSchema`, `AnyOfSchema`, `ObjectSchema`, `TransformedSchema`, and `CodecSchema`.

`parseAndValidate` is removed after migration. Grep all packages (`packages/ack`, `packages/ack_generator`, `packages/ack_firebase_ai`, `packages/ack_json_schema_builder`, `example`, `docs`) before deletion. Any reference must migrate in the same commit.

## Out of scope

- Renaming `parseAndValidate` → `_parse` is *not* a separate decision — it falls out of DEC-B and is the natural name.
- No public method renames. `parse`, `safeParse`, `encode`, `safeEncode` stay.
- No reflow of the milestones doc — M5.5 is appended as an inline addendum, the original ordering stays intact.
