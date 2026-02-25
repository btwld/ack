# Schema Converter Package - Quick Start Template

**Use this for rapid prototyping of new schema converter packages**

This guide is a scaffold for converter authors. The generated converter examples
use `Map<String, Object?>` as a stable intermediate representation to keep this
template runnable without binding to any one target schema SDK.
If your target SDK uses native schema objects, replace each map construction with
the corresponding SDK builders.

## 1. Create Package (2 minutes)

```bash
cd packages/
mkdir ack_<target> && cd ack_<target>

# Create structure
mkdir -p lib/src test example docs
touch lib/ack_<target>.dart
touch lib/src/{converter,extension}.dart
touch test/to_<target>_schema_test.dart
touch example/basic_usage.dart
touch {README,CHANGELOG}.md
touch pubspec.yaml
touch analysis_options.yaml
touch .pubignore
```

## 2. Configure pubspec.yaml (3 minutes)

```yaml
name: ack_<target>
description: <Target> schema converter for Ack validation library
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

## 3. Main Library File (5 minutes)

**`lib/ack_<target>.dart`**:

```dart
/// <Target> schema converter for Ack validation library.
library;

import 'package:ack/ack.dart';

export 'src/extension.dart';
```

## 4. Extension Method (3 minutes)

**`lib/src/extension.dart`**:

```dart
import 'package:ack/ack.dart';
import 'converter.dart';

extension <Target>SchemaExtension on AckSchema {
  /// Converts this Ack schema to <Target> format.
  ///
  /// In this template, this returns a map representation so the example stays
  /// self-consistent across targets.
  Map<String, Object?> to<Target>Schema() {
    return <Target>SchemaConverter.convert(this);
  }
}
```

## 5. Converter Skeleton (10 minutes)

**`lib/src/converter.dart`**:

```dart
import 'package:ack/ack.dart';

class <Target>SchemaConverter {
  const <Target>SchemaConverter._();

  /// Returns a map-based representation to avoid binding this template to one
  /// specific SDK type. Replace these map shapes with your target SDK schema types.
  static Map<String, Object?> convert(AckSchema schema) {
    return _convertSchema(schema);
  }

  static Map<String, Object?> _convertSchema(AckSchema schema) {
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
          'Schema type ${schema.runtimeType} not supported',
        ),
    };
  }

  static Map<String, Object?> _convertString(StringSchema s, Map<String, Object?> j) {
    return <String, Object?>{
      'type': 'string',
      if (j['description'] is String) 'description': j['description'],
      if (s.isNullable) 'nullable': true,
      if (_asInt(j['minLength']) != null) 'minLength': _asInt(j['minLength']),
      if (_asInt(j['maxLength']) != null) 'maxLength': _asInt(j['maxLength']),
      if (j['pattern'] is String && (j['pattern'] as String).isNotEmpty)
        'pattern': j['pattern'],
      if (j['format'] is String) 'format': j['format'],
    };
  }

  static Map<String, Object?> _convertInteger(IntegerSchema s, Map<String, Object?> j) {
    return <String, Object?>{
      'type': 'integer',
      if (j['description'] is String) 'description': j['description'],
      if (s.isNullable) 'nullable': true,
      if (_asInt(j['minimum']) != null) 'minimum': _asInt(j['minimum']),
      if (_asInt(j['maximum']) != null) 'maximum': _asInt(j['maximum']),
      if (j['exclusiveMinimum'] is bool)
        'exclusiveMinimum': j['exclusiveMinimum'],
      if (j['exclusiveMaximum'] is bool)
        'exclusiveMaximum': j['exclusiveMaximum'],
    };
  }

  static Map<String, Object?> _convertDouble(DoubleSchema s, Map<String, Object?> j) {
    return <String, Object?>{
      'type': 'number',
      if (j['description'] is String) 'description': j['description'],
      if (s.isNullable) 'nullable': true,
      if (_asDouble(j['minimum']) != null) 'minimum': _asDouble(j['minimum']),
      if (_asDouble(j['maximum']) != null) 'maximum': _asDouble(j['maximum']),
      if (j['exclusiveMinimum'] is bool)
        'exclusiveMinimum': j['exclusiveMinimum'],
      if (j['exclusiveMaximum'] is bool)
        'exclusiveMaximum': j['exclusiveMaximum'],
    };
  }

  static Map<String, Object?> _convertBoolean(BooleanSchema s, Map<String, Object?> j) {
    return <String, Object?>{
      'type': 'boolean',
      if (j['description'] is String) 'description': j['description'],
      if (s.isNullable) 'nullable': true,
    };
  }

  static Map<String, Object?> _convertObject(ObjectSchema s, Map<String, Object?> j) {
    final properties = j['properties'];
    final required = (j['required'] is List)
        ? (j['required'] as List).whereType<String>().toList()
        : null;

    return <String, Object?>{
      'type': 'object',
      'properties': properties,
      if (required != null && required.isNotEmpty) 'required': required,
      if (j['description'] is String) 'description': j['description'],
      if (s.isNullable) 'nullable': true,
      if (j['additionalProperties'] is bool)
        'additionalProperties': j['additionalProperties'],
    };
  }

  static Map<String, Object?> _convertArray(ListSchema s, Map<String, Object?> j) {
    return <String, Object?>{
      'type': 'array',
      'items': j['items'],
      if (j['description'] is String) 'description': j['description'],
      if (s.isNullable) 'nullable': true,
      if (_asInt(j['minItems']) != null) 'minItems': _asInt(j['minItems']),
      if (_asInt(j['maxItems']) != null) 'maxItems': _asInt(j['maxItems']),
    };
  }

  static Map<String, Object?> _convertEnum(EnumSchema s, Map<String, Object?> j) {
    return <String, Object?>{
      'type': 'string',
      if (j['description'] is String) 'description': j['description'],
      if (s.isNullable) 'nullable': true,
      if (j['enum'] is List) 'enum': j['enum'],
    };
  }

  static Map<String, Object?> _convertAnyOf(AnyOfSchema s) {
    final json = s.toJsonSchema();
    return <String, Object?>{
      'type': 'anyOf',
      if (json['description'] is String) 'description': json['description'],
      if (s.isNullable) 'nullable': true,
      if (json['anyOf'] is List) 'branches': json['anyOf'],
    };
  }

  // Helpers
  static int? _asInt(Object? v) => v is int ? v : (v is double ? v.toInt() : null);
  static double? _asDouble(Object? v) => v is double ? v : (v is int ? v.toDouble() : null);
}
```

## 6. Basic Tests (15 minutes)

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

## 7. Example Usage (5 minutes)

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

## 8. README (10 minutes)

**`README.md`**:

```markdown
# ack_<target>

<Target> schema converter for Ack.

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

Part of the [Ack](https://github.com/btwld/ack) monorepo.
```

## 9. Verify Setup (2 minutes)

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

1. **Verify converter mappings** - Confirm required/optional fields and
   constraints map correctly for your target SDK
2. **Add comprehensive tests** - Cover all Ack schema types
3. **Document limitations** - Update README with specific constraints
4. **Add examples** - Real-world usage patterns
5. **Publish** - Once tests pass and docs are complete

## Total Time Estimate

- **Setup**: 40 minutes
- **Implementation**: 2-4 hours
- **Testing**: 2-3 hours
- **Documentation**: 1-2 hours
- **Total**: 6-10 hours for complete package

## Reference

See [Creating Schema Converter Packages](./creating-schema-converter-packages.md) for detailed guidance.
