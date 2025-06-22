# ACK Generator

Code generator for the ACK (Another Constraint Kit) validation library. This package automatically generates schema classes from Dart model classes annotated with `@AckModel()`.

## Overview

The ACK Generator transforms your Dart model classes into powerful schema validation classes that can:

- Validate data against defined constraints
- Parse and type-check input data
- Generate OpenAPI specifications
- Provide type-safe access to validated data

## Installation

Add `ack_generator` as a dev dependency in your `pubspec.yaml`:

```yaml
dev_dependencies:
  ack_generator: ^1.0.0
  build_runner: ^2.4.0
```

## Usage

### 1. Annotate Your Models

```dart
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
class User {
  final String id;
  final String name;
  final String email;
  final int? age;
  
  User({
    required this.id,
    required this.name,
    required this.email,
    this.age,
  });
}
```

### 2. Run Code Generation

```bash
dart run build_runner build
```

### 3. Use Generated Schema

```dart
import 'user.ack.g.part';

void main() {
  const userSchema = UserSchema();
  
  // Parse and validate data
  final user = userSchema.parse({
    'id': '123',
    'name': 'John Doe',
    'email': 'john@example.com',
    'age': 30,
  });
  
  // Access validated data
  print(user.name); // John Doe
  print(user.email); // john@example.com
}
```

## Generated Code Structure

For each `@AckModel()` annotated class, the generator creates:

- **Schema class** extending `SchemaModel`
- **Validation definition** with field constraints
- **Type-safe getters** for accessing validated data
- **Parse methods** for data validation
- **OpenAPI integration** support

## Development

### Running Tests

```bash
# Run all tests
dart test

# Run only golden tests
dart test --tags=golden

# Run tests in watch mode
dart test --watch
```

### Golden Test Management

Golden tests ensure the generator produces consistent output. Use these tools to manage golden test files:

#### Update Golden Files

When you modify the generator and need to update the expected output:

```bash
# Update all golden files
dart tool/update_goldens.dart --all

# Update specific golden file
dart tool/update_goldens.dart user_schema

# Using melos (from project root)
melos update-golden:all
```

#### View Generator Output

To see what the generator produces without updating files:

```bash
# Show generator output for user schema
dart tool/show_generator_output.dart user_schema

# Show generator output for order schema
dart tool/show_generator_output.dart order_schema
```

#### Golden Test Workflow

1. **Make changes** to the generator code
2. **Run tests** to see failures: `dart test test/golden_test.dart`
3. **Update golden files**: `dart tool/update_goldens.dart --all`
4. **Verify tests pass**: `dart test test/golden_test.dart`
5. **Review changes** in the golden files
6. **Commit updated golden files**

#### Available Melos Commands

From the project root, you can use these melos commands:

```bash
# Golden test management
melos test:golden                 # Run golden tests
melos update-golden:all           # Update all golden files
melos update-golden               # Interactive golden file update
```

### Test Structure

- **`test/integration/`** - End-to-end generator tests
- **`test/src/`** - Unit tests for generator components
- **`test/golden/`** - Golden test reference files
- **`test/test_utils/`** - Shared test utilities

### Architecture

The generator consists of several key components:

- **`AckSchemaGenerator`** - Main build_runner generator
- **`ModelAnalyzer`** - Analyzes Dart model classes
- **`FieldAnalyzer`** - Processes individual fields and constraints
- **`SchemaBuilder`** - Generates schema class code
- **`FieldBuilder`** - Generates field-specific validation code

## Contributing

1. **Fork the repository**
2. **Create a feature branch**
3. **Make your changes**
4. **Add/update tests** (including golden tests if needed)
5. **Run the test suite**: `dart test`
6. **Update golden files** if generator output changed
7. **Submit a pull request**

### Code Style

- Follow Dart style guidelines
- Add documentation for public APIs
- Include tests for new functionality
- Update golden tests when changing generator output

## License

This project is licensed under the MIT License - see the LICENSE file for details.
