# A2UI v0.9 import fixtures

Source: [A2UI](https://github.com/a2ui-project/a2ui) at commit
`f5e945a93da36a5d126228f2ad6fbe68809ef8f7` (Apache-2.0; see LICENSE).

The eleven protocol files are copied unchanged from `specification/v0_9/json/`.
`catalog.json` is the unchanged `specification/v0_9/catalogs/basic/catalog.json`.
`example.json` is the unchanged basic catalog example `00_simple-text.json`.
The test registry aliases `catalog.json` as described by A2UI's protocol docs.

The tests deliberately distinguish exact imports from partial ones. The basic
catalog uses unsupported assertions such as `unevaluatedProperties`; accepting
its sample messages does not establish full catalog conformance.
