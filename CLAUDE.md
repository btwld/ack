# Ack - Schema Validation Library for Dart

## Project Overview

**Ack** is a schema validation library for Dart and Flutter that provides a fluent API for validating data structures. This is a monorepo containing multiple packages managed with [Melos](https://melos.invertase.dev/).

## Packages

- **[ack](./packages/ack)**: Core validation library with fluent schema building API
- **[ack_annotations](./packages/ack_annotations)**: Annotations for code generation
- **[ack_generator](./packages/ack_generator)**: Code generator for creating schema classes from annotated Dart models
- **[ack_firebase_ai](./packages/ack_firebase_ai)**: Firebase AI (Gemini) schema converter for structured output generation
- **[example](./example)**: Example projects demonstrating usage

## Environment Setup

The project uses Melos to manage dependencies across all packages. To set up the environment:

```bash
# Install Melos globally (if not already installed)
dart pub global activate melos

# Bootstrap the workspace (installs dependencies for all packages)
melos bootstrap
```

For a complete automated setup including Dart SDK installation, run:

```bash
./setup.sh
```

## Key Dependencies

- **Dart SDK**: >=3.8.0 <4.0.0
- **Melos**: ^3.4.0 (for monorepo management)
- **build_runner**: For code generation (in applicable packages)
- **Node.js**: Optional, for JSON Schema validation tools

## Common Commands

### Testing

```bash
# Run all tests (Dart + Flutter)
melos test

# Run only Dart tests
melos test:dart

# Run only Flutter tests
melos test:flutter

# Run generator-specific tests
melos test:gen

# Run golden tests
melos test:golden

# Update golden test files
melos update-golden:all
```

### Code Quality

```bash
# Analyze code across all packages
melos analyze

# Format code
melos format

# Apply automated fixes
melos fix
```

### Build & Code Generation

```bash
# Run build_runner for packages that need it
melos build

# Clean build artifacts
melos clean
```

### Versioning & Publishing

```bash
# Bump versions (do not run without permission)
melos version

# Publish to pub.dev (do not run without permission)
melos publish
```

### Validation Tools

```bash
# Validate JSON Schema Draft-7 conformance
melos validate-jsonschema

# Check for outdated dependencies
melos deps-outdated
```

### View Available Scripts

```bash
# List all available Melos scripts
melos list-scripts
```

## Project Structure

```
ack/
├── packages/
│   ├── ack/              # Core validation library
│   ├── ack_annotations/  # Annotations for code generation
│   ├── ack_generator/    # Code generator
│   └── ack_firebase_ai/  # Firebase AI integration
├── example/              # Example applications
├── docs/                 # Documentation
├── tools/                # Development tools (JSON Schema validation)
├── scripts/              # Build and release scripts
├── melos.yaml            # Melos configuration
└── setup.sh              # Automated environment setup
```

## Architecture & Design Patterns

- **Fluent API**: Chainable methods for building schemas (e.g., `Ack.string().email().minLength(5)`)
- **Result Type Pattern**: Uses `Result<T, E>` for validation outcomes instead of throwing exceptions
- **Schema Composition**: Supports nested objects, arrays, and complex validation rules
- **Code Generation**: Annotation-based schema generation via `ack_generator`
- **Type Safety**: Generates type-safe schema classes from Dart models

## Important Notes

### Testing Requirements

- Always run tests before committing: `melos test`
- Golden tests require explicit updates with `melos update-golden:all` if intentionally changed
- The project uses both Dart and Flutter tests - ensure both pass

### Code Style

- Follow [Conventional Commits](https://www.conventionalcommits.org/) for commit messages
- Code is formatted with `dart format` - run `melos format` before committing
- Analysis must pass with no warnings: `melos analyze`

### Versioning

- Uses semantic versioning (SemVer)
- Versioning and publishing are managed through GitHub Releases (see PUBLISHING.md)
- **Never manually version or publish** without explicit permission

### Development Workflow

1. Make changes in relevant package(s)
2. Run `melos build` if code generation is needed
3. Run `melos test` to ensure all tests pass
4. Run `melos format` to format code
5. Run `melos analyze` to check for issues
6. Commit with conventional commit message
7. Create pull request

## Helpful Resources

- [Documentation](https://docs.page/btwld/ack)
- [Contributing Guide](./CONTRIBUTING.md) (coming soon)
- [Publishing Guide](./PUBLISHING.md)
- [Melos Documentation](https://melos.invertase.dev/)

## Common Tasks for Claude Code

When working on this project, you'll commonly need to:

1. **Add new validation methods**: Modify `packages/ack/lib/src/ack.dart` and related files
2. **Update code generation**: Modify `packages/ack_generator/lib/src/`
3. **Add tests**: Create test files in `test/` directories of relevant packages
4. **Update examples**: Modify files in `example/` to demonstrate new features
5. **Update documentation**: Modify files in `docs/` or package README files

## Environment Variables

No special environment variables are required for development. The project runs entirely with Dart SDK and Melos.

## Tips for Development

- Use `melos exec -- <command>` to run commands across all packages
- Package-specific work can be done by `cd`ing into the package directory
- Check `melos.yaml` for the complete list of available scripts
- The example app is a great place to test new features interactively
