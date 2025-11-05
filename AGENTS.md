# Ack Architecture & Context

> **Last Updated:** 2025-11-05
> **Repository:** https://github.com/btwld/ack
> **Version:** Current development state
> **Tech Stack:** Dart, Melos, build_runner

## Executive Summary

**Ack** is a schema validation library for Dart and Flutter that provides a simple, fluent API for validating data. It's inspired by Zod (TypeScript) and provides type-safe schema validation with comprehensive error handling.

**Core Purpose:** Simplify data validation, ensure data integrity from external sources (APIs, user input), and provide a single source of truth for data structures and validation rules.

**Monorepo Structure:** Managed with Melos, contains 4 main packages plus examples.

## Project Structure

```
ack/
├── packages/
│   ├── ack/                    # Core validation library
│   │   ├── lib/
│   │   │   ├── ack.dart       # Main export
│   │   │   └── src/           # Schema implementations
│   │   └── test/              # Unit tests + JSON Schema conformance
│   ├── ack_generator/          # Code generator for schema classes
│   │   ├── lib/
│   │   │   └── builder.dart   # build_runner integration
│   │   ├── test/
│   │   │   └── golden/        # Golden test files
│   │   └── tool/              # Golden test updater
│   ├── ack_firebase_ai/        # Firebase AI (Gemini) schema converter
│   │   └── lib/               # Converts Ack schemas to Firebase AI format
│   └── ack_annotations/        # Annotations for code generator
│       └── lib/
│           └── ack_annotations.dart
├── example/                    # Example projects
├── tools/                      # Development tools
│   ├── jsonschema-validator.js # JSON Schema Draft-7 validation
│   └── package.json           # Node.js dependencies
├── scripts/
│   ├── setup.sh               # Environment setup script
│   ├── update_release_changelog.dart
│   └── api_check.dart         # API compatibility checker
├── melos.yaml                 # Monorepo configuration
└── PUBLISHING.md              # Release process documentation
```

## Package Dependencies

```
ack (core)
  └── No dependencies on other ack packages

ack_annotations
  └── No dependencies on other ack packages

ack_generator
  └── depends on: ack, ack_annotations
  └── dev_depends: build_runner, analyzer

ack_firebase_ai
  └── depends on: ack

example
  └── depends on: ack, ack_generator, ack_annotations
```

## Key Architectural Patterns

### 1. Schema Builder Pattern

Ack uses a fluent API for building schemas:

```dart
final userSchema = Ack.object({
  'name': Ack.string().minLength(2).maxLength(50),
  'email': Ack.string().email(),
  'age': Ack.integer().min(0).max(120).optional(),
});
```

**Key Files:**
- `packages/ack/lib/src/ack.dart` - Main entry point
- `packages/ack/lib/src/schemas/` - All schema types

### 2. Result Type (Ok/Error)

Validation returns a `Result` type (similar to Rust's Result):

```dart
final result = userSchema.safeParse(data);
if (result.isOk) {
  final validData = result.getOrThrow();
} else {
  final error = result.getError();
}
```

**Why:** Explicit error handling, no exceptions in validation flow.

### 3. Schema Types

**Available Schema Types:**
- `StringSchema` - String validation with patterns, length, email, UUID, etc.
- `IntSchema` / `DoubleSchema` - Numeric validation with min/max/positive/negative
- `BoolSchema` - Boolean validation
- `ObjectSchema` - Nested object validation with type-safe field access
- `ListSchema` - Array validation with element schemas
- `UnionSchema` - Type unions (e.g., string | number)
- `LiteralSchema` - Exact value matching
- `EnumSchema` - Enum validation

**Optional & Nullable:**
- `.optional()` - Field may be omitted entirely
- `.nullable()` - Field may be null if present
- Combine both for optional-and-nullable

### 4. Code Generation

`ack_generator` generates schema classes from annotated Dart models:

```dart
@GenerateSchema()
class User {
  final String name;
  final String email;
  final int? age;
}

// Generates: UserSchema class with pre-built validation
```

**Key Files:**
- `packages/ack_generator/lib/builder.dart` - build_runner integration
- `packages/ack_generator/lib/src/generator.dart` - Code generation logic
- `packages/ack_generator/test/golden/` - Golden test files

**Golden Tests:** Output is compared against golden files to ensure consistency.

### 5. Custom Validation with `.refine()`

Add custom validation logic to any schema:

```dart
final orderSchema = Ack.object({...}).refine(
  (order) {
    // Custom validation logic
    return calculatedTotal == order['total'];
  },
  message: 'Total must match sum of item prices',
);
```

### 6. JSON Schema Draft-7 Compatibility

Ack schemas can be converted to JSON Schema Draft-7 format:

```dart
final jsonSchema = userSchema.toJsonSchema();
```

**Validation Tools:**
- `tools/jsonschema-validator.js` - Validates generated schemas
- `melos validate-jsonschema` - Runs conformance tests

## Development Workflows

### Initial Setup

```bash
# Install Dart SDK (if not already installed)
dart --version

# Install Melos globally
dart pub global activate melos

# Bootstrap workspace
melos bootstrap
```

### Common Commands

```bash
# Run all tests
melos test

# Run specific package tests
melos test:dart          # Pure Dart packages
melos test:flutter       # Flutter packages
melos test:gen           # Generator tests only

# Code generation
melos build

# Format code
melos format

# Analyze code
melos analyze

# Clean build artifacts
melos clean
```

### Code Generation Workflow

For packages using `ack_generator`:

```bash
# Run build_runner
cd packages/ack_generator
dart run build_runner build --delete-conflicting-outputs

# Or from root
melos build
```

### Golden Test Updates

When generator output changes:

```bash
# Update specific golden test
melos update-golden

# Update all golden tests
melos update-golden:all
```

### API Compatibility Checking

Before releases, check API compatibility:

```bash
# Check against previous version
melos api-check v0.2.0
```

Uses `dart_apitool` to ensure semantic versioning compliance.

### JSON Schema Validation

Ensure generated JSON schemas are valid Draft-7:

```bash
# Install Node.js dependencies
melos validate-jsonschema:setup

# Run validation tests
melos validate-jsonschema

# Batch validation
melos validate-jsonschema:batch
```

## Testing Strategy

### Unit Tests

- **Location:** `packages/*/test/`
- **Run:** `melos test`
- **Coverage:** Use `melos test:dart` and `melos test:flutter` separately

### Golden Tests

- **Location:** `packages/ack_generator/test/golden/`
- **Purpose:** Ensure code generation output consistency
- **Update:** `melos update-golden:all`

### JSON Schema Conformance Tests

- **Location:** `packages/ack/test/json_schema_conformance_test.dart`
- **Purpose:** Validate JSON Schema Draft-7 compatibility
- **Run:** `melos validate-jsonschema`

### Integration Tests

- **Location:** `example/` directory
- **Purpose:** Real-world usage examples that serve as integration tests

## Common Patterns

### Defining Schemas

**Object with Required Fields:**
```dart
final schema = Ack.object({
  'name': Ack.string(),
  'age': Ack.integer(),
});
```

**Object with Optional Fields:**
```dart
final schema = Ack.object({
  'name': Ack.string(),
  'age': Ack.integer().optional(),
});
```

**Nested Objects:**
```dart
final schema = Ack.object({
  'user': Ack.object({
    'name': Ack.string(),
  }),
});
```

**Lists:**
```dart
final schema = Ack.list(Ack.string()).minLength(1);
```

**Unions:**
```dart
final schema = Ack.union([
  Ack.string(),
  Ack.integer(),
]);
```

### Using Generated Schemas

```dart
// Define model
@GenerateSchema()
class User {
  final String name;
  final int age;
}

// Use generated schema
final result = UserSchema().safeParse(data);
```

## Critical Files

### Core Library (`packages/ack/`)

- `lib/src/ack.dart` - Main entry point, factory methods
- `lib/src/schemas/string_schema.dart` - String validation
- `lib/src/schemas/object_schema.dart` - Object validation
- `lib/src/result.dart` - Result type implementation
- `test/json_schema_conformance_test.dart` - JSON Schema validation

### Code Generator (`packages/ack_generator/`)

- `lib/builder.dart` - build_runner integration
- `lib/src/generator.dart` - Code generation logic
- `tool/update_goldens.dart` - Golden test updater

### Firebase AI Integration (`packages/ack_firebase_ai/`)

- `lib/src/converter.dart` - Converts Ack schemas to Firebase AI format

### Development Tools

- `tools/jsonschema-validator.js` - Node.js JSON Schema validator
- `scripts/api_check.dart` - API compatibility checker
- `scripts/update_release_changelog.dart` - Release changelog generator

## Integration Points

### 1. build_runner Integration

Generator integrates with build_runner:

```yaml
dev_dependencies:
  build_runner: ^2.4.0
  ack_generator: ^0.x.x
```

Run: `dart run build_runner build`

### 2. Firebase AI Integration

Convert schemas for structured output:

```dart
import 'package:ack_firebase_ai/ack_firebase_ai.dart';

final firebaseSchema = userSchema.toFirebaseAISchema();
```

### 3. JSON Schema Export

Export schemas for validation in other systems:

```dart
final jsonSchema = userSchema.toJsonSchema();
```

## Performance Considerations

### Schema Reuse

**Do:** Reuse schema instances
```dart
final userSchema = Ack.object({...});
// Reuse userSchema for multiple validations
```

**Don't:** Recreate schemas on every validation
```dart
// Avoid this in hot paths
final result = Ack.object({...}).safeParse(data);
```

### Validation Overhead

- Schema validation is fast for simple types
- Complex nested objects and custom refinements add overhead
- Use `.optional()` judiciously - it adds a validation check

## Debugging Tips

### Validation Errors

Use `.safeParse()` to get detailed error information:

```dart
final result = schema.safeParse(data);
if (!result.isOk) {
  print('Validation error: ${result.getError()}');
  // Error includes path and message
}
```

### Code Generation Issues

1. Check generated files in `.dart_tool/build/`
2. Run `melos clean` then `melos build`
3. Check build_runner logs for errors
4. Verify annotations are correct

### Golden Test Failures

1. Review the diff in test output
2. Verify changes are intentional
3. Update golden files: `melos update-golden:all`

## Current State & Recent Changes

### Latest Version

Check `packages/*/pubspec.yaml` for current versions.

### Recent Commits

```
c417f85 chore: Update melos.yaml (#38)
9399af2 fix: preserve nullable metadata in firebase ai converter (#36)
4dfed86 Merge pull request #35 from btwld/chore/ci-pipeline
```

### Known Issues

- Check GitHub issues: https://github.com/btwld/ack/issues

### Roadmap

See GitHub milestones and project board for upcoming features.

## Versioning & Publishing

### Semantic Versioning

- **Patch (0.0.x):** Bug fixes, non-breaking changes
- **Minor (0.x.0):** New features, backwards compatible
- **Major (x.0.0):** Breaking changes

### Version Commands

```bash
melos version-patch   # Bump patch version
melos version-minor   # Bump minor version
melos version-major   # Bump major version
```

### Publishing

```bash
# Dry run (validation only)
melos publish-dry

# Publish to pub.dev
melos publish
```

See `PUBLISHING.md` for detailed release process.

## Code Quality & CI

### CI Pipeline

- **Location:** `.github/workflows/ci.yml`
- **Runs:** Tests, analysis, formatting checks
- **Triggers:** Pull requests and pushes to main

### Code Formatting

Uses standard Dart formatting:
```bash
melos format
```

### Static Analysis

```bash
melos analyze  # Uses --fatal-infos
```

### Conventional Commits

Required for all commits:
- `feat:` - New features
- `fix:` - Bug fixes
- `chore:` - Maintenance tasks
- `docs:` - Documentation changes
- `refactor:` - Code refactoring
- `test:` - Test changes

## Contributing

### Pull Request Workflow

1. Fork the repository
2. Create feature branch
3. Add changes
4. Run `melos test` to ensure tests pass
5. Run `melos analyze` to check for issues
6. Use conventional commits
7. Submit pull request

### Development Guidelines

- Follow Dart style guide
- Write tests for new features
- Update documentation
- Ensure CI passes
- Update golden tests if needed

## Getting Help

- **Documentation:** https://docs.page/btwld/ack
- **Issues:** https://github.com/btwld/ack/issues
- **Pub.dev:** https://pub.dev/packages/ack

---

**Remember:** This is a schema validation library. The core principle is to make data validation simple, type-safe, and maintainable.
