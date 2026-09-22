# JSON Schema import conformance fixtures

Source: [JSON Schema Test Suite](https://github.com/json-schema-org/JSON-Schema-Test-Suite)
at commit `80c87e8fca8b207a7a7ae944b875f0fcf889f46a` (MIT; see LICENSE).

`draft2020-12.json` contains the 186 test groups (631 instance cases) that use
the importer's supported subset, selected from `tests/draft2020-12/*.json`.
Descriptions are prefixed with the original filename. Schema and instance
values are unchanged. Referenced fixtures from `remotes/` are included in each
group's `documents` map, keyed by the upstream test-server URI, for offline use.

Selection happened when importing the fixtures, not at test runtime. Every
listed group must continue importing exactly; unsupported features cannot
silently turn these regression tests into skips.

One group is excluded for a semantic deviation rather than an unsupported
keyword: `pattern.json: pattern with Unicode property escape requires unicode
mode`. Its schema imports cleanly, but `pattern` compiles with Dart's default
`RegExp`, which follows ECMA-262 *without* the `u` flag, so `\p{Letter}` is an
identity escape and the group's instances do not match. Enabling `u` would fix
that group and reject patterns ECMA-262 accepts without it, such as an escaped
hyphen outside a character class (`^\d{3}\-\d{4}$`).

The complete suite also contains unsupported keywords; this fixture selection
is **not** a claim of complete draft 2020-12 conformance.
