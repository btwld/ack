# Creating Schema Converter Packages for ACK

This guide provides detailed instructions for creating schema converter packages that transform ACK validation schemas into other schema formats (e.g., JSON Schema, OpenAPI, GraphQL, Protobuf, TypeBox, AJV, etc.).

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

Schema converter packages bridge ACK's validation schemas with external schema systems, enabling:
- **Structured AI output** (Firebase AI, OpenAI Function Calling)
- **API documentation** (OpenAPI, GraphQL)
- **Cross-language validation** (JSON Schema, Protobuf)
- **Frontend validation** (TypeBox, Zod, Yup)

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
description: <Target System> schema converter for ACK validation library
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
/// <Target System> schema converter for ACK validation library.
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

/// Extension methods for converting ACK schemas to <Target> format.
extension <Target>SchemaExtension on AckSchema {
  /// Converts this ACK schema to <Target> format.
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
  /// Some ACK features cannot be converted:
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

/// Converts ACK schemas to <Target> format.
///
/// <Target> uses [describe schema format] for [describe use case].
///
/// This is a utility class with only static methods and cannot be instantiated.
class <Target>SchemaConverter {
  // Private constructor prevents instantiation
  const <Target>SchemaConverter._();

  /// Converts an ACK schema to <Target> format.
  ///
  /// Returns a [<TargetSchema>] representing the schema structure.
  static <TargetSchema> convert(AckSchema schema) {
    return _convertSchema(schema);
  }

  static <TargetSchema> _convertSchema(AckSchema schema) {
    // Option 1: If target needs JSON Schema intermediate step
    final jsonSchema = schema.toJsonSchema();

    // Option 2: Direct conversion based on ACK type
    return switch (schema) {
      StringSchema() => _convertString(schema),
      IntegerSchema() => _convertInteger(schema),
      DoubleSchema() => _convertDouble(schema),
      BooleanSchema() => _convertBoolean(schema),
      ObjectSchema() => _convertObject(schema),
      ListSchema() => _convertArray(schema),
      EnumSchema() => _convertEnum(schema),
      AnyOfSchema() => _convertAnyOf(schema),
      AnySchema() => _convertAny(schema),
      DiscriminatedObjectSchema() => _convertDiscriminated(schema),
      TransformedSchema() => _handleTransformed(schema),
      _ => throw UnsupportedError(
          'Schema type ${schema.runtimeType} is not supported '
          'for <Target> conversion.',
        ),
    };
  }

  // ========================================================================
  // Primitive Type Converters
  // ========================================================================

  static <TargetSchema> _convertString(StringSchema schema) {
    // Extract constraints from JSON Schema or directly from schema
    final jsonSchema = schema.toJsonSchema();

    // Check for enum values
    final enumValues = jsonSchema['enum'] as List<String>?;
    if (enumValues != null) {
      return _buildEnumSchema(enumValues, schema);
    }

    // Build string schema with constraints
    return _buildStringSchema(
      description: schema.description,
      nullable: schema.isNullable,
      format: jsonSchema['format'] as String?,
      minLength: jsonSchema['minLength'] as int?,
      maxLength: jsonSchema['maxLength'] as int?,
      pattern: jsonSchema['pattern'] as String?,
    );
  }

  static <TargetSchema> _convertInteger(IntegerSchema schema) {
    final jsonSchema = schema.toJsonSchema();

    return _buildIntegerSchema(
      description: schema.description,
      nullable: schema.isNullable,
      minimum: jsonSchema['minimum'] as num?,
      maximum: jsonSchema['maximum'] as num?,
      exclusiveMinimum: jsonSchema['exclusiveMinimum'] as bool?,
      exclusiveMaximum: jsonSchema['exclusiveMaximum'] as bool?,
    );
  }

  static <TargetSchema> _convertDouble(DoubleSchema schema) {
    final jsonSchema = schema.toJsonSchema();

    return _buildNumberSchema(
      description: schema.description,
      nullable: schema.isNullable,
      minimum: jsonSchema['minimum'] as num?,
      maximum: jsonSchema['maximum'] as num?,
    );
  }

  static <TargetSchema> _convertBoolean(BooleanSchema schema) {
    return _buildBooleanSchema(
      description: schema.description,
      nullable: schema.isNullable,
    );
  }

  // ========================================================================
  // Complex Type Converters
  // ========================================================================

  static <TargetSchema> _convertObject(ObjectSchema schema) {
    final jsonSchema = schema.toJsonSchema();

    // Convert each property recursively
    final properties = <String, <TargetSchema>>{};
    for (final entry in schema.properties.entries) {
      properties[entry.key] = _convertSchema(entry.value);
    }

    // Determine which properties are required
    final required = jsonSchema['required'] as List<String>?;
    final optionalProperties = properties.keys
        .where((key) => !(required?.contains(key) ?? false))
        .toList();

    return _buildObjectSchema(
      properties: properties,
      optionalProperties: optionalProperties,
      description: schema.description,
      nullable: schema.isNullable,
      additionalProperties: schema.additionalProperties,
    );
  }

  static <TargetSchema> _convertArray(ListSchema schema) {
    // Convert item schema recursively
    final itemSchema = _convertSchema(schema.itemSchema);
    final jsonSchema = schema.toJsonSchema();

    return _buildArraySchema(
      items: itemSchema,
      description: schema.description,
      nullable: schema.isNullable,
      minItems: jsonSchema['minItems'] as int?,
      maxItems: jsonSchema['maxItems'] as int?,
    );
  }

  static <TargetSchema> _convertEnum(EnumSchema schema) {
    final jsonSchema = schema.toJsonSchema();
    final enumValues = (jsonSchema['enum'] as List)
        .cast<String>()
        .toList();

    return _buildEnumSchema(
      enumValues,
      schema,
    );
  }

  static <TargetSchema> _convertAnyOf(AnyOfSchema schema) {
    // Convert each branch
    final branches = schema.schemas
        .map(_convertSchema)
        .toList();

    return _buildAnyOfSchema(
      branches: branches,
      description: schema.description,
      nullable: schema.isNullable,
    );
  }

  static <TargetSchema> _convertDiscriminated(
    DiscriminatedObjectSchema schema,
  ) {
    // Option 1: If target supports discriminated unions natively
    // return _buildDiscriminatedSchema(...);

    // Option 2: Convert to anyOf with discriminator enum injected
    final branches = <TargetSchema>[];

    for (final entry in schema.schemas.entries) {
      final discriminatorValue = entry.key;
      final branchSchema = entry.value;

      // Convert branch and inject discriminator
      final convertedBranch = _convertSchema(branchSchema);
      branches.add(
        _injectDiscriminatorField(
          convertedBranch,
          schema.discriminatorKey,
          discriminatorValue,
        ),
      );
    }

    return _buildAnyOfSchema(
      branches: branches,
      description: schema.description,
      nullable: schema.isNullable,
    );
  }

  static <TargetSchema> _convertAny(AnySchema schema) {
    // Most schema systems don't have a true "any" type
    // Common approaches:
    // 1. Empty object (allows anything)
    // 2. Union of all primitive types
    // 3. Target-specific "any" type if available

    return _buildAnySchema(
      description: schema.description,
      nullable: schema.isNullable,
    );
  }

  static <TargetSchema> _handleTransformed(TransformedSchema schema) {
    // Option 1: Throw error (safest)
    throw UnsupportedError(
      'TransformedSchema cannot be converted to <Target> format. '
      'Convert the underlying schema instead.',
    );

    // Option 2: Extract and convert underlying schema (if target supports metadata)
    // return _convertSchema(schema.underlyingSchema);
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
    // TODO: Implement using target SDK
    throw UnimplementedError('Implement _buildStringSchema');
  }

  static <TargetSchema> _buildIntegerSchema({
    String? description,
    bool nullable = false,
    num? minimum,
    num? maximum,
    bool? exclusiveMinimum,
    bool? exclusiveMaximum,
  }) {
    // TODO: Implement using target SDK
    throw UnimplementedError('Implement _buildIntegerSchema');
  }

  static <TargetSchema> _buildNumberSchema({
    String? description,
    bool nullable = false,
    num? minimum,
    num? maximum,
  }) {
    // TODO: Implement using target SDK
    throw UnimplementedError('Implement _buildNumberSchema');
  }

  static <TargetSchema> _buildBooleanSchema({
    String? description,
    bool nullable = false,
  }) {
    // TODO: Implement using target SDK
    throw UnimplementedError('Implement _buildBooleanSchema');
  }

  static <TargetSchema> _buildObjectSchema({
    required Map<String, <TargetSchema>> properties,
    List<String>? optionalProperties,
    String? description,
    bool nullable = false,
    bool additionalProperties = false,
  }) {
    // TODO: Implement using target SDK
    throw UnimplementedError('Implement _buildObjectSchema');
  }

  static <TargetSchema> _buildArraySchema({
    required <TargetSchema> items,
    String? description,
    bool nullable = false,
    int? minItems,
    int? maxItems,
  }) {
    // TODO: Implement using target SDK
    throw UnimplementedError('Implement _buildArraySchema');
  }

  static <TargetSchema> _buildEnumSchema(
    List<String> enumValues,
    AckSchema schema,
  ) {
    // TODO: Implement using target SDK
    throw UnimplementedError('Implement _buildEnumSchema');
  }

  static <TargetSchema> _buildAnyOfSchema({
    required List<<TargetSchema>> branches,
    String? description,
    bool nullable = false,
  }) {
    // TODO: Implement using target SDK
    throw UnimplementedError('Implement _buildAnyOfSchema');
  }

  static <TargetSchema> _buildAnySchema({
    String? description,
    bool nullable = false,
  }) {
    // TODO: Implement using target SDK
    throw UnimplementedError('Implement _buildAnySchema');
  }

  static <TargetSchema> _injectDiscriminatorField(
    <TargetSchema> schema,
    String discriminatorKey,
    String discriminatorValue,
  ) {
    // TODO: Implement discriminator field injection
    throw UnimplementedError('Implement _injectDiscriminatorField');
  }

  // ========================================================================
  // Helper Methods - Type Coercion
  // ========================================================================

  /// Safely converts a value to int, handling num types.
  static int? _asInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return null;
  }

  /// Safely converts a value to double, handling num types.
  static double? _asDouble(Object? value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return null;
  }

  /// Reads enum values from JSON Schema.
  static List<String>? _readEnumValues(Map<String, Object?> json) {
    final rawEnum = json['enum'];
    if (rawEnum == null) return null;
    if (rawEnum is! List) return null;

    return rawEnum
        .whereType<String>()
        .toList();
  }
}
```

**Key patterns**:
1. **Private constructor** - Prevent instantiation
2. **Static converter methods** - Pure functions
3. **Switch expression** - Type-safe routing
4. **JSON Schema bridge** - Reuse ACK's `toJsonSchema()`
5. **Helper builders** - Wrap target SDK API
6. **Type coercion** - Handle num/int/double safely

---

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
        final jsonSchema = Ack.string().toJsonSchema();
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

### Phase 4: Documentation (1-2 hours)

#### 4.1 README.md Template

```markdown
# ack_<target>

<Target System> schema converter for the [ACK](https://pub.dev/packages/ack) validation library.

[![pub package](https://img.shields.io/pub/v/ack_<target>.svg)](https://pub.dev/packages/ack_<target>)

## Overview

Converts ACK schemas to <Target> format for [use case]. Assumes familiarity with [ACK](https://pub.dev/packages/ack) and [target system].

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

// 4. ALWAYS validate with ACK after
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

| ACK Type | <Target> Type | Notes |
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

| ACK Constraint | <Target> | Notes |
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

This package is part of the [ACK](https://github.com/btwld/ack) monorepo.

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
- Extension method `.to<Target>Schema()` for converting ACK schemas
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

### Pattern 1: JSON Schema Bridge

**When to use**: Target system uses JSON Schema-compatible format

**Implementation**:
```dart
static TargetSchema _convertString(StringSchema schema) {
  // 1. Get JSON Schema representation
  final jsonSchema = schema.toJsonSchema();

  // 2. Extract relevant fields
  final format = jsonSchema['format'] as String?;
  final minLength = jsonSchema['minLength'] as int?;

  // 3. Build target schema
  return TargetSchema.string(
    format: format,
    minLength: minLength,
    description: schema.description,
  );
}
```

**Pros**: Reuses ACK's existing JSON Schema logic
**Cons**: Indirect, may include unused fields

### Pattern 2: Direct Conversion

**When to use**: Target has very different schema model

**Implementation**:
```dart
static TargetSchema _convertString(StringSchema schema) {
  // 1. Access schema properties directly
  final constraints = schema.constraints;

  // 2. Extract constraint values
  int? minLength;
  for (final constraint in constraints) {
    if (constraint is StringMinLengthConstraint) {
      minLength = constraint.minLength;
    }
  }

  // 3. Build target schema
  return TargetSchema.string(
    minLength: minLength,
    description: schema.description,
  );
}
```

**Pros**: Precise, no intermediate steps
**Cons**: More code, must handle each constraint type

### Pattern 3: Hybrid Approach

**When to use**: Most cases (recommended)

**Implementation**:
```dart
static TargetSchema _convertString(StringSchema schema) {
  // Use JSON Schema for standard fields
  final jsonSchema = schema.toJsonSchema();

  // Access schema directly for target-specific handling
  final isNullable = schema.isNullable;

  return TargetSchema.string(
    format: jsonSchema['format'] as String?,
    nullable: isNullable ? true : null,
    description: schema.description,
  );
}
```

**Pros**: Balance of convenience and control
**Cons**: Some duplication

---

## Common Patterns

### Handling TransformedSchema

**Option 1: Reject** (Recommended for most cases)
```dart
if (schema is TransformedSchema) {
  throw UnsupportedError(
    'TransformedSchema cannot be converted to <Target> format. '
    'Convert the underlying schema instead.',
  );
}
```

**Option 2: Extract Underlying** (If target supports metadata overrides)
```dart
if (schema is TransformedSchema) {
  // Extract underlying schema
  final underlying = schema.underlyingSchema;

  // Convert with metadata from transformed schema
  final converted = _convertSchema(underlying);

  // Apply metadata overrides
  return _applyMetadata(
    converted,
    description: schema.description,
    nullable: schema.isNullable,
  );
}
```

### Handling Discriminated Unions

**Option 1: Native Support** (If target has discriminators)
```dart
static TargetSchema _convertDiscriminated(
  DiscriminatedObjectSchema schema,
) {
  return TargetSchema.discriminated(
    discriminatorKey: schema.discriminatorKey,
    branches: {
      for (final entry in schema.schemas.entries)
        entry.key: _convertSchema(entry.value),
    },
  );
}
```

**Option 2: AnyOf with Injected Discriminator** (Fallback)
```dart
static TargetSchema _convertDiscriminated(
  DiscriminatedObjectSchema schema,
) {
  final branches = <TargetSchema>[];

  for (final entry in schema.schemas.entries) {
    final discriminatorValue = entry.key;
    final branchSchema = entry.value;

    // Convert branch
    final converted = _convertSchema(branchSchema);

    // Inject discriminator enum
    final withDiscriminator = _injectField(
      converted,
      schema.discriminatorKey,
      TargetSchema.enumString([discriminatorValue]),
    );

    branches.add(withDiscriminator);
  }

  return TargetSchema.anyOf(branches);
}
```

### Handling AnySchema

**Option 1: Empty Object** (Most permissive)
```dart
static TargetSchema _convertAny(AnySchema schema) {
  return TargetSchema.object(
    properties: const {},
    additionalProperties: true,
  );
}
```

**Option 2: Union of Primitives** (More restrictive)
```dart
static TargetSchema _convertAny(AnySchema schema) {
  return TargetSchema.anyOf([
    TargetSchema.string(),
    TargetSchema.integer(),
    TargetSchema.number(),
    TargetSchema.boolean(),
    TargetSchema.array(items: TargetSchema.any()),
    TargetSchema.object(properties: const {}),
  ]);
}
```

**Option 3: Target-Specific Any** (If available)
```dart
static TargetSchema _convertAny(AnySchema schema) {
  return TargetSchema.any(
    description: schema.description,
    nullable: schema.isNullable,
  );
}
```

### Type Coercion Helpers

```dart
/// Safely converts a value to int, handling num types.
static int? _asInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  return null;
}

/// Safely converts a value to double, handling num types.
static double? _asDouble(Object? value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return null;
}

/// Reads enum values from JSON Schema, filtering non-strings.
static List<String>? _readEnumValues(Map<String, Object?> json) {
  final rawEnum = json['enum'];
  if (rawEnum == null) return null;
  if (rawEnum is! List) return null;

  return rawEnum.whereType<String>().toList();
}

/// Safely reads boolean from JSON, defaulting to false.
static bool _readBool(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is bool) return value;
  return false;
}
```

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
    return _convertSchema(schema);
  }

  static Map<String, Object?> _convertSchema(AckSchema schema) {
    // OpenAPI uses JSON Schema Draft 2020-12
    final jsonSchema = schema.toJsonSchema();

    return switch (schema) {
      StringSchema() => _convertString(schema, jsonSchema),
      IntegerSchema() => _convertInteger(schema, jsonSchema),
      DoubleSchema() => _convertNumber(schema, jsonSchema),
      BooleanSchema() => _convertBoolean(schema, jsonSchema),
      ObjectSchema() => _convertObject(schema, jsonSchema),
      ListSchema() => _convertArray(schema, jsonSchema),
      EnumSchema() => _convertEnum(schema, jsonSchema),
      AnyOfSchema() => _convertAnyOf(schema),
      _ => throw UnsupportedError(
          'Schema type ${schema.runtimeType} not supported',
        ),
    };
  }

  static Map<String, Object?> _convertString(
    StringSchema schema,
    Map<String, Object?> json,
  ) {
    return {
      'type': 'string',
      if (schema.description != null) 'description': schema.description,
      if (json['format'] != null) 'format': json['format'],
      if (json['minLength'] != null) 'minLength': json['minLength'],
      if (json['maxLength'] != null) 'maxLength': json['maxLength'],
      if (json['pattern'] != null) 'pattern': json['pattern'],
      if (json['enum'] != null) 'enum': json['enum'],
    };
  }

  // ... other converters
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
    _convertToSDL(schema, typeName, buffer);
    return buffer.toString();
  }

  static void _convertToSDL(
    AckSchema schema,
    String typeName,
    StringBuffer buffer,
  ) {
    if (schema is ObjectSchema) {
      buffer.writeln('type $typeName {');

      for (final entry in schema.properties.entries) {
        final fieldName = entry.key;
        final fieldSchema = entry.value;
        final gqlType = _getGraphQLType(fieldSchema);
        final isRequired = !fieldSchema.isOptional;
        final nullableSuffix = isRequired ? '!' : '';

        if (fieldSchema.description != null) {
          buffer.writeln('  """${fieldSchema.description}"""');
        }
        buffer.writeln('  $fieldName: $gqlType$nullableSuffix');
      }

      buffer.writeln('}');
    } else {
      throw UnsupportedError(
        'Only ObjectSchema can be converted to GraphQL types. '
        'Got: ${schema.runtimeType}',
      );
    }
  }

  static String _getGraphQLType(AckSchema schema) {
    return switch (schema) {
      StringSchema() => 'String',
      IntegerSchema() => 'Int',
      DoubleSchema() => 'Float',
      BooleanSchema() => 'Boolean',
      ListSchema(:final itemSchema) => '[${_getGraphQLType(itemSchema)}]',
      EnumSchema() => _generateEnumType(schema),
      _ => 'String', // Fallback
    };
  }

  static String _generateEnumType(EnumSchema schema) {
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
- Identify gaps vs ACK features
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
- Use ACK's `toJsonSchema()` as a bridge when possible
- Write tests first (TDD approach)
- Document limitations as you discover them

**For help**:
- Create GitHub issue: https://github.com/btwld/ack/issues
- Reference this guide
- Ask specific questions about target system
