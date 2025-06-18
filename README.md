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
  'name': Ack.string.minLength(2).maxLength(50),
  'email': Ack.string.email(),
  'age': Ack.int.min(0).max(120).nullable(),
}, required: ['name', 'email']);

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

### Code Generator (ack_generator)

For type-safe schema generation from Dart models:

```bash
# Add dependencies
dart pub add ack
dart pub add dev:ack_generator dev:build_runner
```

Define a model with annotations:

```dart
import 'package:ack/ack.dart';

part 'user.g.dart'; // Generated file

@Schema()
class User {
  @MinLength(2)
  @MaxLength(50)
  final String name;

  @IsEmail()
  final String email;

  @Min(0)
  @Max(120)
  final int? age; // Nullable types are automatically detected

  User({required this.name, required this.email, this.age});
}
```

Generate schema classes:

```bash
dart run build_runner build
```

Use the generated schema:

```dart
// Create and validate in one step
final userSchema = UserSchema({
  'name': 'John Doe',
  'email': 'john@example.com',
  'age': 30
});

if (userSchema.isValid) {
  // Access strongly-typed properties directly
  print('User: ${userSchema.name}, ${userSchema.email}');
  
  // Create your model manually
  final user = User(
    name: userSchema.name,
    email: userSchema.email,
    age: userSchema.age,
  );
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
