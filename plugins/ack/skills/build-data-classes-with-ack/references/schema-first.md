# Schema-first models and .schema.json codegen

Owning docs: [Type-safe schemas](https://github.com/btwld/ack/blob/v2.0.0-beta.3/docs/core-concepts/typesafe-schemas.mdx) and the [generator README](https://github.com/btwld/ack/blob/v2.0.0-beta.3/packages/ack_generator/README.md).

## @Schemable on a top-level schema

Use this when the wire contract is the main artifact: unions with codecs, value or scalar roots, or recursion.

```dart
part 'payment.g.dart';

@Schemable()
final cardSchema = Ack.object({
  'last4': Ack.string().matches(r'^\d{4}$'),
  'paidAt': Ack.datetime()
      .min(DateTime.utc(2026))
      .describe('On or after 2026-01-01T00:00:00Z.'),
});

@Schemable()
final bankSchema = Ack.object({
  'iban': Ack.string().minLength(15),
  'timeout': Ack.duration(),           // codec: int ms <-> Duration
});

@Schemable()
final paymentSchema = Ack.discriminated(
  discriminatorKey: 'method',
  schemas: {'card': cardSchema, 'bank': bankSchema},
);
```

This generates `sealed class Payment` with `final class Card` and `Bank`. The name is the variable name minus its trailing `Schema`, or set it with `@Schemable(name: 'X')`. The generated classes have `parse` / `safeParse` / `fromJson`, `toJson` / `safeToJson`, `copyWith`, and `.schema`. Constructors don't validate. The annotated `paymentSchema` variable is still the plain schema and parses to a `Map`; load typed values with `Payment.safeParse(json)`. For export and warning inspection use `Payment.schema.toJsonSchema()` and `Payment.schema.toSchemaModel()`. There is no generated `PaymentSchema` facade in schema-first generation.

The generator rejects:

- one-way `.transform` (use `.codec`);
- nullable roots;
- `Ack.any()` / `Ack.map()` / `Ack.anyOf()` as a model root;
- a bare `Ack.instance`;
- anonymous inline objects as fields (name them as their own `@Schemable` schema);
- union branches from another library;
- object helpers such as `extend` / `pick` in a model root (write the property map out literally).

Recursion uses named `Ack.lazy('Node', () => nodeSchema)`.

Check the union's export: each branch exports its own `const` discriminator (for example, `{"method": {"const": "card"}}`), and `Ack.datetime()` exports `format: date-time`. The `.min(DateTime)` bound is absent from the export. Use the [warning walk](../../using-ack/references/json-schema.md#export) to find `datetime_constraint_not_draft7` on the reachable field node, and put the bound in `.describe(...)`. For rules inside lazy targets, inspect the exported shape and test the runtime rule separately; the walk cannot reach their warnings.

## Models from `.schema.json` (opt-in builder)

1. Put a 2020-12 document at `lib/<name>.schema.json`. Each named `$defs` entry becomes a model. If the document root has any keyword besides `$schema`, `$defs`, `$comment`, `title`, `description` (a `type: object`, say), the build also emits a `Root` model for it. `Root` validates only the root keywords, so `Root.safeParse({})` can pass while the `$defs` rules never run. Validate with the named model (`Message.safeParse(json)`).
2. Enable the builder in the consuming package's `build.yaml`:

```yaml
targets:
  $default:
    builders:
      ack_generator:ack_json_schema:
        enabled: true
        options:
          unknown_properties: schema   # or preserve
          assert_formats: true         # default false: format is only an annotation
          model_mode: auto             # validated = exact source-schema parity
          documents:                   # offline $ref targets: URI -> package asset
            "https://example.com/common.json": "lib/common.json"   # absolute $ref
            "common.json": "lib/common.json"                       # relative $ref
```

Set `assert_formats: true` whenever a `format` (`date-time`, `email`, ...) must reject bad values; left at the default `false`, `"not-a-date"` passes. A relative `documents` key resolves against the schema file's own location, so `"common.json"` matches `{"$ref": "common.json#/$defs/Id"}` from `lib/<name>.schema.json`.

3. Run `dart run build_runner build`, then import `<name>.schema.dart`.

`model_mode: auto` emits typed `@Schemable` models for shapes Ack can express as fields. It falls back to **validated value models** for everything else, backed by `Ack.fromJsonSchema`. These cover `pattern` (to keep Unicode regex semantics), composition, recursion, `multipleOf`, unevaluated keywords, and format assertions. A validated model exposes an immutable `.value`, `parse` / `encode` / `toJson`, and no typed fields. Use `model_mode: validated` when exact parity with the source matters.

The builder never fetches URLs, and unresolved references fail the build with a JSON pointer.
