# Codebase Review: DRY & YAGNI Analysis

**Date:** 2025-12-27
**Branch:** `claude/codebase-review-dry-yagni-oQTTE`
**Method:** Atom of Thought Reasoning

---

## Executive Summary

This review identifies **3 critical DRY violations**, **2 important YAGNI violations**, and provides **3 refactored code solutions**. The largest improvement opportunity is extracting the repeated `toJsonSchema()` nullable pattern across 9 schema classes (~180 lines saved).

---

## Atomic Analysis

### Atom 1: Structure Map

| Component | Location | Responsibility |
|-----------|----------|----------------|
| `AckSchema` (sealed) | `packages/ack/lib/src/schemas/schema.dart:29` | Base schema class with validation core |
| `StringSchema` | `packages/ack/lib/src/schemas/string_schema.dart:16` | String validation |
| `IntegerSchema` | `packages/ack/lib/src/schemas/num_schema.dart:61` | Integer validation |
| `DoubleSchema` | `packages/ack/lib/src/schemas/num_schema.dart:131` | Double validation |
| `BooleanSchema` | `packages/ack/lib/src/schemas/boolean_schema.dart:16` | Boolean validation |
| `ObjectSchema` | `packages/ack/lib/src/schemas/object_schema.dart:5` | Object/Map validation |
| `ListSchema` | `packages/ack/lib/src/schemas/list_schema.dart:5` | List validation |
| `EnumSchema` | `packages/ack/lib/src/schemas/enum_schema.dart:5` | Enum validation |
| `AnySchema` | `packages/ack/lib/src/schemas/any_schema.dart:9` | Dynamic value acceptance |
| `ComparisonConstraint` | `packages/ack/lib/src/constraints/comparison_constraint.dart:14` | Numeric/length comparisons |
| `PatternConstraint` | `packages/ack/lib/src/constraints/pattern_constraint.dart:14` | String pattern/format validation |
| `AckSchemaGenerator` | `packages/ack_generator/lib/src/generator.dart:22` | Code generation from annotations |

---

### Atom 2: DRY Violations

#### Critical: Repeated `toJsonSchema()` Nullable Pattern (9 files)

The identical nullable/non-nullable branching logic appears in every schema class:

**File:** `packages/ack/lib/src/schemas/string_schema.dart:60-85`
```dart
@override
Map<String, Object?> toJsonSchema() {
  if (isNullable) {
    final baseSchema = {
      'type': 'string',
      if (description != null) 'description': description,
    };
    final mergedSchema = mergeConstraintSchemas(baseSchema);
    return {
      if (defaultValue != null) 'default': defaultValue,
      'anyOf': [
        mergedSchema,
        {'type': 'null'},
      ],
    };
  }

  final schema = {
    'type': 'string',
    if (description != null) 'description': description,
    if (defaultValue != null) 'default': defaultValue,
  };

  return mergeConstraintSchemas(schema);
}
```

**Repeated in:**
- `boolean_schema.dart:60-84`
- `num_schema.dart:22-46`
- `list_schema.dart:115-141`
- `object_schema.dart:192-237`
- `enum_schema.dart:120-148`
- `any_schema.dart:66-94`

#### Important: Pattern Detection Logic in ComparisonConstraint (3x)

**File:** `packages/ack/lib/src/constraints/comparison_constraint.dart:268-337`
```dart
// Lines 269-277 (ComparisonType.gte)
final isStringLength =
    constraintKey.startsWith('string_') &&
    (constraintKey.contains('length') || constraintKey.contains('exact'));
final isListItems = constraintKey.startsWith('list_');
final isObjectProperties = constraintKey.startsWith('object_');

// SAME PATTERN REPEATED at lines 283-291 (ComparisonType.lte)
// SAME PATTERN REPEATED at lines 310-314 (ComparisonType.range)
```

#### Important: Enum Suggestion Building (3 locations)

**File:** `packages/ack/lib/src/constraints/pattern_constraint.dart:135-141`
```dart
final closest = findClosestStringMatch(v, values);
final suggestion = closest != null && closest != v
    ? ' Did you mean "$closest"?'
    : '';
```

**Duplicated at:**
- `pattern_constraint.dart:284-287` (buildMessage)
- `enum_schema.dart:74-77`

---

### Atom 3: YAGNI Violations

#### Important: Unused BuilderOptions Parameter

**File:** `packages/ack_generator/lib/src/builder.dart:7-9`
```dart
Builder ackGenerator(BuilderOptions options) {
  return LibraryBuilder(AckSchemaGenerator(), generatedExtension: '.g.dart');
}
```
The `options` parameter is never used. Configuration in `build.yaml` (`verbose: false`) is dead code.

#### Minor: Deprecated Backward Compatibility Methods

**File:** `packages/ack/lib/src/schemas/schema.dart:257-267`
```dart
@Deprecated('Use safeParse(...) instead.')
SchemaResult<DartType> validate(Object? value, {String? debugName}) =>
    safeParse(value, debugName: debugName);

@Deprecated('Use safeParse(...).getOrNull() instead.')
DartType? tryParse(Object? value, {String? debugName}) { ... }
```

**File:** `packages/ack/lib/src/schemas/fluent_schema.dart:19-22`
```dart
@Deprecated('Use describe() instead. Will be removed in a future version.')
Schema withDescription(String description) => ...
```

---

### Atom 4: Data Flow Issues

#### Double JSON Schema Conversion

**File:** `packages/ack/lib/src/converters/ack_to_json_schema_model.dart:10-13`
```dart
JsonSchema _convert(AckSchema schema) {
  final parsed = JsonSchema.fromJson(schema.toJsonSchema());  // First conversion
  // ... then builds JsonSchema again
```

The code converts schema to Map, parses to JsonSchema, then rebuilds. Consider direct property access.

---

### Atom 5: Abstraction Audit

| Abstraction | Verdict | Notes |
|-------------|---------|-------|
| `AckSchema` sealed class | Good | Central to design, enforces type safety |
| `FluentSchema` mixin | Good | Cleanly separates fluent API, reused by 9 classes |
| `Constraint<T>` base | Good | Clean constraint system with mixins |
| `SchemaResult<T>` sealed | Good | Standard Result pattern |
| `JsonSchema` model | Good | Canonical intermediate representation |

---

### Atom 6: Missing Abstractions

1. **JSON Schema Generation Helper** - A helper in `AckSchema` for nullable handling
2. **Constraint Category Enum** - Type-safe categorization instead of string matching
3. **Suggestion Builder Utility** - Shared "Did you mean...?" logic

---

### Atom 7: Naming Issues

| Location | Current Name | Suggestion |
|----------|--------------|------------|
| `comparison_constraint.dart:19` | `multipleValue` | `multipleOfValue` |
| `pattern_constraint.dart:7` | `PatternType.format` | `PatternType.customValidator` |

---

## Prioritized Recommendations

### 1. [Critical] Extract toJsonSchema Helper Method
- **What:** Create protected helper in `AckSchema` for nullable JSON Schema generation
- **Where:** `packages/ack/lib/src/schemas/schema.dart`
- **Why:** Eliminates ~180 lines of duplicate code across 9 schema classes
- **Impact:** High

### 2. [Important] Extract Constraint Category Detection
- **What:** Create enum and helper to categorize constraint keys
- **Where:** `packages/ack/lib/src/constraints/comparison_constraint.dart`
- **Why:** Same string pattern matching repeated 3 times
- **Impact:** Medium

### 3. [Important] Create Suggestion Builder Utility
- **What:** Extract "Did you mean...?" logic to shared function
- **Where:** `packages/ack/lib/src/utils/string_utils.dart`
- **Why:** Same pattern in 3 locations
- **Impact:** Medium

### 4. [Minor] Remove Unused BuilderOptions
- **What:** Use `_` for unused parameter
- **Where:** `packages/ack_generator/lib/src/builder.dart:7`
- **Impact:** Low

---

## Refactored Code

### Fix 1: Extract toJsonSchema Helper (Critical)

Add to `packages/ack/lib/src/schemas/schema.dart`:

```dart
/// Builds JSON Schema with proper nullable handling.
@protected
Map<String, Object?> buildJsonSchemaWithNullable({
  required Map<String, Object?> baseTypeSchema,
  Object? defaultValue,
}) {
  if (isNullable) {
    final mergedSchema = mergeConstraintSchemas({
      ...baseTypeSchema,
      if (description != null) 'description': description,
    });
    return {
      if (defaultValue != null) 'default': defaultValue,
      'anyOf': [
        mergedSchema,
        {'type': 'null'},
      ],
    };
  }

  final schema = {
    ...baseTypeSchema,
    if (description != null) 'description': description,
    if (defaultValue != null) 'default': defaultValue,
  };

  return mergeConstraintSchemas(schema);
}
```

Then in each schema class:
```dart
@override
Map<String, Object?> toJsonSchema() {
  return buildJsonSchemaWithNullable(
    baseTypeSchema: {'type': 'string'},
    defaultValue: defaultValue,
  );
}
```

### Fix 2: Extract Constraint Category Detection

Add to `packages/ack/lib/src/constraints/comparison_constraint.dart`:

```dart
enum _ConstraintCategory { stringLength, listItems, objectProperties, numeric }

_ConstraintCategory _categorize(String constraintKey) {
  if (constraintKey.startsWith('string_') &&
      (constraintKey.contains('length') || constraintKey.contains('exact'))) {
    return _ConstraintCategory.stringLength;
  }
  if (constraintKey.startsWith('list_')) return _ConstraintCategory.listItems;
  if (constraintKey.startsWith('object_')) return _ConstraintCategory.objectProperties;
  return _ConstraintCategory.numeric;
}
```

### Fix 3: Create Suggestion Builder Utility

Add to `packages/ack/lib/src/utils/string_utils.dart`:

```dart
/// Builds a "Did you mean...?" suggestion string.
String buildDidYouMeanSuggestion(String value, List<String> allowedValues) {
  final closest = findClosestStringMatch(value, allowedValues);
  if (closest != null && closest != value) {
    return ' Did you mean "$closest"?';
  }
  return '';
}
```

---

## Summary Statistics

| Category | Count | Lines Affected |
|----------|-------|----------------|
| Critical DRY Violations | 1 | ~180 lines |
| Important DRY Violations | 2 | ~45 lines |
| YAGNI Violations | 2 | ~15 lines |
| Missing Abstractions | 3 | N/A |
| Naming Issues | 2 | N/A |

**Total potential lines saved:** ~240 lines through recommended refactoring.
