---
name: build-data-classes-with-ack
description: Generate Dart data classes with Ack 2.0's @Schemable and ack_generator. Use when adding or changing a @Schemable model (class-first or schema-first), its @Is…/@Has… rule annotations, @AckKey, cross-field .refine, custom field types, the .g.dart part and build_runner, loading JSON into a model, or generating models from a .schema.json file.
---

# Build data classes with Ack

> **Ack 2.0 card.** Pin `ack: ^2.0.0-beta.3` and the same pin for every `ack_*` package; a bare `dart pub add ack` selects the stable release. Dart >=3.13, Flutter >=3.47. Use the [repository API index](https://github.com/btwld/ack/blob/main/llms.txt) and check that examples match your installed version. Untrusted JSON goes through `safeParse`; constructors and schema exports do not run validation. Native `toJsonSchema()` emits Draft-7.

The class is the source of truth: you write a `final class` and the generator writes its schema, JSON mapping, `copyWith`, and equality. The fluent schema API itself (presence, constraints, codecs, errors) belongs to the `using-ack` skill.

## 1. Set up the package

1. Check `dart pub deps --style=compact | grep ack`. If ack is 1.x or an earlier 2.0 prerelease, ask the user to confirm `2.0.0-beta.3` and the SDK requirements. “Update to the latest” does not confirm the prerelease. Wait for confirmation before editing dependencies or source, then follow `using-ack`'s migration reference.
2. Add `dart pub add ack:^2.0.0-beta.3 dev:ack_generator:^2.0.0-beta.3 dev:build_runner`.
3. In a large package, optionally scope the generator in `build.yaml` with `ack_generator:ack_generator: generate_for: [lib/models/**.dart]`.

Done when `dart pub deps` shows `ack 2.0.0-beta.3` and `ack_generator 2.0.0-beta.3`.

## 2. Write the class

```dart
import 'package:ack/ack.dart';

part 'invoice.g.dart';

@Schemable(caseStyle: AckCaseStyle.snake, description: 'A customer invoice.')
final class const Invoice({
  @HasMinLength(1) required final String invoiceId,
  @IsEmail() required final String customerEmail,
  @IsPositive() required final double amount,
  final String? notes,                                   // may be omitted or null
  final String currency = 'usd',                         // omitted -> 'usd'; null fails
  final JsonMaybe<double> discount = const JsonMaybe.absent(), // keeps omitted vs null
  @AckKey('due') required final DateTime dueAt,          // ISO string on the wire
  required final DateTime issuedAt,
}) with _$InvoiceAck {
  static final schema = InvoiceSchema.schema.refine(
    (i) => !i.dueAt.isBefore(i.issuedAt),
    message: 'due must not be before issued_at',
  );
}
```

The rules that make it build:

- One `part '<file>.g.dart';`, a `final class` (or `sealed class` for a union) with only final fields, an unnamed or primary constructor, and `with _$<Class>Ack`. The examples use Dart 3.13 primary constructors; a classic constructor with annotated fields generates identical code.
- **Presence comes from the constructor.** `required T` means required and non-null. `required T?` means required, but may be null. Optional `T?` may be omitted and drops the key on encode when null. A default becomes `withDefault`. Change only the wire contract with `@IsOptional()`, `@IsRequired()`, `@IsNotNull()`.
- **Rules** are top-level `Is…` / `Has…` annotations from `package:ack/ack.dart`: `@HasMin`, `@HasMax`, `@IsPositive`, `@IsNegative`, `@IsMultipleOf`, `@HasMinLength`, `@HasMaxLength`, `@HasMatch` (unanchored), `@IsEmail`, `@IsUrl`, `@IsUri`, `@IsUuid`, `@IsDate`, `@IsDateTime`, `@IsIp`, `@IsNotEmpty`, `@HasMinItems`, `@HasMaxItems`, `@HasUniqueItems`. Write these; `@Validate.*` is deprecated and goes away at 2.0.0.
- **Wire names:** `caseStyle:` for the whole model (`snake`, `kebab`, `pascal`, `screamingSnake`), `@AckKey('wire')` for one field. Use `@AckKey`, not `@JsonKey`.
- **Descriptions** are exported only from `@Schemable(description:)` or a one-line `/// @description ...` doc tag.
- **Unknown keys** are rejected by default. Use `@Schemable(unknownProperties: AckUnknownPropertyPolicy.capture)` with a `Map<String, Object?> additionalProperties` field when you need to round-trip them.
- **Inferred field types:** `String`, `bool`, `int`, `double`, `num`, `DateTime` (UTC ISO string), `Uri`, `Duration` (ms), enums, `List<T>`, `Set<T>`, `Map<String, T>`, `Object`/`Object?` (any JSON), nested `@Schemable` classes, `JsonMaybe<T>`. Any other type needs a schema: read [references/custom-types.md](references/custom-types.md).
- **Unions:** `@Schemable(discriminatorKey: 'type') sealed class` with `final class` branches in the same library (`@Schemable(discriminatorValue: 'x')` fixes a wire value; otherwise the class name is used).

## 3. Generate

Run `dart run build_runner build`. For a class-first model the build writes `<file>.g.dart` with a public `<Class>Schema` facade (`schema`, `wireSchema`, `parse`, `safeParse`, `fromJson`, `encode`, `safeEncode`, `toJsonSchema`, `toSchemaModel`) and the `_$<Class>Ack` mixin (`toJson`, `safeToJson`, typed `copyWith`, deep `==`/`hashCode`). A misplaced `@Schemable` option or an unsupported type fails the build with a message. Fix the source and rebuild; never hand-edit a `.g.dart`. An analyzer language-version warning in the build log is harmless. build_runner 2.16 has no `--delete-conflicting-outputs` flag, so a plain `build` is the whole command.

## 4. Load JSON into the class

- Load untrusted input with `Invoice.schema.safeParse(json)` (or `InvoiceSchema.safeParse` when there is no refine) and handle `Fail`. `fromJson` / `parse` throw `AckException`.
- **A refine lives only on the static you attached it to.** `InvoiceSchema.parse`, `InvoiceSchema.fromJson`, and anything wired to them skip it. Route every load through `Invoice.schema` when the class has a refine. A refine failure is a `SchemaValidationError` at path `#`.
- **Generated constructors don't validate.** `Invoice(amount: -1, ...)` compiles and runs. Values built in code are checked when you encode them: `toJson()` throws, `safeToJson()` returns `Fail`. Both encode through `InvoiceSchema`, so they check field rules but **not** a class-level refine; `Invoice.schema.safeEncode(invoice)` checks both. Run a form or user edit through `Invoice.schema.safeEncode(...)` before you store it.
- Build `JsonMaybe` fields with `const JsonMaybe.absent()` (key omitted), `JsonMaybe.value(0.1)`, or `JsonMaybe<double>.value(null)` (explicit `null` on the wire).
- `copyWith(notes: null)` clears a nullable field; leaving the argument out keeps it.
- Compose: `Ack.list(Invoice.schema)`, or a field typed `Invoice` inside another `@Schemable` class.

## Branches

- **Schema-first models** (`@Schemable()` on a top-level `Ack.object` / `Ack.discriminated`), value or scalar roots, recursion with `Ack.lazy`, or **generating models from `lib/**.schema.json`**: read [references/schema-first.md](references/schema-first.md).
- **Custom field types** (value objects, extension types, third-party classes, generic wrappers): read [references/custom-types.md](references/custom-types.md).

## Done when

- `dart run build_runner build` succeeds and `dart analyze` reports no issues and no ack deprecations.
- Every model you added or changed has tests that: parse a valid payload and assert typed fields; round-trip `toJson()` back through `Model.schema.parse` to an equal value; and, for each rule annotation, presence choice, and refine, parse a payload that breaks it and assert `isFail` with the expected leaf path (walk `SchemaNestedError.errors`, see `using-ack`; the top `error.path` is `#`). Watch each failing case actually fail.
- No load path for a refined model goes through `<Class>Schema.fromJson` / `.parse`.

Siblings: `using-ack` (fluent schemas, errors, JSON Schema, migration), `ack-provider-schemas` (schemas for MCP and Gemini).
