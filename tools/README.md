# Ack Development Tools

This directory contains Draft-7 compatibility tooling:

- `jsonschema-validator.js` validates and compiles schemas with Ajv.
- `generate_reference_fixtures.js` generates the reference fixture set.
- `test-fixtures/` contains schemas and the batch configuration.

Ack 2.0 also supports imported Draft 2020-12 resources. These tools cover the
Draft-7 compatibility path, not all importer dialect behavior. See the
[JSON Schema guide](../docs/guides/json-schema-integration.mdx) for that contract.

## Setup and validation

Run these commands from `tools/`:

```bash
npm ci
node jsonschema-validator.js validate-schema --schema schema.json --output results.json
node jsonschema-validator.js validate-batch --input test-fixtures/reference-config.json --output results.json
```

The validator returns structured JSON, including schema validity and per-schema
batch results. It exits with status 0 when validation succeeds and 1 when
validation fails or an error occurs. Use `--help` on a command for its options.

From the repository root, the corresponding Melos commands are:

```bash
dart run melos run validate-jsonschema
dart run melos run validate-jsonschema:batch
```

The first command runs the Dart conformance test after installing Node tooling;
the batch command validates the reference configuration. For an individual Dart
fixture, follow `packages/ack/test/json_schema_conformance_test.dart` rather than
maintaining a second test harness in this README.

## Update reference fixtures

Edit the schema case in `generate_reference_fixtures.js`, then run from `tools/`:

```bash
npm run generate-fixtures
npm run validate-fixtures
```

Review the resulting changes to `test-fixtures/reference-schemas/` and
`test-fixtures/reference-config.json` before committing them. Run relevant checks
from [CONTRIBUTING.md](../CONTRIBUTING.md); list other root tasks with
`dart run melos run --list`.
