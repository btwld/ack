# JSON Schema export and import (Ack 2.0.0-beta.3)

Owning guide: https://github.com/btwld/ack/blob/main/docs/guides/json-schema-integration.mdx

## Export

`schema.toJsonSchema()` returns a `Map<String, Object?>`. `schema.toSchemaModel()` returns the `AckSchemaModel` behind it; each node's `.warnings` (each with `code`, `message`, `path`) list what the export dropped **at that node**. The root's `.warnings` doesn't collect warnings from properties, items, or union branches, so walk the tree:

```dart
Iterable<AckSchemaModelWarning> allWarnings(AckSchemaModel model) sync* {
  yield* model.warnings;
  final children = switch (model) {
    AckObjectSchemaModel(:final properties) => properties?.values ?? const [],
    AckArraySchemaModel(:final items) => [?items],
    AckAnyOfSchemaModel(:final schemas) => schemas,
    AckOneOfSchemaModel(:final schemas) => schemas,
    AckAllOfSchemaModel(:final schemas) => schemas,
    _ => const <AckSchemaModel>[],
  };
  for (final child in children) {
    yield* allWarnings(child);
  }
}
```

A class-first model exports through its generated `ModelSchema.toJsonSchema()` facade (or `Model.schema.toJsonSchema()` if the class defines that static). A schema-first generated model exports through `Model.schema.toJsonSchema()`.

- Native schemas emit **Draft-7** keywords with no `$schema` stamp.
- `nullable()` becomes `anyOf: [<schema>, {type: null}]`. Keep that shape and don't flatten it.
- `Ack.object` exports `additionalProperties: false` unless you opened it. Omitted keys are left out of `required`, and so are defaulted keys, which also export `default`.
- `Ack.discriminated` exports an `anyOf` of objects, each with an exact `const` discriminator, not an OpenAPI `discriminator`.
- A codec exports its **boundary** (input) schema. `Ack.datetime()` becomes `{type: string, format: date-time}` and `Ack.duration()` becomes `{type: integer}`.

The export drops these, and the warning codes say so:

| Lost on export | Warning code |
|---|---|
| `.refine` / custom `.constrain` logic | none, so assume it is always lost |
| Constraints on a codec's runtime value | `codec_runtime_constraint_not_exported` |
| `min`/`max` on `Ack.date()` / `Ack.datetime()` | `datetime_constraint_not_draft7`, on the field's node |
| A default that is not valid JSON | `default_not_export_safe` |
| `Ack.any()` boundary | `ack_any_json_boundary` |
| `Ack.lazy` `maxDepth` | `lazy_runtime_checks_not_export_safe` |

A date bound has no Draft-7 keyword, so the export carries only `format`. State the bound in `.describe('on or after 2026-01-01')` for whoever reads the schema. For other warnings, move the rule onto the input schema (`Ack.string().minLength(5).codec(...)`) or accept that only `safeParse` enforces it. Never add an invented keyword to make up for it.

## Import

`Ack.fromJsonSchema(decodedMap, {baseUri, documents, assertFormats})` compiles a decoded 2020-12 or Draft-7 document (a map or a bool, not a JSON string) into `AckSchema<Object, Object>`.

- References resolve only from the `documents` map (`Uri` mapped to the decoded document), relative to `baseUri`. Nothing is fetched or read from disk.
- `format` is only an annotation unless you pass `assertFormats: true` (or the dialect declares `format-assertion`).
- An imported `pattern` uses ECMA-262 Unicode mode (`\p{Lu}` works). A native `.matches` uses Dart `RegExp`, so the same pattern can behave differently after a round trip. Imported `minLength` counts code points; native counts UTF-16 units.
- Imports never fill in defaults or coerce values. A failure is a `JsonSchemaValidationError`: `path` is the instance location (`#/b`) and `pointer` the schema location (`#/additionalProperties`). It reports only the first failing keyword. `keyword` can be empty (an `additionalProperties: false` failure has `keyword == ''`), so branch on `pointer`.
- `toJsonSchema()` on an imported schema keeps 2020-12 (`$defs`, `unevaluatedProperties`, ...). `toJsonSchemaDraft7()` / `toSchemaModelDraft7()` convert it down and throw `UnsupportedError` when the meaning would change. Catch that rather than dropping keywords by hand.

To generate Dart models from a `.schema.json` file, see the `build-data-classes-with-ack` skill.
