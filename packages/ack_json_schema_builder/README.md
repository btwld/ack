# ack_json_schema_builder

JSON Schema Builder converter for the [ACK](https://pub.dev/packages/ack) validation library.

[![pub package](https://img.shields.io/pub/v/ack_json_schema_builder.svg)](https://pub.dev/packages/ack_json_schema_builder)

## Overview

Converts ACK schemas to json_schema_builder format via `.toJsonSchemaBuilder()`. Assumes familiarity with [ACK](https://pub.dev/packages/ack) and [json_schema_builder](https://pub.dev/packages/json_schema_builder).

## Installation

```yaml
dependencies:
  ack: ^1.0.0-beta.12-wip
  ack_json_schema_builder: ^1.0.0-beta.12-wip
  json_schema_builder: ^0.1.3
```

### Compatibility

Requires `json_schema_builder: >=0.1.3 <1.0.0` as a peer dependency. Report [compatibility issues](https://github.com/btwld/ack/issues).

## Conversion Model

`ack_json_schema_builder` uses ACK's canonical adapter boundary:

```text
AckSchema
  -> AckSchemaModel
  -> JSON Schema map
  -> json_schema_builder Schema.fromMap()
```

That means defaults, const values, extension keywords, transformed-schema
metadata, composition, and discriminated-union branches follow
`AckSchema.toSchemaModel().toJsonSchema()`.

## Limitations ⚠️

**Read this first** - json_schema_builder schema conversion has important
constraints:

### Custom Refinements Not Supported

Custom validation logic cannot be expressed in JSON Schema format.

```dart
// Cannot convert
final schema = Ack.string().refine((s) => s.startsWith('ACK_'));

// Validate with ACK schema instead
final result = schema.safeParse(data);
```

ACK still remains the authoritative runtime validator for refinements and
other logic that JSON Schema cannot represent.

### Target Schema Support

The converter emits ACK's canonical JSON Schema map before constructing the
`json_schema_builder` schema. If a downstream validator or consumer ignores a
JSON Schema keyword, validate with ACK after parsing.

```dart
final schema = Ack.date().min(DateTime.utc(2026));
final jsonSchema = schema.toJsonSchemaBuilder(); // Includes date format bounds.
```

## Usage

```dart
import 'package:ack/ack.dart';
import 'package:ack_json_schema_builder/ack_json_schema_builder.dart';

// 1. Define schema
final userSchema = Ack.object({
  'name': Ack.string().minLength(2).maxLength(50),
  'email': Ack.string().email(),
  'age': Ack.integer().min(0).max(120).optional(),
});

// 2. Convert to json_schema_builder
final jsonSchema = userSchema.toJsonSchemaBuilder();

// 3. Use with json_schema_builder for validation
final errors = await jsonSchema.validate(data);
if (errors.isEmpty) {
  print('Data is valid!');
} else {
  print('Validation errors: $errors');
}
```

## Schema Mapping

### Supported Types

| ACK Type | json_schema_builder Type | Conversion details |
|----------|--------------------------|-------------------|
| `Ack.string()` | `Schema.string()` | Full support with minLength/maxLength |
| `Ack.integer()` | `Schema.integer()` | Full support |
| `Ack.double()` | `Schema.number()` | Full support |
| `Ack.boolean()` | `Schema.boolean()` | Full support |
| `Ack.object({...})` | `Schema.object()` | Full support |
| `Ack.list(...)` | `Schema.list()` | Full support |
| `Ack.enumString([...])` | `Schema.string()` with `enumValues` | Full support |
| `Ack.anyOf([...])` | `Schema.combined(anyOf: ...)` | Full support |
| `Ack.any()` | `Schema.combined(anyOf: ...)` | Expands to union of all types |

### Supported Constraints

| ACK Constraint | json_schema_builder | Notes |
|----------------|---------------------|-------|
| `.minLength()` / `.maxLength()` | `minLength` / `maxLength` | String and array support |
| `.min()` / `.max()` | `minimum` / `maximum` | Numeric bounds |
| `.email()` / `.uuid()` / `.url()` | `format` | Format hints |
| `.optional()` | Excluded from `required` | Optional fields |
| `.describe()` | `description` | Descriptions |
| `.withDefault()` | `default` | JSON-compatible defaults |
| `Ack.literal(...)` | `const` | Literal values |
| `.unique()` | `uniqueItems` | Array uniqueness |

## Testing

```bash
cd packages/ack_json_schema_builder
dart test
```

## Contributing

For contribution guidelines, see [CONTRIBUTING.md](../../CONTRIBUTING.md) in the root repository.

## License

This package is part of the [ACK](https://github.com/btwld/ack) monorepo.

## Related Packages

- [ack](https://pub.dev/packages/ack) - Core validation library
- [ack_firebase_ai](https://pub.dev/packages/ack_firebase_ai) - Firebase AI converter
- [json_schema_builder](https://pub.dev/packages/json_schema_builder) - JSON Schema builder
