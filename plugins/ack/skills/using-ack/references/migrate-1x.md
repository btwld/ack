# Migrating Ack 1.x and earlier 2.0 prereleases

Upgrade only after the user confirms the target in [the version check](../SKILL.md#1-check-the-installed-version-first). “Latest” alone does not confirm a prerelease; leave dependencies and source unchanged while you wait for the answer. See the [migration guide](https://github.com/btwld/ack/blob/v2.0.0-beta.3/docs/getting-started/migration-guide.mdx) for every substitution.

## Steps

1. Set `ack` and its companion packages to the agreed 2.x constraint. Remove `ack_annotations`. Remove `json_serializable` / `json_annotation` unless non-Ack classes still use them. Check the target release's SDK requirements and tell the user if an SDK upgrade is needed.
2. Replace the imports `package:ack_annotations/...` and `package:ack/format_annotations.dart` with `import 'package:ack/ack.dart';`.
3. Replace every Ack part in a library (`part 'x.ack.dart';`, `part 'x.ack.g.dart';`, `part 'role.ack.dart';`, however many) with the single `part 'x.g.dart';` named after the library file. In `build.yaml`, change `ack_generator|ack_models` / `ack_model_json` to `ack_generator:ack_generator`.
4. Add `with _$<Class>Ack` to every class you annotate with `@Schemable` (`class User with _$UserAck`); the generated `toJson`, `copyWith`, and `==` come from that mixin.
5. Rename symbols with the tables below, then run `dart run build_runner build` and `dart analyze`.

Done when `dart pub deps` shows the agreed 2.x release, the build writes one `.g.dart` per model library, `dart analyze` shows no Ack deprecations, and the existing tests pass.

## Model and field annotations

| 1.x | 2.x |
|---|---|
| `@AckModel(...)` on a class | `@Schemable(...)` |
| `@AckInfer(...)` / `@AckType()` on a schema | `@Schemable(...)` |
| `@JsonKey(name: 'w')` | `@AckKey('w')` |
| `@AckField(schema: ...)` / `@JsonConverter` | `static final schema = ...` on the type, or `@Schemable(schemas: [fn])` |
| `@AckField(description: ...)` | `/// @description ...` doc tag |

## Rule annotations (1.x top-level, or deprecated 2.0 `@Validate.*`)

| Old | New |
|---|---|
| `@Optional()` / `@Validate.optional()` | `@IsOptional()` |
| `@Required()` / `@Validate.required()` | `@IsRequired()` |
| `@NotNull()` / `@Validate.notNull()` | `@IsNotNull()` |
| `@Min(n)` / `@Max(n)` | `@HasMin(n)` / `@HasMax(n)` |
| `@MultipleOf(n)` | `@IsMultipleOf(n)` |
| `@Positive()` / `@Negative()` | `@IsPositive()` / `@IsNegative()` |
| `@MinLength(n)` / `@MaxLength(n)` | `@HasMinLength(n)` / `@HasMaxLength(n)` |
| `@Pattern(r)` / `@Matches(r)` / `@Validate.matches(r)` | `@HasMatch(r)` (unanchored) |
| `@NotEmpty()` | `@IsNotEmpty()` |
| `@Email()` `@Url()` `@Uri()` `@Uuid()` | `@IsEmail()` `@IsUrl()` `@IsUri()` `@IsUuid()` |
| `@Date()` / `@DateTime()` | `@IsDate()` / `@IsDateTime()` |
| `@Ip()` / `@Ipv4()` / `@Ipv6()` | `@IsIp()` / `@IsIp(version: 4)` / `@IsIp(version: 6)` |
| `@MinItems(n)` / `@MaxItems(n)` / `@UniqueItems()` | `@HasMinItems(n)` / `@HasMaxItems(n)` / `@HasUniqueItems()` |

## Runtime APIs

| Removed | Use |
|---|---|
| `Ack.enumCodec(E.values)` | `Ack.enumValues(E.values)` |
| `schema.toMap()` | `schema.toJsonSchema()` / `schema.toSchemaModel()` |
| `*Type` extension types, `.args`, `UserType.parse` | generated `User` class: `User.parse`, `User.fromJson`, `user.toJson()` |
| `server.registerAckModelTool(...)` | `server.registerAckTool(name, input: Model.schema, callback: ...)` |
| `convertAckSchemaModelToBuilder(m)` | `schema.toJsonSchemaBuilder()` with `import 'package:ack_json_schema_builder/ack_json_schema_builder.dart';` |
| `.trim()` as a one-way transform | `Ack.string().trim()` is now a two-way normalizer |

## Behavior changes to check in tests

- `copyWith(field: null)` now **clears** a nullable field. Omitting the argument keeps the value. Code that relied on "null means keep" needs rewriting.
- Since beta.2, `withDefault` fills only an omitted key. A present `null` fails unless the field is `.nullable().withDefault(v)`.
- `Ack.fromJsonSchema` no longer asserts `format` by default; pass `assertFormats: true`.
- `toJsonSchema()` keeps imported 2020-12 documents; call `toJsonSchemaDraft7()` when a consumer needs Draft-7.
