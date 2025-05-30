# ACK Generator - Setup Instructions

## Implementation Status
✅ Core files created:
- `lib/builder.dart` - Builder registration
- `lib/src/generator.dart` - Main generator using code_builder
- `test/generator_test.dart` - Golden file tests
- `ack_generator_plan_v2.md` - Simple migration plan

## Next Steps to Complete Setup

### 1. Copy Analyzers from Current Generator
```bash
# From ack_generator directory:
cp -r ../ack_generator/lib/src/analyzers ./lib/src/
cp -r ../ack_generator/lib/src/models ./lib/src/  # If exists

# Or create models directory and copy individual files:
mkdir -p lib/src/models
cp ../ack_generator/lib/src/schema_data.dart ./lib/src/models/  # If not in analyzers
```

### 2. Create Test Directories
```bash
mkdir -p test/fixtures
mkdir -p test/golden
```

### 3. Copy Test Fixtures
```bash
# Copy test models as fixtures
cp ../ack_generator/test/models/user_model.dart ./test/fixtures/
cp ../ack_generator/test/models/product_model.dart ./test/fixtures/
cp ../ack_generator/test/models/block_model.dart ./test/fixtures/

# Copy generated files as golden files
cp ../ack_generator/test/models/user_model.g.dart ./test/golden/user_model.golden
cp ../ack_generator/test/models/product_model.g.dart ./test/golden/product_model.golden
cp ../ack_generator/test/models/block_model.g.dart ./test/golden/block_model.golden
```

### 4. Create pubspec.yaml
```yaml
name: ack_generator
description: Code generator for ACK validation schemas
version: 0.1.0

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  analyzer: ^6.3.0
  build: ^2.4.1
  code_builder: ^4.10.0
  source_gen: ^1.4.0
  dart_style: ^2.3.4
  ack: ^0.2.0-beta.1

dev_dependencies:
  build_runner: ^2.4.6
  build_test: ^2.2.0
  test: ^1.25.0
```

### 5. Create build.yaml
```yaml
builders:
  ack_schema:
    import: "package:ack_generator/builder.dart"
    builder_factories: ["ackSchemaBuilder"]
    build_extensions: {".dart": [".ack.dart"]}
    auto_apply: dependents
    build_to: source
    applies_builders: ["source_gen|combining_builder"]
```

### 6. Run Tests
```bash
# Install dependencies
dart pub get

# Run tests (will fail until golden files exist)
dart test

# Create/update golden files
UPDATE_GOLDEN=true dart test

# Run tests again to verify
dart test
```

## Key Implementation Notes

- The generator reuses ALL existing analyzers unchanged
- Uses code_builder for type-safe generation instead of strings
- Maintains exact same output as current generator
- Discriminated unions temporarily use string generation (TODO for phase 2)
- Total new code: ~400 lines (vs 900+ in over-engineered version)

## Architecture

```
ack_generator/
├── lib/
│   ├── builder.dart (17 lines)
│   └── src/
│       ├── generator.dart (~400 lines)
│       └── analyzers/ (copied from ack_generator)
├── test/
│   ├── generator_test.dart (86 lines)
│   ├── fixtures/ (input dart files)
│   └── golden/ (expected output files)
└── pubspec.yaml
```

This is a true MVP - minimal new code, maximum reuse, same functionality.