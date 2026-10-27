# Ack Generator

`ack_generator` supports two directions through `@Schemable()`:
it turns a top-level Ack schema into an immutable model and derives an Ack
codec schema from a hand-written class. `@Schemable()`, `@AckKey()`, and the
`@Validate.*` validation namespace are all exported from `package:ack/ack.dart`.


## Generate models from JSON Schema

The opt-in `ack_json_schema` builder turns a draft 2020-12 JSON Schema into
models. It emits typed `@Schemable` models for shapes it can represent as Ack
fields. For other valid 2020-12 shapes, it emits validated value models backed
by `Ack.fromJsonSchema`, preserving every supported assertion. Name the source
`lib/contract.schema.json`; named `$defs` entries produce models, and a schema
with root assertions also produces `Root` (`DocumentRoot` when `$defs/Root`
already owns that name):

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$defs": {
    "User": {
      "type": "object",
      "properties": { "name": { "type": "string" } },
      "required": ["name"],
      "additionalProperties": false
    }
  }
}
```

Enable the builder in the consuming package's `build.yaml`:

```yaml
targets:
  $default:
    builders:
      ack_generator:ack_json_schema:
        enabled: true
        options:
          unknown_properties: schema
          assert_formats: false
          model_mode: auto # use validated for exact source-schema parity
          # Optional offline resources: retrieval URI -> package asset path.
          # documents:
          #   "https://example.test/common.json": "lib/common.json"
```

Run `dart run build_runner build`. Import `contract.schema.dart` to use the
generated models. A typed model also writes `contract.schema.g.dart` and offers
typed fields and `copyWith`. A validated value model needs no parts:
`User.parse(value)` returns a wrapper whose immutable `value` is the validated
JSON value; `User.encode(model)`, `User.safeEncode(model)`, and `model.toJson()`
revalidate on output. The `userSchema` declaration and `User.schema` expose the
exact source validator. Do not hand-edit generated files.

The default `unknown_properties: schema` follows each object's
`additionalProperties`. Choose `preserve` for a forward-compatible client: it
widens `additionalProperties: false` to `true` at every object, records every
widened JSON pointer in the generated header, and captures unknown fields in
`additionalProperties`. The source JSON Schema is never rewritten. This is a
deliberate change to the effective validation contract.

Typed output covers named non-null objects, references to named definitions,
inline objects, maps, arrays with non-null items, common primitives and bounds,
string enums, and simple unions in fields. Other valid shapes—including named
scalar unions, regex patterns, recursive and dynamic references, composition,
nullable roots and items, `multipleOf`, unevaluated keywords, and format
assertions—use validated value models. Patterns use the source validator to
preserve Unicode regex semantics, including astral characters. Integral decimal
length and item bounds are normalized to integers; bounds outside the Dart
integer range use validated value models. `assert_formats: true` opts into
format assertions under the standard dialect; unknown asserted formats and
unresolved or malformed schemas fail the build with a JSON-pointer diagnostic.
External resources are read only from the explicit `documents` mapping; the
builder never fetches URLs. The complete required 2020-12 corpus generates
offline with its supplied resources. Custom vocabulary support is limited to
what `Ack.fromJsonSchema` implements.

Definitions with non-Dart names receive stable UpperCamelCase wrapper names.
If the entire document uses fallback, all its models are value wrappers so
references and dynamic scope stay bound to the same effective source document.
Validated wrappers do not expose inferred fields or typed `copyWith`.

An integral JSON number beyond Dart's `int` range is a known edge case:
`Ack.fromJsonSchema` can accept it as an integral `double`, while a typed
`Ack.integer()` model cannot represent it as an `int`. String length bounds also
differ for astral Unicode characters (code points in the importer versus UTF-16
units in the fluent schema). Set `model_mode: validated` when these edge cases
matter; typed output retains the original v1 contract for compatibility.

## Schema-first usage

```dart
import 'package:ack/ack.dart';

part 'user_schema.g.dart';

@Schemable()
final userSchema = Ack.object({
  'name': Ack.string(),
  'email': Ack.string().email(),
});
```

Run `dart run build_runner build`. A declaration ending in `Schema` loses that
suffix, so `userSchema` generates `User`:

```dart
void main() {
  final user = User.parse({
    'name': 'Ada',
    'email': 'ada@example.com',
  });

  print(user.name);     // String
  print(user.toJson()); // {'name': 'Ada', 'email': 'ada@example.com'}
}
```

`User.schema` is the model-valued schema: it parses input into `User` and
encodes a `User` back, so it composes like any other Ack schema:

```dart
final users = Ack.list(User.schema).parse(json)!; // List<User>
```

It is a shorthand for `User.$ack.modelSchema`. The generator omits it when the
model has a field or union discriminator named `schema`, when the annotated
declaration is itself named `schema`, or when the library imports a prefix
named `schema`; use `$ack.modelSchema` there.

Constructors don't validate immediately. Use `parse` for untrusted input;
`toJson` and `safeToJson` validate a directly constructed model while encoding
it. Generated models don't implement `Map`, and there are no `fromMap` or
`toMap` aliases.

Omit `name` when the inferred class name is right. Use
`@Schemable(name: 'Member')` only when you need an exact custom name. Custom
names must be unchanged UpperCamelCase identifiers.

## Class-first usage

In a class-first library, keep the model in source (using a standard or Dart 3.12+
primary constructor) and apply the generated mixin:

```dart
import 'package:ack/ack.dart';

part 'account.g.dart';

@Schemable()
final class Account with _$AccountAck {
  const Account({required this.name});

  @Validate.minLength(2)
  final String name;

  static final schema = _accountSchema;
  static final fromJson = AccountSchema.fromJson;
}
```

After generation, `Account.schema`, the public `AccountSchema` facade, and model
JSON methods all use the same Ack codec boundary:

```dart
void main() {
  final account = Account.fromJson({'name': 'Ada'});
  print(account.toJson());
  print(Account.schema.toJsonSchema());
}
```

### Heterogeneous JSON fields

A field whose values are native JSON needs no wrapper. `Ack.any()` and an
`Ack.anyOf(...)` whose branches are all native JSON (strings, numbers,
booleans, `Ack.any()`, inline objects, and lists, maps, unions, or lazy schemas
of those) become `Object` fields, including as list items and map values:

```dart
final answerValue = Ack.anyOf([
  Ack.string(), Ack.number(), Ack.list(Ack.string()),
]);

@Schemable()
final answerSchema = Ack.object({'values': Ack.map(answerValue)});
// Generates `final Map<String, Object> values;`.
```

A union branch must not decode its value. Codec branches such as
`Ack.datetime()`, `Ack.enumValues(...)`, and `.codec(...)`, `Ack.instance<T>()`,
model schemas, and nullable branches are rejected; mark the union itself
`.nullable()` instead. Use `Ack.discriminated(...)` for a union of models.
`Ack.anyOf(...)` model roots remain unsupported. Branches are proven from their
static schema types and statically resolvable initializers. A custom method
whose declared runtime type is `Object` or a JSON collection but that returns a
codec cannot be detected.

`Ack.preserveBoundary(...)` stores the JSON of a codec-bearing object, map, or
discriminated union. It validates with the full typed schema and keeps the
wire value, so a field over a preserved object is a `Map<String, Object?>`, and
a field over a preserved `Ack.map(...)` keeps each value's wire type (a JSON
number is a `num`). A preserved object can also be a union branch. Put
`withDefault(...)` outside the wire view; a default inside it does not apply.

The constructor snapshots nested JSON collections without validating them.
Parsing and encoding still enforce the original schema. Opaque codec runtime
values retain their identity and runtime container types. Statically
unresolvable or opaque JSON schemas are rejected instead of inferred.

### Custom schema resolution

A field of custom type `T` (including inside `List<T>`, `Set<T>`, `Map<String, T>`,
`JsonMaybe<T>`, or generic type-owned schemas `Box<T>`) resolves in priority order:

1. **`@Schemable(schemas: [...])`** on the class, enclosing union base, current
   `library;` directive, or an imported `library;` directive;
2. **Type-owned schema**: a static `T.schema` or `T.schema<A>(...)` on the type;
3. **Automatic current-library detection**: a unique top-level
   `AckSchema<Boundary, T>` variable, getter, or zero-argument function in the
   current library.

A generic type declares `static AckSchema<B, T<A>> schema<A>()`, which is called
with the field's type arguments, for example `Command.schema<CompletionAction>()`
or `Command.schema<void>()`. A `schema<A>()` that declares one positional
`AckSchema<Object, A>` parameter per type parameter `A` receives each type
argument's inferred schema, as in `Box.schema<Row>(RowSchema.schema)`. An enum
with a static `schema` or a `@Schemable(schemas: [...])` entry resolves to it
instead of `Ack.enumValues`. A class may also expose its own generated codec
with `static final schema = _accountSchema;` (or `AccountSchema.schema`).

Use `@Schemable(description: ...)` for class descriptions and a single-line
`@description` tag in a `///` or `/** */` doc comment on a class, field, or
constructor parameter for schema descriptions. Only the text after the tag, on
the same line, is exported. Untagged prose never becomes schema data. Duplicate
or blank tags fail generation. Annotation text on `@Schemable(description: ...)`
takes precedence over a class doc tag. A class description applies to both the
object schema and model codec, including union bases and branches. A field
description applies at its property without changing a nested model.
The generator shares its type and constraint inference through
`package:ack_generator/inference.dart`. A second generator can use
`AckSchemaInference.inferType`, `applyConstraints`, and `applyDescription`.
The caller resolves application model types and import prefixes. For function
parameters, read the documentation comment from the source AST and pass it as
`sourceComment` to `applyDescription`. That method uses the same tag-only rule.

## Schema support

The generator supports objects, empty objects, scalar and collection roots,
literals, enums, defaults, additional properties, built-in and custom
bidirectional codecs, two-way string normalizers (`.trim()`, `.toLowerCase()`,
`.toUpperCase()`), `JsonMaybe<T>` PATCH presence fields, named nested models,
aliases, named `Ack.lazy` recursion, and same-library discriminated unions.
Lists, sets, and maps stored by a model generated from a `@Schemable()` schema
are copied recursively into unmodifiable collections. Class-first parsing
provides the same guarantee, including for captured extras. Hand-written
constructors and collection replacements passed to `copyWith` remain responsible
for their own defensive copies; use `deepUnmodifiableJsonMap` for dynamic JSON
maps. Raw `Ack.object(..., additionalProperties: true)` schemas preserve extras,
while a class-first model applies its later `unknownProperties` projection. Use
`discard` only for tolerant, read-only consumers and `capture` for round trips.

Generation rejects shapes without a useful static, encodable model contract:

- one-way `.transform()` calls; use `.codec()` with an encoder;
- nullable roots;
- nullable `Ack.list` item schemas and automatically inferred `List<T?>` or
  `Set<T?>` fields; make the collection or element type non-nullable;
- `Ack.any()` and `Ack.map()` roots (both are supported as fields),
  `Ack.anyOf()`, and bare `Ack.instance<T>()`;
- anonymous inline object fields and unresolved dynamic schema factories;
- invalid names, generated-member collisions, and cross-library union branches;
- types the annotated library cannot name, because a generated part cannot add
  imports;
- `@Schemable` options set for the other target.

Named model references work through direct imports, prefixes, and re-exports.
Nested conversion uses each model's public `$ack` adapter so codec runtime
values aren't parsed twice.

Schema-first fields retain optional, nullable, and default behavior through
named schema variables and getters. Explicit constant flag overrides such as
`.optional(value: false)` are honored, as is the outermost `.strict()` or
`.passthrough()` object policy. Shape-changing object methods (`extend`,
`partial`, `merge`, `pick`, `omit`, or `copyWith(properties: ...)`) are rejected
when generating an object model; write its final properties in an
`Ack.object({...})` map literal instead. An outer bidirectional codec can still
wrap such a schema as a value model.

## Generated part

Every annotated library declares a single `.g.dart` part:

```dart
part 'account.g.dart';
```

`ack_generator` emits both the Ack schema/model facade and the structural JSON
helpers directly into `.g.dart` via `SharedPartBuilder` (without requiring
`json_serializable`), and coexists cleanly with other `SharedPartBuilder`
generators in the same `.g.dart` file.

`copyWith` is a getter that returns a typed `$AccountCopyWith<Account>`
interface. Call it as `account.copyWith(name: 'Grace')`. Omitted arguments keep
their current values, explicit `null` clears nullable fields, and arguments
with incompatible static types fail analysis.

The generated part starts with `// ignore_for_file: type=lint` and
`// coverage:ignore-file`, so your lint rules and coverage reports apply only to
your own source.

## Supported declarations

On a schema, `@Schemable()` annotates top-level schema variables and top-level
schema getters; instance members and local variables are rejected. Only its
`name` option applies there.

On a `library;` directive, `@Schemable(schemas: [...])` registers custom schemas
shared by all `@Schemable` classes in that library and any library that imports it.

On a class, `@Schemable()` annotates public, constructable `final class` declarations whose
stored fields are final. Annotated sealed union bases remain supported, and
their concrete branches must also be final. Use `@Validate.optional()` or
`@Validate.required()` to override inferred key presence, `@Validate.notNull()`
to reject JSON `null` without requiring the key, `JsonMaybe<T>` to distinguish
omitted keys from explicit `null` on both parse and encode, and
`@AckKey('wire_name')` to override a single field's JSON key. Validation
annotations use `@Validate.*` (such as `@Validate.matches(pattern)` for
`Ack.string().matches(pattern)`). See the
[Model Code Generation guide](https://concepta.dev/documentation/ack/advanced/typesafe-schemas)
for both directions, field inference, sealed unions, passthrough properties,
and build configuration.


Open JSON and presence-aware fields are inferred from their Dart types. `Object`
means a JSON-safe value, not an arbitrary Dart instance:

| Dart field | Inferred schema |
| --- | --- |
| `Object` / `Object?` | `Ack.any()` / `Ack.any().nullable()` |
| `List<Object>` | `Ack.list(Ack.any())`; `List<Object?>` is rejected |
| `Map<String, T>` | `Ack.map(<schema for T>)` |
| `Map<String, Object?>` | `Ack.map(Ack.any().nullable())` |
| `JsonMaybe<T>` | Optional-and-nullable `<schema for T>`; omitted when `JsonAbsent`, `null` when `JsonValue(null)` |
| `dynamic` | rejected; use `Object?` |

For a hand-written `Account`, class-first generation exposes an
`AccountSchema` facade backed by a private `_accountSchema` codec. The facade
provides parsing, safe parsing, encoding, JSON Schema/schema-model export,
typed `schema`, and a `wireSchema` that validates like `schema` but returns the
JSON map. Instantiable models apply the generated
`_$AccountAck` mixin, which supplies `toJson`, `safeToJson`, a typed `copyWith`,
and deep collection-aware equality. Add `static final schema = _accountSchema;`
and `static final fromJson = AccountSchema.fromJson;` when the class should
expose the schema and one-argument JSON constructor directly. Imported nested
models compose as `prefix.AddressSchema.schema` (or `prefix.Address.schema` when
`Address.schema` is declared and `AddressSchema` is hidden by a combinator).
Across all imports and barrel exports, `show`/`hide` combinators must expose the
authored declaration and either `Address.schema` or its generated companion
(`AddressSchema` for class-first, or `Address` for schema-first). Visibility may
be split across multiple imports that use the same prefix.
