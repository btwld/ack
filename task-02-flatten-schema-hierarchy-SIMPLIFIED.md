# Task 2: Remove ScalarSchema (Simplified)

## Overview
**ONLY** remove the intermediate ScalarSchema layer if it's genuinely unused and causing maintenance issues.

## Before Proceeding - Validation Required

### Step 1: Check if ScalarSchema is actually a problem
```bash
# Check if ScalarSchema is referenced anywhere important
rg "ScalarSchema" --type dart packages/ack/lib/
rg "extends ScalarSchema" --type dart packages/ack/lib/

# Check inheritance usage
rg "super\." --type dart packages/ack/lib/src/schemas/
```

### Step 2: Verify it's safe to remove
```bash
# Look for any complex logic in ScalarSchema
cat packages/ack/lib/src/schemas/schema.dart | grep -A 20 "class ScalarSchema"

# Check if type conversion logic is complex
rg "_tryConvertType|_tryParseNum|_tryParseString" --type dart packages/ack/lib/
```

## Implementation (Only if removal is beneficial)

### If ScalarSchema is truly just an empty intermediate layer:

1. **Move type conversion logic directly to concrete classes**
2. **Update inheritance:** `StringSchema extends AckSchema<String>` instead of `ScalarSchema`
3. **Remove ScalarSchema class definition**
4. **Run tests**

### Changes Required:
- `StringSchema extends AckSchema<String>`
- `BooleanSchema extends AckSchema<bool>`  
- `IntegerSchema extends AckSchema<int>`
- `DoubleSchema extends AckSchema<double>`

## Success Criteria
- [ ] All tests pass
- [ ] No new functionality added
- [ ] Simpler inheritance hierarchy
- [ ] Same type conversion behavior

## Exit Criteria (Skip if any of these are true)
- ScalarSchema contains important shared logic
- Type conversion is complex and working well
- Removal requires more than 2-3 hours of work
- Any risk of breaking existing functionality

**Principle: Only remove it if it's obviously dead weight**