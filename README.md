# Ack Validation Workspace

[![CI/CD](https://github.com/leoafarias/ack/actions/workflows/ci.yml/badge.svg)](https://github.com/leoafarias/ack/actions/workflows/ci.yml)
[![docs.page](https://img.shields.io/badge/docs.page-documentation-blue)](https://docs.page/leoafarias/ack)

This is a monorepo containing packages for the Ack validation ecosystem.

## Packages

- **[ack](./packages/ack)**: A fluent schema-building and validation library for Dart.
- **[ack_generator](./packages/ack_generator)**: Code generator that creates validation schema classes from annotated Dart classes.
- **[example](./example)**: Demonstrates usage of `ack` and `ack_generator`.

## Documentation

Detailed documentation is available at [docs.page/leoafarias/ack](https://docs.page/leoafarias/ack).

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
```

## Contributing

Contributions are welcome! A detailed CONTRIBUTING.md file will be added soon with specific guidelines.

In the meantime, please follow these basic steps:
1. Fork the repository
2. Create a feature branch
3. Add your changes
4. Run tests with `melos test`
5. Submit a pull request
