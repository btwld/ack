# ACK Generator

**⚠️ EXPERIMENTAL PACKAGE - UNDER DEVELOPMENT**

Code generator for the ACK validation library. This package is currently experimental and under active development.

## Current Status

This package is being developed to generate schema validation code from annotated Dart models. The implementation is not yet complete and the API may change significantly.

**Current limitations:**
- SchemaModel base class is not yet implemented in the main ack package
- Generated code may not compile with current ack version
- API is subject to breaking changes

## Planned Features

The ACK Generator is planned to transform your Dart model classes into schema validation classes that can:

- Validate data against defined constraints
- Parse and type-check input data
- Generate JSON Schema specifications
- Provide type-safe access to validated data

## Alternative: Manual Schema Definition

For production use, we recommend using manual schema definition with the current ack package:

```dart
import 'package:ack/ack.dart';

// Define schemas manually using the fluent API
final userSchema = Ack.object({
  'id': Ack.string().uuid(),
  'name': Ack.string().minLength(1),
  'email': Ack.string().email(),
  'age': Ack.integer().min(0).optional(),
});

// Validate data
final result = userSchema.validate(userData);
if (result.isOk) {
  final validData = result.getOrThrow();
  // Use validated data
}
```

## Development Status

This package contains experimental code generation functionality. The current implementation includes:

- Annotation definitions (`@AckModel`, constraint annotations)
- Code generation infrastructure
- Golden test framework for testing generated output

However, the generated code depends on a `SchemaModel` base class that is not yet implemented in the main ack package.

## For Contributors

If you're interested in contributing to the code generation functionality:

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

Golden tests ensure the generator produces consistent output:

```bash
# Update all golden files
UPDATE_GOLDEN=true dart test test/golden_test.dart

# View current generator output
dart test test/golden_test.dart
```

### Test Structure

- **`test/golden/`** - Golden test reference files (expected generator output)
- **`test/test_utils/`** - Shared test utilities and mock classes
- **`test/golden_test.dart`** - Main golden test file

### Architecture

The generator includes these components:

- **`AckSchemaGenerator`** - Main build_runner generator (experimental)
- **Annotation definitions** - `@AckModel` and constraint annotations
- **Golden test framework** - For testing generated output consistency

## Roadmap

To complete this package, the following work is needed:

1. **Implement SchemaModel base class** in the main ack package
2. **Complete code generation logic** for schema classes
3. **Add proper integration** with the current AckSchema architecture
4. **Update generated code** to work with current ack APIs
5. **Add comprehensive documentation** and examples

## Contributing

Contributions are welcome! If you're interested in helping complete the code generation functionality:

1. **Check existing issues** for planned work
2. **Discuss major changes** in issues before implementing
3. **Follow existing code patterns** and test structure
4. **Update golden tests** when changing generator output
5. **Test with the main ack package** to ensure compatibility

## License

This project is licensed under the MIT License - see the LICENSE file for details.
