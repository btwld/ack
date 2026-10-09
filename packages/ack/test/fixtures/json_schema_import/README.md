# JSON Schema import conformance fixtures

Source: [JSON Schema Test Suite](https://github.com/json-schema-org/JSON-Schema-Test-Suite)
at commit `80c87e8fca8b207a7a7ae944b875f0fcf889f46a` (MIT; see LICENSE).

`draft2020-12.json` contains the 341 test groups (1,178 instance cases) that use
the importer's supported subset, selected from `tests/draft2020-12/*.json`.
Descriptions are prefixed with the original filename. Schema and instance
values are unchanged. Referenced fixtures from `remotes/` are included in each
group's `documents` map, keyed by the upstream test-server URI, for offline use.

Selection happened when importing the fixtures, not at test runtime. Every
listed group must continue importing exactly; unsupported features cannot
silently turn these regression tests into skips.

The `multipleOf`, `contains`, `minContains`, `maxContains`,
`dependentRequired`, `dependentSchemas`, `patternProperties`, `prefixItems`,
`if-then-else`, `unevaluatedProperties`, `unevaluatedItems`, `format` annotation,
`content` annotation, and remaining
`items` groups, plus the
Unicode-property-escape group in `pattern.json`, were added as those semantics
were implemented. Pattern compilation uses Unicode mode, as required by the
draft 2020-12 dialect.

Two official `unevaluated*` groups use `$dynamicRef` and remain outside this
selected fixture. They, along with all 21 `dynamicRef.json` groups, run in the
complete conformance suite and the dedicated dynamic-reference test in both
source-validation and export/re-import modes. This selected fixture is not the
complete conformance suite.

The complete suite also contains unsupported keywords; this fixture selection
is **not** a claim of complete draft 2020-12 conformance.
