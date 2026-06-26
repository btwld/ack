# Ack

[![CI/CD](https://github.com/btwld/ack/actions/workflows/ci.yml/badge.svg)](https://github.com/btwld/ack/actions/workflows/ci.yml)
[![docs.page](https://img.shields.io/badge/docs.page-documentation-blue)](https://docs.page/btwld/ack)
[![pub package](https://img.shields.io/pub/v/ack.svg)](https://pub.dev/packages/ack)
[![llms.txt](https://img.shields.io/badge/llms.txt-available-8A2BE2)](https://docs.page/btwld/ack/llms.txt)

Ack is a schema validation library for Dart and Flutter. It validates data with a fluent API. Ack is short for "acknowledge".

For AI agents: start at [`/llms.txt`](https://docs.page/btwld/ack/llms.txt).

## Why use Ack?

- **Validate external payloads**: Guard API and user inputs by validating required fields, types, and constraints at boundaries
- **Single source of truth**: Define data structures and rules in one place
- **Less boilerplate**: Minimize repetitive validation and JSON conversion code
- **Type safety**: Generate typed wrappers for hand-written Ack schemas with `@AckType()`

## Packages

This repository is a monorepo containing:

- **[ack](./packages/ack)**: Core validation library with a fluent schema-building API, codecs, and JSON Schema export
- **[ack_annotations](./packages/ack_annotations)**: The `@AckType()` annotation that marks schemas for code generation
- **[ack_generator](./packages/ack_generator)**: Code generator that turns `@AckType()` schemas into type-safe extension types
- **[ack_firebase_ai](./packages/ack_firebase_ai)**: Firebase AI (Gemini) schema converter for structured-output generation
- **[ack_json_schema_builder](./packages/ack_json_schema_builder)**: Converter to `json_schema_builder` schemas
- **[example](./example)**: Example projects demonstrating usage of all packages

## Quick start

### Core library (ack)

Add Ack to your project:

```bash
dart pub add ack
```

Define and use a schema:

```dart
import 'package:ack/ack.dart';

final userSchema = Ack.object({
  'name': Ack.string().minLength(2).maxLength(50),
  'email': Ack.string().email(),
  'age': Ack.integer().min(0).max(120).optional(),
});

final result = userSchema.safeParse({
  'name': 'John Doe',
  'email': 'john@example.com',
  'age': 30
});

if (result.isOk) {
  final validData = result.getOrThrow();
  print('Valid user: $validData');
} else {
  final error = result.getError();
  print('Validation failed: $error');
}
```

Use `.optional()` when a field may be omitted entirely. Chain `.nullable()` if a present field may hold `null`, or combine both for an optional-and-nullable value.

### Advanced usage

For complex validation:

```dart
import 'package:ack/ack.dart';

// Complex nested object validation
final orderSchema = Ack.object({
  'id': Ack.string().uuid(),
  'customer': Ack.object({
    'name': Ack.string().minLength(2),
    'email': Ack.string().email(),
  }),
  'items': Ack.list(Ack.object({
    'product': Ack.string(),
    'quantity': Ack.integer().positive(),
    'price': Ack.double().positive(),
  })).minLength(1),
  'total': Ack.double().positive(),
}).refine(
  (order) {
    // Custom validation: total should match sum of items
    final items = order['items'] as List;
    final calculatedTotal = items.fold<double>(0, (sum, item) {
      final itemMap = item as Map<String, Object?>;
      final quantity = itemMap['quantity'] as int;
      final price = itemMap['price'] as double;
      return sum + (quantity * price);
    });
    final total = order['total'] as double;
    return (calculatedTotal - total).abs() < 0.01;
  },
  message: 'Total must match sum of item prices',
);

// Validate complex data
final result = orderSchema.safeParse(orderData);
if (result.isOk) {
  final validOrder = result.getOrThrow();
  print('Valid order: ${validOrder['id']}');
} else {
  print('Validation failed: ${result.getError()}');
}
```

## Code generation

Generate type-safe wrappers for hand-written schemas with `@AckType()`. Add
`ack_annotations` to `dependencies` and `ack_generator` + `build_runner` to
`dev_dependencies`, then annotate a top-level schema:

```dart
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

part 'user.g.dart';

@AckType()
final userSchema = Ack.object({
  'name': Ack.string().minLength(2),
  'email': Ack.string().email(),
});
```

Run the generator:

```bash
dart run build_runner build --delete-conflicting-outputs
```

This emits a `UserType` extension type with `parse`/`safeParse` and typed
getters — no manual casting:

```dart
final user = UserType.parse({'name': 'Alice', 'email': 'alice@example.com'});
print(user.name); // typed String getter
```

`@AckType()` supports objects, primitives, lists, enums, explicit transforms, and discriminated unions. See the [TypeSafe Schemas guide](https://docs.page/btwld/ack/core-concepts/typesafe-schemas).

## Codecs

Codecs decode boundary values (the JSON you receive) into rich Dart runtime types and encode them back. Ack ships built-in codecs and lets you define your own:

```dart
// Built-in codec: ISO 8601 String boundary <-> UTC DateTime runtime
final when = Ack.datetime();
final dt = when.parse('2026-01-01T00:00:00Z'); // DateTime
final iso = when.encode(dt);                    // back to an ISO 8601 String

// Other built-ins: Ack.date(), Ack.uri(), Ack.duration(), Ack.enumCodec(...)

// Custom bidirectional codec
final csv = Ack.codec<String, String, List<String>>(
  input: Ack.string(),
  decode: (s) => s.split(','),
  encode: (list) => list.join(','),
);

csv.parse('a,b,c');          // ['a', 'b', 'c']
csv.encode(['a', 'b', 'c']); // 'a,b,c'
```

Use `.transform<R>(...)` for one-way (parse-only) conversions. See the
[Codecs guide](https://docs.page/btwld/ack/core-concepts/codecs).

## Documentation

- Human docs: [docs.page/btwld/ack](https://docs.page/btwld/ack)
- AI agent index: [docs.page/btwld/ack/llms.txt](https://docs.page/btwld/ack/llms.txt)
- Canonical plaintext source: [raw.githubusercontent.com/btwld/ack/main/llms.txt](https://raw.githubusercontent.com/btwld/ack/main/llms.txt)

## Development

This project uses [Melos](https://github.com/invertase/melos) to manage the monorepo.

### Setup

```bash
# Install Melos (if not already installed)
dart pub global activate melos

# Bootstrap the workspace (installs dependencies for all packages)
melos bootstrap
```

### Common commands (run from root)

```bash
# Run tests across all packages
melos test

# Format code across all packages
melos format

# Analyze code across all packages
melos analyze

# Check for outdated dependencies
melos deps-outdated

# Run build_runner for packages that need it (e.g., ack_generator, example)
melos build

# Clean build artifacts
melos clean

# Propose/apply version and changelog updates
melos version

# Dry-run pub.dev validation for one package
(cd packages/ack && dart pub publish --dry-run)

# Publish all packages (no dry-run)
melos run publish
```

### Development tools

```bash
# JSON Schema validation (JSON Schema Draft-7 compatibility)
melos validate-jsonschema

# API compatibility check (for semantic versioning)
melos api-check v0.2.0

# See all available scripts
melos list-scripts
```

Additional development documentation is available in the `tools/` directory.

## Versioning and publishing

This project uses GitHub Releases to manage versioning and publishing. See [PUBLISHING.md](./PUBLISHING.md) for instructions.

## Contributing

Contributions are welcome. Follow these steps:

1. Fork the repository
2. Create a feature branch
3. Add your changes
4. Run tests with `melos test`
5. Follow [Conventional Commits](https://www.conventionalcommits.org/) in your commit messages
6. Submit a pull request
