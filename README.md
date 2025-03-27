# Ack Validation Workspace

This is a monorepo containing packages for the Ack validation ecosystem.

## Packages

- **[ack](./packages/ack)**: A fluent schema-building and validation library for Dart
- **[ack_generator](./packages/ack_generator)**: Code generator that creates validation schema classes from annotated Dart classes

## Development

This project uses [Melos](https://github.com/invertase/melos) to manage the monorepo.

### Setup

```bash
# Install Melos
dart pub global activate melos

# Bootstrap the workspace
melos bootstrap
```

### Commands

```bash
# Run tests across all packages
melos test

# Format code across all packages
melos format

# Check for outdated dependencies
melos deps-outdated
```
