# Ack Generator

`ack_generator` supports two modern directions through `@Schemable()`:
it turns a top-level Ack schema into an immutable model and derives an Ack
codec schema from a hand-written class. The annotations are exported from
`package:ack/ack.dart`. `@AckInfer()` and `@AckModel()` are deprecated
spellings of `@Schemable()` until 2.0.0. It also retains the deprecated Ack
1.1 `@AckType()` generator unchanged.

## Schema-first usage

```dart
import 'package:ack/ack.dart';

part 'user_schema.ack.dart';
part 'user_schema.ack.g.dart';

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

In a class-first library, keep the model in source and apply the generated
mixin:

```dart
import 'package:ack/ack.dart';

part 'account.ack.dart';
part 'account.ack.g.dart';

@Schemable()
final class Account with _$AccountAck {
  const Account({required this.name});

  @MinLength(2)
  final String name;

  static final fromJson = AccountSchema.fromJson;
}
```

After generation, the public facade and model JSON methods use the same Ack
codec boundary:

```dart
void main() {
  final account = Account.fromJson({'name': 'Ada'});
  print(account.toJson());
  print(AccountSchema.toJsonSchema());
}
```

A field whose type declares a static `schema` resolves to it without an
annotation, also as a `List` or `Set` item and as a `Map` value. A generic type
declares `static AckSchema<B, T<A>> schema<A>()`, which is called with the
field's type arguments, for example `Command.schema<CompletionAction>()`. The
schema must produce the field's type. A class may also expose its own facade
with `static final schema = AccountSchema.schema;`.

Use `@Schemable(description: ...)` and `@AckField(description: ...)` for schema
descriptions. A single-line `@description` tag in a `///` or `/** */` doc
comment is a fallback. Only the text after the tag, on the same line, is exported. Untagged
prose never becomes schema data. Duplicate or blank tags fail generation.
Annotation text takes precedence over a tag. A class description applies to
both the object schema and model codec, including union bases and branches.
A field description applies at its property without changing a nested model.
The generator shares its type and constraint inference through
`package:ack_generator/inference.dart`. A second generator can use
`AckSchemaInference.inferType`, `applyConstraints`, and `applyDescription`.
The caller resolves application model types and import prefixes. For function
parameters, read the documentation comment from the source AST and pass it as
`sourceComment` to `applyDescription`. That method uses the same tag-only rule.

## Schema support

The generator supports objects, empty objects, scalar and collection roots,
literals, enums, defaults, additional properties, built-in and custom
bidirectional codecs, named nested models, aliases, named `Ack.lazy` recursion,
and same-library discriminated unions. Lists, sets, and maps stored by a model
generated from a `@Schemable()` schema are copied recursively into unmodifiable
collections. Class-first parsing provides the same guarantee, including for
captured extras. Hand-written constructors and collection replacements passed
to `copyWith` remain responsible for their own defensive copies; use
`deepUnmodifiableJsonMap` for dynamic JSON maps. Raw
`Ack.object(..., additionalProperties: true)` schemas preserve extras, while a
class-first model applies its later `unknownProperties` projection. Use
`discard` only for tolerant, read-only consumers and `capture` for round trips.

Generation rejects shapes without a useful static, encodable model contract:

- one-way `.transform()` calls, including `.trim()`, `.toLowerCase()`, and
  `.toUpperCase()`; use `.codec()` with an encoder;
- nullable roots;
- nullable `Ack.list` item schemas and automatically inferred `List<T?>` or
  `Set<T?>` fields; make the collection nullable instead, or use an explicit
  `@AckField(schema: ...)` codec for a different collection contract;
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

## Generated parts

`copyWith` is a getter that returns a typed `$AccountCopyWith<Account>`
interface. Call it as `account.copyWith(name: 'Grace')`. Omitted arguments keep
their current values, explicit `null` clears nullable fields, and arguments
with incompatible static types fail analysis.

Both generated parts start with `// ignore_for_file: type=lint` and
`// coverage:ignore-file`, so your lint rules and coverage reports apply only to
your own source.

## JSON serialization

Every annotated library declares both parts:

```dart
part 'account.ack.dart';
part 'account.ack.g.dart';
```

Ack owns schema validation, defaults, codecs, union dispatch, and the public
`parse` / `fromJson` / `toJson` methods. `json_serializable` generates the
structural `_$ClassFromJson` / `_$ClassToJson` helpers into the Ack JSON
part. Ack-only apps do not add `json_annotation` or `json_serializable`;
`ack_generator` activates that second phase itself.

When a modern-only target also uses an ordinary source-gen builder that owns
`.g.dart`, disable the unused legacy builder in that target so it remains the
sole `.g.dart` owner:

```yaml
targets:
  $default:
    builders:
      ack_generator:ack_generator:
        enabled: false
```

## Supported declarations

On a schema, `@Schemable()` annotates top-level schema variables and top-level
schema getters; instance members and local variables are rejected. Only its
`name` option applies there.

On a class, `@Schemable()` annotates public, constructable `final class` declarations whose
stored fields are final. Annotated sealed union bases remain supported, and
their concrete branches must also be final. Use `@Optional()` or `@Required()`
to override inferred key presence, `@NotNull()` to reject JSON `null` without
requiring the key, and `@AckField(schema: ...)` for a type you cannot give a
static `schema`. Constraint annotations include `@Matches(pattern)` for
`Ack.string().matches(pattern)`. See the
[Model Code Generation guide](https://concepta.dev/documentation/ack/advanced/typesafe-schemas)
for both directions, field inference, sealed unions, passthrough properties,
and build configuration.

Open JSON fields are inferred from their Dart types. `Object` means a JSON-safe
value, not an arbitrary Dart instance:

| Dart field | Inferred schema |
| --- | --- |
| `Object` / `Object?` | `Ack.any()` / `Ack.any().nullable()` |
| `List<Object>` | `Ack.list(Ack.any())`; `List<Object?>` is rejected |
| `Map<String, T>` | `Ack.map(<schema for T>)` |
| `Map<String, Object?>` | `Ack.map(Ack.any().nullable())` |
| `dynamic` | rejected; use `Object?` |

For a hand-written `Account`, class-first generation exposes an
`AccountSchema` facade backed by a private `_accountSchema` codec. The facade
provides parsing, safe parsing, encoding, JSON Schema/schema-model export,
typed `schema`, and raw `wireSchema`. Instantiable models apply the generated
`_$AccountAck` mixin, which supplies `toJson`, a typed `copyWith` (omitted
means keep; explicit `null` clears a nullable field; a wrongly typed argument is
a compile-time error), and deep collection-aware equality. Add
`static final fromJson = AccountSchema.fromJson;` when the class should expose
the conventional one-argument entry point. Imported nested models compose as
`prefix.AddressSchema.schema`. Across all imports and barrel exports,
`show`/`hide` combinators must expose both the authored declaration and its
generated companion (`Address` plus `AddressSchema` for class-first, or
`addressSchema` plus `Address` for schema-first). Visibility may be split
across multiple imports that use the same prefix.

Class-first wire-name overrides support `@JsonKey(name: 'wire_name')` on the
field. Other `JsonKey` options and constructor-parameter placement fail
generation so schema validation and JSON mapping remain identical.

## Deprecated AckType compatibility

An unchanged Ack 1.1 declaration still uses `part 'file.g.dart';` and generates
the same `*Type`, `.args`, Map, `parse`, and `safeParse` APIs. `AckType` is frozen
until its removal in Ack 2.0. New connected model graphs must use
`@Schemable()`; nested references between legacy and modern graphs are rejected
with a migration diagnostic.

| Legacy | Modern opt-in |
|---|---|
| `@AckType()` | `@Schemable()` |
| `file.g.dart` | `file.ack.dart` + `file.ack.g.dart` |
| `UserType.parse(...)` | `User.parse(...)` or `User.fromJson(...)` |
| Map access and `.args` | Typed fields, `.additionalProperties`, and `toJson()` |
