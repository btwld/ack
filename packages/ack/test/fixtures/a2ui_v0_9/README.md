# A2UI v0.9 import fixtures

Source: [A2UI](https://github.com/a2ui-project/a2ui) at commit
`f5e945a93da36a5d126228f2ad6fbe68809ef8f7` (Apache-2.0; see LICENSE).

The five schemas used by the importer tests are copied unchanged from
`specification/v0_9/json/`: `client_capabilities.json`,
`client_data_model.json`, `client_to_server.json`, `common_types.json`, and
`server_capabilities.json`.

The tests cover strict imports of supported protocol documents and diagnostics
for unsupported meta-schema references and the `date-time` format. They are not
a claim of full A2UI conformance.
