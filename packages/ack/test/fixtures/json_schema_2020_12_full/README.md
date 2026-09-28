# Pinned JSON Schema Test Suite

This directory vendors the **complete** `tests/draft2020-12/` tree and the
suite's `remotes/` fixtures from
[JSON-Schema-Test-Suite](https://github.com/json-schema-org/JSON-Schema-Test-Suite)
commit `80c87e8fca8b207a7a7ae944b875f0fcf889f46a` (MIT; see `LICENSE`).
The GitHub archive SHA-256 is
`33e7f6afcade9777013752f124ff0bc9bdc41a5a33cb91b9578c3908cb83ed1d`.

The fixtures mirror upstream, except four trailing-space lines were normalized
for diff hygiene. They are intended for fully offline validation: URLs under
`http://localhost:1234/` identify files in
`remotes/` and must never trigger network fetches. The historical selected
subset in `../json_schema_import/` remains a separate regression corpus.

Do not count the presence of these files as a conformance pass. The conformance
tests exercise every required group, plus the optional format-assertion groups
in their correct modes, without silent skips. Other optional groups are not
claimed as complete.
