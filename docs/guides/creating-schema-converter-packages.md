# Creating Schema Converter Packages for Ack

This guide provides detailed instructions for creating schema converter packages that transform Ack validation schemas into other schema formats (e.g., JSON Schema, OpenAPI, GraphQL, Protobuf, TypeBox, AJV, etc.).

**Based on**: `ack_firebase_ai` package (reference implementation)

## Table of Contents

1. [Overview](#overview)
2. [Package Structure](#package-structure)
3. [Step-by-Step Implementation Guide](#step-by-step-implementation-guide)
4. [Architecture Patterns](#architecture-patterns)
5. [Testing Strategy](#testing-strategy)
6. [Documentation Requirements](#documentation-requirements)
7. [Common Patterns](#common-patterns)
8. [Examples](#examples)

---

## Overview

### Purpose

Schema converter packages bridge Ack's validation schemas with external schema systems, enabling:
- **Structured AI output** (Firebase AI, OpenAI Function Calling)
- **API documentation** (OpenAPI, GraphQL)
- **Cross-language validation** (JSON Schema, Protobuf)
- **Frontend validation** (TypeBox, Zod, Yup)

Current converter packages should use Ack's canonical export model:

```dart
final model = schema.toSchemaModel();
```

`AckSchemaModel` describes the boundary shape, constraints, export-safe
defaults, discriminator metadata, and warnings that adapters can reuse. Adapter
packages should render from `AckSchemaModel`; they should not traverse
`AckSchema` subclasses or parse raw `schema.toJsonSchema()` output as their
source of truth.

### Package Naming Convention

```
ack_<target_system>
```

**Examples**:
- `ack_firebase_ai` - Firebase AI (Gemini) schemas
- `ack_openapi` - OpenAPI 3.0/3.1 schemas
- `ack_graphql` - GraphQL SDL schemas
- `ack_protobuf` - Protocol Buffer schemas
- `ack_typebox` - TypeBox schemas
- `ack_ajv` - AJV JSON Schema schemas

---

## Package Structure

### Directory Layout

```
packages/ack_<target>/
├── lib/
│   ├── ack_<target>.dart           # Main library file (public API)
│   └── src/
│       ├── converter.dart          # Core conversion logic
│       └── extension.dart          # Extension method on AckSchema
├── test/
│   └── to_<target>_schema_test.dart  # Comprehensive test suite
├── example/
│   └── basic_usage.dart            # Usage examples
├── docs/
│   ├── <target>_schema_format.md   # Target schema documentation
│   └── migration_guide.md          # Migration/upgrade guide (if needed)
├── pubspec.yaml                    # Package metadata
├── README.md                       # User-facing documentation
├── CHANGELOG.md                    # Version history
├── LICENSE                         # License file
├── analysis_options.yaml           # Dart analyzer config
└── .pubignore                      # Publish exclusions
```

### File Responsibilities

| File | Purpose | Required? |
|------|---------|-----------|
| `lib/ack_<target>.dart` | Main entry point, exports public API | ✅ Yes |
| `lib/src/converter.dart` | Conversion logic (private) | ✅ Yes |
| `lib/src/extension.dart` | Extension methods (private) | ✅ Yes |
| `test/to_<target>_schema_test.dart` | Comprehensive tests | ✅ Yes |
| `example/basic_usage.dart` | Working examples | ✅ Yes |
| `README.md` | Documentation | ✅ Yes |
| `CHANGELOG.md` | Version history | ✅ Yes |
| `docs/` | Additional documentation | ⚠️ Recommended |

---

## Step-by-Step Implementation Guide

### Phase 1: Setup (30 minutes)

#### 1.1 Create Package Structure

```bash
cd packages/
mkdir ack_<target>
cd ack_<target>

# Create directories
mkdir -p lib/src test example docs

# Create files
touch lib/ack_<target>.dart
touch lib/src/converter.dart
touch lib/src/extension.dart
touch test/to_<target>_schema_test.dart
touch example/basic_usage.dart
touch README.md
touch CHANGELOG.md
touch pubspec.yaml
touch analysis_options.yaml
touch .pubignore
```

#### 1.2 Configure pubspec.yaml

```yaml
name: ack_<target>
description: <Target System> schema converter for Ack validation library
version: 1.0.0-beta.1
repository: https://github.com/btwld/ack
issue_tracker: https://github.com/btwld/ack/issues

environment:
  sdk: '>=3.8.0 <4.0.0'
  # Add flutter if target SDK requires it
  # flutter: '>=3.16.0'

dependencies:
  ack: ^1.0.0
  # Add target SDK dependency if needed
  # <target_sdk>: ^x.y.z
  meta: ^1.15.0

dev_dependencies:
  test: ^1.24.0
  lints: ^5.0.0
  # flutter_test:  # Only if using Flutter
  #   sdk: flutter
```

**Key decisions**:
- Does the target SDK require Flutter? (e.g., Firebase AI does)
- What's the minimum Dart SDK version?
- What version constraints for the target SDK?

#### 1.3 Configure analysis_options.yaml

```yaml
include: package:lints/recommended.yaml

analyzer:
  exclude:
    - "**/*.g.dart"
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true
```

#### 1.4 Configure .pubignore

```
# Development and IDE files
.claude/
.idea/
.vscode/

# Build artifacts
build/
.dart_tool/

# Coverage files
coverage/

# Local example files
example/local/
```

---

### Phase 2: Core Implementation (2-4 hours)

#### 2.1 Main Library File (`lib/ack_<target>.dart`)

**Template**:

```dart
/// <Target System> schema converter for Ack validation library.
///
/// Converts Ack validation schemas to <Target> format for [use case].
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
/// Some Ack features cannot be converted to <Target> format:
/// - [List specific limitations based on target system]
/// - Custom refinements (`.refine()`) - validate after
/// - [Other limitations...]
library;

import 'package:ack/ack.dart';
// Import target SDK if applicable
// import 'package:<target_sdk>/<target_sdk>.dart' as target;

// Export public API
export 'src/extension.dart';

// Optionally export converter if users need direct access
// export 'src/converter.dart' show <Target>SchemaConverter;
```

**Key sections**:
1. **Library documentation** - Top-level overview
2. **Usage example** - Quick start code
3. **Limitations** - What doesn't convert
4. **Exports** - Only export public API

#### 2.2 Extension Method (`lib/src/extension.dart`)

**Template**:

```dart
import 'package:ack/ack.dart';
// Import target type
// import 'package:<target_sdk>/<target_sdk>.dart' show <TargetSchema>;

import 'converter.dart';

/// Extension methods for converting Ack schemas to <Target> format.
extension <Target>SchemaExtension on AckSchema {
  /// Converts this Ack schema to <Target> format.
  ///
  /// Returns a [<TargetSchema>] instance that can be used with
  /// [describe target use case].
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
  ///
  /// ## Limitations
  ///
  /// Some Ack features cannot be converted:
  /// - [List specific limitations]
  /// - Custom refinements (`.refine()`)
  /// - Regex patterns (`.matches()`)
  /// - [Other limitations...]
  ///
  /// ## <Target> Schema Format
  ///
  /// The returned [<TargetSchema>] follows <Target>'s schema format.
  /// Key fields include:
  /// - [Describe key schema fields]
  /// - [Describe structure]
  <TargetSchema> to<Target>Schema() {
    return <Target>SchemaConverter.convert(this);
  }
}
```

**Design pattern**: Simple extension that delegates to converter

#### 2.3 Converter Logic (`lib/src/converter.dart`)

**Template**:

```dart
import 'package:ack/ack.dart';
// Import target SDK
// import 'package:<target_sdk>/<target_sdk>.dart' as target;

/// Converts Ack schemas to <Target> format.
///
/// <Target> uses [describe schema format] for [describe use case].
///
/// This is a utility class with only static methods and cannot be instantiated.
class <Target>SchemaConverter {
  // Private constructor prevents instantiation
  const <Target>SchemaConverter._();

  /// Converts an Ack schema to <Target> format.
  ///
  /// Returns a [<TargetSchema>] representing the schema structure.
  static <TargetSchema> convert(AckSchema schema) {
    return _convertModel(schema.toSchemaModel());
  }

  static <TargetSchema> _convertModel(AckSchemaModel schema) {
    return switch (schema) {
      AckStringSchemaModel() => _convertString(schema),
      AckIntegerSchemaModel() => _convertInteger(schema),
      AckNumberSchemaModel() => _convertNumber(schema),
      AckBooleanSchemaModel() => _convertBoolean(schema),
      AckObjectSchemaModel() => _convertObject(schema),
      AckArraySchemaModel() => _convertArray(schema),
      AckAnyOfSchemaModel() => _convertAnyOf(schema),
      AckOneOfSchemaModel() => _convertOneOf(schema),
      AckAllOfSchemaModel() => _convertAllOf(schema),
      AckNullSchemaModel() => _buildNullSchema(),
    };
  }

  // ========================================================================
  // Primitive Type Converters
  // ========================================================================

  static <TargetSchema> _convertString(AckStringSchemaModel schema) {
    final enumValues = schema.allowedStringValues;
    if (enumValues != null) {
      return _buildEnumSchema(enumValues, schema);
    }

    return _buildStringSchema(
      description: schema.description,
      nullable: schema.nullable,
      format: schema.format,
      minLength: schema.minLength,
      maxLength: schema.maxLength,
      pattern: schema.pattern,
    );
  }

  static <TargetSchema> _convertInteger(AckIntegerSchemaModel schema) {
    return _buildIntegerSchema(
      description: schema.description,
      nullable: schema.nullable,
      minimum: schema.minimum,
      maximum: schema.maximum,
      exclusiveMinimum: schema.exclusiveMinimum,
      exclusiveMaximum: schema.exclusiveMaximum,
    );
  }

  static <TargetSchema> _convertNumber(AckNumberSchemaModel schema) {
    return _buildNumberSchema(
      description: schema.description,
      nullable: schema.nullable,
      minimum: schema.minimum,
      maximum: schema.maximum,
    );
  }

  static <TargetSchema> _convertBoolean(AckBooleanSchemaModel schema) {
    return _buildBooleanSchema(
      description: schema.description,
      nullable: schema.nullable,
    );
  }

  // ========================================================================
  // Complex Type Converters
  // ========================================================================

  static <TargetSchema> _convertObject(AckObjectSchemaModel schema) {
    final properties = <String, TargetSchema>{};
    for (final entry in schema.properties?.entries ?? const []) {
      properties[entry.key] = _convertModel(entry.value);
    }

    final required = schema.required ?? const [];
    final optionalProperties = properties.keys
        .where((key) => !required.contains(key))
        .toList();

    final additionalProperties = switch (schema.additionalProperties) {
      AckAdditionalPropertiesAllowed() || null => true,
      AckAdditionalPropertiesDisallowed() => false,
      AckAdditionalPropertiesSchema(schema: final schema) =>
        _convertModel(schema),
    };

    return _buildObjectSchema(
      properties: properties,
      optionalProperties: optionalProperties,
      description: schema.description,
      nullable: schema.nullable,
      additionalProperties: additionalProperties,
    );
  }

  static <TargetSchema> _convertArray(AckArraySchemaModel schema) {
    final itemSchema = schema.items != null
        ? _convertModel(schema.items!)
        : _buildAnySchema();

    return _buildArraySchema(
      items: itemSchema,
      description: schema.description,
      nullable: schema.nullable,
      minItems: schema.minItems,
      maxItems: schema.maxItems,
    );
  }

  static <TargetSchema> _convertAnyOf(AckAnyOfSchemaModel schema) {
    final branches = schema.schemas.map(_convertModel).toList();

    return _buildAnyOfSchema(
      branches: branches,
      description: schema.description,
      nullable: schema.nullable,
    );
  }

  static <TargetSchema> _convertOneOf(AckOneOfSchemaModel schema) {
    final branches = schema.schemas.map(_convertModel).toList();

    return _buildOneOfSchema(
      branches: branches,
      description: schema.description,
      nullable: schema.nullable,
      discriminator: schema.discriminator?.propertyName,
    );
  }

  static <TargetSchema> _convertAllOf(AckAllOfSchemaModel schema) {
    final branches = schema.schemas.map(_convertModel).toList();

    return _buildAllOfSchema(
      branches: branches,
      description: schema.description,
      nullable: schema.nullable,
    );
  }

  // ========================================================================
  // Helper Methods - Schema Builders
  // ========================================================================
  // These wrap the target SDK's schema construction API

  static <TargetSchema> _buildStringSchema({
    String? description,
    bool nullable = false,
    String? format,
    int? minLength,
    int? maxLength,
    String? pattern,
  }) {
    return <String, Object?>{
      'type': 'string',
      if (description != null) 'description': description,
      if (nullable) 'nullable': true,
      if (format != null) 'format': format,
      if (minLength != null) 'minLength': minLength,
      if (maxLength != null) 'maxLength': maxLength,
      if (pattern != null) 'pattern': pattern,
    } as TargetSchema;
  }

  static <TargetSchema> _buildIntegerSchema({
    String? description,
    bool nullable = false,
    num? minimum,
    num? maximum,
    num? exclusiveMinimum,
    num? exclusiveMaximum,
  }) {
    return <String, Object?>{
      'type': 'integer',
      if (description != null) 'description': description,
      if (nullable) 'nullable': true,
      if (minimum != null) 'minimum': minimum,
      if (maximum != null) 'maximum': maximum,
      if (exclusiveMinimum != null)
        'exclusiveMinimum': exclusiveMinimum,
      if (exclusiveMaximum != null)
        'exclusiveMaximum': exclusiveMaximum,
    } as TargetSchema;
  }

  static <TargetSchema> _buildNumberSchema({
    String? description,
    bool nullable = false,
    num? minimum,
    num? maximum,
  }) {
    return <String, Object?>{
      'type': 'number',
      if (description != null) 'description': description,
      if (nullable) 'nullable': true,
      if (minimum != null) 'minimum': minimum,
      if (maximum != null) 'maximum': maximum,
    } as TargetSchema;
  }

  static <TargetSchema> _buildBooleanSchema({
    String? description,
    bool nullable = false,
  }) {
    return <String, Object?>{
      'type': 'boolean',
      if (description != null) 'description': description,
      if (nullable) 'nullable': true,
    } as TargetSchema;
  }

  static <TargetSchema> _buildObjectSchema({
    required Map<String, TargetSchema> properties,
    List<String>? optionalProperties,
    String? description,
    bool nullable = false,
    Object additionalProperties = false,
  }) {
    final required = <String>[];
    for (final propertyName in properties.keys) {
      if (optionalProperties == null || !optionalProperties.contains(propertyName)) {
        required.add(propertyName);
      }
    }

    return <String, Object?>{
      'type': 'object',
      'properties': properties,
      if (required.isNotEmpty) 'required': required,
      if (description != null) 'description': description,
      if (nullable) 'nullable': true,
      'additionalProperties': additionalProperties,
    } as TargetSchema;
  }

  static <TargetSchema> _buildArraySchema({
    required TargetSchema items,
    String? description,
    bool nullable = false,
    int? minItems,
    int? maxItems,
  }) {
    return <String, Object?>{
      'type': 'array',
      'items': items,
      if (description != null) 'description': description,
      if (nullable) 'nullable': true,
      if (minItems != null) 'minItems': minItems,
      if (maxItems != null) 'maxItems': maxItems,
    } as TargetSchema;
  }

  static <TargetSchema> _buildEnumSchema(
    List<Object?> enumValues,
    AckSchemaModel schema,
  ) {
    return <String, Object?>{
      'type': 'string',
      'enum': enumValues.map((value) => value.toString()).toList(),
      if (schema.nullable) 'nullable': true,
      if (schema.description != null) 'description': schema.description,
    } as TargetSchema;
  }

  static <TargetSchema> _buildAnyOfSchema({
    required List<TargetSchema> branches,
    String? description,
    bool nullable = false,
  }) {
    return <String, Object?>{
      'type': 'anyOf',
      'branches': branches,
      if (description != null) 'description': description,
      if (nullable) 'nullable': true,
    } as TargetSchema;
  }

  static <TargetSchema> _buildOneOfSchema({
    required List<TargetSchema> branches,
    String? description,
    bool nullable = false,
    String? discriminator,
  }) {
    return <String, Object?>{
      'type': 'oneOf',
      'branches': branches,
      if (description != null) 'description': description,
      if (nullable) 'nullable': true,
      if (discriminator != null) 'discriminator': discriminator,
    } as TargetSchema;
  }

  static <TargetSchema> _buildAllOfSchema({
    required List<TargetSchema> branches,
    String? description,
    bool nullable = false,
  }) {
    return <String, Object?>{
      'type': 'allOf',
      'branches': branches,
      if (description != null) 'description': description,
      if (nullable) 'nullable': true,
    } as TargetSchema;
  }

  // Add target SDK coercion helpers here only when the target builder API
  // needs a narrower type than AckSchemaModel exposes.
}
```

**Key patterns**:
1. **Private constructor** - Prevent instantiation
2. **Static converter methods** - Pure functions
3. **Model-first routing** - Convert once with `schema.toSchemaModel()`
4. **Switch expression** - Type-safe routing on sealed `AckSchemaModel` variants
5. **Helper builders** - Wrap target SDK API
6. **Explicit gaps** - Throw or warn for target-unsupported model features

---

## Testing Strategy

### Phase 3: Testing (2-3 hours)

#### 3.1 Test Structure

**Template** (`test/to_<target>_schema_test.dart`):

```dart
import 'package:ack/ack.dart';
import 'package:ack_<target>/ack_<target>.dart';
// Import target SDK for assertions
// import 'package:<target_sdk>/<target_sdk>.dart' as target;
import 'package:test/test.dart';

// Test data
enum Color { red, green, blue }
enum Status { pending, active, completed }

/// Tests for the to<Target>Schema() extension method.
///
/// Coverage areas:
/// - Basic schema conversion (primitives, objects, arrays)
/// - Constraint mapping
/// - Edge cases and error handling
/// - Semantic validation (behavioral equivalence)
/// - Metadata and descriptions
/// - Dart enum support
void main() {
  group('to<Target>Schema()', () {
    group('Primitives', () {
      test('converts basic string schema', () {
        final schema = Ack.string();
        final result = schema.to<Target>Schema();

        // Assert target schema properties
        expect(result.type, target.SchemaType.string);
        expect(result.nullable, isFalse);
      });

      test('converts string with description', () {
        final schema = Ack.string().describe('User name');
        final result = schema.to<Target>Schema();

        expect(result.description, 'User name');
      });

      test('converts nullable string', () {
        final schema = Ack.string().nullable();
        final result = schema.to<Target>Schema();

        expect(result.nullable, isTrue);
      });

      test('converts string with minLength', () {
        final schema = Ack.string().minLength(5);
        final result = schema.to<Target>Schema();

        // Assert minLength is preserved (if supported by target)
        expect(result.minLength, 5);
      });

      test('converts string with maxLength', () {
        final schema = Ack.string().maxLength(50);
        final result = schema.to<Target>Schema();

        expect(result.maxLength, 50);
      });

      test('converts string with email format', () {
        final schema = Ack.string().email();
        final result = schema.to<Target>Schema();

        expect(result.format, 'email');
      });

      test('converts integer schema', () {
        final schema = Ack.integer();
        final result = schema.to<Target>Schema();

        expect(result.type, target.SchemaType.integer);
      });

      test('converts integer with minimum', () {
        final schema = Ack.integer().min(0);
        final result = schema.to<Target>Schema();

        expect(result.minimum, 0);
      });

      test('converts integer with maximum', () {
        final schema = Ack.integer().max(100);
        final result = schema.to<Target>Schema();

        expect(result.maximum, 100);
      });

      test('converts double schema', () {
        final schema = Ack.double();
        final result = schema.to<Target>Schema();

        expect(result.type, target.SchemaType.number);
      });

      test('converts double with range', () {
        final schema = Ack.double().min(0.0).max(1.0);
        final result = schema.to<Target>Schema();

        expect(result.minimum, 0.0);
        expect(result.maximum, 1.0);
      });

      test('converts boolean schema', () {
        final schema = Ack.boolean();
        final result = schema.to<Target>Schema();

        expect(result.type, target.SchemaType.boolean);
      });
    });

    group('Objects', () {
      test('converts basic object schema', () {
        final schema = Ack.object({
          'name': Ack.string(),
          'age': Ack.integer(),
        });
        final result = schema.to<Target>Schema();

        expect(result.type, target.SchemaType.object);
        expect(result.properties.keys, containsAll(['name', 'age']));
      });

      test('converts object with optional fields', () {
        final schema = Ack.object({
          'name': Ack.string(),
          'age': Ack.integer().optional(),
        });
        final result = schema.to<Target>Schema();

        expect(result.required, contains('name'));
        expect(result.required, isNot(contains('age')));
        // OR: expect(result.optionalProperties, contains('age'));
      });

      test('converts nested object schema', () {
        final schema = Ack.object({
          'user': Ack.object({
            'name': Ack.string(),
          }),
        });
        final result = schema.to<Target>Schema();

        expect(result.properties['user']?.type, target.SchemaType.object);
      });

      test('includes propertyOrdering if supported', () {
        final schema = Ack.object({
          'id': Ack.string(),
          'name': Ack.string(),
          'email': Ack.string(),
        });
        final result = schema.to<Target>Schema();

        // If target supports property ordering
        expect(result.propertyOrdering, ['id', 'name', 'email']);
      });
    });

    group('Arrays', () {
      test('converts basic array schema', () {
        final schema = Ack.list(Ack.string());
        final result = schema.to<Target>Schema();

        expect(result.type, target.SchemaType.array);
        expect(result.items.type, target.SchemaType.string);
      });

      test('converts array with minItems', () {
        final schema = Ack.list(Ack.string()).minLength(1);
        final result = schema.to<Target>Schema();

        expect(result.minItems, 1);
      });

      test('converts array with maxItems', () {
        final schema = Ack.list(Ack.string()).maxLength(10);
        final result = schema.to<Target>Schema();

        expect(result.maxItems, 10);
      });

      test('converts array of objects', () {
        final schema = Ack.list(
          Ack.object({
            'id': Ack.integer(),
            'name': Ack.string(),
          }),
        );
        final result = schema.to<Target>Schema();

        expect(result.items.type, target.SchemaType.object);
      });
    });

    group('Enums', () {
      test('converts string enum schema', () {
        final schema = Ack.enumString(['red', 'green', 'blue']);
        final result = schema.to<Target>Schema();

        expect(result.enumValues, ['red', 'green', 'blue']);
      });

      test('converts Dart enum to string enumValues', () {
        final schema = EnumSchema<Color>(values: Color.values);
        final result = schema.to<Target>Schema();

        expect(result.enumValues, ['red', 'green', 'blue']);
      });
    });

    group('Edge Cases', () {
      test('handles anyOf schema', () {
        final schema = Ack.anyOf([
          Ack.string(),
          Ack.integer(),
        ]);
        final result = schema.to<Target>Schema();

        expect(result.anyOf, hasLength(2));
      });

      test('throws UnsupportedError for unsupported schema types', () {
        final schema = Ack.string().refine((s) => s.startsWith('A'));

        // Refinements should not be supported
        // Check if it throws or handles gracefully
        expect(
          () => schema.to<Target>Schema(),
          throwsUnsupportedError,
        );
      });

      test('handles empty object schema', () {
        final schema = Ack.object({});
        final result = schema.to<Target>Schema();

        expect(result.type, target.SchemaType.object);
        expect(result.properties, isEmpty);
      });
    });

    group('Metadata', () {
      test('preserves description metadata', () {
        final schema = Ack.string().describe('User email address');
        final result = schema.to<Target>Schema();

        expect(result.description, 'User email address');
      });

      test('preserves nullable flag', () {
        final schema = Ack.string().nullable();
        final result = schema.to<Target>Schema();

        expect(result.nullable, isTrue);
      });

      test('handles title metadata if supported', () {
        final schemaWithTitle = Ack.string(); // Add title somehow
        final result = schemaWithTitle.to<Target>Schema();

        // Check if title is preserved
        // expect(result.title, 'Some Title');
      });
    });

    group('Semantic Validation', () {
      // Test that converted schemas behave correctly with target system

      test('validates string constraints correctly', () {
        final schema = Ack.string().minLength(5).maxLength(10);
        final targetSchema = schema.to<Target>Schema();

        // Test with target system's validator
        final validResult = targetSchema.validate('hello');
        final invalidShort = targetSchema.validate('hi');
        final invalidLong = targetSchema.validate('this is too long');

        expect(validResult.isValid, isTrue);
        expect(invalidShort.isValid, isFalse);
        expect(invalidLong.isValid, isFalse);
      });

      test('validates integer range correctly', () {
        final schema = Ack.integer().min(0).max(100);
        final targetSchema = schema.to<Target>Schema();

        expect(targetSchema.validate(50).isValid, isTrue);
        expect(targetSchema.validate(-1).isValid, isFalse);
        expect(targetSchema.validate(101).isValid, isFalse);
      });

      test('validates enum values correctly', () {
        final schema = Ack.enumString(['red', 'green', 'blue']);
        final targetSchema = schema.to<Target>Schema();

        expect(targetSchema.validate('red').isValid, isTrue);
        expect(targetSchema.validate('yellow').isValid, isFalse);
      });
    });

    group('Complex Scenarios', () {
      test('converts complete nested structure', () {
        final schema = Ack.object({
          'user': Ack.object({
            'id': Ack.integer().min(1),
            'name': Ack.string().minLength(2),
            'email': Ack.string().email(),
            'roles': Ack.list(Ack.string()),
            'metadata': Ack.object({
              'createdAt': Ack.string(),
              'updatedAt': Ack.string().optional(),
            }),
          }),
          'tags': Ack.list(Ack.string()).optional(),
        });

        final result = schema.to<Target>Schema();

        // Verify structure
        expect(result.type, target.SchemaType.object);
        expect(result.properties.containsKey('user'), isTrue);
        expect(result.properties.containsKey('tags'), isTrue);

        final userSchema = result.properties['user']!;
        expect(userSchema.properties.containsKey('metadata'), isTrue);
      });
    });
  });
}
```

**Test categories**:
1. **Primitives** - Basic type conversions
2. **Objects** - Complex structures, nesting
3. **Arrays** - Lists with constraints
4. **Enums** - String and Dart enums
5. **Edge Cases** - Empty, null, unsupported
6. **Metadata** - Descriptions, titles
7. **Semantic Validation** - Actual behavior with target system
8. **Complex Scenarios** - Real-world structures

**Coverage target**: 85%+ line coverage

---

## Documentation Requirements

### Phase 4: Documentation (1-2 hours)

#### 4.1 README.md Template

```markdown
# ack_<target>

<Target System> schema converter for the [Ack](https://pub.dev/packages/ack) validation library.

[![pub package](https://img.shields.io/pub/v/ack_<target>.svg)](https://pub.dev/packages/ack_<target>)

## Overview

Converts Ack schemas to <Target> format for [use case]. Assumes familiarity with [Ack](https://pub.dev/packages/ack) and [target system].

## Installation

\`\`\`yaml
dependencies:
  ack: ^1.0.0
  ack_<target>: ^1.0.0
  <target_sdk>: ^x.y.z  # Required peer dependency
\`\`\`

### Compatibility

Requires `<target_sdk>: >=x.y.z <n.0.0` as a peer dependency. Report [compatibility issues](https://github.com/btwld/ack/issues).

## Limitations ⚠️

**Read this first** - <Target> schema conversion has important constraints:

### 1. [Primary Limitation]

[Explain the most important limitation]

**Example**:
\`\`\`dart
// What doesn't work and why
\`\`\`

### 2. [Secondary Limitation]

[Explain]

### 3. [Other Limitations]

- [List other limitations]
- [Feature gaps]
- [Workarounds]

## Usage

\`\`\`dart
import 'package:ack/ack.dart';
import 'package:ack_<target>/ack_<target>.dart';
import 'package:<target_sdk>/<target_sdk>.dart';

// 1. Define schema
final userSchema = Ack.object({
  'name': Ack.string().minLength(2).maxLength(50),
  'email': Ack.string().email(),
  'age': Ack.integer().min(0).max(120).optional(),
});

// 2. Convert to <Target>
final targetSchema = userSchema.to<Target>Schema();

// 3. Use with <Target> system
[Show actual usage with target system]

// 4. ALWAYS validate with Ack after
final result = userSchema.safeParse(responseData);
if (result.isOk) {
  final user = result.getOrThrow();
  print('Valid: $user');
} else {
  print('Invalid: ${result.getError()}');
}
\`\`\`

## Schema Mapping

### Supported Types

| Ack Type | <Target> Type | Notes |
|----------|---------------|-------|
| `Ack.string()` | [target type] | [Notes] |
| `Ack.integer()` | [target type] | [Notes] |
| `Ack.double()` | [target type] | [Notes] |
| `Ack.boolean()` | [target type] | [Notes] |
| `Ack.object({...})` | [target type] | [Notes] |
| `Ack.list(...)` | [target type] | [Notes] |
| `Ack.enumString([...])` | [target type] | [Notes] |
| `Ack.anyOf([...])` | [target type] | [Notes] |

### Supported Constraints

| Ack Constraint | <Target> | Notes |
|----------------|----------|-------|
| `.minLength()` / `.maxLength()` | [mapping] | [Notes] |
| `.min()` / `.max()` | [mapping] | [Notes] |
| `.email()` / `.uuid()` / `.url()` | [mapping] | [Notes] |
| `.nullable()` | [mapping] | [Notes] |
| `.optional()` | [mapping] | [Notes] |
| `.describe()` | [mapping] | [Notes] |

## Testing

[Instructions for running tests]

\`\`\`bash
cd packages/ack_<target>
dart test  # or flutter test if using Flutter
\`\`\`

## Contributing

For contribution guidelines, see the [CONTRIBUTING.md](https://github.com/btwld/ack/blob/main/CONTRIBUTING.md) in the root repository.

## License

This package is part of the [Ack](https://github.com/btwld/ack) monorepo.

## Related Packages

- [ack](https://pub.dev/packages/ack) - Core validation library
- [ack_generator](https://pub.dev/packages/ack_generator) - Code generator
- [<target_sdk>](https://pub.dev/packages/<target_sdk>) - <Target> SDK
```

#### 4.2 CHANGELOG.md Template

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0-beta.1] - YYYY-MM-DD

### Added
- Initial release of ack_<target> package
- Extension method `.to<Target>Schema()` for converting Ack schemas
- Support for all basic schema types (string, integer, double, boolean, object, array)
- Support for enum schemas
- Constraint mapping ([list key constraints])
- Nullable and optional field support
- Comprehensive test suite with [X]+ tests
- Full documentation and examples

### Supported
- [List supported features]

### Limitations
- [List known limitations]

[1.0.0-beta.1]: https://github.com/btwld/ack/releases/tag/ack_<target>-v1.0.0-beta.1
```

---

## Architecture Patterns

### Pattern 1: AckSchemaModel Renderer

**When to use**: Default for new converter packages

**Implementation**:
```dart
extension TargetSchemaExtension on AckSchema {
  TargetSchema toTargetSchema() => _convert(toSchemaModel());
}

TargetSchema _convert(AckSchemaModel schema) {
  return switch (schema) {
    AckStringSchemaModel() => _convertString(schema),
    AckIntegerSchemaModel() => _convertInteger(schema),
    AckNumberSchemaModel() => _convertNumber(schema),
    AckBooleanSchemaModel() => _convertBoolean(schema),
    AckArraySchemaModel() => _convertArray(schema),
    AckObjectSchemaModel() => _convertObject(schema),
    AckAnyOfSchemaModel() => _convertAnyOf(schema),
    AckOneOfSchemaModel() => _convertOneOf(schema),
    AckAllOfSchemaModel() => _convertAllOf(schema),
    AckNullSchemaModel() => TargetSchema.nullValue(),
  };
}

TargetSchema _convertString(AckStringSchemaModel schema) {
  return TargetSchema.string(
    format: schema.format,
    minLength: schema.minLength,
    description: schema.description,
  );
}
```

**Pros**: One normalized Ack-owned model, shared semantics with maintained adapter packages, no duplicated discriminator/default/nullability traversal
**Cons**: Target-specific unsupported features still need explicit handling

### Pattern 2: JSON Schema Renderer

**When to use**: Target system consumes JSON Schema-compatible maps directly

**Implementation**:
```dart
Map<String, Object?> _convert(AckSchema schema) {
  return schema.toSchemaModel().toJsonSchema();
}
```

**Pros**: Uses the canonical model while emitting a standard map format
**Cons**: Target systems that are not JSON Schema-compatible still need a model renderer

### Pattern 3: Target-Specific Model Post-Processing

**When to use**: Target systems require extra annotations after the canonical
model has been rendered

**Implementation**:
```dart
TargetSchema _convert(AckSchema schema) {
  final model = schema.toSchemaModel();
  final converted = _convertModel(model);
  return _applyTargetAnnotations(converted, model.extensions);
}
```

**Pros**: Keeps conversion anchored on `AckSchemaModel` while leaving room for target-specific metadata
**Cons**: Extra metadata must be documented and tested per target

---

## Common Patterns

### Handling Transformed Schemas

`toSchemaModel()` projects transformed schemas from their boundary input schema
and preserves adapter-safe metadata such as description, nullability, and
`x-transformed`.

**Option 1: Render projected boundary model** (Recommended)
```dart
TargetSchema _convertTransformed(AckSchemaModel schema) {
  return _convert(schema);
}
```

**Option 2: Reject explicit transformed marker** (If target cannot tolerate transforms)
```dart
if (schema.extensions['x-transformed'] == true) {
  throw UnsupportedError('Transformed Ack schemas are not supported here.');
}
```

### Handling Discriminated Unions

**Option 1: Native Support** (If target has discriminators)
```dart
static TargetSchema _convertDiscriminated(
  AckOneOfSchemaModel schema,
) {
  return TargetSchema.discriminated(
    discriminatorKey: schema.discriminator!.propertyName,
    branches: [for (final branch in schema.schemas) _convert(branch)],
  );
}
```

**Option 2: OneOf with Effective Discriminator Properties** (Fallback)
```dart
static TargetSchema _convertDiscriminated(
  AckOneOfSchemaModel schema,
) {
  final branches = <TargetSchema>[];

  for (final branch in schema.schemas) {
    // Branches already expose the union-owned discriminator as an exact const.
    branches.add(_convert(branch));
  }

  return TargetSchema.oneOf(
    branches,
    discriminator: schema.discriminator?.propertyName,
  );
}
```

### Handling Any Schema Models

`Ack.any()` reaches converters as an `AckAnyOfSchemaModel` over the
JSON-compatible value shapes Ack can export. Inspect `schema.warnings` if the
target needs to surface that runtime `Object` acceptance is wider than the
export boundary.

**Option 1: Union of JSON-Compatible Shapes** (Canonical)
```dart
static TargetSchema _convertAny(AckAnyOfSchemaModel schema) {
  return TargetSchema.anyOf([
    for (final branch in schema.schemas) _convert(branch),
  ]);
}
```

**Option 2: Target-Specific Any** (If available)
```dart
static TargetSchema _convertAny(AckAnyOfSchemaModel schema) {
  return TargetSchema.any(
    description: schema.description,
    nullable: schema.nullable,
  );
}
```

**Option 3: Empty Object Fallback** (If the target has no union support)
```dart
static TargetSchema _convertAny(AckAnyOfSchemaModel schema) {
  return TargetSchema.object(
    properties: const {},
    additionalProperties: true,
    description: schema.description,
  );
}
```

### Target Builder Helpers

`AckSchemaModel` exposes typed fields for constraints and enum values, so
converter packages should not parse JSON Schema maps to recover them. Add helper
functions only for target SDK requirements, such as adapting `num` bounds to a
target API that requires `int` or `double`.

---

## Examples

### Example 1: OpenAPI Schema Converter

**Target**: OpenAPI 3.1 Schema

```dart
// lib/src/converter.dart
import 'package:ack/ack.dart';

class OpenApiSchemaConverter {
  const OpenApiSchemaConverter._();

  static Map<String, Object?> convert(AckSchema schema) {
    // OpenAPI 3.1 is JSON Schema-compatible enough for the canonical renderer.
    return schema.toSchemaModel().toJsonSchema();
  }
}
```

### Example 2: GraphQL SDL Converter

**Target**: GraphQL Schema Definition Language

```dart
// lib/src/converter.dart
import 'package:ack/ack.dart';

class GraphQlSchemaConverter {
  const GraphQlSchemaConverter._();

  static String convert(AckSchema schema, {required String typeName}) {
    final buffer = StringBuffer();
    _convertToSDL(schema.toSchemaModel(), typeName, buffer);
    return buffer.toString();
  }

  static void _convertToSDL(
    AckSchemaModel schema,
    String typeName,
    StringBuffer buffer,
  ) {
    if (schema is! AckObjectSchemaModel) {
      throw UnsupportedError('Only object schema models can be converted.');
    }

    buffer.writeln('type $typeName {');

    final required = schema.required ?? const <String>[];
    for (final entry in schema.properties?.entries ?? const []) {
      final fieldName = entry.key;
      final fieldSchema = entry.value;
      final gqlType = _getGraphQLType(fieldSchema);
      final nullableSuffix = required.contains(fieldName) ? '!' : '';

      if (fieldSchema.description != null) {
        buffer.writeln('  """${fieldSchema.description}"""');
      }
      buffer.writeln('  $fieldName: $gqlType$nullableSuffix');
    }

    buffer.writeln('}');
  }

  static String _getGraphQLType(AckSchemaModel schema) {
    return switch (schema) {
      AckStringSchemaModel(allowedStringValues: final values)
          when values != null && values.isNotEmpty =>
        _generateEnumType(schema),
      AckStringSchemaModel() => 'String',
      AckIntegerSchemaModel() => 'Int',
      AckNumberSchemaModel() => 'Float',
      AckBooleanSchemaModel() => 'Boolean',
      AckArraySchemaModel(items: final item?) => '[${_getGraphQLType(item)}]',
      _ => 'String', // Fallback
    };
  }

  static String _generateEnumType(AckStringSchemaModel schema) {
    // Would need to generate enum definitions separately
    return 'EnumType';
  }
}
```

---

## Checklist

### Implementation Phase
- [ ] Create package directory structure
- [ ] Configure `pubspec.yaml` with correct dependencies
- [ ] Implement main library file with documentation
- [ ] Implement extension method
- [ ] Implement converter with all schema types
- [ ] Add type coercion helpers
- [ ] Handle edge cases (TransformedSchema, AnySchema, etc.)

### Testing Phase
- [ ] Write tests for all primitive types
- [ ] Write tests for complex types (object, array)
- [ ] Write tests for enums (string and Dart)
- [ ] Write tests for anyOf/discriminated unions
- [ ] Write tests for constraints and metadata
- [ ] Write tests for edge cases
- [ ] Add semantic validation tests
- [ ] Achieve 85%+ test coverage

### Documentation Phase
- [ ] Write comprehensive README
- [ ] Document all limitations upfront
- [ ] Add usage examples
- [ ] Create schema mapping tables
- [ ] Write CHANGELOG
- [ ] Add inline code documentation
- [ ] Create additional docs (if needed)

### Quality Assurance
- [ ] All tests pass
- [ ] `dart analyze` shows no issues
- [ ] `dart format` applied
- [ ] Examples run successfully
- [ ] README reviewed for clarity
- [ ] Limitations clearly documented

### Publication
- [ ] Version set correctly in pubspec.yaml
- [ ] CHANGELOG updated
- [ ] README finalized
- [ ] .pubignore configured
- [ ] Package published to pub.dev
- [ ] PR created for monorepo integration

---

## Additional Resources

### Reference Implementations
- **ack_firebase_ai**: Firebase AI/Gemini schemas
- **ack core**: JSON Schema implementation (`toJsonSchema()`)

### Target System Documentation
- Research target schema format documentation
- Understand supported types and constraints
- Identify gaps vs Ack features
- Document limitations clearly

### Monorepo Integration
- Add to `melos.yaml` packages list
- Configure CI/CD for testing
- Update root README with new package
- Add to documentation site

---

## Questions & Support

**Before starting**:
1. Does the target system have an official schema format?
2. Is there a Dart/Flutter SDK for the target?
3. What schema features does the target support?
4. What constraints can be represented?
5. How are nullability and optionality handled?

**During development**:
- Reference `ack_firebase_ai` for patterns
- Use `schema.toSchemaModel()` as the adapter boundary
- Write tests first (TDD approach)
- Document limitations as you discover them

**For help**:
- Create GitHub issue: https://github.com/btwld/ack/issues
- Reference this guide
- Ask specific questions about target system
