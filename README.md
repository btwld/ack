# Ack

[![CI/CD](https://github.com/btwld/ack/actions/workflows/ci.yml/badge.svg)](https://github.com/btwld/ack/actions/workflows/ci.yml)
[![docs.page](https://img.shields.io/badge/docs.page-documentation-blue)](https://docs.page/btwld/ack)
[![pub package](https://img.shields.io/pub/v/ack.svg)](https://pub.dev/packages/ack)

Ack is a schema validation library for Dart and Flutter that helps you validate data with a simple, fluent API. Ack is short for "acknowledge".

## Why Use Ack?

- **Simplify Validation**: Easily handle complex data validation logic
- **Ensure Data Integrity**: Guarantee data consistency from external sources (APIs, user input)
- **Single Source of Truth**: Define data structures and rules in one place
- **Reduce Boilerplate**: Minimize repetitive code for validation and JSON conversion
- **Type Safety**: Generate type-safe schema classes from your Dart models

## Packages

This repository is a monorepo containing:

- **[ack](./packages/ack)**: Core validation library with fluent schema building API
- **[ack_generator](./packages/ack_generator)**: Code generator for creating schema classes from annotated Dart models
- **[example](./example)**: Example projects demonstrating usage of both packages

## Quick Start

### Core Library (ack)

Add Ack to your project:

```bash
dart pub add ack
```

Define and use a schema:

```dart
import 'package:ack/ack.dart';

// Define a schema for a user object
final userSchema = Ack.object({
  'name': Ack.string().minLength(2).maxLength(50),
  'email': Ack.string().email(),
  'age': Ack.integer().min(0).max(120).nullable().optional(),
});

// Validate data against the schema
final result = userSchema.validate({
  'name': 'John Doe',
  'email': 'john@example.com',
  'age': 30
});

// Check if validation passed
if (result.isOk) {
  final validData = result.getOrThrow();
  print('Valid user: $validData');
} else {
  final error = result.getError();
  print('Validation failed: $error');
}
```

### Advanced Usage

For more complex validation scenarios:

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
final result = orderSchema.validate(orderData);
if (result.isOk) {
  final validOrder = result.getOrThrow();
  print('Valid order: ${validOrder['id']}');
} else {
  print('Validation failed: ${result.getError()}');
}
```

## Documentation

Detailed documentation is available at [docs.page/btwld/ack](https://docs.page/btwld/ack).

## Development

This project uses [Melos](https://github.com/invertase/melos) to manage the monorepo.

### Setup

```bash
# Install Melos (if not already installed)
dart pub global activate melos

# Bootstrap the workspace (installs dependencies for all packages)
melos bootstrap
```

### Common Commands (run from root)

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

# Bump patch version (0.0.x)
melos version-patch

# Bump minor version (0.x.0)
melos version-minor

# Bump major version (x.0.0)
melos version-major

# Dry-run publish (validation only)
melos publish-dry

# Publish packages to pub.dev
melos publish
```

### Development Tools

The project includes additional development tools for maintainers:

```bash
# JSON Schema validation (ensures compatibility with JSON Schema Draft-7)
melos validate-jsonschema

# API compatibility checking using Dart script (for semantic versioning)
melos api-check v0.2.0

# See all available scripts
melos list-scripts
```

> **Note**: Additional development documentation is available in the `tools/` directory for project maintainers.

## Versioning and Publishing

This project uses GitHub Releases to manage versioning and publishing. For detailed instructions on how to create releases and publish packages, see [PUBLISHING.md](./PUBLISHING.md).

## Contributing

Contributions are welcome! A detailed CONTRIBUTING.md file will be added soon with specific guidelines.

In the meantime, please follow these basic steps:
1. Fork the repository
2. Create a feature branch
3. Add your changes
4. Run tests with `melos test`
5. Make sure to follow [Conventional Commits](https://www.conventionalcommits.org/) in your commit messages
6. Submit a pull request
