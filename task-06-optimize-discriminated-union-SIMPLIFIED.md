# Task 6: Fix Discriminated Union Structure Validation (Simplified)

## Overview
**ONLY** move structure validation to construction time if it's actually causing performance issues.

## Before Proceeding - Validation Required

### Step 1: Check if structure validation is actually a problem
```bash
# Look at current implementation
cat packages/ack/lib/src/schemas/discriminated_object_schema.dart

# Check if structure validation runs on every validation call
rg "discriminator.*validate|validate.*discriminator" --type dart packages/ack/lib/

# Look for ObjectDiscriminatorStructureConstraint usage
rg "ObjectDiscriminatorStructureConstraint" --type dart packages/ack/lib/
```

### Step 2: Verify it's actually slow
```bash
# Create simple benchmark to test current performance
# Only proceed if validation is measurably slow
```

## Implementation (Only if there's a real performance issue)

### Current Problem (if it exists):
- Schema structure validation happens on every validation call
- Should only happen once at construction time

### Simple Fix:
1. **Move validation to constructor**
2. **Cache validated structure**
3. **Remove redundant runtime checks**

### Changes Required:
```dart
class DiscriminatedObjectSchema {
  DiscriminatedObjectSchema({
    required String discriminatorKey,
    required Map<String, ObjectSchema> schemas,
  }) {
    // Validate structure ONCE at construction
    _validateStructure(discriminatorKey, schemas);
    // Store for runtime use
    _discriminatorKey = discriminatorKey;
    _validatedSchemas = schemas;
  }
}
```

## Success Criteria
- [ ] Structure validation only runs at construction
- [ ] Same validation behavior
- [ ] Measurably faster validation (if that was the problem)
- [ ] All tests pass

## Exit Criteria (Skip if any of these are true)
- Current validation is already fast enough
- Structure validation doesn't run redundantly
- Change requires more than 2-3 hours of work
- No measurable performance benefit

**Principle: Only fix it if it's obviously broken**