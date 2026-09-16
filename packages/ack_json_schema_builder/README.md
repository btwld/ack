# ack_json_schema_builder

JSON Schema Builder converter for the [ACK](https://pub.dev/packages/ack) validation library.

[![pub package](https://img.shields.io/pub/v/ack_json_schema_builder.svg)](https://pub.dev/packages/ack_json_schema_builder)

## Overview

Converts ACK schemas to json_schema_builder format via `.toJsonSchemaBuilder()`
and imports builder models via `.toAckSchema()`.

## Importing a schema

```dart
import 'package:ack/ack.dart';
import 'package:ack_json_schema_builder/ack_json_schema_builder.dart';
import 'package:json_schema_builder/json_schema_builder.dart' as jsb;

final AckSchema<Object, Object> schema = jsb.Schema.object(
  properties: {'name': jsb.Schema.string()},
  required: ['name'],
).toAckSchema();

final value = schema.parse({'name': 'Ada'});
final exported = schema.toJsonSchemaBuilder();
```

Imports use ACK's draft 2020-12 `importJsonSchema()` implementation. Supply
cross-document references through `documents: <Uri, jsb.Schema>{...}` and an
optional `baseUri`; no network requests are made. Strict imports reject
unsupported features: `toAckSchema()` returns an executable validator and has
no partial-conversion option. For a report, use `importToAck()`:

```dart
final JsonSchemaImportResult report = jsb.Schema.fromMap({
  'type': 'string',
  'format': 'email',
}).importToAck(allowUnsupported: true);
final AckSchema<Object, Object> partial = report.schema;
assert(!report.isExact);
print(report.diagnostics);
```

The builder model is the source document; `JsonSchemaImportResult` is the
immutable diagnostic report with a validator; `AckSchema<Object, Object>` is
the executable validator. `importToAck()` is also strict unless partial
conversion is explicitly requested. Exports preserve supported validation
behavior, not textual round-trip identity or omitted assertions.

The subset includes objects, arrays, primitives, enum/const, numeric bounds,
length constraints, `anyOf`/`allOf`/exclusive `oneOf`/`not`, and recursive
references. Formats, patterns, multiples, dynamic references, and meta-schema
validation are not supported. Exports contain only enforced assertions.
The published A2UI basic catalog also requires unsupported unevaluated-property
checks and conditionals: import it partially only when its diagnostics are
acceptable for your application. Full A2UI support and MCP registration
compatibility remain separate work.
See the [import guide](https://concepta.dev/documentation/ack/guides/json-schema-integration)
for the complete support matrix and reference/diagnostic behavior.

## Installation

```yaml
dependencies:
  ack: ^1.2.0
  ack_json_schema_builder: ^1.5.0
  json_schema_builder: ^0.1.3
```

### Compatibility

Requires `json_schema_builder: >=0.1.3 <1.0.0` as a peer dependency. Report [compatibility issues](https://github.com/conceptadev/ack/issues).

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

The converter emits ACK's generic Draft-7 JSON Schema map before constructing
the `json_schema_builder` schema. If a downstream validator or consumer ignores
a JSON Schema keyword, validate with ACK after parsing.

```dart
final schema = Ack.date().min(DateTime(2026));
final jsonSchema = schema.toJsonSchemaBuilder(); // Includes format: date.
```

`Ack.date()` uses local-midnight `DateTime` values at runtime. Use
`DateTime.utc(...)` with `Ack.datetime()`, whose runtime invariant is UTC.

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

For contribution guidelines, see the repository's
[CONTRIBUTING.md](https://github.com/conceptadev/ack/blob/main/CONTRIBUTING.md).

## License

This package is part of the [ACK](https://github.com/conceptadev/ack) monorepo.

## Related Packages

- [ack](https://pub.dev/packages/ack) - Core validation library
- [ack_firebase_ai](https://pub.dev/packages/ack_firebase_ai) - Firebase AI converter
- [json_schema_builder](https://pub.dev/packages/json_schema_builder) - JSON Schema builder
