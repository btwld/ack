# ack_json_schema_builder

JSON Schema Builder converter for the [ACK](https://pub.dev/packages/ack) validation library.

[![pub package](https://img.shields.io/pub/v/ack_json_schema_builder.svg)](https://pub.dev/packages/ack_json_schema_builder)

## Overview

Converts ACK schemas to json_schema_builder format via `.toJsonSchemaBuilder()`. Assumes familiarity with [ACK](https://pub.dev/packages/ack) and [json_schema_builder](https://pub.dev/packages/json_schema_builder).

## Installation

```yaml
dependencies:
  ack: ^1.0.0
  ack_json_schema_builder: ^1.0.0
  json_schema_builder: ^0.1.3
```

### Compatibility

Requires `json_schema_builder: >=0.1.3 <1.0.0` as a peer dependency. Report [compatibility issues](https://github.com/btwld/ack/issues).

## Limitations ⚠️

**Read this first** - json_schema_builder schema conversion has important constraints:

### 1. Custom Refinements Not Supported

Custom validation logic cannot be expressed in JSON Schema format.

```dart
// Cannot convert
final schema = Ack.string().refine((s) => s.startsWith('ACK_'));

// Validate with ACK schema instead
final result = schema.safeParse(data);
```

### 2. Default Values Not Applied

Defaults are ACK-only. Apply after parsing.

```dart
final schema = Ack.string().withDefault('default');
schema.toJsonSchemaBuilder(); // Default not included in JSON Schema
```

### 3. TransformedSchema Limitations

Transformed schemas convert the underlying schema. Metadata overrides may not be fully preserved due to json_schema_builder's immutable Schema objects.

```dart
final dateSchema = Ack.date(); // TransformedSchema
final jsonSchema = dateSchema.toJsonSchemaBuilder(); // Converts underlying string schema
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
