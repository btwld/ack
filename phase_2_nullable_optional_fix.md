# Phase 2: Fix Nullable/Optional Semantics

## Overview
Fix the fundamental semantic confusion between "optional" (field can be missing) and "nullable" (field can be null) in the Ack framework. This phase separates these orthogonal concepts to match JSON Schema 2020-12 standards.

## Problem Statement

### Current Issues
1. **OptionalSchema forces `isNullable = true`** (line 20 in optional_schema.dart)
2. **Cannot express "optional non-nullable"** - a field that can be missing but if present, cannot be null
3. **JSON Schema generation mixes concepts** - uses both `required` array and type arrays inconsistently
4. **Validation workflow confusion** - null handling happens before type checking

### The Four Required Cases
| Case | Field Presence | Value Type | JSON Schema | Current Ack | Issue |
|------|---------------|------------|-------------|-------------|-------|
| 1 | Required | Non-null | `required: ["field"], type: "string"` | `Ack.string()` | ✅ Works |
| 2 | Required | Nullable | `required: ["field"], type: ["string", "null"]` | `Ack.string().nullable()` | ✅ Works |
| 3 | Optional | Non-null | `type: "string"` (not in required) | `Ack.string().optional()` | ❌ Forces nullable |
| 4 | Optional | Nullable | `type: ["string", "null"]` (not in required) | `Ack.string().nullable().optional()` | ✅ Works but verbose |

## Current Implementation Analysis

### OptionalSchema Current Behavior
```dart
OptionalSchema({
  required this.wrappedSchema,
  // ...
}) : super(
  schemaType: wrappedSchema.schemaType,
  isNullable: true,  // ❌ FORCES NULLABLE
);

@override
SchemaResult<DartType> parseAndValidate(Object? input, context) {
  if (inputValue == null) {
    // Missing field returns null without error
    return SchemaResult.ok(null);  // ❌ Always allows null
  }
  return wrappedSchema.parseAndValidate(inputValue, context);
}
```

### Object Schema Field Detection
```dart
if (!hasValue && !schema.isOptional) {
  // Missing required property - ERROR
}
// If hasValue is false and schema.isOptional is true, we skip
```

**Issue**: No way to detect that a field is present but explicitly set to null vs missing entirely.

## Solution Design

### 1. Introduce Missing Field Marker
```dart
// Add to schema.dart
class _MissingField {
  const _MissingField();
  @override
  String toString() => '<missing>';
}

const _missingFieldMarker = _MissingField();
```

### 2. Fix OptionalSchema
```dart
// Type-safety: Optional values are nullable at the API boundary.
final class OptionalSchema<T extends Object> extends AckSchema<T?> {
  OptionalSchema({
    required this.wrappedSchema,
    // ...
  }) : super(
    schemaType: wrappedSchema.schemaType,
    isNullable: false, // Optional ≠ nullable; nullability stays explicit
  );

  final AckSchema<T> wrappedSchema;

  @override
  List<JsonType> get acceptedTypes {
    // Optional doesn't add the null JSON type. Use .nullable() explicitly for that.
    return wrappedSchema.acceptedTypes;
  }

  @override
  SchemaResult<T?> parseAndValidate(Object? input, context) {
    // Distinguish truly-missing from present-null.
    if (identical(input, _missingFieldMarker)) {
      // Missing field → omit from output; represent as null at this wrapper layer.
      return SchemaResult.ok(null);
    }

    // Field is present (could be null) → delegate to wrapped schema.
    return wrappedSchema.parseAndValidate(input, context)
        .cast<T?>();
  }
}
```

### 3. Update Object Schema Validation
```dart
@override
SchemaResult<Map> parseAndValidate(Object? input, context) {
  final map = input as Map;
  final result = <String, Object?>{};

  for (final entry in properties.entries) {
    final key = entry.key;
    final schema = entry.value;
    final hasKey = map.containsKey(key);

    if (!hasKey) {
      if (!schema.isOptional) {
        return SchemaResult.fail(RequiredFieldMissingError(key, context.path));
      }
      // Pass missing marker to optional schema
      final fieldResult = schema.parseAndValidate(
        _missingFieldMarker,
        context.createChild(name: key, schema: schema, value: null, pathSegment: key)
      );
      if (fieldResult.isOk) {
        final value = fieldResult.getOrThrow();
        if (value != null) {  // Don't add missing fields to result
          result[key] = value;
        }
      } else {
        return fieldResult;
      }
    } else {
      // Field is present - validate the actual value
      final fieldValue = map[key];
      final fieldResult = schema.parseAndValidate(
        fieldValue,
        context.createChild(name: key, schema: schema, value: fieldValue, pathSegment: key)
      );
      if (fieldResult.isOk) {
        result[key] = fieldResult.getOrThrow();
      } else {
        return fieldResult;
      }
    }
  }

  return SchemaResult.ok(result);
}
```

### 5. Defaults Policy (Simplified)
- JSON Schema “default” is an annotation. Core validation does not auto‑insert defaults.
- If the library offers a convenience “apply defaults” utility, it should be a separate, opt‑in post‑validation transform — not part of the validation pipeline. This avoids duplicating behavior from other packages and keeps validation pure.

### 4. Add Explicit Nullable Extension
```dart
extension NullableSchema<T extends Object> on AckSchema<T> {
  AckSchema<T?> nullable() {
    return NullableWrapperSchema(wrappedSchema: this);
  }
}

class NullableWrapperSchema<T extends Object> extends AckSchema<T?> {
  final AckSchema<T> wrappedSchema;

  NullableWrapperSchema({required this.wrappedSchema})
      : super(
          schemaType: wrappedSchema.schemaType,
          isNullable: true,
        );

  @override
  List<JsonType> get acceptedTypes {
    return [...wrappedSchema.acceptedTypes, JsonType.nil];
  }

  @override
  SchemaResult<T?> parseAndValidate(Object? input, context) {
    if (input == null) {
      return SchemaResult.ok(null);
    }
    return wrappedSchema.parseAndValidate(input, context);
  }

  @override
  Map<String, Object?> toJsonSchema() {
    final baseSchema = wrappedSchema.toJsonSchema();
    final baseType = baseSchema['type'];

    return {
      ...baseSchema,
      'type': switch (baseType) {
        String type => [type, 'null'],
        List types => [...types, 'null'],
        _ => ['null'],
      },
    };
  }
}
```

## Implementation Steps

### Step 1: Add Missing Field Infrastructure
1. Add `_MissingField` class and marker to schema.dart
2. Update imports in object_schema.dart
3. Add tests for missing field detection

### Step 2: Fix OptionalSchema
1. Remove `isNullable: true` from constructor
2. Update `parseAndValidate` to handle missing marker and return `T?`
3. Add tests for all four cases:
   - Optional present non-null ✅
   - Optional present null (should fail for non-nullable)
   - Optional missing (should succeed)
   - (Defaults application is out of scope for core validation)

### Step 3: Update Object Schema
1. Modify field validation loop
2. Pass missing marker for absent fields
3. Update error messages for clarity
4. Add comprehensive tests

### Step 4: Add Nullable Extension
1. Create `NullableWrapperSchema` class
2. Add `.nullable()` extension method
3. Update JSON schema generation
4. Add tests for nullable behavior

### Step 5: Update Existing Schemas
1. Review all schema types for consistency
2. Update JSON schema generation to use `acceptedTypes`
3. Ensure backward compatibility

## Test Cases

### Case 1: Required Non-null
```dart
test('required non-null field', () {
  final schema = Ack.object({'name': Ack.string()});

  // Valid
  expect(schema.validate({'name': 'John'}), isSuccess);

  // Invalid - missing
  expect(schema.validate({}), isFail);

  // Invalid - null
  expect(schema.validate({'name': null}), isFail);
});
```

### Case 2: Required Nullable
```dart
test('required nullable field', () {
  final schema = Ack.object({'age': Ack.integer().nullable()});

  // Valid - number
  expect(schema.validate({'age': 25}), isSuccess);

  // Valid - null
  expect(schema.validate({'age': null}), isSuccess);

  // Invalid - missing
  expect(schema.validate({}), isFail);
});
```

### Case 3: Optional Non-null (THE FIX!)
```dart
test('optional non-null field', () {
  final schema = Ack.object({'email': Ack.string().optional()});

  // Valid - present
  expect(schema.validate({'email': 'test@example.com'}), isSuccess);

  // Valid - missing
  expect(schema.validate({}), isSuccess);

  // Invalid - null (THIS SHOULD FAIL NOW!)
  expect(schema.validate({'email': null}), isFail);
});
```

### Case 4: Optional Nullable
```dart
test('optional nullable field', () {
  final schema = Ack.object({'nickname': Ack.string().nullable().optional()});

  // Valid - present
  expect(schema.validate({'nickname': 'Johnny'}), isSuccess);

  // Valid - null
  expect(schema.validate({'nickname': null}), isSuccess);

  // Valid - missing
  expect(schema.validate({}), isSuccess);
});
```

## JSON Schema Output

### Before (Incorrect)
```json
{
  "type": "object",
  "properties": {
    "email": {"type": ["string", "null"]},  // Wrong! Forces nullable
  },
  "required": ["name"]  // email not required, but nullable
}
```

### After (Correct)
```json
{
  "type": "object",
  "properties": {
    "name": {"type": "string"},                    // required non-null
    "age": {"type": ["integer", "null"]},          // required nullable
    "email": {"type": "string"},                   // optional non-null
    "nickname": {"type": ["string", "null"]}       // optional nullable
  },
  "required": ["name", "age"]  // Both name and age required
}
```

## Migration Guide

### For Users - Minimal Breaking Change
```dart
// Before: This worked but was semantically wrong
'email': Ack.string().optional()  // Allowed null!

// After: Must be explicit about nullability
'email': Ack.string().optional()           // Only missing or string
'email': Ack.string().nullable().optional() // Missing, null, or string
```

### API Compatibility
- ✅ `.nullable()` continues to work
- ✅ `.optional()` continues to work
- ⚠️ `.optional()` now correctly rejects null (breaking change for incorrect usage)
- ✅ All other APIs unchanged

## Risk Assessment

### High Risk
- **Breaking change**: Optional fields that were incorrectly accepting null will now fail
- **User confusion**: Need clear migration guide

### Mitigation
1. **Gradual rollout**: Add deprecation warnings first
2. **Clear error messages**: "Field 'email' cannot be null. Use .nullable().optional() if null is allowed"
3. **Migration tool**: Scan codebases for `.optional()` usage
4. **Documentation**: Clear examples of all four cases

### Rollback Plan
1. Keep old `OptionalSchema` as `LegacyOptionalSchema`
2. Add feature flag to switch between implementations
3. If needed, restore old behavior with deprecation warnings

## Success Metrics
1. ✅ All four semantic cases expressible
2. ✅ JSON Schema output matches JSON Schema 2020-12
3. ✅ Clear, predictable validation behavior
4. ✅ Backward compatibility for correct usage
5. ✅ Performance unchanged or improved

## Timeline
- **Week 1**: Steps 1-2 (Infrastructure + OptionalSchema fix)
- **Week 2**: Steps 3-4 (Object Schema + Nullable extension)
- **Week 3**: Step 5 + Testing (Schema updates + comprehensive tests)
- **Week 4**: Documentation + Migration tools

This phase establishes the correct foundation for nullable/optional semantics that aligns with JSON Schema standards while maintaining Dart's type safety benefits.
