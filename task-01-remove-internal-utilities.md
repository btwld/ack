# Task 1: Remove Internal Unused Utilities

## Overview
Remove over-engineered internal utilities that add complexity without proportional value while preserving all public API functionality.

## Investigation Summary
After thorough analysis, identified **300+ lines** of internal complexity that can be safely removed or simplified without affecting public APIs.

## ✅ 2024-2025 Validation Update
**Research Confirmation (June 2025):**
- Current Dart best practices strongly support dead code elimination
- DCM tooling emphasizes removing unused code to reduce maintenance costs
- Modern Dart compilers include built-in tree shaking and dead code elimination
- All identified utilities confirmed as still unused in production code
- Task remains **HIGH PRIORITY** and **LOW RISK**

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
# 1. Verify no actual usage with modern DCM tooling
dcm check-unused-code packages/ack/lib/
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

**Current Usage (2025 Update):**
- Used in `PatternConstraint` and enum validations for error message suggestions
- Performance overhead for minimal UX benefit
- Modern error handling patterns favor simpler approaches

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
# 1. Run DCM analysis for comprehensive unused code detection
dcm check-unused-code packages/ack/lib/
dcm check-unused-files packages/ack/

# 2. Run full test suite to establish baseline
melos test

# 3. Check for any references to code being removed
rg "Template|findClosestStringMatch|levenshtein" --type dart packages/

# 4. Verify exports are only used internally
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
2. Integrate DCM into CI pipeline for continuous dead code detection
3. Consider adding linter rules to prevent similar over-engineering
4. Review other packages for similar patterns using DCM tooling

## Modern Tooling Integration (2025)
**DCM Integration:**
```bash
# Add to CI pipeline for continuous monitoring
dcm check-unused-code --ci packages/ack/lib/

# Regular maintenance checks
dcm check-unused-files packages/ack/
```

**Benefits of DCM Integration:**
- Automated detection of future dead code
- Continuous code quality monitoring
- Integration with CI/CD pipelines
- Reduced manual code review overhead

## 📋 Atomic Task Execution Plan

### Task Dependencies and Execution Order

**Prerequisites (Must Complete First):**
1. `pre-test-baseline` - Run DCM analysis and establish testing baseline
2. `verify-usage-patterns` - Verify current usage patterns of utilities to be removed

**Phase 1: Zero Risk Removals**
3. `remove-template-system` - Remove Template system (template.dart file and export)
4. `remove-empty-test-helpers` - Remove empty test_helpers.dart file

**Phase 2: Low Risk Simplifications**
5. `simplify-string-similarity` - Replace complex string similarity with simple alternative
6. `simplify-iterable-extensions` - Simplify IterableExt extensions, keep only duplicates getter
7. `replace-truthy-checks` - Replace JavaScript-style truthiness with explicit null checks

**Phase 3: Medium Risk Investigations & Changes**
8. `investigate-builder-helpers` - Investigate builder helpers usage before moving to ack_generator
9. `investigate-json-schema-llm` - Investigate LLM parsing usage in JSON schema converter

**Final Validation:**
10. `run-final-tests` - Run comprehensive test suite and validation
11. `update-documentation` - Update documentation to remove references to removed utilities

### Task Status Tracking

| Task ID | Description | Risk Level | Dependencies | Status |
|---------|-------------|------------|--------------|--------|
| pre-test-baseline | DCM analysis baseline | N/A | None | ⏳ Pending |
| verify-usage-patterns | Verify utility usage | N/A | None | ⏳ Pending |
| remove-template-system | Remove Template system | ZERO | 1,2 | ⏳ Pending |
| remove-empty-test-helpers | Remove empty test file | ZERO | 1,2 | ⏳ Pending |
| simplify-string-similarity | Simplify string matching | LOW | 1,2 | ⏳ Pending |
| simplify-iterable-extensions | Simplify extensions | LOW | 1,2 | ⏳ Pending |
| replace-truthy-checks | Replace truthy checks | LOW | 1,2 | ⏳ Pending |
| investigate-builder-helpers | Check builder helpers | MEDIUM | 1,2 | ⏳ Pending |
| investigate-json-schema-llm | Check LLM parsing | MEDIUM | 1,2 | ⏳ Pending |
| run-final-tests | Final validation | N/A | 3-9 | ⏳ Pending |
| update-documentation | Update docs | N/A | 10 | ⏳ Pending |

### Execution Commands for Each Task

**Task 1: pre-test-baseline**
```bash
dcm check-unused-code packages/ack/lib/
dcm check-unused-files packages/ack/
melos test
```

**Task 2: verify-usage-patterns**
```bash
rg "Template|findClosestStringMatch|levenshtein" --type dart packages/
rg "import.*template|import.*builder_helpers" --type dart packages/
```

**Task 3: remove-template-system**
```bash
# Remove export from packages/ack/lib/ack.dart
# Delete packages/ack/lib/src/utils/template.dart
melos test
```

**Task 4: remove-empty-test-helpers**
```bash
rm packages/ack/test/test_helpers.dart
```

**Task 5-9: [Implementation specific commands listed above]**

**Task 10: run-final-tests**
```bash
melos test
melos analyze
melos build
```

---

**Next Task:** Task 2 - Flatten Schema Inheritance Hierarchy