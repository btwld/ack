# ack codecs — master plan

> **Branch:** `claude/add-ack-codecs-bGth6` (`origin/main` is the merge target)
> **Status:** ready to merge — `dart format` clean, `dart analyze --fatal-infos`
> clean, 1072/1072 tests pass.
>
> **Audience:** any agent or human picking up this work. This document is
> self-contained. Read this first before touching the branch.

---

## 1. Goal

Bring **Zod 4.1's `z.codec` API** to ack with Dart-appropriate ergonomics. The
ack package already supports forward-only validation via `parseAndValidate` and
unidirectional `.transform(...)`. This branch adds the *backward* direction —
encoding a runtime value back to its boundary representation — plus the
infrastructure to compose codecs through objects, lists, and unions.

The primitive: `Ack.codec<I, O>(inputSchema, outputSchema, decode:, encode:)`.
The recipes: `Ack.codecs.*` for common boundary↔runtime pairs (ISO datetime,
URI, Duration, JSON, etc.). The methods: `safeEncode` / `encode` on every
`AckSchema`, mirroring `safeParse` / `parse`.

## 2. Why this matters

Without codecs:
- Users hand-roll inverses for every domain object that needs to round-trip
  through a wire format.
- Schemas built with `Ack.datetime()` / `Ack.uri()` / etc. parse just fine but
  there's no way to serialize back. Composition multiplies the pain.
- ack's selling point is "Zod for Dart"; missing the codec primitive is a
  visible gap once Zod 4.1 shipped (Aug 2025).

With codecs:
- One declaration covers both directions of a transformation.
- `Ack.object({...}).encode(parsed)` works end-to-end for any tree of codecs.
- A small recipe catalogue covers the 90% case (datetime, URI, JSON, etc.)
  without users writing closures.
- Errors carry structured paths in both directions — debugging is symmetric.

## 3. Reference: Zod 4.1 codec spec

Verified against [zod.dev/codecs](https://zod.dev/codecs) and the
[v4.1 release notes](https://github.com/colinhacks/zod/releases/tag/v4.1.0).

| Behavior | Shape |
|---|---|
| Codec primitive | `z.codec(input, output, { decode, encode })` |
| Methods on every schema | `.decode` / `.encode` / `.safeDecode` / `.safeEncode` (+ async variants) |
| Top-level shortcuts | `z.encode(schema, value)` / `z.decode(schema, value)` |
| Encode flow | (1) type-check value against output schema → (2) run encode → (3) validate against input |
| Defaults / `.catch()` | Forward-only; not synthesized on encode |
| Composition | Through `z.object`, `z.array`, `z.union`, `z.discriminatedUnion`, `z.pipe` |
| Unidirectional `.transform()` | Throws plain `Error` (NOT `ZodError`) on encode |
| `z.invertCodec(c)` | Swaps input/output and decode/encode |
| Errors | Standard `ZodError` with `issues[].path` |
| Built-in codecs | None — Zod ships a recipe page (copy-paste) instead |

## 4. Design decisions

### 4.1 Codec primitive (`CodecSchema<I, O>`)
- Two child schemas (`inputSchema: AckSchema<I>`, `outputSchema: AckSchema<O>`) plus two pure closures (`decode: O Function(I)`, `encode: I Function(O)`).
- Public closures stored as private fields `_decode` / `_encode` to avoid
  collision with the homonymous `decode()` / `encode()` methods.
- Forward (`parseAndValidate`): inputSchema → decode → outputSchema → codec-level constraints/refinements.
- Backward (`encodeValue`): output type-check → outputSchema → codec-level constraints/refinements → encode → inputSchema validation.
- Defaults are runtime-typed (`O`); never synthesized on encode (matches Zod).

### 4.2 Encode placement on the base class
- `safeEncode` / `encode` / `encodeValue` live on **every** `AckSchema` — not
  just `CodecSchema`. Composition needs this: `ObjectSchema.encodeValue`
  recursively dispatches to every child's `encodeValue`, including non-codec
  children (where it's a forward-validation pass).
- For non-codec primitive schemas (`StringSchema`, `IntegerSchema`, etc.), the
  default `encodeValue` is a runtime type check + constraints/refinements pass.
  Boundary form equals runtime form.
- `TransformedSchema.encodeValue` always fails closed with
  `SchemaUnidirectionalEncodeError` — transforms have no inverse.

### 4.3 Composite encode dispatch
- `ObjectSchema`: recurse over properties, collect errors with field paths.
  Explicit `null` for an optional non-nullable field is rejected (mirrors
  parse-side strictness).
- `ListSchema`: recurse over items, indexed paths.
- `AnyOfSchema`: try each member's `encodeValue`; first `Ok` wins; all-fail returns
  `SchemaNestedError` containing every branch's error.
- `DiscriminatedObjectSchema`: two-tier dispatch. Tier 1 — if runtime is a
  Map containing the discriminator, dispatch directly to that branch. Tier 2 —
  fall back to AnyOf-style "try each branch in turn" (covers sealed-class
  domain objects with codec branches). Tier 1 short-circuits with a clearer
  `SchemaUnidirectionalEncodeError` when the matched branch is a
  `TransformedSchema`.

### 4.4 Recipe catalogue (`Ack.codecs.*`)
- Following Zod's "ship recipes, not built-ins" stance: existing
  `Ack.datetime()` / `Ack.uri()` / `Ack.duration()` / `.trim()` / `.toLowerCase()` /
  `.toUpperCase()` stay parse-only. Their dartdoc points at the round-trippable
  recipe.
- Recipes shipped: `isoStringToDateTime`, `epochMillisToDateTime`, `stringToUri`,
  `intMillisToDuration`, `stringToInt`, `stringToDouble`, `stringToBigInt`,
  `json<T>(schema)`.

### 4.5 Custom runtime-type schema (`CustomSchema<T>`)
- The recommended output side for codecs whose runtime is a domain object.
- Validates that the runtime value is `T`; optional caller-provided predicate
  runs after the type check.
- `toJsonSchema` does NOT serialize runtime defaults — they have no portable JSON
  form. Defaults still apply at decode time.

### 4.6 Error model
**Decision: classify by *kind*, not by *direction*.**
- The error CLASS indicates *what* went wrong (constraint, type mismatch,
  refinement failure, transform throw, encode throw, structural mismatch).
- `path` and `context` indicate *where* in the graph it failed.
- *Direction* (parse vs encode) is implied by which method was called.
- Inner schema errors propagate verbatim during codec traversal — they are NOT
  wrapped in `SchemaTransformError` / `SchemaEncodeError`. Wrapping would obscure
  useful information (e.g. `TypeMismatchError`'s `expectedType`/`actualType`).
- An architectural review proposed wrapping; we chose **document over wrap**
  to preserve information richness.

### 4.7 Error class hierarchy (sealed)
```
SchemaError                    sealed   (base)
├── TypeMismatchError          final
├── SchemaConstraintsError     final
├── SchemaNestedError          final
├── SchemaValidationError      final
├── SchemaTransformError       final    (codec decode closure threw)
└── SchemaEncodeError          base     (codec encode closure threw, type mismatch on encode, etc.)
    └── SchemaUnidirectionalEncodeError   final   (.transform() on encode path)
```
- Sealing enables exhaustive switch matching via Dart 3 patterns.
- `SchemaEncodeError` must remain `base` (not `final`) so
  `SchemaUnidirectionalEncodeError` can extend it.
- External subclassing of `SchemaError` is no longer supported.

### 4.8 Public API surface
- **Codecs:** `Ack.codec(...)`, `CodecSchema<I,O>`, `Ack.custom(...)`,
  `Ack.codecs.*`, `CodecSchema.inverse()`.
- **Methods on every schema:** `parse` / `safeParse` / `encode` / `safeEncode`
  (loose-typed `Object?`).
- **Methods on `CodecSchema` only:** `decode(I?)` / `safeDecode(I?)` (typed
  entry points). `encode` returns `I?` and `safeEncode` returns
  `SchemaResult<I>` (covariant return narrowing on the base).
- **Top-level shortcuts:** `Ack.encode(schema, v)` / `Ack.decode(schema, v)` /
  `Ack.safeEncode` / `Ack.safeDecode`.

## 5. What landed

### 5.1 New files
- `lib/src/schemas/codec_schema.dart` — `CodecSchema<I,O>` (forward + backward
  pipelines, `inverse()`, typed `decode`/`encode` methods).
- `lib/src/schemas/custom_schema.dart` — `CustomSchema<T>`.
- `lib/src/codecs/recipes.dart` — `Codecs` namespace + 8 recipe factories.
- `test/schemas/codec_schema_test.dart` — 67+ test cases (codec basics, object
  integration, list integration, discriminated dispatch, AnyOf dispatch,
  inverse, copyWith, JSON Schema export, codec-in-codec, null strictness,
  additionalProperties, transform unidirectional rejection, plus a top-level
  `expectEncodeFailure(result, {messageContains})` helper).
- `test/codecs/recipes_test.dart` — round-trip tests per recipe + edge cases
  (UTC vs local DateTime, NaN/Infinity for double, deeply-nested JSON path
  preservation).

### 5.2 Modified files
- `lib/src/ack.dart` — `Ack.codec`, `Ack.custom`, `Ack.codecs`, `Ack.encode`/`decode`/`safeEncode`/`safeDecode`. Dartdoc on `Ack.date`/`datetime`/`uri`/`duration` points at recipes.
- `lib/src/schemas/schema.dart` — `safeEncode` / `encode` / `encodeValue` /
  `handleNullForEncode` on `AckSchema` base.
- `lib/src/schemas/transformed_schema.dart` — `final class` modifier;
  `encodeValue` raises `SchemaUnidirectionalEncodeError`.
- `lib/src/schemas/object_schema.dart` — `encodeValue` with explicit-null
  rejection for optional non-nullable fields.
- `lib/src/schemas/list_schema.dart` — `encodeValue` with indexed paths.
- `lib/src/schemas/any_of_schema.dart` — `encodeValue` with first-Ok-wins.
- `lib/src/schemas/discriminated_object_schema.dart` — `encodeValue` with
  two-tier dispatch + transform-branch short-circuit; `parseAndValidate` uses
  `case Fail(:final error)` destructure.
- `lib/src/schemas/extensions/string_schema_extensions.dart` — dartdoc note on
  `.trim()` / `.toLowerCase()` / `.toUpperCase()` flagging unidirectional.
- `lib/src/validation/schema_error.dart` — `SchemaError` is `sealed`; cascade
  modifiers on every subclass; new `SchemaUnidirectionalEncodeError`.
- `CHANGELOG.md` — Unreleased section: Features, Behavior changes, Improvements.
- `README.md` — new "Codecs (bidirectional transforms)" section.

### 5.3 Public API delta (Zod parity)
| Zod 4.1 | ack |
|---|---|
| `z.codec(in, out, { decode, encode })` | `Ack.codec(in, out, decode:, encode:)` |
| `.decode` / `.safeDecode` (typed input) | `CodecSchema.decode(I?)` / `safeDecode(I?)` |
| `.encode` / `.safeEncode` (everywhere) | `AckSchema.encode` / `safeEncode` (loose); `CodecSchema.encode` / `safeEncode` (typed return `I?`) |
| `z.encode(s, v)` / `z.decode(s, v)` | `Ack.encode(s, v)` / `Ack.decode(s, v)` |
| `z.invertCodec(c)` | `CodecSchema.inverse()` |
| Recipes (copy-paste page) | `Ack.codecs.*` (shipped) |
| `.transform()` encode → plain `Error` | → `SchemaUnidirectionalEncodeError` (subtype of `SchemaError`) |
| `ZodError` with `issues[].path` | `SchemaError` with structured `path` |

## 6. Verification

```bash
cd packages/ack
dart format . --set-exit-if-changed   # 0 changed
dart analyze --fatal-infos             # no issues
dart test                              # 1072/1072 pass
```

End-to-end smoke (paste into a `bin/main.dart`):
```dart
final user = Ack.object({
  'name': Ack.string(),
  'createdAt': Ack.codecs.isoStringToDateTime(),
});
final parsed = user.parse({
  'name': 'Ada',
  'createdAt': '2025-06-15T10:30:00Z',
});
final encoded = user.encode(parsed);
// encoded == {'name': 'Ada', 'createdAt': '2025-06-15T10:30:00.000Z'}
```

## 7. Intentionally deferred / out-of-scope

Each item below was explicitly considered and not done on this branch.

| Item | Reason | Where to revisit |
|---|---|---|
| `.pipe()` primitive | Zod's pipe flips direction on encode (B→A). ack has no pipe today. | Separate effort. |
| Async codecs (`decodeAsync`/`encodeAsync`) | ack is fully sync; async ripples through every method. | Separate effort, only if a real driver appears. |
| Make `Ack.datetime()` / `Ack.uri()` / `Ack.duration()` round-trip in place | Zod also keeps these one-way; recipes catalogue is the answer. | Permanent design decision. |
| `copyWith(defaultValue: null)` cannot clear a default | Project-wide pattern (every schema's `copyWith` does `param ?? this.param`). Codec-only fix would create an inconsistency. | Separate package-wide refactor. |
| Formal `@Deprecated` on `Ack.date`/`datetime`/`uri`/`duration` | Dartdoc already says "use `Ack.codecs.X` instead." Adding `@Deprecated` triggers analyzer warnings on every existing usage — needs an advertised cycle. | Separate deprecation PR after this lands. |
| Wrap inner schema errors during codec traversal | Would obscure information (e.g. `TypeMismatchError`'s `expectedType`/`actualType`). Documented over wrapped. | Revisit only if real users hit the asymmetry. |
| `Ack.encode` / `Ack.decode` static helpers | An architectural review called them redundant; we kept them for Zod parity. ~12 lines. | Keep. |
| `encode` on the base `AckSchema` (vs only on `CodecSchema`) | Composition needs it; matches Zod. | Keep. |
| Recipe `epochMillisToDateTime` rename to match Zod's exact wording | Already follows the `<int-with-unit>To<RuntimeType>` shape. | Skip. |
| `stringToUri` rejecting non-authority URIs (mailto:, urn:) | Tradeoff baked into `Ack.string().uri()` constraint. | Document as known boundary. |

## 8. File map

```
packages/ack/
├── CHANGELOG.md                                    # Unreleased section
├── README.md                                       # "Codecs" section
├── plan.md                                         # this document
├── lib/
│   ├── ack.dart                                    # barrel exports (unchanged)
│   └── src/
│       ├── ack.dart                                # Ack.codec, Ack.codecs, Ack.encode/decode
│       ├── codecs/
│       │   └── recipes.dart                        # Codecs class + 8 recipe factories
│       ├── schemas/
│       │   ├── any_of_schema.dart                  # encodeValue (first-Ok-wins)
│       │   ├── codec_schema.dart                   # CodecSchema<I,O> + inverse() + dartdoc error model
│       │   ├── custom_schema.dart                  # CustomSchema<T>
│       │   ├── discriminated_object_schema.dart    # encodeValue (two-tier + transform short-circuit)
│       │   ├── list_schema.dart                    # encodeValue (indexed paths)
│       │   ├── object_schema.dart                  # encodeValue (null strictness)
│       │   ├── schema.dart                         # AckSchema base: safeEncode, encodeValue, handleNullForEncode
│       │   ├── transformed_schema.dart             # final class; encodeValue raises Unidirectional error
│       │   └── extensions/
│       │       └── string_schema_extensions.dart   # dartdoc on .trim/.toLowerCase/.toUpperCase
│       └── validation/
│           └── schema_error.dart                   # sealed SchemaError tree + SchemaUnidirectionalEncodeError
└── test/
    ├── codecs/
    │   └── recipes_test.dart                       # 17 recipe round-trip + edge tests
    └── schemas/
        └── codec_schema_test.dart                  # 67+ codec/object/list/AnyOf/discriminated tests
```

## 9. Future work (suggested order)

1. **Formal deprecation cycle** for `Ack.date`/`datetime`/`uri`/`duration` —
   add `@Deprecated` annotations with a removal target, after this branch lands
   and the recipes are documented. ~1 PR.
2. **`.pipe()` primitive** — directional pipeline that flips direction on encode.
   Needs design work; ~2-3 PRs.
3. **Async codec variant** — `decodeAsync` / `encodeAsync` for I/O-bound codecs
   (e.g. JSON over network). Big surface change; needs a real use case.
4. **Codec-aware JSON Schema generation** — `CodecSchema.toJsonSchema`
   currently encodes the default to boundary form; could be extended with
   richer codec metadata for downstream tooling consumers.

## 10. Review history (for context)

This branch went through five review rounds before reaching merge state. Each
round caught new issues; this section is a record so future work can spot
patterns.

1. **Initial review** — caught the encode coverage gap on `AnyOfSchema` /
   `DiscriminatedObjectSchema`, the `decoder`/`encoder` naming inconsistency,
   the missing typed return on `safeEncode`.
2. **Best-practices pass** — class modifier mismatch on `SchemaEncodeError`,
   `inverse()` dropping description for no reason, NaN/Infinity in
   `stringToDouble`, local-vs-UTC asymmetry in `epochMillisToDateTime`.
3. **Code simplifier** — five sites in `CodecSchema` collapsed to
   `case Fail(:final error)` destructure pattern.
4. **Three-way third pass** (parallel: simplification, architecture,
   best-practices) — highlighted the json recipe path loss, discriminated
   transform-branch error, sealed `SchemaError` tree.
5. **Parallel execution + final acceptance** — four parallel sonnet agents
   landed the third-pass plan in distinct file domains. Final fresh-eyes
   review caught two missing `@immutable` annotations on sealed leaves;
   patched.

If you find another issue, expect it to be subtle — the obvious ones have all
been caught. Add a note to this section if you do another round.
