# Draft 2020-12 capability matrix

This matrix tracks four different claims. **Compile** means `Ack.fromJsonSchema`
accepts a schema and resolves its declarations. **Validate** means its instance
semantics are exercised. **Export** means `toJsonSchema()` preserves the
meaning under draft 2020-12. **Generate** means the opt-in
`ack_generator:ack_json_schema` builder emits a usable typed or validated Dart
model. `model_mode: auto` keeps typed v1 output where possible and uses a
validated value-model fallback otherwise; `model_mode: validated` forces the
source validator for exact parse/encode behavior. A keyword is not fully
supported merely because a compiler accepts it.

Status: **yes** = implemented and covered, **partial** = known gaps, **no** =
unsupported or not yet implemented. `toJsonSchema()` and `toSchemaModel()`
preserve imported Draft 2020-12 resources by default (`toJsonSchemaDraft7()`
and `toSchemaModelDraft7()` lower compatible imports to Draft-7); native Ack
schemas remain Draft-7.

| Vocabulary / keywords | Compile | Validate | Export | Generate | Remaining work |
|---|---|---|---|---|---|
| Core: boolean schemas, `$schema`, `$id`, `$defs`, `$ref`, pointers, `$anchor`, supplied documents | partial | yes | yes | yes | All 384 required groups generate offline; builder `documents` maps retrieval URIs to local assets. Custom dialects and vocabularies remain bounded by the importer. |
| Core: `$dynamicAnchor`, `$dynamicRef` | yes | yes | yes | yes | Validated value models retain dynamic scope; typed field inference remains unavailable. |
| Core: `$vocabulary` | partial | partial | partial | partial | Supplied custom dialects select supported vocabularies; unknown required vocabularies fail and unknown optional vocabularies remain inert. |
| Core: unknown keywords | yes | n/a | partial | yes | Value models preserve inert annotations; unknown required vocabularies fail. |
| Applicators: `properties`, `additionalProperties`, `propertyNames`, `items`, `allOf`, `anyOf`, `oneOf`, `not` | yes | yes | yes | yes | Typed output covers simple forms; general compositions use validated value models. |
| Applicators: `contains`, `if`, `then`, `else` | yes | yes | yes | yes | Validated value models retain the source assertions; typed fields remain a follow-up. |
| Applicators: `patternProperties`, `dependentSchemas`, `prefixItems` | yes | yes | yes | yes | Validated value models retain the source assertions; typed fields remain a follow-up. |
| Unevaluated: `unevaluatedProperties`, `unevaluatedItems` | yes | yes | yes | yes | Validated value models retain evaluated-location semantics; typed fields remain a follow-up. |
| Validation: `type`, `enum`, `const`, `required`, length/number/array/object bounds, `pattern`, `uniqueItems` | yes | yes | yes | yes | General JSON enum/const use value models. Typed `int` and UTF-16 string-length edges require `model_mode: validated` for exact parity. |
| Validation: `multipleOf`, `minContains`, `maxContains`, `dependentRequired` | yes | yes | yes | yes | Validated value models bind the compiled source schema. |
| Metadata: `title`, `description`, `default`, `examples`, `deprecated`, `readOnly`, `writeOnly`, `$comment` | yes | n/a | yes | yes | Value models retain annotations without injecting defaults or access projections. |
| Format annotation / assertion | yes | yes | yes | yes | `assert_formats: true` enables supported assertions; unknown asserted formats fail compilation by Ack's contract. |
| Content: `contentEncoding`, `contentMediaType`, `contentSchema` | yes | n/a | yes | yes | Preserved as annotations without implicit decoding. |

## Verification contract

- Run the **complete pinned upstream** draft 2020-12 suite and remote fixtures
  offline, organized by vocabulary. Do not silently skip unsupported groups.
- Run format cases in annotation and assertion modes separately. Include
  Unicode property escapes and numeric/collection equality cases.
- Generated parse and encode must agree with the compiled source validator,
  including property presence and nullable roots/elements. Wrapper fallback is
  explicit, documented and schema-validated.

The complete **required** suite passes 384 groups in source-validation and
export/re-import modes. The optional format-assertion corpus passes 30 groups
in both modes, with its unknown-format group checked against Ack's explicit
fail-on-unknown-asserted-format contract. All 384 required groups also generate
source offline with their supplied resources. A real `build_runner` consumer
verifies generated parse/encode for
representative recursive, dynamic-reference, composition, unevaluated, numeric,
format-assertion, and external-resource cases. This is not a separate runtime
execution of every generated official case; other optional vocabularies remain
partially covered. The historical selected fixture remains a round-trip
regression corpus.
