# Ack

[![CI/CD](https://github.com/btwld/ack/actions/workflows/ci.yml/badge.svg)](https://github.com/btwld/ack/actions/workflows/ci.yml)
[![Documentation](https://img.shields.io/badge/docs-documentation-blue)](https://concepta.dev/ack)
[![pub package](https://img.shields.io/pub/v/ack.svg)](https://pub.dev/packages/ack)
[![llms.txt](https://img.shields.io/badge/llms.txt-available-8A2BE2)](https://concepta.dev/documentation/ack/reference/llms-txt)

Ack is a schema validation library for Dart and Flutter. It validates data with a fluent API. Ack is short for "acknowledge".

For AI agents: start at [`/llms.txt`](https://concepta.dev/documentation/ack/reference/llms-txt).

## Why use Ack?

- **Validate external payloads**: Guard API and user inputs by validating required fields, types, and constraints at boundaries
- **Single source of truth**: Define data structures and rules in one place
- **Less boilerplate**: Minimize repetitive validation and JSON conversion code
- **Type safety**: Generate immutable models for hand-written Ack schemas with `@AckInfer()`
- **Class-first generation**: Derive validated codec schemas from hand-written Dart classes with `@AckModel()`

## Packages

This repository is a monorepo containing:

- **[ack](./packages/ack)**: Core validation library with a fluent schema-building API, codecs, and JSON Schema export
- **[ack_annotations](./packages/ack_annotations)**: The `@AckInfer()`, `@AckModel()`, and deprecated legacy `@AckType()` annotations
- **[ack_generator](./packages/ack_generator)**: Generates models from schemas and schemas from hand-written models
- **[ack_firebase_ai](./packages/ack_firebase_ai)**: Firebase AI (Gemini) schema converter for structured-output generation
- **[ack_json_schema_builder](./packages/ack_json_schema_builder)**: Converter to `json_schema_builder` schemas
- **[ack_mcp_dart](./packages/ack_mcp_dart)**: MCP tool schemas and typed argument validation for `mcp_dart`
- **[example](./example)**: Example projects demonstrating usage of all packages

## Community and support

- Read [CONTRIBUTING.md](./CONTRIBUTING.md) before proposing a change.
- Use [SUPPORT.md](./SUPPORT.md) for questions, bug reports, and feature requests.
- Report vulnerabilities privately as described in [SECURITY.md](./SECURITY.md).
- Participation is governed by the [Code of Conduct](./CODE_OF_CONDUCT.md).

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

Generate immutable models for hand-written schemas with `@AckInfer()`. Add
`ack_annotations` to `dependencies` and `ack_generator` + `build_runner` to
`dev_dependencies`, then annotate a top-level schema:

```dart
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

part 'user.ack.dart';
part 'user.ack.g.dart';

@AckInfer()
final userSchema = Ack.object({
  'name': Ack.string().minLength(2),
  'email': Ack.string().email(),
});
```

Run the generator:

```bash
dart run build_runner build
```

This emits a `User` class with stored typed fields, validation helpers, and a
JSON boundary:

```dart
final user = User.parse({'name': 'Alice', 'email': 'alice@example.com'});
print(user.name);     // String
print(user.toJson()); // {'name': 'Alice', 'email': 'alice@example.com'}
```

`@AckInfer()` supports objects, primitives, lists, enums, bidirectional codecs,
named recursion, and discriminated unions. One-way transforms are rejected
because a generated model must be encodable. See the
[Model Code Generation guide](docs/core-concepts/typesafe-schemas.mdx).

### Legacy Ack 1.1 generation

`@AckType()` remains available for source compatibility and keeps the Ack 1.1
extension-type API and `.g.dart` output unchanged. It is deprecated and will be
removed in Ack 2.0:

```dart
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

part 'legacy_user.g.dart';

@AckType()
final userSchema = Ack.object({'name': Ack.string()});
```

This still generates `UserType`, including its Map interface, typed getters,
`parse` / `safeParse`, and `.args`. New code should use `@AckInfer()` or
`@AckModel()`.

| Ack 1.1 source | Optional immutable-model migration |
|---|---|
| Keep `@AckType()` | Rename it to `@AckInfer()` |
| Keep `part 'file.g.dart';` | Add `file.ack.dart` and `file.ack.g.dart` parts |
| Use `*Type`, Map access, and `.args` | Use the generated class, typed fields, `parse`, `fromJson`, and `toJson` |

Legacy and modern declarations may coexist when they are unrelated. A nested
reference graph cannot cross between them; migrate that connected graph
together.

Already own the model class? Use `@AckModel()` to derive a codec schema from
constructor-backed fields while keeping the class hand-written. A class named
`Account` receives an `AccountSchema` facade for parsing, encoding, schema
export, and nested composition; the backing codec remains private:

```dart
@AckModel()
final class Account with _$AccountAck {
  const Account({required this.name});

  @MinLength(2)
  final String name;

  static final fromJson = AccountSchema.fromJson;
}
```

`Account.fromJson({'name': 'Ada'})` validates and constructs the model, while
`account.toJson()` validates and encodes it. See the
[Model Code Generation guide](docs/core-concepts/typesafe-schemas.mdx).

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
[Codecs guide](https://concepta.dev/documentation/ack/advanced/codecs).

## Documentation

- Human docs: [concepta.dev/ack](https://concepta.dev/ack)
- AI agent index: [AI & llms.txt](https://concepta.dev/documentation/ack/reference/llms-txt)
- Canonical plaintext source: [raw.githubusercontent.com/btwld/ack/main/llms.txt](https://raw.githubusercontent.com/btwld/ack/main/llms.txt)

## Development

This project uses [Melos](https://github.com/invertase/melos) to manage the monorepo.

### Setup

```bash
# Resolve the workspace-local Melos dependency
dart pub get

# Bootstrap the workspace (installs dependencies for all packages)
dart run melos bootstrap
```

### Common commands (run from root)

```bash
# Run tests across all packages
dart run melos run test

# Format code across all packages
dart run melos run format

# Analyze code across all packages
dart run melos run analyze

# Check for outdated dependencies
dart run melos run deps-outdated

# Run build_runner for packages that need it (e.g., ack_generator, example)
dart run melos run build

# Clean build artifacts
dart run melos run clean

# Propose/apply version and changelog updates
dart run melos version

# Dry-run pub.dev validation for every package, requiring zero warnings
dart scripts/publish_dry_run.dart
```

Publishing runs only from a `v*` tag through GitHub Actions. See
[PUBLISHING.md](./PUBLISHING.md).

### Development tools

```bash
# JSON Schema validation (JSON Schema Draft-7 compatibility)
dart run melos run validate-jsonschema

# API compatibility check (for semantic versioning)
dart run melos run api-check -- 1.1.0

# See all available scripts
dart run melos run --list
```

Additional development documentation is available in the `tools/` directory.

## Versioning and publishing

This project uses GitHub Releases to manage versioning and publishing. See [PUBLISHING.md](./PUBLISHING.md) for instructions.

## Contributing

Contributions are welcome. Follow these steps:

1. Fork the repository
2. Create a feature branch
3. Add your changes
4. Run tests with `dart run melos run test`
5. Follow [Conventional Commits](https://www.conventionalcommits.org/) in your commit messages
6. Submit a pull request
