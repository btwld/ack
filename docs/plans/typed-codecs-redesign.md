# ACK Typed Codecs Redesign Plan

## Purpose

Redesign ACK's schema and codec model from `main`, not from the current
`feat/codecs` branch, so the API starts from a clean type model instead of
retrofitting encode support onto the existing one-type `AckSchema<T>` design.

The goal is to make ACK a bidirectional schema system where every schema has:

```
Boundary type = encoded / wire / JSON-facing value
Runtime type  = parsed / Dart application value
```

This should make parse and encode statically typed, allow nested codecs to
compose correctly, and provide a cleaner model for object-to-model mappings
used by Mix-style schemas.

---

## Core Decision

Move from:

```dart
AckSchema<T>
```

to:

```dart
AckSchema<Boundary, Runtime>
```

Meaning:

```
parse:  Boundary/dynamic input -> Runtime
encode: Runtime                -> Boundary
```

Examples:

```dart
Ack.string();             // AckSchema<String, String>
Ack.integer();            // AckSchema<int, int>
Ack.date();               // AckSchema<String, DateTime>
Ack.duration();           // AckSchema<int, Duration>
Ack.list(Ack.date());     // AckSchema<List<String>, List<DateTime>>
Ack.object({...});        // AckSchema<JsonMap, JsonMap>
Ack.object({...}).model<User>(...); // CodecSchema<JsonMap, User>
```

This design should replace ad hoc typed encode helpers and make the
boundary/runtime split explicit across the entire library.

---

## Vocabulary

Use these terms consistently:

| Term            | Meaning                                                                          |
|-----------------|----------------------------------------------------------------------------------|
| schema          | The universal bidirectional contract: `AckSchema<Boundary, Runtime>`             |
| boundary        | Encoded/wire/JSON/OpenAPI-facing value                                           |
| runtime         | Parsed Dart/application value                                                    |
| codec           | A schema that maps one runtime shape to another while preserving a typed boundary|
| object schema   | `JsonMap <-> JsonMap` structural schema                                          |
| model           | `JsonMap <-> Dart object` mapping built from an object schema                    |
| ref             | A typed wrapper around a component schema, used for `$ref` export                |
| discriminated   | A typed union/router over object-shaped branches                                 |

Avoid these public terms:

```
leaf codec
root codec
struct codec
stream codec
```

Those describe where a schema is used, not what it is. A schema can be root in
one context and nested in another.

---

## High-Level API Shape

### Base schema

```dart
abstract class AckSchema<Boundary extends Object, Runtime extends Object> {
  Runtime? parse(Object? value, {String? debugName});
  SchemaResult<Runtime> safeParse(Object? value, {String? debugName});
  Boundary? encode(Runtime? value, {String? debugName});
  SchemaResult<Boundary> safeEncode(Runtime? value, {String? debugName});
  AckSchema<Boundary, Runtime> nullable({bool value = true});
  AckSchema<Boundary, Runtime> optional({bool value = true});
  DefaultSchema<Boundary, Runtime> withDefault(Runtime value);
}
```

Notes:

* `parse` accepts `Object?` because boundary input normally enters from
  untyped JSON/dynamic data.
* `encode` accepts `Runtime?`, not `Object?`, because encoded values should
  start from typed Dart runtime values.
* Nullability remains a runtime schema flag in the first implementation. Do
  not model it as `AckSchema<Boundary?, Runtime?>` yet.

### Public codec schema

Expose only two type parameters publicly:

```dart
final class CodecSchema<Boundary extends Object, Runtime extends Object>
    extends AckSchema<Boundary, Runtime> {
  AckSchema<Boundary, dynamic> get inputSchema;
  AckSchema<dynamic, Runtime> get outputSchema;
}
```

Construction still needs a hidden intermediate input runtime type:

```dart
static CodecSchema<Boundary, Runtime> create<
  Boundary extends Object,
  InputRuntime extends Object,
  Runtime extends Object
>({
  required AckSchema<Boundary, InputRuntime> inputSchema,
  required AckSchema<dynamic, Runtime> outputSchema,
  required Runtime Function(InputRuntime value) decoder,
  required InputRuntime Function(Runtime value)? encoder,
});
```

The public API should not expose the intermediate type because it makes
signatures noisy. `create` preserves that relationship at construction time;
the concrete wrapper erases it afterward because a codec's encoder returns the
input schema's runtime shape, which is then recursively encoded by the input
schema.

---

## Why the Hidden Intermediate Type Is Needed

Example:

```dart
final userCodec = Ack.object({
  'createdAt': Ack.datetime(),
}).model<User>(
  decode: (data) => User(
    createdAt: data['createdAt'] as DateTime,
  ),
  encode: (user) => {
    'createdAt': user.createdAt, // DateTime runtime value, not String
  },
);
```

The model encoder returns a runtime map:

```dart
{'createdAt': DateTime.utc(...)}
```

But the final boundary value must be:

```json
{"createdAt": "2026-05-10T00:00:00.000Z"}
```

That final conversion happens because the codec feeds the encoder result back
through the input object schema. The object schema recursively encodes child
fields.

So a codec internally has three conceptual types:

```
Boundary       = final encoded/wire type
InputRuntime   = input schema's parsed/runtime type
Runtime        = codec's final Dart value
```

But users should see only:

```dart
CodecSchema<Boundary, Runtime>
```

---

## Main Public API

### Universal codec factory

```dart
static CodecSchema<Boundary, Runtime> codec<
  Boundary extends Object,
  InputRuntime extends Object,
  Runtime extends Object
>({
  required AckSchema<Boundary, InputRuntime> input,
  required Runtime Function(InputRuntime value) decode,
  required InputRuntime Function(Runtime value) encode,
  AckSchema<dynamic, Runtime>? output,
});
```

Public parameter names should be verbs:

```
decode:
encode:
```

Use internal field names if needed:

```
decoder
encoder
```

### Codec combinator on any schema

```dart
extension AckSchemaCodecExtension<
  Boundary extends Object,
  InputRuntime extends Object
> on AckSchema<Boundary, InputRuntime> {
  CodecSchema<Boundary, Runtime> codec<Runtime extends Object>({
    required Runtime Function(InputRuntime value) decode,
    required InputRuntime Function(Runtime value) encode,
    AckSchema<dynamic, Runtime>? output,
  }) {
    return Ack.codec(
      input: this,
      output: output ?? Ack.instance<Runtime>(),
      decode: decode,
      encode: encode,
    );
  }
}
```

Examples:

```dart
final intFromString = Ack.string().codec<int>(
  decode: int.parse,
  encode: (value) => value.toString(),
);

final date = Ack.string().date().codec<DateTime>(
  decode: DateTime.parse,
  encode: _encodeDateOnly,
);
```

### Object model mapping

Do not add `Ack.struct` as the primary public API. Prefer:

```dart
Ack.object({...}).model<T>(...)
```

This reads as:

> Start with a JSON object shape.
> Map that object shape into a Dart model.

Suggested API:

```dart
extension ObjectSchemaModelExtension on ObjectSchema {
  CodecSchema<JsonMap, Runtime> model<Runtime extends Object>({
    required Runtime Function(JsonMap data) decode,
    required JsonMap Function(Runtime value) encode,
    AckSchema<dynamic, Runtime>? output,
    bool omitNullOptionals = true,
  });
}
```

Implementation concept:

```dart
extension ObjectSchemaModelExtension on ObjectSchema {
  CodecSchema<JsonMap, Runtime> model<Runtime extends Object>({
    required Runtime Function(JsonMap data) decode,
    required JsonMap Function(Runtime value) encode,
    AckSchema<dynamic, Runtime>? output,
    bool omitNullOptionals = true,
  }) {
    return codec<Runtime>(
      output: output ?? Ack.instance<Runtime>(),
      decode: decode,
      encode: (value) {
        final raw = encode(value);
        if (!omitNullOptionals) return raw;
        return {
          for (final entry in raw.entries)
            if (!(entry.value == null &&
                (properties[entry.key]?.isOptional ?? false)))
              entry.key: entry.value,
        };
      },
    );
  }
}
```

Example:

```dart
final eventSchema = Ack.object({
  'createdAt': Ack.datetime(),
}).model<Event>(
  decode: (data) => Event(
    createdAt: data['createdAt'] as DateTime,
  ),
  encode: (event) => {
    'createdAt': event.createdAt,
  },
);

Event? parsed = eventSchema.parse({
  'createdAt': '2026-05-10T00:00:00.000Z',
});

JsonMap? encoded = eventSchema.encode(parsed);
```

---

## Built-In Schema Types

### Primitive schemas

```
StringSchema  extends AckSchema<String, String>
IntegerSchema extends AckSchema<int, int>
DoubleSchema  extends AckSchema<double, double>
NumberSchema  extends AckSchema<num, num>
BooleanSchema extends AckSchema<bool, bool>
AnySchema     extends AckSchema<Object, Object>
InstanceSchema<T> extends AckSchema<T, T>
```

Add `Ack.number()` if starting from main.

### Built-in codecs

Implement these as true bidirectional codecs:

```
Ack.date()      -> CodecSchema<String, DateTime>
Ack.datetime()  -> CodecSchema<String, DateTime>
Ack.uri()       -> CodecSchema<String, Uri>
Ack.duration()  -> CodecSchema<int, Duration>
```

Examples:

```dart
DateTime? value = Ack.date().parse('2026-05-10');
String? encoded = Ack.date().encode(DateTime(2026, 5, 10));

Duration? d = Ack.duration().parse(1500);
int? ms = Ack.duration().encode(const Duration(milliseconds: 1500));
```

### Lists

```dart
final class ListSchema<ItemBoundary extends Object, ItemRuntime extends Object>
    extends AckSchema<List<ItemBoundary>, List<ItemRuntime>> {
  final AckSchema<ItemBoundary, ItemRuntime> itemSchema;
}
```

Factory:

```dart
static ListSchema<B, R> list<B extends Object, R extends Object>(
  AckSchema<B, R> itemSchema,
)
```

Example:

```dart
final schema = Ack.list(Ack.date());
List<DateTime>? parsed = schema.parse(['2026-05-10']);
List<String>? encoded = schema.encode([DateTime(2026, 5, 10)]);
```

### Objects

Keep objects map-shaped:

```dart
typedef JsonMap = Map<String, Object?>;

final class ObjectSchema extends AckSchema<JsonMap, JsonMap> {
  final Map<String, AnyAckSchema> properties;
}
```

Do not attempt to infer a typed object/record shape from a
`Map<String, AnyAckSchema>`. Use `.model<T>()` for nominal object output.

### Enums

If compatibility is not a concern, simplify enum values to string-boundary
only:

```dart
EnumSchema<T extends Enum> extends AckSchema<String, T>
```

Parse:

```
'admin' -> Role.admin
```

Encode:

```
Role.admin -> 'admin'
```

Avoid accepting enum instances and integer indices as boundary input. This
keeps JSON Schema, parse, and encode aligned.

### AnyOf

Keep broad typing initially:

```dart
AnyOfSchema extends AckSchema<Object, Object>
```

Do not attempt precise union typing in the first implementation. Dart does
not have first-class union types.

### Discriminated schemas

```dart
DiscriminatedObjectSchema<T extends Object>
    extends AckSchema<JsonMap, T>
```

Do not add discriminator ownership in the first PR. Keep it as a follow-up.

### References

OpenAPI-style references should be wrappers, not codecs.

Concept:

```dart
Ack.ref(component) // AckSchema<Boundary, Runtime>
```

Runtime behavior:

```
parse/encode delegates to target schema
```

Export behavior:

```
{ "$ref": "#/components/schemas/Name" }
```

### Streams

Keep streams outside the core schema engine initially.

Future helper:

```dart
extension AckStreamExtension<Boundary extends Object, Runtime extends Object>
    on AckSchema<Boundary, Runtime> {
  Stream<Runtime> parseStream(Stream<Boundary> source) async* { ... }
  Stream<Boundary> encodeStream(Stream<Runtime> source) async* { ... }
}
```

Do not add `StreamSchema` in this redesign.

---

## Simplifications From `main`

### Remove `defaultValue` from base `AckSchema`

`main` stores `defaultValue` directly on `AckSchema<T>`. This causes awkward
behavior for transformed schemas because a default may be a runtime value,
not a boundary value.

Replace it with:

```dart
DefaultSchema<Boundary, Runtime>
```

Produced by:

```dart
schema.withDefault(runtimeValue)
```

Semantics:

```
parse(null)  -> runtime default
encode(null) -> no default injection
```

### Remove `strictPrimitiveParsing`

Earlier versions supported strict parsing toggles and implicit primitive
coercion. In the new design, primitives are strict and conversions are
explicit codecs.

Instead of implicit conversion:

```dart
Ack.integer().parse('42')
```

Use:

```dart
Ack.string().codec<int>(
  decode: int.parse,
  encode: (value) => value.toString(),
);
```

This removes hidden behavior and makes the boundary/runtime conversion
explicit.

### Replace TransformedSchema behavior

Keep one-way transforms, but do not use them for built-ins.

```dart
schema.transform<R>(decode)
```

Parse works:

```dart
Ack.string().transform<int>(int.parse).parse('42'); // 42
```

Encode fails clearly:

```dart
safeEncode(42) -> SchemaEncodeError.oneWayTransform
```

Built-ins such as `Ack.date()`, `Ack.datetime()`, `Ack.uri()`, and
`Ack.duration()` should be true bidirectional codecs, not transforms.

### Consolidate object/model APIs

Do not add all of these:

```
Ack.struct(...)
Ack.objectCodec(...)
Ack.model(...)
```

Use one pattern:

```dart
Ack.object({...}).model<T>(...)
```

### Consolidate nullable JSON Schema helpers later

Nullable JSON Schema handling will likely be spread across schema types. Do
not over-focus on that in the type refactor. Once typed codecs compile and
tests pass, extract shared nullable JSON Schema helpers if needed.

---

## Out of Scope for First PR

Do not include these in the first typed schema PR:

1. Discriminated ownership of the key.
2. Enum-keyed discriminated unions.
3. OpenAPI component registry / `$ref` export machinery.
4. Stream schemas.
5. Codegen for model bridges.
6. `Ack.field` descriptors.
7. Typed nullable generics such as `AckSchema<String?, String?>`.
8. Precise AnyOf union typing.
9. Record-driven API design.

These may be follow-up improvements.

---

## Implementation Plan From `main`

### Phase 1 — Create branch

Create a fresh branch from `main`:

```bash
git checkout main
git pull
git checkout -b feat/typed-boundary-runtime-schemas
```

Do not base this on `feat/codecs`.

Use `feat/codecs` only as a reference for runtime lifecycle ideas.

---

### Phase 2 — Add characterization tests

Add tests that describe the intended public types. These are compile-time
plus runtime tests.

#### Typed built-in codec encode

```dart
test('Ack.date encode is statically typed as String', () {
  final schema = Ack.date();
  final String? encoded = schema.encode(DateTime(2026, 5, 10));
  expect(encoded, '2026-05-10');
});

test('Ack.duration encode is statically typed as int', () {
  final schema = Ack.duration();
  final int? encoded = schema.encode(
    const Duration(milliseconds: 500),
  );
  expect(encoded, 500);
});
```

#### Nested list codec encode

```dart
test('Ack.list(Ack.date()) encode is statically typed as List<String>', () {
  final schema = Ack.list(Ack.date());
  final List<String>? encoded = schema.encode([
    DateTime(2026, 5, 10),
  ]);
  expect(encoded, ['2026-05-10']);
});
```

#### Object model mapping

```dart
final class Foo {
  Foo(this.createdAt);
  final DateTime createdAt;
}

test('ObjectSchema.model parses model and encodes JsonMap', () {
  final schema = Ack.object({
    'createdAt': Ack.datetime(),
  }).model<Foo>(
    decode: (data) => Foo(data['createdAt'] as DateTime),
    encode: (foo) => {
      'createdAt': foo.createdAt,
    },
  );

  final Foo? parsed = schema.parse({
    'createdAt': '2026-05-10T00:00:00.000Z',
  });

  final JsonMap? encoded = schema.encode(parsed);

  expect(encoded, {
    'createdAt': '2026-05-10T00:00:00.000Z',
  });
});
```

#### Generic codec combinator

```dart
test('schema.codec creates typed bidirectional schema', () {
  final schema = Ack.string().codec<int>(
    decode: int.parse,
    encode: (value) => value.toString(),
  );

  final int? parsed = schema.parse('42');
  final String? encoded = schema.encode(42);

  expect(parsed, 42);
  expect(encoded, '42');
});
```

---

### Phase 3 — Add shared aliases

In `common_types.dart`:

```dart
typedef JsonMap = Map<String, Object?>;
typedef MapValue = JsonMap; // temporary alias if existing tests/code use MapValue
```

Optionally add:

```dart
typedef ObjectCodec<T extends Object> = CodecSchema<JsonMap, T>;
```

Avoid exposing `LeafCodec` initially.

---

### Phase 4 — Refactor `AckSchema`

Change:

```dart
AckSchema<DartType>
```

to:

```dart
AckSchema<Boundary, Runtime>
```

Update public methods:

```dart
SchemaResult<Runtime> safeParse(Object? value, {String? debugName});
Runtime? parse(Object? value, {String? debugName});
SchemaResult<Boundary> safeEncode(Runtime? value, {String? debugName});
Boundary? encode(Runtime? value, {String? debugName});
```

Update constraints/refinements to apply to runtime values:

```dart
List<Constraint<Runtime>> constraints;
List<Refinement<Runtime>> refinements;
```

Update protected hooks:

```dart
SchemaResult<Runtime> parseWithContext(Object? input, SchemaContext context);
SchemaResult<Runtime> validateRuntimeWithContext(
  Object? value,
  SchemaContext context,
);
SchemaResult<Boundary> encodeWithContext(
  Runtime value,
  SchemaContext context,
);
```

Lifecycle:

```
parse:
  handle parse null/default
  decode boundary to runtime
  apply runtime constraints/refinements

encode:
  validate runtime value
  encode runtime to boundary
```

---

### Phase 5 — Add operation-aware context

Add:

```dart
enum SchemaOperation { parse, encode }
```

Add operation to `SchemaContext`.

Use operation to return encode-specific errors where appropriate.

---

### Phase 6 — Add encode errors

Add or update:

```
SchemaEncodeError.nonNullable
SchemaEncodeError.typeMismatch
SchemaEncodeError.oneWayTransform
SchemaEncodeError.encoderThrew
SchemaEncodeError.missingRequiredProperty
SchemaEncodeError.unexpectedProperty
```

Encode-side object validation should use encode-specific errors for missing
required properties and unexpected additional properties.

---

### Phase 7 — Refactor primitives

Target:

```
StringSchema extends AckSchema<String, String>
IntegerSchema extends AckSchema<int, int>
DoubleSchema extends AckSchema<double, double>
NumberSchema extends AckSchema<num, num>
BooleanSchema extends AckSchema<bool, bool>
AnySchema extends AckSchema<Object, Object>
InstanceSchema<T> extends AckSchema<T, T>
```

Make primitives strict by default.

Remove `strictPrimitiveParsing` from the base schema.

---

### Phase 8 — Add `CodecSchema`

Public:

```dart
final class CodecSchema<Boundary extends Object, Runtime extends Object>
    extends AckSchema<Boundary, Runtime> {
  final AckSchema<Boundary, dynamic> inputSchema;
  final AckSchema<dynamic, Runtime> outputSchema;

  static CodecSchema<Boundary, Runtime> create<
    Boundary extends Object,
    InputRuntime extends Object,
    Runtime extends Object
  >({
    required AckSchema<Boundary, InputRuntime> inputSchema,
    required AckSchema<dynamic, Runtime> outputSchema,
    required Runtime Function(InputRuntime value) decoder,
    required InputRuntime Function(Runtime value)? encoder,
  });
}
```

Parse algorithm:

```
inputSchema.parse -> InputRuntime
run decoder -> Runtime
validate output schema runtime
apply codec constraints/refinements
```

Encode algorithm:

```
validate runtime via output schema
apply codec constraints/refinements
run encoder -> InputRuntime
validate input runtime shape
inputSchema.encodeWithContext -> Boundary
```

---

### Phase 9 — Add codec factories/extensions

Top-level factory:

```dart
static CodecSchema<Boundary, Runtime> codec<
  Boundary extends Object,
  InputRuntime extends Object,
  Runtime extends Object
>({
  required AckSchema<Boundary, InputRuntime> input,
  required Runtime Function(InputRuntime value) decode,
  required InputRuntime Function(Runtime value) encode,
  AckSchema<dynamic, Runtime>? output,
});
```

Schema extension:

```dart
extension AckSchemaCodecExtension<
  Boundary extends Object,
  InputRuntime extends Object
> on AckSchema<Boundary, InputRuntime> {
  CodecSchema<Boundary, Runtime> codec<Runtime extends Object>({
    required Runtime Function(InputRuntime value) decode,
    required InputRuntime Function(Runtime value) encode,
    AckSchema<dynamic, Runtime>? output,
  });
}
```

---

### Phase 10 — Implement built-in codecs

Replace `main`'s transformed built-ins with codecs.

```dart
static CodecSchema<String, DateTime> date()
static CodecSchema<String, DateTime> datetime()
static CodecSchema<String, Uri> uri()
static CodecSchema<int, Duration> duration()
```

Use output schema refinements for runtime invariants.

Examples:

```dart
static CodecSchema<String, DateTime> date() {
  return Ack.string().date().codec<DateTime>(
    output: Ack.instance<DateTime>().refine(
      _isLocalMidnightDate,
      message: 'Expected a local DateTime at midnight.',
    ),
    decode: DateTime.parse,
    encode: _encodeDateOnly,
  );
}

static CodecSchema<String, DateTime> datetime() {
  return Ack.string().datetime().codec<DateTime>(
    output: Ack.instance<DateTime>().refine(
      (value) => value.isUtc,
      message: 'Expected a UTC DateTime.',
    ),
    decode: DateTime.parse,
    encode: _encodeUtcDateTime,
  );
}

static CodecSchema<int, Duration> duration() {
  return Ack.integer().codec<Duration>(
    output: Ack.instance<Duration>().refine(
      (value) => value.inMicroseconds % Duration.microsecondsPerMillisecond == 0,
      message: 'Expected a whole-millisecond Duration.',
    ),
    decode: (ms) => Duration(milliseconds: ms),
    encode: (value) => value.inMilliseconds,
  );
}
```

---

### Phase 11 — Refactor `ObjectSchema`

Target:

```dart
final class ObjectSchema extends AckSchema<JsonMap, JsonMap>
```

Properties:

```dart
final Map<String, AckSchema<dynamic, dynamic>> properties;
```

Keep recursive parse/encode behavior.

Add encode-side validation:

* Missing required key -> `SchemaEncodeError.missingRequiredProperty`
* Unexpected additional key -> `SchemaEncodeError.unexpectedProperty`

---

### Phase 12 — Add `ObjectSchema.model<T>()`

Add extension:

```dart
extension ObjectSchemaModelExtension on ObjectSchema {
  CodecSchema<JsonMap, Runtime> model<Runtime extends Object>({
    required Runtime Function(JsonMap data) decode,
    required JsonMap Function(Runtime value) encode,
    AckSchema<dynamic, Runtime>? output,
    bool omitNullOptionals = true,
  });
}
```

Implement as `this.codec(...)`.

Make sure nested codecs encode correctly:

```dart
Ack.object({
  'createdAt': Ack.datetime(),
}).model<Event>(
  decode: (data) => Event(data['createdAt'] as DateTime),
  encode: (event) => {'createdAt': event.createdAt},
);
```

Expected encoded boundary:

```json
{"createdAt": "2026-05-10T00:00:00.000Z"}
```

---

### Phase 13 — Refactor `ListSchema`

Target:

```dart
final class ListSchema<ItemBoundary extends Object, ItemRuntime extends Object>
    extends AckSchema<List<ItemBoundary>, List<ItemRuntime>>
```

Factory:

```dart
static ListSchema<B, R> list<B extends Object, R extends Object>(
  AckSchema<B, R> itemSchema,
)
```

---

### Phase 14 — Refactor defaults

Remove `defaultValue` from base `AckSchema`.

Add:

```dart
final class DefaultSchema<Boundary extends Object, Runtime extends Object>
    extends AckSchema<Boundary, Runtime>
```

Behavior:

```
parse(null) -> runtime default
encode(null) -> no default injection
```

`toJsonSchema()` should encode the default to boundary form when possible.

---

### Phase 15 — Refactor transform

Replace `TransformedSchema` with a two-type-compatible one-way transform backed
by `CodecSchema`.

```dart
CodecSchema.create<Boundary, InputRuntime, Runtime>(
  inputSchema: schema,
  outputSchema: Ack.instance<Runtime>(),
  decoder: decode,
  encoder: null,
)
```

Created by:

```dart
schema.transform<R>(decode)
```

Encode should fail with:

```
SchemaEncodeError.oneWayTransform
```

---

### Phase 16 — Refactor enum schema

Target:

```dart
EnumSchema<T extends Enum> extends AckSchema<String, T>
```

Parse string name only.

Encode enum to `.name`.

JSON Schema boundary:

```json
{ "type": "string", "enum": [...] }
```

---

### Phase 17 — Refactor `AnyOfSchema`

Keep broad:

```dart
AnyOfSchema extends AckSchema<Object, Object>
```

On encode, first branch whose full runtime validation + encode succeeds wins.

Do not attempt precise union typing in this pass.

---

### Phase 18 — Refactor `DiscriminatedObjectSchema`

Target:

```dart
DiscriminatedObjectSchema<T extends Object>
    extends AckSchema<JsonMap, T>
```

Keep current behavior initially.

Do not implement discriminator key ownership in this PR.

---

### Phase 19 — Update JSON Schema conversion

Converters should describe the boundary shape.

For codecs:

```
_convert(schema.inputSchema)
```

For model schemas, this naturally exports the object boundary shape.

Ensure built-ins export:

```
Ack.date()      -> {"type":"string", "format":"date"}
Ack.datetime()  -> {"type":"string", "format":"date-time"}
Ack.duration()  -> {"type":"integer"}
Ack.uri()       -> {"type":"string", "format":"uri"}
```

---

### Phase 20 — Update package APIs and generator

Update all usages from:

```dart
AckSchema<T>
```

to:

```dart
AckSchema<Boundary, Runtime>
```

For generator package:

* Object schemas remain `JsonMap, JsonMap`.
* Primitive schemas have identical boundary/runtime types.
* Built-in codecs have differing boundary/runtime types.
* Generated parse helpers should use runtime type.
* Generated encode helpers, if present, should use boundary type.

---

### Phase 21 — Update docs

Add a central explanation:

> ACK schemas are bidirectional.
> Every schema has a boundary type and a runtime type.
> Boundary is the encoded JSON/wire form.
> Runtime is the parsed Dart form.
> `AckSchema<Boundary, Runtime>`

Examples:

```dart
Ack.string();              // AckSchema<String, String>
Ack.date();                // AckSchema<String, DateTime>
Ack.list(Ack.date());      // AckSchema<List<String>, List<DateTime>>
Ack.object({...});         // AckSchema<JsonMap, JsonMap>
Ack.object({...}).model<User>(...); // CodecSchema<JsonMap, User>
```

Clarify:

```dart
Ack.string().date() // validates a date string, returns String
Ack.date()          // parses date string to DateTime and encodes DateTime to string
```

---

### Phase 22 — Validation commands

Run:

```bash
dart analyze --fatal-infos packages/ack
dart test packages/ack
dart test packages/ack_json_schema_builder
dart test packages/ack_generator
flutter test packages/ack_firebase_ai
melos run validate-jsonschema
melos run test --no-select
```

---

## Follow-Up Roadmap

### Follow-up 1 — Discriminated ownership

Make `Ack.discriminated` own the discriminator key end-to-end:

```
parse: read key, strip key, route to branch
encode: route branch, add key
export: oneOf + discriminator
```

### Follow-up 2 — Component references

Add:

```dart
Ack.component(name: 'Pet', schema: petSchema)
Ack.ref(petComponent)
```

`Ack.ref` should preserve `Boundary` and `Runtime` and export as `$ref`.

### Follow-up 3 — Stream helpers

Add:

```dart
schema.parseStream(...)
schema.encodeStream(...)
```

### Follow-up 4 — Generated model bridges

If Mix-schema files remain too verbose, generate only the `.model<T>()`
bridge:

```dart
decode: (data) => T(...)
encode: (value) => {...}
```

Do not generate the schema contract unless intentionally desired.

---

## Risks

### Risk: generic noise

The public API should avoid exposing the hidden intermediate codec type.
Use:

```dart
CodecSchema<Boundary, Runtime>
```

not:

```dart
CodecSchema<Boundary, InputRuntime, Runtime>
```

### Risk: object schemas cannot be precisely typed

This is expected. Keep object schemas as:

```dart
AckSchema<JsonMap, JsonMap>
```

Use `.model<T>()` for typed Dart objects.

### Risk: nullable list item semantics

Do not solve nullable list element typing in the first PR. Either preserve
current behavior or explicitly reject nullable item schemas in
`Ack.list(...)` with a clear error. Revisit later.

### Risk: generator churn

The generator may need broad generic signature changes. Keep behavior
changes minimal in the generator until `packages/ack` compiles and passes
tests.

### Risk: too much in one PR

Do not include discriminated ownership, refs, streams, or generated model
bridges in the first PR.

---

## Acceptance Criteria

The PR is complete when these are true:

1. `AckSchema<Boundary, Runtime>` is the core type.
2. `parse` returns `Runtime?`.
3. `encode` returns `Boundary?`.
4. `Ack.date().encode(...)` is statically `String?`.
5. `Ack.duration().encode(...)` is statically `int?`.
6. `Ack.list(Ack.date()).encode(...)` is statically `List<String>?`.
7. `Ack.object({...}).model<T>(...)` returns `CodecSchema<JsonMap, T>`.
8. Built-ins are bidirectional codecs, not parse-only transforms.
9. Defaults are represented by `DefaultSchema`, not base `defaultValue`.
10. Primitives are strict and conversions are explicit codecs.
11. JSON Schema converters continue to export boundary shapes.
12. Test suite and analyzer pass.

---

## Final Summary

Start from `main` and redesign ACK around:

```dart
AckSchema<Boundary, Runtime>
```

Then add:

```dart
schema.codec<T>(...)
Ack.object({...}).model<T>(...)
```

Do not create public leaf/root/struct codec categories. Do not lead with
records or `Ack.field`. The first implementation should make the type model
correct, keep object schemas map-shaped, and provide a clean model mapping
API. Further simplification for Mix-style schemas should come later through
generated `.model<T>()` bridges or discriminator ownership.
