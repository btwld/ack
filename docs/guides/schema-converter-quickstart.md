# Schema Converter Package - Quick Start Template

**Use this for rapid prototyping of new schema converter packages**

## 1️⃣ Create Package (2 minutes)

```bash
cd packages/
mkdir ack_<target> && cd ack_<target>

# Create structure
mkdir -p lib test example docs
touch lib/ack_<target>.dart
touch test/to_<target>_schema_test.dart
touch example/basic_usage.dart
touch {README,CHANGELOG}.md
touch pubspec.yaml
touch analysis_options.yaml
touch .pubignore
```

## 2️⃣ Configure pubspec.yaml (3 minutes)

```yaml
name: ack_<target>
description: <Target> schema converter for ACK validation library
version: 1.0.0-beta.1
repository: https://github.com/btwld/ack

environment:
  sdk: '>=3.8.0 <4.0.0'
  # flutter: '>=3.16.0'  # Uncomment if needed

dependencies:
  ack: ^1.0.0
  # <target_sdk>: ^x.y.z  # Add if needed
  meta: ^1.15.0

dev_dependencies:
  test: ^1.24.0
  lints: ^5.0.0
```

## 3️⃣ Single Library File (15 minutes)

**`lib/ack_<target>.dart`** - All code in one file:

```dart
/// <Target> schema converter for ACK validation library.
///
/// Converts ACK validation schemas to <Target> format for [use case].
///
/// ## Usage
///
/// ```dart
/// import 'package:ack/ack.dart';
/// import 'package:ack_<target>/ack_<target>.dart';
///
/// final schema = Ack.object({
///   'name': Ack.string().minLength(2),
///   'age': Ack.integer().min(0).optional(),
/// });
///
/// // Convert to <Target> format
/// final targetSchema = schema.to<Target>Schema();
/// ```
///
/// ## Limitations
///
/// Some ACK features cannot be converted to <Target> format:
/// - Custom refinements (`.refine()`) - validate after
/// - [Other limitations specific to target system...]
library;

import 'package:ack/ack.dart';
// Import target SDK if needed
// import 'package:<target_sdk>/<target_sdk>.dart' as target;

// ============================================================================
// Public Extension API
// ============================================================================

/// Extension methods for converting ACK schemas to <Target> format.
extension <Target>SchemaExtension on AckSchema {
  /// Converts this ACK schema to <Target> format.
  ///
  /// Returns a [<TargetType>] instance for use with [target system].
  ///
  /// ## Example
  ///
  /// ```dart
  /// final schema = Ack.object({
  ///   'name': Ack.string().minLength(2),
  ///   'age': Ack.integer().min(0).optional(),
  /// });
  ///
  /// final targetSchema = schema.to<Target>Schema();
  /// ```
  <TargetType> to<Target>Schema() {
    return _convert(this);
  }
}

// ============================================================================
// Converter Implementation
// ============================================================================

<TargetType> _convert(AckSchema schema) {
  final json = schema.toJsonSchema();

  return switch (schema) {
    StringSchema() => _convertString(schema, json),
    IntegerSchema() => _convertInteger(schema, json),
    DoubleSchema() => _convertDouble(schema, json),
    BooleanSchema() => _convertBoolean(schema, json),
    ObjectSchema() => _convertObject(schema, json),
    ListSchema() => _convertArray(schema, json),
    EnumSchema() => _convertEnum(schema, json),
    AnyOfSchema() => _convertAnyOf(schema),
    _ => throw UnsupportedError(
        'Schema type ${schema.runtimeType} not supported for <Target> conversion.',
      ),
  };
}

// TODO: Implement converters
<TargetType> _convertString(StringSchema s, Map<String, Object?> j) {
  throw UnimplementedError('Implement _convertString');
}

<TargetType> _convertInteger(IntegerSchema s, Map<String, Object?> j) {
  throw UnimplementedError('Implement _convertInteger');
}

<TargetType> _convertDouble(DoubleSchema s, Map<String, Object?> j) {
  throw UnimplementedError('Implement _convertDouble');
}

<TargetType> _convertBoolean(BooleanSchema s, Map<String, Object?> j) {
  throw UnimplementedError('Implement _convertBoolean');
}

<TargetType> _convertObject(ObjectSchema s, Map<String, Object?> j) {
  throw UnimplementedError('Implement _convertObject');
}

<TargetType> _convertArray(ListSchema s, Map<String, Object?> j) {
  throw UnimplementedError('Implement _convertArray');
}

<TargetType> _convertEnum(EnumSchema s, Map<String, Object?> j) {
  throw UnimplementedError('Implement _convertEnum');
}

<TargetType> _convertAnyOf(AnyOfSchema s) {
  throw UnimplementedError('Implement _convertAnyOf');
}

// Helpers
int? _asInt(Object? v) => v is int ? v : (v is double ? v.toInt() : null);
double? _asDouble(Object? v) => v is double ? v : (v is int ? v.toDouble() : null);
```

## 4️⃣ Basic Tests (15 minutes)

**`test/to_<target>_schema_test.dart`**:

```dart
import 'package:ack/ack.dart';
import 'package:ack_<target>/ack_<target>.dart';
import 'package:test/test.dart';

void main() {
  group('to<Target>Schema()', () {
    test('converts string schema', () {
      final schema = Ack.string();
      final result = schema.to<Target>Schema();

      expect(result, isNotNull);
      // Add specific assertions
    });

    test('converts integer schema', () {
      final schema = Ack.integer();
      final result = schema.to<Target>Schema();

      expect(result, isNotNull);
    });

    test('converts object schema', () {
      final schema = Ack.object({
        'name': Ack.string(),
        'age': Ack.integer(),
      });
      final result = schema.to<Target>Schema();

      expect(result, isNotNull);
    });

    test('converts array schema', () {
      final schema = Ack.list(Ack.string());
      final result = schema.to<Target>Schema();

      expect(result, isNotNull);
    });
  });
}
```

## 5️⃣ Example Usage (5 minutes)

**`example/basic_usage.dart`**:

```dart
import 'package:ack/ack.dart';
import 'package:ack_<target>/ack_<target>.dart';

void main() {
  // Define schema
  final schema = Ack.object({
    'name': Ack.string().minLength(2),
    'email': Ack.string().email(),
    'age': Ack.integer().min(0).optional(),
  });

  // Convert
  final targetSchema = schema.to<Target>Schema();

  print('Converted: $targetSchema');
}
```

## 6️⃣ README (10 minutes)

**`README.md`**:

```markdown
# ack_<target>

<Target> schema converter for ACK.

## Installation

\`\`\`yaml
dependencies:
  ack: ^1.0.0
  ack_<target>: ^1.0.0
\`\`\`

## Usage

\`\`\`dart
import 'package:ack/ack.dart';
import 'package:ack_<target>/ack_<target>.dart';

final schema = Ack.object({
  'name': Ack.string(),
});

final targetSchema = schema.to<Target>Schema();
\`\`\`

## Limitations

- [List limitations]

## License

Part of the [ACK](https://github.com/btwld/ack) monorepo.
```

## 7️⃣ Verify Setup (2 minutes)

```bash
# Get dependencies
dart pub get

# Run tests
dart test

# Analyze
dart analyze

# Format
dart format .
```

---

## Next Steps

1. **Implement converters** - Fill in `UnimplementedError()` methods
2. **Add comprehensive tests** - Cover all ACK schema types
3. **Document limitations** - Update README with specific constraints
4. **Add examples** - Real-world usage patterns
5. **Publish** - Once tests pass and docs are complete

## Total Time Estimate

- **Setup**: 35 minutes (simplified single-file structure)
- **Implementation**: 2-4 hours
- **Testing**: 2-3 hours
- **Documentation**: 1-2 hours
- **Total**: 5-10 hours for complete package

## Reference

See [Creating Schema Converter Packages](./creating-schema-converter-packages.md) for detailed guidance.
