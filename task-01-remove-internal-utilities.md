# Task 1: Remove Internal Unused Utilities

## Overview
Remove over-engineered internal utilities that add complexity without proportional value while preserving all public API functionality.

## Investigation Summary
After thorough analysis, identified **300+ lines** of internal complexity that can be safely removed or simplified without affecting public APIs.

## Detailed Implementation Plan

### Phase 1: Safe Removals (Zero Risk)

#### 1.1 Remove Template System
**Files to Modify:**
- `/packages/ack/lib/src/utils/template.dart` (DELETE - 171 lines)
- `/packages/ack/lib/ack.dart` (Remove export line)

**Justification:**
- Exported but has **zero production usage**
- Only used in unit tests
- Classic case of speculative generality

**Implementation Steps:**
```bash
# 1. Verify no actual usage
rg "Template" --type dart packages/ack/lib/src/ -A 2 -B 2

# 2. Remove export from main library
# Remove line: export 'src/utils/template.dart';

# 3. Delete the file
rm packages/ack/lib/src/utils/template.dart

# 4. Run tests to ensure no breakage
melos test
```

**Risk Level:** ZERO - No production usage found

#### 1.2 Remove String Similarity Matching
**Files to Modify:**
- `/packages/ack/lib/src/helpers.dart` (Remove lines 10-101, ~91 lines)
- `/packages/ack/lib/src/constraints/validators.dart` (Simplify StringEnumConstraint)

**Current Usage:**
- Only used in `StringEnumConstraint` for error message suggestions
- Performance overhead for minimal UX benefit

**Implementation Steps:**
```bash
# 1. Replace complex similarity with simple alternative
# In StringEnumConstraint, replace:
findClosestStringMatch(value, values) 

# With simple alternative:
String? _findSimpleMatch(String value, List<String> allowed) {
  final lower = value.toLowerCase();
  return allowed.firstWhereOrNull(
    (item) => item.toLowerCase().startsWith(lower.substring(0, math.min(2, lower.length)))
  );
}

# 2. Remove levenshtein and findClosestStringMatch functions
# 3. Update tests for StringEnumConstraint
```

**Risk Level:** LOW - Only affects error message quality

#### 1.3 Remove Empty Test Helpers
**Files to Modify:**
- `/packages/ack/test/test_helpers.dart` (DELETE - empty file)

**Implementation Steps:**
```bash
rm packages/ack/test/test_helpers.dart
```

**Risk Level:** ZERO - File is empty

### Phase 2: Simplifications (Low Risk)

#### 2.1 Simplify IterableExt Extensions
**Files to Modify:**
- `/packages/ack/lib/src/helpers.dart` (lines 127-160)

**Changes:**
- Remove `firstWhereOrNull` (redundant with Dart SDK)
- Remove unused `areUnique`/`areNotUnique` getters
- Remove unused `containsAll`/`getNonContainedValues`
- Keep only `duplicates` getter (has legitimate usage)

**Implementation Steps:**
```dart
// Keep only this extension:
extension IterableExt<E> on Iterable<E> {
  /// Returns duplicate elements in this iterable
  Iterable<E> get duplicates {
    final seen = <E>{};
    final duplicates = <E>{};
    for (final element in this) {
      if (!seen.add(element)) {
        duplicates.add(element);
      }
    }
    return duplicates;
  }
}
```

**Risk Level:** LOW - Removes unused convenience methods

#### 2.2 Simplify Builder Helpers
**Files to Modify:**
- `/packages/ack/lib/src/builder_helpers/schema_registry.dart`
- `/packages/ack/lib/src/builder_helpers/type_service.dart`
- `/packages/ack/lib/ack.dart` (Remove exports)

**Strategy:**
- Move to `ack_generator` package as internal utilities
- Remove from main library exports
- Keep functionality but make it generator-specific

**Implementation Steps:**
```bash
# 1. Move files to generator package
mv packages/ack/lib/src/builder_helpers/* packages/ack_generator/lib/src/utils/

# 2. Remove exports from main library
# Remove: export 'src/builder_helpers/schema_registry.dart';

# 3. Update generator imports
# Update packages/ack_generator/lib/src/ files to use local imports
```

**Risk Level:** MEDIUM - Affects generated code, needs careful testing

#### 2.3 Simplify JSON Schema Converter
**Files to Modify:**
- `/packages/ack/lib/src/utils/json_schema.dart`

**Changes:**
- Remove LLM response parsing functionality if unused
- Simplify exception hierarchy
- Focus on core JSON schema generation

**Investigation Needed:**
```bash
# Check usage of LLM parsing functions
rg "parseJsonFromLLMResponse|LLMParsingException" --type dart packages/
```

**Risk Level:** MEDIUM - Need to verify LLM parsing usage

### Phase 3: Minor Cleanups (Low Risk)

#### 3.1 Replace TruthyCheck Extension
**Files to Modify:**
- `/packages/ack/lib/src/validation/schema_error.dart`

**Change:**
```dart
// Replace JavaScript-style truthiness:
if (value.isTruthy) 

// With explicit null check:
if (value != null)
```

**Risk Level:** LOW - Simple replacement

## Testing Strategy

### Pre-Implementation Testing
```bash
# 1. Run full test suite to establish baseline
melos test

# 2. Check for any references to code being removed
rg "Template|findClosestStringMatch|levenshtein" --type dart packages/

# 3. Verify exports are only used internally
rg "import.*template|import.*builder_helpers" --type dart packages/
```

### Post-Implementation Testing
```bash
# 1. Run full test suite
melos test

# 2. Run analysis
melos analyze

# 3. Build generator examples
melos build

# 4. Test code generation
cd example && dart run build_runner build
```

## Success Criteria
- [ ] All tests pass
- [ ] No analysis warnings
- [ ] Code generation still works
- [ ] Public API unchanged
- [ ] Documentation builds successfully
- [ ] Performance unchanged or improved

## Rollback Plan
```bash
# Git rollback if issues found
git checkout -- packages/ack/lib/src/helpers.dart
git checkout -- packages/ack/lib/src/utils/
git checkout -- packages/ack/lib/ack.dart
```

## Risk Assessment

| Change | Risk Level | Impact | Mitigation |
|--------|------------|--------|------------|
| Remove Template | ZERO | None - unused | N/A |
| Remove String Similarity | LOW | Error message quality | Simple replacement |
| Remove Empty Files | ZERO | None | N/A |
| Simplify Extensions | LOW | Remove unused methods | Keep core functionality |
| Move Builder Helpers | MEDIUM | Generated code | Thorough testing |
| Simplify JSON Converter | MEDIUM | JSON schema features | Usage verification |

## Estimated Impact
- **Code Reduction:** 300+ lines
- **Maintenance Reduction:** Eliminates complex algorithms
- **Performance:** Removes unnecessary computations
- **API Surface:** Cleaner exports
- **Implementation Time:** 4-6 hours

## Dependencies
- No external dependencies
- All changes are internal implementation
- Public API remains unchanged

## Follow-up Tasks
After completion:
1. Update documentation to remove references to removed utilities
2. Consider adding linter rules to prevent similar over-engineering
3. Review other packages for similar patterns

---

**Next Task:** Task 2 - Flatten Schema Inheritance Hierarchy