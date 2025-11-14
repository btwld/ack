# Known Issues

This document tracks critical bugs discovered during code audits. These issues are actively being worked on and will be resolved in upcoming releases.

## Status Legend

- **CRITICAL - HIGH IMPACT**: Affects core functionality, blocks common use cases
- **MEDIUM IMPACT**: Affects edge cases or has workarounds available
- **LOW IMPACT**: Minor issues with minimal user impact

---

## Critical Issues

### 1. List Type Extraction Bug (CRITICAL - HIGH IMPACT)

**Status:** Known issue, fix in progress

**Location:** `/home/user/ack/packages/ack_generator/lib/src/analyzer/schema_ast_analyzer.dart` lines 447-475

**Description:**

The generator extracts `List<dynamic>` instead of proper typed lists when using schema variable references or inline Ack schema definitions. This results in loss of type safety across ALL generated code that uses lists.

**Root Cause:**

The `_extractListType()` method only handles direct `Ack.list(Ack.string())` patterns but falls back to `List<dynamic>` for schema variable references and other valid patterns.

**Example - This fails:**

```dart
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

@AckType()
final userSchema = Ack.object({
  'tags': Ack.list(Ack.string()),  // ❌ Generates List<dynamic>
  'scores': Ack.list(Ack.integer()),  // ❌ Generates List<dynamic>
});
```

**Generated (incorrect):**

```dart
extension type UserSchema(Map<String, dynamic> _args) {
  List<dynamic> get tags => _args['tags'] as List<dynamic>;  // ❌ Wrong!
  List<dynamic> get scores => _args['scores'] as List<dynamic>;  // ❌ Wrong!
}
```

**Expected (correct):**

```dart
extension type UserSchema(Map<String, dynamic> _args) {
  List<String> get tags => (_args['tags'] as List).cast<String>();
  List<int> get scores => (_args['scores'] as List).cast<int>();
}
```

**Impact:**

- Loss of type safety in generated code
- Users cannot rely on typed list operations
- Runtime type errors become more likely
- Affects ALL models using list fields

**Workaround:**

Currently, there is **no workaround** that preserves type safety. Users should:

1. Be aware generated lists are `List<dynamic>`
2. Manually cast list elements when needed
3. Add runtime type checks where necessary

**Related Tests:**

See `/home/user/ack/packages/ack_generator/test/bugs/schema_variable_bugs_test.dart` for reproduction tests:
- `should extract String type from Ack.list(Ack.string())`
- `should extract int type from Ack.list(Ack.integer())`
- `should handle nested lists (List<List<T>>)`

---

### 2. Nested Schema References Bug (CRITICAL - HIGH IMPACT)

**Status:** Known issue, fix in progress

**Location:** `/home/user/ack/packages/ack_generator/lib/src/analyzer/schema_ast_analyzer.dart` lines 317-341

**Description:**

Schema variable references are typed as `Map<String, dynamic>` rather than resolving to the actual schema type. While the current implementation intentionally uses `Map<String, dynamic>` to avoid complex resolution, this blocks common compositional patterns and can cause fields to disappear from generated code.

**Root Cause:**

The `_parseFieldValue()` method treats `SimpleIdentifier` (schema variable references) as `Map<String, dynamic>` without actually resolving the referenced schema's structure. This is intentional to simplify implementation but creates usability issues.

**Example - This fails:**

```dart
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

@AckType()
final addressSchema = Ack.object({
  'street': Ack.string(),
  'city': Ack.string(),
  'zipCode': Ack.string(),
});

@AckType()
final userSchema = Ack.object({
  'name': Ack.string(),
  'address': addressSchema,  // ❌ Field may be silently ignored
});
```

**Generated (problematic):**

```dart
extension type UserSchema(Map<String, dynamic> _args) {
  String get name => _args['name'] as String;
  Map<String, dynamic> get address => _args['address'] as Map<String, dynamic>;
}
```

The `address` field loses all type information about its structure (street, city, zipCode).

**Impact:**

- Users blocked from compositional schema patterns
- Loss of type safety for nested objects
- Cannot reuse schema definitions across models
- Fields may disappear or become untyped Maps

**Workaround:**

**Option 1: Inline all schemas** (recommended for now)

```dart
@AckType()
final userSchema = Ack.object({
  'name': Ack.string(),
  'address': Ack.object({  // ✅ Inline instead of reference
    'street': Ack.string(),
    'city': Ack.string(),
    'zipCode': Ack.string(),
  }),
});
```

**Option 2: Use dart_mappable or other serialization libraries** for nested types where full type safety is required.

**Related Tests:**

See `/home/user/ack/packages/ack_generator/test/bugs/schema_variable_bugs_test.dart` for reproduction tests:
- `should resolve schema variable reference`
- `should handle multiple schema references`

---

## Medium Impact Issues

### 3. Method Chain Walker Safety (MEDIUM IMPACT)

**Status:** Known issue, mitigation recommended

**Location:** Multiple locations in `schema_ast_analyzer.dart`

**Description:**

The method chain walker (which processes chained method calls like `.optional().nullable()`) has no depth limits or cycle detection. Deep method chains could cause performance issues or infinite loops.

**Root Cause:**

The while loop that walks method chains (processing `.optional()`, `.nullable()`, etc.) has no iteration counter or maximum depth check.

**Example - Potentially problematic:**

```dart
@AckType()
final deepSchema = Ack.object({
  // Extremely deep chain (25+ calls)
  'field': Ack.string()
    .optional()
    .nullable()
    .optional()
    .nullable()
    // ... 20+ more chained calls ...
    .optional(),
});
```

**Impact:**

- Deep method chains (20+ calls) may cause slow builds
- No clear error messages for excessive chaining
- Potential for infinite loops if circular references exist
- Performance degradation during code generation

**Workaround:**

**Keep method chains reasonable:**

```dart
// ✅ Good: 2-3 chained calls
'field': Ack.string().optional().nullable(),

// ⚠️ Avoid: Deep chains
'field': Ack.string().optional().nullable().optional().nullable()...,
```

**Recommended depth limit:** Maximum 5-10 chained method calls per field.

**Related Tests:**

See `/home/user/ack/packages/ack_generator/test/bugs/schema_variable_bugs_test.dart`:
- `should handle normal method chains correctly`
- `should prevent infinite loops with deeply nested chains`

---

## Additional Information

### Reporting New Issues

If you discover a bug not listed here:

1. Check the [GitHub Issues](https://github.com/btwld/ack/issues) to see if it's already reported
2. Create a minimal reproduction case
3. Submit a new issue with:
   - Clear description of the problem
   - Code example showing the bug
   - Expected vs actual behavior
   - Version of `ack_generator` you're using

### Contributing Fixes

We welcome contributions! If you'd like to help fix these issues:

1. See the test files in `/home/user/ack/packages/ack_generator/test/bugs/` for reproduction cases
2. Review the affected code in `schema_ast_analyzer.dart`
3. Follow the [Contributing Guidelines](./README.md#contributing)
4. Ensure all tests pass with `melos test`

### Staying Updated

- Watch the [GitHub repository](https://github.com/btwld/ack) for updates
- Check the [CHANGELOG.md](./CHANGELOG.md) for fixed issues in new releases
- Subscribe to release notifications to know when fixes are published

---

**Last Updated:** 2025-11-14

**Affected Versions:** v1.0.0-beta.2 and earlier

**Next Steps:** These issues are prioritized for the next patch release. Follow the workarounds above until fixes are available.
