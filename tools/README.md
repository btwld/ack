# Ack Development Tools

This directory contains internal development tools and documentation for the Ack library, focusing on JSON Schema validation.

## 📁 Directory Structure

- `jsonschema-validator.js` - JSON Schema Draft-7 validation tool
- `docs/` - **Internal development documentation** (not published)
- `test-fixtures/` - Test data and configurations

## 📚 Documentation

See the main project documentation for development workflows.

## Setup

Install Node.js dependencies:

```bash
cd tools
npm install
```

## JSON Schema Validator

The `jsonschema-validator.js` script validates that Ack-generated JSON schemas are valid JSON Schema Draft-7 specifications using industry-standard JSON Schema validation.

### Usage

#### Single Schema Validation

Validate a single JSON schema specification:

```bash
node jsonschema-validator.js validate-schema --schema schema.json --output results.json
```

#### Batch Schema Validation

Run multiple schema validation tests from a configuration file:

```bash
node jsonschema-validator.js validate-batch --input test-fixtures/reference-config.json --output results.json
```

### Test Fixtures

The `test-fixtures/` directory contains:

- `reference-schemas/` - JSON schemas generated from Ack reference fixtures
- `reference-config.json` - Batch validation config for the reference schemas

### Integration with Dart Tests

The validator can be called from Dart tests to create golden file tests that ensure Ack's validation behavior matches JSON Schema validation standards.

Example Dart test:

```dart
test('JSON Schema compatibility for user schema', () async {
  // Generate JSON schema from Ack schema
  final ackSchema = Ack.object({
    'name': Ack.string().minLength(2),
    'email': Ack.string().email(),
  });
  
  final jsonSchema = ackSchema.toSchemaModel().toJsonSchema();
  
  // Write schema to temp file
  final schemaFile = File('temp/user-schema.json');
  await schemaFile.writeAsString(jsonEncode(jsonSchema));
  
  // Run JSON Schema validation
  final result = await Process.run('node', [
    'tools/jsonschema-validator.js',
    'validate-batch',
    '--input', 'tools/test-fixtures/reference-config.json',
    '--output', 'temp/jsonschema-results.json'
  ]);

  expect(result.exitCode, equals(0));

  // Compare with golden file
  final results = jsonDecode(await File('temp/jsonschema-results.json').readAsString());
  await expectLater(results, matchesGoldenFile('jsonschema-validation-results.golden'));
});
```

### Output Format

The validator outputs structured JSON results:

```json
{
  "timestamp": "2024-01-01T00:00:00.000Z",
  "configPath": "test-fixtures/reference-config.json",
  "schemas": [
    {
      "name": "string-basic",
      "description": "Reference fixture for string basic",
      "path": "test-fixtures/reference-schemas/string-basic.json",
      "result": {
        "valid": true,
        "errors": [],
        "schemaName": "string-basic",
        "schema": {
          "$schema": "http://json-schema.org/draft-07/schema#",
          "type": "string"
        },
        "validationType": "compilation"
      }
    }
  ]
}
```

## Adding New Test Cases

1. Add or update the Ack schema case in `generate_reference_fixtures.js`
2. Run `npm run generate-fixtures`
3. Run `npm run validate-fixtures`
4. Commit the updated `test-fixtures/reference-schemas/` files and `test-fixtures/reference-config.json`

## Integration with Melos

The JSON Schema validation tool is integrated into the Melos workflow with `validate-jsonschema` scripts.

See the main project's `melos.yaml` for all available commands.
