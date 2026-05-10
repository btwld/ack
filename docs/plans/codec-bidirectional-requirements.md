# ACK Bidirectional Codec Reference Requirements

**Project:** `btwld/ack`
**Document type:** Product and technical requirements
**Audience:** Dart package maintainers, ACK contributors, generator/converter package maintainers, reviewers
**Status:** Reference design requirements
**Basis:** Reviewed codec reference implementation in PR #105 (`feat: bidirectional codec support`) and current ACK schema architecture.

---

## 1. Executive Summary

ACK shall support Zod-like bidirectional codecs as a first-class schema capability. A schema must be able to validate and decode external boundary data into runtime Dart values, then encode runtime Dart values back to the boundary representation through the same schema graph.

The reference model is:

```text
parse / safeParse:
  boundary value -> runtime value

encode / safeEncode:
  runtime value -> boundary value
```

The implementation shall prioritize semantic correctness, invariant safety, explicit conversion, composability, local clarity, and minimal meaningful abstractions. Performance remains a constraint, not the primary optimization target.

The codec system shall be implemented around `CodecSchema<I, O> extends AckSchema<O>`, where `I` is the boundary/input type and `O` is the runtime/output type. `AckSchema<T>` continues to mean: “a schema whose parsed runtime value is `T`.”

---

## 2. Design Principles

The requirements in this document follow these implementation principles:

1. **Semantic correctness first.** Code structure must preserve the distinction between boundary data and runtime data.
2. **One source of truth for traversal.** Object, list, union, and discriminated schemas must not duplicate ad hoc encode/decode logic.
3. **Abstractions must pay rent.** Each abstraction must protect an invariant, remove duplicated meaning, or make behavior easier to verify.
4. **No implicit conversion drift.** Primitive schemas validate primitive runtime types. Conversion belongs in codecs.
5. **No hidden default synthesis during encode.** Defaults are parse-side behavior only.
6. **Nested schemas must compose.** A codec must work at the top level and inside objects, lists, unions, and discriminated schemas.
7. **Errors must preserve location.** Nested failures must retain JSON Pointer paths such as `#/user/createdAt`.
8. **One-way transforms must remain one-way.** Encoding through `.transform(...)` must fail clearly rather than pretending a reverse function exists.

---

## 3. Terminology

| Term | Meaning |
| --- | --- |
| Boundary value | The external representation accepted from JSON, wire data, database payloads, or other untyped/serialized inputs. |
| Runtime value | The Dart-side value produced after parsing, validation, and decoding. |
| Codec | A bidirectional schema that decodes `I -> O` and encodes `O -> I`. |
| Transform | A one-way conversion used during parse only. It has no valid encode direction. |
| Input schema | The boundary-side schema of a codec. It validates `I`. |
| Output schema | The runtime-side schema of a codec. It validates `O`. |
| Runtime validation | Validation of already-decoded Dart values. |
| Boundary decoding | Parse-side validation and conversion from external data. |
| Boundary encoding | Encode-side conversion from runtime data back to external representation. |
| Parse default | A value supplied only when parse input is `null` or a missing optional object field with default behavior. |

---

## 4. Scope

### 4.1 In Scope

The codec feature shall include:

- `Ack.codec<I, O>(input:, output:, decoder:, encoder:)`.
- `Ack.instance<T>()` for runtime type guarding.
- `encode(...)` and `safeEncode(...)` on all `AckSchema` instances.
- Recursive encoding for object and list schemas.
- Encoding support for `AnyOfSchema`, `DiscriminatedObjectSchema`, and `EnumSchema`.
- One-way `.transform(...)` implemented as a one-way codec.
- Parse-only defaults implemented through a wrapper schema.
- Built-in round-tripping codecs for `Ack.date()`, `Ack.datetime()`, `Ack.uri()`, and `Ack.duration()`.
- JSON Schema output based on boundary/input shape.
- Migration guidance for removed implicit coercion and old transform/default APIs.

### 4.2 Out of Scope

The following are not required for the initial reference release:

- Automatic codec derivation for arbitrary Dart classes.
- Automatic inverse generation for `.transform(...)`.
- Runtime reflection-based structural validation of custom classes beyond `Ack.instance<T>()`.
- Guaranteeing `encode(parse(x)) == x` for non-canonical boundary values.
- Guaranteeing equality of codec behavior by comparing closure bodies.
- Asynchronous codecs.
- Streaming encode/decode.

---

## 5. Public API Requirements

### 5.1 Codec Factory

ACK shall expose:

```dart
static CodecSchema<I, O> codec<I extends Object, O extends Object>({
  required AckSchema<I> input,
  required AckSchema<O> output,
  required O Function(I value) decoder,
  required I Function(O value) encoder,
});
```

Requirement details:

- `input` validates the boundary/input value.
- `output` validates the runtime/output value.
- `decoder` runs after successful input validation.
- `encoder` runs after successful output validation.
- The returned schema parses to `O` and encodes to boundary shape `I` or a recursively encoded form of `I`.
- Naming follows `dart:convert`: methods are verbs (`encode`/`decode`), the
  function-typed fields holding them are nouns (`encoder`/`decoder`).
- **`Ack.codec(...)` is bidirectional by definition.** Both `decoder`
  and `encoder` are required (DEC-C2). For one-way conversions use
  `schema.transform<R>(...)`, which constructs a one-way `CodecSchema`
  (`encoder: null`) internally. Direct `CodecSchema(..., encoder: null)`
  construction is reserved for advanced/internal use (e.g. the
  `.transform` extension's implementation).

Example:

```dart
final bigIntCodec = Ack.codec<String, BigInt>(
  input: Ack.string().matches(r'^-?\d+$'),
  output: Ack.instance<BigInt>(),
  decoder: BigInt.parse,
  encoder: (value) => value.toString(),
);
```

### 5.2 Runtime Instance Schema

ACK shall expose:

```dart
static InstanceSchema<T> instance<T extends Object>();
```

`Ack.instance<T>()` shall validate `value is T` and may be used as the output schema of a codec when ACK cannot structurally validate the runtime object.

Example:

```dart
Ack.codec<String, Uri>(
  input: Ack.string().uri(),
  output: Ack.instance<Uri>(),
  decoder: Uri.parse,
  encoder: (value) => value.toString(),
);
```

### 5.3 Encode Methods

Every `AckSchema<T>` shall expose:

```dart
Object? encode(Object? value, {String? debugName});
SchemaResult<Object> safeEncode(Object? value, {String? debugName});
```

Behavior:

- `encode(...)` throws `AckException` on failure.
- `safeEncode(...)` never throws and returns `SchemaResult<Object>`.
- Encoded outputs may be `null` if the schema is nullable and value is `null`.
- Composite encoders return unmodifiable maps/lists where applicable.

### 5.4 Transform Method

`.transform<R>(...)` shall remain a parse-only operation but shall be implemented as a one-way `CodecSchema<T, R>` with no encoder.

```dart
CodecSchema<T, R> transform<R extends Object>(
  R Function(T value) transformer,
);
```

Encoding through a transformed schema shall fail with a `SchemaEncodeError` explaining that the schema is one-way and that `Ack.codec(...)` is required for bidirectional behavior.

### 5.5 Defaults

Defaults shall be applied through:

```dart
schema.withDefault(value)
```

`withDefault` shall return a wrapper schema such as `DefaultSchema<T>`.

Defaults are parse-only:

```text
parse(null)  -> default, if configured and valid
encode(null) -> failure unless schema is nullable
```

---

## 6. Core Semantic Requirements

### 6.1 Parse Direction

For `CodecSchema<I, O>`, parse shall follow this sequence:

```text
1. Receive boundary input.
2. Validate/decode through inputSchema.
3. If input validation fails, return that error.
4. Run decode(I) -> O.
5. If decode throws, wrap as a schema transform/decode error.
6. Validate O through outputSchema runtime validation.
7. Apply codec-level constraints/refinements.
8. Return O.
```

### 6.2 Encode Direction

For `CodecSchema<I, O>`, encode shall follow this sequence:

```text
1. Receive runtime value.
2. Validate O through outputSchema runtime validation.
3. Apply codec-level constraints/refinements as part of runtime validation.
4. If validation fails, return that error.
5. Run encode(O) -> I.
6. If encode throws, wrap as SchemaEncodeError.
7. Recursively encode/validate through inputSchema.
8. Return boundary-shaped output.
```

### 6.3 Runtime Validation vs Boundary Decoding

The implementation shall separate these operations:

```dart
_validateRuntime(...)
decodeBoundary(...)
encodeBoundary(...)
```

- `_validateRuntime` validates already-decoded runtime values.
- `decodeBoundary` validates and decodes boundary values during parse.
- `encodeBoundary` encodes validated runtime values during encode.

This separation prevents encode from accidentally accepting boundary values through parse/coercion rules.

### 6.4 Directional Context

`SchemaContext` shall carry a direction flag:

```dart
enum SchemaOperation { parse, encode }
```

The operation shall be preserved across child contexts. Direction-sensitive behavior, especially defaults and encode-specific errors, shall use this field rather than ad hoc booleans.

---

## 7. Schema-Specific Requirements

### 7.1 Primitive Schemas

All primitive schemas validate exact runtime primitive types:

| Schema | Runtime type accepted |
| --- | --- |
| `Ack.string()` | `String` |
| `Ack.integer()` | `int` |
| `Ack.double()` | `double` |
| `Ack.boolean()` | `bool` |

Implicit primitive coercion is not part of the public surface. For
explicit boundary conversion use `Ack.codec(...)`.

```dart
Ack.string().safeParse('hi'); // ok
Ack.string().safeParse(42);   // fail
Ack.integer().safeParse(42);  // ok
Ack.integer().safeParse('42');// fail
Ack.double().safeParse(3.14); // ok
Ack.double().safeParse(42);   // fail
Ack.boolean().safeParse(true);   // ok
Ack.boolean().safeParse('true'); // fail
```

Boundary conversions should be implemented with codecs:

```dart
final intStringCodec = Ack.codec<String, int>(
  input: Ack.string().matches(r'^-?\d+$'),
  output: Ack.instance<int>(),
  decoder: int.parse,
  encoder: (value) => value.toString(),
);
```

Tested recipes for `string ↔ int / double / bool` (including a radix
example) live in `packages/ack/test/migration_recipes_test.dart`.

### 7.2 ObjectSchema

Object encode shall:

1. Validate that runtime input is a map with string keys.
2. Encode each known property recursively.
3. Omit missing optional fields.
4. Fail missing required fields.
5. Never synthesize parse defaults during encode.
6. Reject unknown fields unless `additionalProperties` is true.
7. Pass through additional properties when allowed.
8. Preserve nested error paths.
9. Return an unmodifiable encoded map.
10. Run object-level constraints/refinements on the runtime map, not the encoded map.

### 7.3 ListSchema

List encode shall:

1. Validate that runtime input is a list.
2. Validate and encode each item recursively.
3. Preserve index paths such as `#/items/0` or `#/0`.
4. Reject null items where ACK list semantics require non-null elements.
5. Return an unmodifiable encoded list.
6. Run list-level constraints/refinements on the runtime list.

### 7.4 AnyOfSchema

`AnyOfSchema` encode shall:

1. Try branches in declaration order.
2. Return the first successful encode result.
3. Aggregate branch errors when no branch matches.
4. Preserve the parent path by using empty path segments for internal branches.
5. Apply union-level constraints/refinements to the runtime value before returning encoded output.

### 7.5 DiscriminatedObjectSchema

Discriminated schema encode shall support two cases:

1. Runtime value is a map with the discriminator field.
2. Runtime value is a non-map domain object and branch schemas are tried until one can encode it.

Requirements:

- Missing discriminator fails at the discriminator field path.
- Non-string discriminator fails at the discriminator field path.
- Unknown discriminator fails at the discriminator field path.
- Branch shape inspection must unwrap codec and default wrappers.
- Branches must be object-backed for JSON Schema/discriminator checks.
- Branch-level errors must not pollute paths with internal branch names.

### 7.6 EnumSchema

Enum parse/decode shall accept enum values, enum names, and any supported legacy integer index behavior if maintained.

Enum encode shall output the enum `.name` string.

Wrong runtime type during encode shall be reported as `SchemaEncodeError.typeMismatch`, not as an “invalid enum value” constraint failure.

### 7.7 AnySchema

`AnySchema` shall accept any non-null runtime value unless nullable/default semantics dictate otherwise.

Encode shall return the runtime value unchanged.

### 7.8 InstanceSchema

`InstanceSchema<T>` shall:

- Validate `value is T`.
- Support nullability.
- Support constraints/refinements.
- Return the value unchanged during encode.
- Emit an unconstrained JSON Schema shape because the runtime class is not directly representable as serialized JSON Schema.

---

## 8. Built-In Codec Requirements

### 8.1 `Ack.date()` _(decision A2 (a))_

`Ack.date()` shall be a codec between:

```text
String boundary: YYYY-MM-DD
DateTime runtime: local DateTime at midnight
```

Encode requirements:

- **Reject UTC `DateTime`.** A date is a calendar date, not an
  instant; for instants/timestamps callers should use `Ack.datetime()`.
  The encode error message must NOT advise `.toUtc()` (that would push
  callers in the wrong direction).
- **Reject any value with non-zero time components**
  (hour/minute/second/millisecond/microsecond).
- **Output `YYYY-MM-DD`** built from the local `year`/`month`/`day`
  fields, with month and day zero-padded to two digits.

### 8.2 `Ack.datetime()` _(decision A3 (b))_

`Ack.datetime()` shall be a codec between:

```text
String boundary: ISO-8601 datetime with timezone
DateTime runtime: UTC DateTime
```

Encode requirements:

- **Encode UTC `DateTime` values using `toIso8601String()`.**
- **Reject non-UTC values.** The encode error message shall advise
  `value.toUtc()` so callers can canonicalize before encoding.

### 8.3 `Ack.uri()`

`Ack.uri()` shall be a codec between:

```text
String boundary: absolute URI
Uri runtime: Uri
```

Encode requirements:

- Reject relative URIs.
- Require scheme and authority when matching the parse-side validation contract.
- Output `Uri.toString()`.

### 8.4 `Ack.duration()`

`Ack.duration()` shall be a codec between:

```text
int boundary: whole milliseconds
Duration runtime: Duration
```

Encode requirements:

- Reject durations that cannot be represented as whole milliseconds.
- Output `duration.inMilliseconds`.

---

## 9. Error Handling Requirements

### 9.1 Result Model

All safe operations shall return `SchemaResult<T>`.

- `safeParse(...)` returns `SchemaResult<T>`.
- `safeEncode(...)` returns `SchemaResult<Object>`.
- Failures shall preserve their original `SchemaError` type when generic casts are required.

### 9.2 Encode Errors

Encode-specific failures shall use `SchemaEncodeError`.

Required cases:

- Runtime value has wrong type.
- Non-nullable schema receives `null` during encode.
- One-way transform is encoded.
- User-supplied `encode` closure throws.
- Required object property is missing during encode.
- Additional property is present when `additionalProperties` is false.

### 9.3 Decode/Transform Errors

Decode closure failures may use the existing `SchemaTransformError` for compatibility, but a future `SchemaDecodeError` may be introduced for symmetry.

### 9.4 Path Preservation

Nested errors shall use JSON Pointer style paths:

```text
#
#/createdAt
#/items/0
#/user/settings/theme
```

Internal wrappers such as `anyOf` branches or discriminated branch names shall not appear in user-facing paths unless explicitly intended.

---

## 10. JSON Schema and Converter Requirements

### 10.1 Boundary Shape

JSON Schema output for codecs shall describe the boundary/input shape, not the runtime/output Dart object.

Example:

```dart
Ack.datetime().toJsonSchema()
```

shall describe a string datetime, not a Dart `DateTime` instance.

### 10.2 Codec Marker

Codec JSON Schema output shall include exactly one extension marker:

```json
{"x-ack-codec": true}
```

The legacy `x-transformed` marker is gone. Downstream converters MUST
key off `x-ack-codec`.

### 10.3 Default Serialization

Default values in JSON Schema shall be serialized to boundary representation where possible.

If a default wraps a codec, JSON Schema default serialization should run through codec encode so the emitted default matches the boundary format.

### 10.4 Converter Packages

Downstream converters shall treat `CodecSchema` according to target semantics:

- JSON Schema-style targets should convert the input/boundary schema.
- Runtime-object targets may reject codecs or convert the output schema.

---

## 11. Equality and Hashing Requirements

Schema equality shall be structural and deterministic.

For `CodecSchema<I, O>`, equality shall include:

- base schema fields
- input schema
- output schema

Closure identity for `decode` / `encode` may be intentionally ignored to avoid unstable function comparison. If ignored, this behavior must be documented and covered by tests.

---

## 12. Migration Requirements

### 12.1 `TransformedSchema`

`TransformedSchema<I, O>` is removed (the deprecated typedef alias is
gone). Use `CodecSchema<I, O>` directly.

Migration guidance:

- The old positional constructor is no longer available.
- Old `.schema` and `.transformer` fields are no longer available.
- Use `CodecSchema.inputSchema`, `CodecSchema.outputSchema`,
  `CodecSchema.decoder`, and `CodecSchema.encoder` instead.
- Use `Ack.codec(...)` for bidirectional conversion;
  `schema.transform(...)` (returns one-way `CodecSchema`) for
  parse-only.

### 12.2 Primitive Coercion

All primitive schemas are strict. Implicit conversions are not part of
the public surface — use `Ack.codec(...)` for explicit boundary
conversion.

The following all now fail; build a codec to migrate:

```dart
Ack.string().parse(42);       // fail
Ack.integer().parse('42');    // fail
Ack.integer().parse(42.0);    // fail
Ack.boolean().parse('true');  // fail
Ack.double().parse(42);       // fail
```

Replacement codec (works today, and the same recipe scales to the
other primitives — see `packages/ack/test/migration_recipes_test.dart`):

```dart
final intFromString = Ack.codec<String, int>(
  input: Ack.string().matches(r'^-?\d+$'),
  output: Ack.instance<int>(),
  decoder: int.parse,
  encoder: (value) => value.toString(),
);
```

### 12.3 Defaults

Old constructor/copyWith default plumbing shall migrate to:

```dart
schema.withDefault(value)
```

Docs shall clearly state that defaults are parse-only.

---

## 13. Acceptance Criteria

| ID | Requirement | Acceptance Criteria |
| --- | --- | --- |
| AC-01 | Top-level codec parse | `Ack.codec<String, int>(...).parse('42')` returns `42`. |
| AC-02 | Top-level codec encode | `Ack.codec<String, int>(...).encode(42)` returns `'42'`. |
| AC-03 | Input validation precedes decode | Invalid input schema prevents `decode` from running. |
| AC-04 | Output validation precedes encode | Invalid runtime value prevents `encode` from running. |
| AC-05 | Decode closure failure | Thrown decode errors are wrapped in schema error result. |
| AC-06 | Encode closure failure | Thrown encode errors are wrapped in `SchemaEncodeError`. |
| AC-07 | Nested object codec | `Ack.object({'d': Ack.datetime()}).encode(...)` emits string datetime. |
| AC-08 | Nested list codec | `Ack.list(Ack.datetime()).encode([...])` emits list of strings. |
| AC-09 | Optional missing encode | Missing optional object fields are omitted without validation/default synthesis. |
| AC-10 | Required missing encode | Missing required object fields fail with encode error. |
| AC-11 | Defaults parse-only | `schema.withDefault(x).parse(null)` uses default; `encode(null)` fails unless nullable. |
| AC-12 | Transform one-way | `.transform(...).safeEncode(...)` fails with message pointing to `Ack.codec`. |
| AC-13 | Enum encoding | `Ack.enumValues(E.values).encode(E.x)` emits `'x'`. |
| AC-14 | AnyOf encoding | Branches are tried in order; errors aggregate if no branch matches. |
| AC-15 | Discriminated encode | Map values dispatch by discriminator; bad discriminator errors point to discriminator path. |
| AC-16 | JSON Schema boundary output | Codec JSON Schema describes input schema, not runtime schema. |
| AC-17 | Path preservation | Nested encode/decode failures retain precise JSON Pointer paths. |
| AC-18 | Built-in round-trip | Date, datetime, URI, duration codecs round-trip valid canonical values. |
| AC-19 | Strict primitive schemas | All primitive schemas reject boundary values that require conversion. `Ack.string().parse(42)`, `Ack.integer().parse('42')`, `Ack.integer().parse(42.0)`, `Ack.boolean().parse('true')`, `Ack.double().parse(42)`, and `Ack.double().parse('42.0')` all fail. Use `Ack.codec(...)` for explicit conversion; migration recipes live in `test/migration_recipes_test.dart`. |
| AC-20 | Test suite | Package tests pass; converter packages updated for `CodecSchema`. |

---

## 14. Test Matrix

### 14.1 Core Codec Tests

- Identity codec parse/encode.
- String to int parse/encode.
- String to `DateTime` parse/encode.
- Decode error wrapping.
- Encode error wrapping.
- Output validation prevents encode closure.
- Input validation prevents decode closure.
- Codec-of-codec recursive boundary encoding.

### 14.2 Composite Tests

- Object with nested codec field.
- Object with missing optional field.
- Object with missing required field.
- Object with additional properties disabled/enabled.
- List of codecs.
- Nested list inside object.
- Object/list refinements run against runtime values.
- Encoded maps/lists are unmodifiable.

### 14.3 Union Tests

- AnyOf branch order.
- AnyOf error aggregation.
- AnyOf nullable behavior.
- AnyOf refinement sees runtime value.

### 14.4 Discriminated Tests

- Valid map discriminator dispatch.
- Missing discriminator path.
- Non-string discriminator path.
- Unknown discriminator path.
- Object-backed branch unwrapping through codec/default wrappers.
- Domain object branch trial for codec-backed branches.

### 14.5 Default Tests

- Parse default works.
- Default validates through output schema.
- Encode does not synthesize default.
- JSON Schema default serializes to boundary value.
- Default cloning prevents shared mutable state.

### 14.6 Built-In Codec Tests

- `Ack.date()` canonical boundary/runtime round-trips.
- `Ack.datetime()` UTC round-trips.
- `Ack.uri()` absolute URI round-trips.
- `Ack.duration()` whole millisecond round-trips.
- Invalid runtime values fail encode.

### 14.7 Migration Tests

- `.transform(...)` parse still works.
- `.transform(...)` encode fails clearly with
  `SchemaEncodeError.oneWayTransform`.
- All primitives are strict: `Ack.string().parse(42)`,
  `Ack.integer().parse('42')`, `Ack.integer().parse(42.0)`,
  `Ack.boolean().parse('true')`, and `Ack.double().parse(42)` all
  fail. Tested migration recipes in
  `test/migration_recipes_test.dart` show how to build `string ↔ int`
  / `double` / `bool` codecs explicitly with `Ack.codec(...)`.

---

## 15. Implementation Requirements by File Area

| Area | Required work |
| --- | --- |
| `schemas/schema.dart` | Introduce operation direction, runtime validation, boundary decode, boundary encode, `safeEncode`, `encode`, and generic failure casting. |
| `schemas/codec_schema.dart` | Implement `CodecSchema<I, O>` with input/output schemas, decoder, encoder (nullable on the internal constructor only — supports `.transform(...)`'s one-way path; the public `Ack.codec(...)` factory requires encoder per DEC-C2), JSON Schema marker, and equality. |
| `schemas/default_schema.dart` | Implement parse-only default wrapper and boundary default serialization. |
| `schemas/instance_schema.dart` | Implement runtime type guard schema. |
| `schemas/object_schema.dart` | Refactor validation/decode and implement recursive encode. |
| `schemas/list_schema.dart` | Refactor validation/decode and implement recursive encode. |
| `schemas/any_of_schema.dart` | Support runtime validation, boundary decode, and encode branch traversal. |
| `schemas/discriminated_object_schema.dart` | Support map discriminator dispatch and branch-trial encode. |
| `schemas/enum_schema.dart` | Split runtime validation from boundary decode and encode as `.name`. |
| `schemas/extensions/ack_schema_extensions.dart` | Implement `.transform(...)` as one-way codec and `.withDefault(...)` wrapper. |
| `validation/schema_error.dart` | Add `SchemaEncodeError`. |
| `context.dart` | Add `SchemaOperation` to context and preserve it for children. |
| `utils/discriminated_branch_utils.dart` | Unwrap codec/default wrappers and validate discriminator-literal compatibility. |
| `converters/*` | Convert `CodecSchema` as input/boundary schema for serialized targets. |
| docs/tests | Update public docs, migration notes, and examples. |

---

## 16. Non-Functional Requirements

### 16.1 Maintainability

- New behavior should be implemented through small semantic hooks rather than repeated type-switch logic.
- Directional behavior must be explicit through `SchemaOperation`.
- Helper names should describe semantics, not mechanics.

### 16.2 Testability

- Every directional rule must have a regression test.
- Nested path preservation must be tested for object, list, union, and transform encode failure.
- Built-in codecs must be round-trip tested.

### 16.3 Performance

- Encode/decode traversal should be linear in the number of visited schema nodes and input values.
- Missing optional fields during encode should be skipped without invoking child schema validation.
- Additional branch trial behavior for unions/discriminated schemas is acceptable and should match existing parse semantics.

### 16.4 Compatibility

- Public migration docs are required for coercion removal, default wrapper behavior, and transform unification.
- Deprecated typedefs may be used to preserve source compatibility where practical.

---

## 17. Risks and Mitigations

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Large breaking change | Existing beta users may need code updates. | Provide migration docs and examples; version as a major beta transition. |
| Codec equality ignores closures | Different behavior may compare equal. | Document structural equality policy and test it intentionally. |
| Built-in date/time canonicalization surprises users | Encode may reject non-UTC or non-midnight values. | Document canonical runtime requirements clearly. |
| AnyOf branch order ambiguity | First valid branch wins may surprise users. | Document branch order as deterministic and intentional. |
| Discriminated domain object branch trial may be expensive | Multiple branch validations during encode. | Accept as union semantics; advise discriminator maps or object-backed codecs for performance-sensitive paths. |

---

## 18. Resolved Decisions

All open decisions are resolved. The full list — with the original
question, options considered, and the locked decision — lives in
`codec-open-questions.md`. Summary:

- **A1 (extended by C3).** All primitive schemas are strict on parse
  and encode: `Ack.string()`, `Ack.integer()`, `Ack.double()`, and
  `Ack.boolean()` reject implicit conversions. The original A1
  decision tightened only `Ack.double()` in the M11 sweep; the C3
  cleanup extended the rule to every primitive before any beta.12
  release.
- **A2 (a).** `Ack.date()` is a calendar date — local midnight
  `DateTime`. Encode rejects UTC values and any value with non-zero
  hour/minute/second/millisecond/microsecond. The error message does
  NOT advise `.toUtc()`; date is not an instant.
- **A3 (b).** `Ack.datetime()` is a UTC instant. Encode rejects non-UTC
  `DateTime`; the error advises `value.toUtc()`.
- **A4.** `EnumSchema` parse continues to accept the enum value, the
  `.name` string, and the legacy integer index. Encode requires the
  enum value and emits `.name`.
- **A5.** AnyOf encode chooses the first branch whose **full** encode
  pipeline (`_validateRuntime` + `encodeBoundary`) succeeds end-to-end.
  A branch whose runtime validation passes but whose boundary encode
  then fails is NOT a winner.
- **A6.** `ObjectSchema(additionalProperties: true)` passes unknown
  keys through as-is.
- **A7.** Defaults are parse-only.
  `DefaultSchema(nullableInner).encode(null)` returns `null` via inner
  nullability — defaults are never synthesized on encode.
- **B1 (revised by C1).** `CodecSchema.toJsonSchema` emits
  `x-ack-codec: true` only. The original B1 dual-emission compat
  window was scoped to one beta cycle and was removed before any
  beta.12 release shipped.
- **B2.** Decode failures keep using `SchemaTransformError`; no
  separate `SchemaDecodeError` class.
- **B3.** Codec equality ignores decoder/encoder closure identity but
  distinguishes one-way (`encoder == null`) from bidirectional
  (`encoder != null`) codecs.
- **B4 (a).** No `Ack.intFromString()` / `Ack.doubleFromString()` /
  `Ack.boolFromString()` in the public namespace. Migration recipes
  using `Ack.codec(...)` ship as runnable documentation in
  `packages/ack/test/migration_recipes_test.dart`. Reconsider a
  separate `AckCoercions` namespace post-beta only if user demand
  surfaces.
- **B5.** Released as `1.0.0-beta.12` with explicit breaking-change
  notes (see `packages/ack/CHANGELOG.md`).

---

## 18a. Traceability — Rule → Owner → Tests

Each semantic rule has a single code owner and a single test file. If
behaviour drifts, this table is the place to start.

| Semantic rule                                      | Code owner                                     | Tests                                                  |
| -------------------------------------------------- | ---------------------------------------------- | ------------------------------------------------------ |
| Boundary ↔ runtime conversion                      | `CodecSchema<I, O>`                            | `test/codec_schema_test.dart`                          |
| Bidirectional public codec factory                 | `Ack.codec(...)`                               | `test/codec_schema_test.dart`, `test/instance_schema_test.dart` |
| One-way `.transform(...)`                          | `AckSchemaExtensions.transform`                | `test/transform_codec_unification_test.dart`, `test/transformed_encode_test.dart` |
| Encode pipeline (validate → encode)                | `AckSchema.safeEncode` + `_validateRuntime` + `encodeBoundary` | `test/encode_base_hooks_test.dart`           |
| Object recursive encode                            | `ObjectSchema._validateRuntime` + `encodeBoundary` | `test/object_encode_test.dart`                      |
| List recursive encode                              | `ListSchema._validateRuntime` + `encodeBoundary` | `test/list_encode_test.dart`                          |
| Enum runtime/boundary split                        | `EnumSchema._validateRuntime` + `encodeBoundary` | `test/enum_encode_test.dart`                          |
| AnyOf full-pipeline branch trial                   | `AnyOfSchema._validateRuntime` + `encodeBoundary` | `test/any_of_encode_test.dart`                       |
| Discriminated map dispatch + domain-object trial   | `DiscriminatedObjectSchema._validateRuntime` + `encodeBoundary` | `test/discriminated_encode_test.dart`        |
| Parse-only defaults                                | `DefaultSchema<T>`                             | `test/default_schema_test.dart`                        |
| Built-in semantic codecs                           | `Ack.date/datetime/uri/duration` + private encoders | `test/builtin_codecs_test.dart`                   |
| `Ack.double()` strict (A1)                         | `SchemaType.number` + `DoubleSchema`           | `test/double_strict_test.dart`                         |
| Migration recipes (string ↔ int/double/bool)       | `Ack.codec(...)` examples                      | `test/migration_recipes_test.dart`                     |
| Operation-aware errors                             | `_failNullForRuntime` / `_failTypeMismatchForRuntime` + `SchemaEncodeError` | `test/schema_encode_error_test.dart`, `test/instance_schema_test.dart` |
| Discriminated branch unwrapping                    | `unwrapDiscriminatedBranchSchema`              | `test/discriminated_encode_test.dart`, `test/default_schema_test.dart` |
| JSON Schema model conversion                       | `ack_to_json_schema_model.dart`                | `test/converters/ack_to_json_schema_model_test.dart`   |

---

## 19. Definition of Done

The codec reference implementation is complete when:

- `Ack.codec<I, O>` is available and documented.
- `Ack.instance<T>` is available and documented.
- `encode` and `safeEncode` exist on every schema.
- Top-level and nested codecs round-trip valid canonical values.
- `.transform(...)` remains parse-only and fails clearly during encode.
- Defaults are parse-only and implemented through a wrapper.
- Objects, lists, enums, unions, and discriminated schemas support encode.
- JSON Schema output describes boundary shape.
- Downstream converters handle `CodecSchema` intentionally.
- Tests cover the acceptance criteria in this document.
- Documentation includes migration examples for primitive conversion, defaults, transforms, and built-in codecs.
- Remaining open decisions are resolved or explicitly documented as intentional compatibility choices.

---

## 20. Summary Requirement

ACK shall treat schemas as bidirectional semantic contracts:

```text
parse validates boundary data and produces runtime data.
encode validates runtime data and produces boundary data.
```

`CodecSchema<I, O>` is the mechanism for explicit conversion. Composite schemas must recursively preserve this contract. Defaults are parse-only. Primitive conversion is explicit. One-way transforms are one-way. Errors preserve paths. JSON Schema describes the boundary shape.

This is the reference-quality implementation target.
