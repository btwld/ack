# Ack - Schema Validation Library Architecture & Context

> **Last Updated:** 2025-11-05
> **Version:** 1.0.0-beta.3
> **Status:** Active Development (Beta)
> **Repository:** https://github.com/btwld/ack

## Executive Summary

Ack is a type-safe schema validation library for Dart and Flutter, inspired by Zod (TypeScript). It provides a fluent API for building complex validation schemas with excellent error messages and strong type inference. The project is structured as a monorepo with 4 publishable packages managed by Melos, supporting both pure Dart and Flutter environments.

**Tech Stack:**
- **Language:** Dart >= 3.8.0, Flutter 3.32.4 (FVM)
- **Monorepo Manager:** Melos 3.4.0
- **Code Generation:** build_runner + source_gen
- **Testing:** Dart test + golden tests
- **CI/CD:** GitHub Actions (custom reusable workflow)

## Project Structure

```
ack/
├── packages/                          # Core publishable packages
│   ├── ack/                          # Core validation library (1.0.0-beta.3)
│   │   ├── lib/src/schemas/          # Schema implementations (string, object, list, etc.)
│   │   ├── lib/src/errors/           # Error handling & messages
│   │   └── lib/src/types/            # Core types (Validator, ParseResult, etc.)
│   ├── ack_annotations/              # Annotations for code generation (1.0.0-beta.3)
│   │   └── lib/src/                  # @AckModel, @AckField annotations
│   ├── ack_generator/                # Code generator (1.0.0-beta.3)
│   │   ├── lib/src/                  # Generator logic, visitors
│   │   └── test/golden/              # Golden test files
│   └── ack_firebase_ai/              # Firebase AI/Gemini converter (1.0.0-beta.3)
│       └── lib/                      # Schema → Firebase AI Schema conversion
├── example/                          # Example project (1.0.0-beta.1)
├── tools/                            # Node.js JSON Schema validators
│   ├── jsonschema-validator.js       # Draft-7 validator
│   └── generate_reference_fixtures.js
├── scripts/                          # Utility scripts
│   ├── api_check.dart               # API compatibility checker
│   └── update_release_changelog.dart # Changelog generator
├── docs/                             # MDX documentation site
│   ├── getting-started/
│   ├── core-concepts/
│   ├── api-reference/
│   └── guides/
├── .github/workflows/                # CI/CD pipelines
├── melos.yaml                        # Monorepo configuration (163 lines)
├── pubspec.yaml                      # Root workspace package
├── .fvmrc                           # Flutter version pin (3.32.4)
└── setup.sh                         # Initial environment setup
```

## Key Architectural Patterns

### 1. Fluent Schema Builder API

**Location:** `packages/ack/lib/src/schemas/`

Ack provides a chainable API for building validation schemas:

```dart
// Example: User schema with nested validation
final userSchema = AckObject({
  'name': AckString().min(1).max(100),
  'email': AckString().email(),
  'age': AckNumber().int().positive(),
  'role': AckEnum(['admin', 'user', 'guest']),
}).strict();

// Usage
final result = userSchema.parse({'name': 'John', 'email': 'john@example.com'});
if (result.isSuccess) {
  print(result.value); // Type-safe parsed data
} else {
  print(result.error); // Detailed error messages
}
```

**Key Files:**
- `ack_string.dart` - String validation with regex, email, URL, UUID support
- `ack_object.dart` - Object/map validation with strict/partial modes
- `ack_list.dart` - Array validation with length constraints
- `ack_number.dart` - Numeric validation (int, double, ranges)
- `ack_boolean.dart` - Boolean validation
- `ack_enum.dart` - Enum validation
- `ack_union.dart` - Union type validation
- `ack_optional.dart` - Optional/nullable handling

### 2. Code Generation Workflow

**Location:** `packages/ack_generator/lib/src/`

Ack generates type-safe validation code from annotated classes:

```dart
// Input: Annotated class
@AckModel()
class User {
  final String name;
  final String email;

  @AckField(validators: [AckValidators.min(0)])
  final int age;

  User({required this.name, required this.email, required this.age});
}

// Generated: user.ack.dart
final userSchema = AckObject({
  'name': AckString(),
  'email': AckString(),
  'age': AckNumber().int().min(0),
});
```

**Generator Process:**
1. Analyzer scans for `@AckModel` annotations
2. `AckModelGenerator` extracts class metadata
3. `SchemaGenerator` builds schema AST
4. `code_builder` emits Dart code
5. Golden tests verify output consistency

**Key Files:**
- `ack_model_generator.dart` - Main generator entry point
- `schema_generator.dart` - Schema AST builder
- `validators/` - Validation logic extractors
- `test/golden/` - Golden test fixtures

### 3. Discriminated Types (Polymorphic Validation)

**Location:** `packages/ack/lib/src/schemas/ack_discriminated.dart`

Handle polymorphic data with type discriminators:

```dart
final shapeSchema = AckDiscriminated(
  discriminator: 'type',
  schemas: {
    'circle': AckObject({'type': AckLiteral('circle'), 'radius': AckNumber()}),
    'rectangle': AckObject({'type': AckLiteral('rectangle'), 'width': AckNumber(), 'height': AckNumber()}),
  },
);

// Validates and parses based on 'type' field
final result = shapeSchema.parse({'type': 'circle', 'radius': 5.0});
```

**Use Cases:**
- API response handling with multiple response types
- Event system with different event payloads
- Redux-like action patterns

### 4. Schema Converters

**Location:** `packages/ack/lib/src/converters/`

Convert Ack schemas to external formats:

- **JSON Schema (Draft-7):** `ack_to_json_schema.dart`
  - Full Draft-7 compliance validated by `tools/jsonschema-validator.js`
  - Supports `$ref`, nested schemas, format validators
- **Firebase AI/Gemini:** `packages/ack_firebase_ai/` (separate package)
  - Converts to Firebase AI's schema format
  - Maintains semantic equivalence

**Example:**
```dart
final schema = AckString().min(1).max(100);
final jsonSchema = ackToJsonSchema(schema);
// Output: {"type": "string", "minLength": 1, "maxLength": 100}
```

## Technology Stack

### Dart/Flutter
- **Dart SDK:** >= 3.8.0, < 4.0.0
- **Flutter SDK:** 3.32.4 (FVM-managed)
- **Package Manager:** pub + Melos

### Build & Code Generation
- **build_runner:** 2.4.0 - Code generation orchestrator
- **source_gen:** 2.0.0 - Dart code generation framework
- **code_builder:** 4.10.0 - Code AST builder
- **analyzer:** ^7.0.0 - Dart static analysis

### Testing
- **test:** ^1.24.0 - Unit testing
- **build_test:** ^3.1.0 - Generator testing
- **coverage:** ^1.11.1 - Code coverage
- Golden tests for generator output verification

### Linting & Quality
- **lints:** ^5.0.0 - Dart lints (packages/ack)
- **very_good_analysis:** ^6.0.0 - Stricter lints (generator, annotations)
- **DCM:** Code metrics (CI/CD)

### Tooling
- **Melos:** 3.4.0 - Monorepo management
- **FVM:** Flutter version management
- **Node.js Tools:**
  - **ajv:** 8.12.0 - JSON Schema validator
  - **commander:** 11.1.0 - CLI framework

## Development Workflows

### Setup

```bash
# Initial setup (already exists as setup.sh)
./setup.sh

# Or manually:
dart pub global activate melos
fvm install
fvm use --force
melos bootstrap
```

### Common Tasks

| Task | Command | Description |
|------|---------|-------------|
| **Install dependencies** | `melos bootstrap` | Bootstrap all packages |
| **Run tests** | `melos test` | Run all Dart + Flutter tests |
| **Format code** | `melos format` | Format with dart format |
| **Lint** | `melos analyze` | Run analyzer on all packages |
| **Generate code** | `melos build` | Run build_runner |
| **Clean** | `melos clean` | Clean build artifacts |
| **Check outdated deps** | `melos deps-outdated` | List outdated dependencies |

### Code Generation

```bash
# Generate schemas from annotations
melos build

# Watch mode for generator development
melos test:gen:watch

# Update golden test files
melos update-golden:all
```

### Validation & Testing

```bash
# JSON Schema conformance tests
melos validate-jsonschema
melos validate-jsonschema:batch

# API compatibility check (semantic versioning)
melos api-check v0.2.0
```

### Versioning & Publishing

```bash
# Version bumps
melos version-patch   # 1.0.0 → 1.0.1
melos version-minor   # 1.0.0 → 1.1.0
melos version-major   # 1.0.0 → 2.0.0

# Publish (dry-run first!)
melos publish-dry
melos publish

# Combined version + publish
melos release
```

See `PUBLISHING.md` for detailed release process.

## Critical Files & Conventions

| File | Purpose | Change Frequency |
|------|---------|------------------|
| `melos.yaml` | Monorepo config, scripts | Low |
| `packages/ack/lib/ack.dart` | Public API exports | Medium |
| `packages/ack_generator/lib/src/ack_model_generator.dart` | Generator logic | Low |
| `PUBLISHING.md` | Release process | Very Low |
| `docs/` | Documentation site | Medium |
| `.github/workflows/ci.yml` | CI pipeline | Low |
| `.fvmrc` | Flutter version pin | Very Low |

### Conventions

1. **Package Naming:** All packages prefixed with `ack_` (except core `ack`)
2. **Versioning:** Semantic versioning, synchronized across packages
3. **Testing:** Golden tests for generator, unit tests for schemas
4. **Documentation:** Inline dartdoc + MDX docs in `/docs`
5. **Linting:** Strict lints enabled, very_good_analysis for generator/annotations
6. **Exports:** Barrel exports via `lib/<package_name>.dart`

## Current State

### Recent Changes (as of beta.3)

- **v1.0.0-beta.3** (latest):
  - Enhanced nullable metadata preservation in Firebase AI converter
  - CI pipeline improvements
  - Melos configuration updates

- **v1.0.0-beta.2:**
  - Introduced Firebase AI schema converter
  - Discriminated type support
  - JSON Schema Draft-7 compliance

- **v1.0.0-beta.1:**
  - Initial public beta
  - Core validation schemas
  - Code generator foundation

### Known Issues

- Beta status: API may change before 1.0.0 stable
- Breaking changes possible in subsequent beta releases
- See GitHub Issues: https://github.com/btwld/ack/issues

### Active Development Areas

1. **Stabilizing API:** Moving towards 1.0.0 stable release
2. **Documentation:** Expanding guides and examples
3. **Schema Converters:** Supporting more external formats
4. **Performance:** Optimizing validation speed for large datasets
5. **Flutter Integration:** Better form validation patterns

## Code Standards

### Dart Style

- Follow official Dart style guide
- Use `dart format` (enforced by CI)
- Max line length: 80 characters
- Prefer `final` over `var`

### Testing Requirements

- Unit tests for all public APIs
- Golden tests for generator output
- JSON Schema conformance tests
- Minimum 80% code coverage (ack core package)

### Quality Gates (CI)

1. All tests must pass (Dart + Flutter)
2. Zero analyzer warnings/errors
3. Code formatted correctly
4. DCM metrics within thresholds
5. API compatibility check (for releases)

### Documentation

- Dartdoc comments for all public APIs
- Include examples in doc comments
- Update `/docs` for new features
- Keep README.md in sync with capabilities

## Testing Strategy

### Unit Tests

**Location:** `packages/*/test/`

```bash
# Run all tests
melos test

# Run specific package tests
cd packages/ack && dart test
```

**Coverage:**
- Core schemas: ~90% coverage
- Generator: Golden tests + unit tests
- Annotations: Minimal (mostly interfaces)

### Golden Tests

**Location:** `packages/ack_generator/test/golden/`

Generator output is validated against golden files:

```bash
# Update golden files after generator changes
melos update-golden:all
```

### JSON Schema Conformance

**Location:** `tools/jsonschema-validator.js`

Validates Ack's JSON Schema output against Draft-7 spec:

```bash
melos validate-jsonschema
```

### Integration Tests

**Location:** `example/`

Example project serves as integration test, verifying:
- Code generation workflow
- Schema usage patterns
- Build integration

## Common Pitfalls

### 1. Generator Development

**Issue:** Forgetting to update golden tests after generator changes
**Solution:** Always run `melos update-golden:all` after modifying generator

### 2. Melos Bootstrap

**Issue:** Missing dependencies or version conflicts
**Solution:** Run `melos clean && melos bootstrap` to reset workspace

### 3. FVM Not Used

**Issue:** Using system Flutter instead of FVM-managed version
**Solution:** Ensure `fvm` is in PATH and use `fvm flutter` commands

### 4. JSON Schema Validation Fails

**Issue:** Ack schema doesn't convert correctly to JSON Schema
**Solution:** Check `tools/jsonschema-validator.js` output for specific errors

### 5. Circular Dependencies

**Issue:** Cross-package imports causing build failures
**Solution:** Use `melos.yaml` dependency overrides, ensure proper package boundaries

### 6. Breaking Changes in Beta

**Issue:** API changes between beta versions
**Solution:** Pin exact versions in pubspec.yaml until stable release

## Resources

### Documentation

- **Getting Started:** `/docs/getting-started/`
- **Core Concepts:** `/docs/core-concepts/`
- **API Reference:** `/docs/api-reference/`
- **Guides:** `/docs/guides/`
- **Publishing Guide:** `PUBLISHING.md`

### Repository

- **GitHub:** https://github.com/btwld/ack
- **Issues:** https://github.com/btwld/ack/issues
- **CI/CD:** Uses `btwld/dart-actions` reusable workflow

### External

- **Pub.dev:** https://pub.dev/packages/ack
- **Zod (Inspiration):** https://zod.dev
- **JSON Schema Draft-7:** https://json-schema.org/draft-07/schema

## Package Dependencies

### Internal Dependencies

```
ack (core)
├── No internal dependencies
└── Depended on by: ack_generator, ack_firebase_ai, example

ack_annotations
├── No internal dependencies
└── Depended on by: ack_generator, example

ack_generator
├── ack
├── ack_annotations
└── Depended on by: example (dev)

ack_firebase_ai
└── ack
```

### Key External Dependencies

**ack:**
- `meta: ^1.15.0` - Metadata annotations

**ack_generator:**
- `analyzer: ^7.0.0` - Static analysis
- `build: ^2.4.0` - Build system
- `source_gen: ^2.0.0` - Code generation
- `code_builder: ^4.10.0` - Code AST
- `collection: ^1.18.0` - Collections utilities
- `path: ^1.9.0` - Path manipulation
- `dart_style: ^3.1.0` - Code formatting

**ack_firebase_ai:**
- `firebase_ai: >=3.4.0 <5.0.0` - Firebase AI SDK
- `flutter` - Flutter SDK

## CI/CD Pipeline

### Workflow: `.github/workflows/ci.yml`

Uses reusable workflow from `btwld/dart-actions`:

```yaml
jobs:
  dart-ci:
    uses: btwld/dart-actions/.github/workflows/ci.yml@main
```

**Steps:**
1. Checkout code
2. Setup Dart/Flutter
3. Install dependencies (`melos bootstrap`)
4. Run analyzer (`melos analyze`)
5. Format check (`melos format`)
6. Run tests (`melos test`)
7. DCM code metrics
8. Coverage reporting

**Triggers:**
- Push to `main`
- Pull requests

### Release Workflow: `.github/workflows/release.yml`

Automates GitHub release creation and changelog updates.

**Triggers:**
- Manual (workflow_dispatch)
- Push tags matching version pattern

### Documentation Workflow: `.github/workflows/docs.yml`

Deploys MDX documentation to hosting platform.

---

## Quick Reference

### Project Identity
- **Name:** Ack
- **Purpose:** Type-safe schema validation for Dart/Flutter
- **Inspiration:** Zod (TypeScript)
- **Status:** Beta (1.0.0-beta.3)

### Primary Commands
```bash
melos bootstrap    # Setup
melos test         # Test
melos build        # Generate
melos analyze      # Lint
melos format       # Format
melos clean        # Clean
```

### Key Directories
- `packages/ack/` - Core library
- `packages/ack_generator/` - Code generator
- `docs/` - Documentation
- `tools/` - JSON Schema validators

### Important Files
- `melos.yaml` - Monorepo config
- `.fvmrc` - Flutter version
- `PUBLISHING.md` - Release process

### External Resources
- GitHub: btwld/ack
- Docs: /docs
- Pub.dev: pub.dev/packages/ack
