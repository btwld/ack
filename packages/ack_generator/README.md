# Ack Generator

`ack_generator` supports two modern directions: `@AckInfer()` turns a
top-level Ack schema into an immutable model, while `@AckModel()` derives an
Ack codec schema from a hand-written class. It also retains the deprecated Ack
1.1 `@AckType()` generator unchanged.

## Schema-first usage

```dart
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

part 'user_schema.ack.dart';
part 'user_schema.ack.g.dart';

@AckInfer()
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

Constructors don't validate immediately. Use `parse` for untrusted input;
`toJson` and `safeToJson` validate a directly constructed model while encoding
it. Generated models don't implement `Map`, and there are no `fromMap` or
`toMap` aliases.

Omit `name` when the inferred class name is right. Use
`@AckInfer(name: 'Member')` only when you need an exact custom name. Custom
names must be unchanged UpperCamelCase identifiers.

## Class-first usage

In a class-first library, keep the model in source and apply the generated
mixin:

```dart
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

part 'account.ack.dart';
part 'account.ack.g.dart';

@AckModel()
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

Field documentation becomes an Ack schema description. The generator shares
its type and constraint inference through
`package:ack_generator/inference.dart`. A second generator can use
`AckSchemaInference.inferType`, `applyConstraints`, and `applyDescription`.
The caller resolves application model types and import prefixes. For function
parameters, read the documentation comment from the source AST and pass it as
`sourceComment` to `applyDescription`.

## Schema support

The generator supports objects, empty objects, scalar and collection roots,
literals, enums, defaults, additional properties, built-in and custom
bidirectional codecs, named nested models, aliases, named `Ack.lazy` recursion,
and same-library discriminated unions. Lists, sets, and maps stored by a model
generated with `@AckInfer()` are copied recursively into unmodifiable
collections. `@AckModel()` parsing provides the same guarantee, including for
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
- invalid names, generated-member collisions, and cross-library union branches.

Named model references work through direct imports, prefixes, and re-exports.
Nested conversion uses each model's public `$ack` adapter so codec runtime
values aren't parsed twice.

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

`@AckInfer()` can annotate top-level schema variables and top-level schema
getters. Classes, instance members, and local variables are rejected.

`@AckModel()` annotates public, constructable `final class` declarations whose
stored fields are final. Annotated sealed union bases remain supported, and
their concrete branches must also be final. Use `@Optional()` or `@Required()`
to override inferred key presence, `@NotNull()` to reject JSON `null` without
requiring the key, and `@AckField(schema: ...)` for custom codecs. See the
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
`_$AccountAck` mixin, which supplies `toJson`, `copyWith` (omitted means keep;
explicit `null` clears a nullable field), and deep collection-aware equality. Add
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

For design details and migration notes, see the
[model and schema generation architecture](https://github.com/conceptadev/ack/blob/main/docs/architecture/ackinfer-model-generation.md).

## Deprecated AckType compatibility

An unchanged Ack 1.1 declaration still uses `part 'file.g.dart';` and generates
the same `*Type`, `.args`, Map, `parse`, and `safeParse` APIs. `AckType` is frozen
until its removal in Ack 2.0. New connected model graphs must use `AckInfer` or
`AckModel`; nested references between legacy and modern graphs are rejected
with a migration diagnostic.

| Legacy | Modern opt-in |
|---|---|
| `@AckType()` | `@AckInfer()` |
| `file.g.dart` | `file.ack.dart` + `file.ack.g.dart` |
| `UserType.parse(...)` | `User.parse(...)` or `User.fromJson(...)` |
| Map access and `.args` | Typed fields, `.additionalProperties`, and `toJson()` |
