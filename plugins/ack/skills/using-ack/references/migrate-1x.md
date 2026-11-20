# Migrating Ack 1.x (and 2.0 alpha/beta.1-2) to 2.0.0-beta.3

Upgrade only after the user confirms the `2.0.0-beta.3` target. “Latest” alone does not confirm a prerelease; leave dependencies and source unchanged while you wait for the answer. Owning guide with every substitution: https://github.com/btwld/ack/blob/main/docs/getting-started/migration-guide.mdx

## Steps

1. Set `ack: ^2.0.0-beta.3` and every `ack_*` package to the same pin. Remove `ack_annotations`. Remove `json_serializable` / `json_annotation` unless non-Ack classes still use them. If the SDK constraint is below `>=3.13.0`, raise it, and tell the user when that forces a Flutter upgrade to >=3.47.
2. Replace the imports `package:ack_annotations/...` and `package:ack/format_annotations.dart` with `import 'package:ack/ack.dart';`.
3. Replace every Ack part in a library (`part 'x.ack.dart';`, `part 'x.ack.g.dart';`, `part 'role.ack.dart';`, however many) with the single `part 'x.g.dart';` named after the library file. In `build.yaml`, change `ack_generator|ack_models` / `ack_model_json` to `ack_generator:ack_generator`.
4. Add `with _$<Class>Ack` to every class you annotate with `@Schemable` (`class User with _$UserAck`); the generated `toJson`, `copyWith`, and `==` come from that mixin.
5. Rename symbols with the tables below, then run `dart run build_runner build` and `dart analyze`.

Done when `dart pub deps` shows beta.3, the build writes one `.g.dart` per model library, `dart analyze` shows no Ack deprecations, and the existing tests pass.

## Model and field annotations

| 1.x | 2.0.0-beta.3 |
|---|---|
| `@AckModel(...)` on a class | `@Schemable(...)` |
| `@AckInfer(...)` / `@AckType()` on a schema | `@Schemable(...)` |
| `@JsonKey(name: 'w')` | `@AckKey('w')` |
| `caseStyle:` with any other spelling (`CaseStyle.snakeCase`) | `caseStyle: AckCaseStyle.snake` (`none`, `snake`, `kebab`, `pascal`, `screamingSnake`) |
| `@AckField(schema: ...)` / `@JsonConverter` | `static final schema = ...` on the type, or `@Schemable(schemas: [fn])` |
| `@AckField(description: ...)` | `/// @description ...` doc tag |
| `AckAdditionalPropertiesMode` | `unknownProperties: AckUnknownPropertyPolicy.reject` / `.discard` / `.capture` |

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
| `convertAckSchemaModelToBuilder(m)` | `schema.toJsonSchemaBuilder()` |
| `.trim()` as a one-way transform | `Ack.string().trim()` is now a two-way normalizer |

## Behavior changes to check in tests

- `copyWith(field: null)` now **clears** a nullable field. Omitting the argument keeps the value. Code that relied on "null means keep" needs rewriting.
- Since beta.2, `withDefault` fills only an omitted key. A present `null` fails unless the field is `.nullable().withDefault(v)`.
- `Ack.fromJsonSchema` no longer asserts `format` by default; pass `assertFormats: true`.
- `toJsonSchema()` keeps imported 2020-12 documents; call `toJsonSchemaDraft7()` when a consumer needs Draft-7.
