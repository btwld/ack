# Production Readiness Review — ack v1.0.0

**Date:** 2026-02-25
**Scope:** Full monorepo (5 packages, ~99 test files, docs site, CI/CD)
**Current version:** 1.0.0-beta.7

---

## Executive Summary

The ack validation library is well-architected with consistent patterns, strong type safety, and good test coverage. However, several issues should be addressed before a 1.0.0 release. This review identified **8 critical/high-priority items**, **15 medium-priority items**, and **12 low-priority items** across all checklist categories.

### Top Blockers for 1.0.0

| # | Issue | Category | Severity |
|---|-------|----------|----------|
| 1 | `packages/ack/README.md` is empty (0 bytes) — this is the pub.dev landing page | Documentation | **CRITICAL** |
| 2 | Deprecated APIs (`validate()`, `tryParse()`, `withDescription()`, `StringSchema.enumString()`, `StringSchema.literal()`) still ship — decide: remove or keep with migration path | API Surface | **HIGH** |
| 3 | `schemas_instructions.md` references non-existent methods (`validateOrThrow`, `parseOrThrow`) | Documentation | **HIGH** |
| 4 | IPv6 regex lacks `^$` anchors — correctness bug + performance concern | Security | **HIGH** |
| 5 | `safeParse()` can throw on `Map<int, dynamic>` input via `.cast()` — violates never-throws guarantee | Core Logic | **HIGH** |
| 6 | Error messages echo full input values — data leakage risk for sensitive fields | Security | **HIGH** |
| 7 | No depth limit on nested validation — stack overflow on adversarial input | Security | **HIGH** |
| 8 | `topics` field missing from ALL pubspec.yaml files — impacts pub.dev discoverability | Metadata | **HIGH** |

---

## 1. API Surface & Public Contract

### 1.1 Deprecated APIs

Five deprecated APIs were found that will ship with 1.0.0:

| API | Location | Deprecation Message | Recommendation |
|-----|----------|-------------------|----------------|
| `validate()` | `schema.dart:373` | Use `safeParse()` instead | **Remove** — aliases safeParse, no unique behavior |
| `tryParse()` | `schema.dart:378` | Use `safeParse().getOrNull()` | **Remove** — trivial wrapper |
| `withDescription()` | `fluent_schema.dart:20` | Use `describe()` instead | **Remove** — exact same behavior |
| `StringSchema.enumString()` | `string_schema_extensions.dart:128` | Use `Ack.enumString()` | **Remove** — moved to top-level API |
| `StringSchema.literal()` | `string_schema_extensions.dart:135` | Use `Ack.literal()` | **Remove** — moved to top-level API |

**Decision needed:** These are beta-era APIs. For a clean 1.0.0, removing them avoids permanent API surface commitment. If kept, the deprecation messages serve as migration paths.

### 1.2 Barrel Exports

`packages/ack/lib/ack.dart` exports 13 paths. Review of exported symbols:
- Core API entry point `src/ack.dart` — clean
- Constraints: only `constraint.dart` and `datetime_constraint.dart` are public (good)
- Extensions: 6 extension files exported — these become permanent API surface
- JSON Schema, validation errors, schema results — all appropriate

**Findings:**
- `TestUnsupportedAckSchema` in `testing/testing_schemas.dart` is included via `part of 'schema.dart'` and is `@visibleForTesting` but publicly accessible. This is a test utility leaking into the public API.
- `wrapPropertyConversion` is exported through `json_schema.dart` → `json_schema_utils.dart`. Used by `ack_json_schema_builder` integration package. Consider whether this should be a public API.
- `convertJsonSchemaToBuilder()` in `ack_json_schema_builder` is public but only used in tests. Consider `@visibleForTesting`.

### 1.3 Sealed Class Exhaustiveness

**`AckSchema<DartType>`** — sealed with all subtypes accounted for:

| Subtype | Modifier | Notes |
|---------|----------|-------|
| `StringSchema` | `final` | |
| `NumSchema<T>` | `sealed` | Intermediate sealed class |
| → `IntegerSchema` | `final` | Extends `NumSchema<int>` |
| → `DoubleSchema` | `final` | Extends `NumSchema<double>` |
| `BooleanSchema` | `final` | |
| `ObjectSchema` | `final` | |
| `ListSchema<V>` | `final` | |
| `EnumSchema<T>` | `final` | |
| `AnyOfSchema` | `final` | |
| `AnySchema` | `final` | |
| `DiscriminatedObjectSchema` | `final` | |
| `TransformedSchema<I,O>` | **`class`** (not `final`) | Cosmetic — sealed hierarchy prevents external subclassing |
| `TestUnsupportedAckSchema` | `final` | `@visibleForTesting` — test utility |

**`SchemaResult<T>`** — sealed with `Ok<T>` and `Fail<T>`. Both are `class` (not `final`), but sealed hierarchy prevents external subclassing.

### 1.4 Public Method Naming Consistency

| Method | Available On | Notes |
|--------|-------------|-------|
| `parse()` | All schemas | Throws `AckException` on failure |
| `safeParse()` | All schemas | Returns `SchemaResult` |
| `parseAs()` | All schemas (added beta.6) | Maps validated value |
| `safeParseAs()` | All schemas (added beta.6) | Safe version of parseAs |

**Consistent across all schema types.** The naming convention (`parse`/`safeParse` + `As` variants) is clean and well-structured.

### 1.5 Extension Methods Visibility

All extension methods in the 6 exported extension files are public. Key extensions:
- `AckSchemaExtensions` — `nullable()`, `optional()`, `transform()`, `refine()`
- `StringSchemaExtensions` — `minLength()`, `maxLength()`, `email()`, `uuid()`, `url()`, etc.
- `NumericExtensions` — `min()`, `max()`, `positive()`, `negative()`, etc.
- `ListSchemaExtensions` — `minItems()`, `maxItems()`, `uniqueItems()`
- `ObjectSchemaExtensions` — `strict()`, `passthrough()`, `merge()`, `partial()`, `extend()`, `pick()`, `omit()`
- `DateTimeSchemaExtensions` — `min()`, `max()`

**All appropriate for public API.** No internal-only extensions found in exported files. No private extensions (`extension _...`) exist in the codebase.

**Note:** `ListSchemaExtensions` has redundant aliases (`minItems`/`minLength`, `maxItems`/`maxLength`, `nonEmpty`/`notEmpty`, `exactLength`/`length`) which doubles the API surface for lists. The aliasing is documented as "mirroring documentation naming."

---

## 2. Breaking Changes & Versioning

### 2.1 CHANGELOG Completeness

| Location | Status | Issue |
|----------|--------|-------|
| Root `CHANGELOG.md` | **POOR** | Last real entry is beta.2 (Oct 2025). Beta.3–7 undocumented. Contains 6x duplicated `0.3.0-beta.1` entries |
| `packages/ack/CHANGELOG.md` | Adequate | Beta.3 and beta.7 are "see release notes" only |
| `packages/ack_annotations/CHANGELOG.md` | Adequate | Documents beta.6 breaking change (required → requiredMode) |
| `packages/ack_generator/CHANGELOG.md` | Adequate | Good detail for beta.4–6 |
| `packages/ack_firebase_ai/CHANGELOG.md` | Fair | Missing version link references for beta.2–4, 6–7 |
| `packages/ack_json_schema_builder/CHANGELOG.md` | **POOR** | Missing beta.2 and beta.3 entries entirely |

**Action:** Clean up root CHANGELOG and fill gaps before 1.0.0.

### 2.2 Inter-Package Version Constraints

| Package | Depends On | Constraint | Assessment |
|---------|-----------|------------|------------|
| `ack_generator` | `ack` | `^1.0.0-beta.7` | Needs update to `^1.0.0` for release |
| `ack_generator` | `ack_annotations` | `^1.0.0-beta.7` | Needs update to `^1.0.0` for release |
| `ack_firebase_ai` | `ack` | `^1.0.0-beta.7` | Needs update to `^1.0.0` for release |
| `ack_json_schema_builder` | `ack` | `^1.0.0-beta.7` | Needs update to `^1.0.0` for release |

### 2.3 SDK Constraints

- `sdk: '>=3.8.0 <4.0.0'` — Dart 3.8 is very recent (released ~2025). This excludes users on stable Dart 3.6 or 3.7. **Intentional** since the library uses Dart workspace features (`resolution: workspace`).
- `analyzer: '>=7.0.0 <9.0.0'` — Wide range for generator compatibility. Should be tested on both boundaries.

### 2.4 Migration Path from Beta

The beta.6 `AckField.required` → `requiredMode` breaking change is documented in `ack_annotations/CHANGELOG.md`. However, there is no consolidated migration guide. The `docs/guides/migration-v1.mdx` exists but is not linked from the sidebar (orphaned page).

---

## 3. Core Logic & Correctness

### 3.1 Strict vs. Lenient Parsing — PASS

Consistent across all primitive types. Each schema has `strictPrimitiveParsing` field with `.strictParsing()` fluent method. Coercion matrix is centralized in `SchemaType.canAcceptFrom()`.

**Minor notes:**
- Loose mode allows `"NaN"` → `double.nan` via string coercion (document this)
- Boolean coercion only accepts `"true"`/`"false"` (not `"1"`/`"0"` or `"yes"`/`"no"`) — by design

### 3.2 ObjectSchema Additional Properties — PASS with concern

- Defaults to `additionalProperties: false` (safe default)
- Unknown properties produce clear per-key errors

**Bug:** `object_schema.dart:47-49` — `.cast<String, Object?>()` can throw on `Map<int, dynamic>` input, violating safeParse's never-throws guarantee:
```dart
final mapValue = inputValue is Map<String, Object?>
    ? inputValue
    : inputValue.cast<String, Object?>();  // Can throw!
```
**Fix:** Wrap in try-catch or use a safer conversion.

### 3.3 DiscriminatedObjectSchema Edge Cases — PASS with concern

- Missing discriminator: clear error with `ObjectRequiredPropertiesConstraint`
- Unknown discriminator value: error with allowed values + "did you mean?" suggestion
- Nested types: correctly enforces `AckSchema<MapValue>` type constraint at compile time

**Bug:** `{'type': null}` produces misleading "Required property 'type' is missing" instead of "Discriminator must be a non-null string." The code doesn't distinguish between missing key and null value.

### 3.4 EnumSchema Matching — PASS

Three matching modes (exact enum, string name, integer index) work correctly. Index matching on enum subsets could surprise users (index 0 = first value in subset, not first in declaration).

### 3.5 TransformedSchema Error Propagation — PASS

Clean error propagation. Transform exceptions properly wrapped in `SchemaTransformError` with cause and stack trace. Maintains safeParse's never-throws guarantee.

### 3.6 AnyOfSchema — PASS with documentation gap

**First-match-wins semantics are correct but undocumented.** Combined with loose-mode coercion, this means `Ack.anyOf([Ack.string(), Ack.integer()])` will ALWAYS coerce integers to strings (because StringSchema accepts ints in loose mode). This is a significant behavioral surprise.

**Action:** Document that order matters and recommend strict parsing on member schemas.

### 3.7 Nullable/Optional Interaction — PASS

**Order does NOT matter.** `.nullable().optional()` produces identical schema to `.optional().nullable()`. Both are independent boolean flags that compose orthogonally.

### 3.8 withDefault() Behavior — PASS

- Default takes priority over nullable (null input triggers default, not `Ok(null)`)
- Defaults are deep-cloned via `cloneDefault()` to prevent shared-state mutation
- Defaults are validated against schema constraints

**Note:** Cloned defaults produce unmodifiable Maps/Lists while normally-parsed values are mutable — potential surprise for users.

---

## 4. JSON Schema Compliance

### 4.1 Conformance Testing — GOOD

Three major test files provide comprehensive coverage:

1. **Zod Conformance Tests** (`json_schema_zod_conformance_test.dart`) — Loads 60+ reference fixtures generated by Zod v4, covering all schema types with all constraint combinations. Round-trip parsing (`JSON → JsonSchema → JSON`) verified.

2. **Round-Trip Tests** (`json_schema_roundtrip_test.dart`) — 741 lines covering all primitives, composition types, edge cases, union type normalization (`type: ['string', 'null']` → `anyOf` pattern).

3. **Comprehensive JSON Schema Tests** (`comprehensive_json_schema_test.dart`) — Verifies `toJsonSchema()` output from ACK schema builders.

**Gap:** No tests against the official JSON Schema Test Suite (https://github.com/json-schema-org/JSON-Schema-Test-Suite). Tests rely on Zod-generated fixtures, which may miss spec edge cases.

### 4.2 toJsonSchema() Coverage — COMPLETE

All 11 schema types implement `toJsonSchema()`:
- All use `buildJsonSchemaWithNullable()` for consistent nullable wrapping (`anyOf: [{schema}, {type: null}]`)
- `additionalProperties: true` emits `{}` (empty schema) instead of `true` — valid but non-standard
- `TransformedSchema` adds `x-transformed: true` — good custom annotation practice
- `EnumSchema` serializes values as string names — correct
- `DiscriminatedObjectSchema` uses `anyOf` in direct output, `oneOf` in `AckToJsonSchemaModel` converter (correct for each context)

Dual conversion paths exist:
1. Direct `toJsonSchema()` returning `Map<String, Object?>` (legacy)
2. `AckToJsonSchemaModel` converter producing structured `JsonSchema` model objects (used by integration packages)

### 4.3 ack_firebase_ai Limitations — Well Documented

7 documented limitations in README with workarounds:
1. Gemini doesn't enforce schemas (hints only)
2. String length not enforced (Firebase AI SDK limitation)
3. Refinements unsupported
4. Regex patterns limited
5. Default values not passed
6. `oneOf` converted to `anyOf`
7. Transformed schemas supported (metadata overrides work)

Test coverage: 1000+ lines with snapshot matching against expected `firebase_ai.Schema` output.

### 4.4 ack_json_schema_builder — Correct

- Targets JSON Schema Draft 2020-12 via `json_schema_builder` package
- Nullable wrapping correct: `_wrapNullable()` produces `anyOf: [base, Schema.nil()]`
- `_effective()` helper prevents double-wrapping of already-nullable schemas

---

## 5. Code Generator

### 5.1 Golden Tests — Adequate with Gap

Three golden tests exist in `golden_test.dart` (User schema, complex nested, additional properties). However, these use **inline `contains` assertions**, not on-disk golden file comparisons. Formatting or ordering regressions may not be caught.

The `validateGeneratedCode` helper (runs `dart analyze` on generated output) is **defined but never called** in the current golden tests.

**Recommendation:** Add actual `.g.dart` golden files for snapshot diffing.

### 5.2 Edge Case Tests — Comprehensive

Coverage includes:
- Empty classes, static-only fields, abstract classes, non-class targets
- Nested models (3 levels deep), lists of nested models
- Generic types, inherited fields
- Contradictory annotations (required + nullable)
- Very long annotation values
- All `@AckField` × `@AckModel` combinations tested

### 5.3 Circular Reference Handling — Adequate

`TypeBuilder.topologicalSort()` implements DFS with cycle detection. On cycle, falls back to original order with logged warning (safe because extension types wrap `Map<String, Object?>`).

**Gap:** No explicit integration test for mutual references (A → B → A). Only self-references tested in `ModelValidator`.

### 5.4 CodeValidator — Clean

Uses the official `analyzer` package's `parseString` for syntax validation. Semantic errors (undefined identifiers) are correctly ignored since generated code references types from source files.

### 5.5 @AckType Extension Type Generation — Thorough

Extensively tested including:
- Same-file and cross-file schema references
- Prefixed imports (`import 'x.dart' as y`)
- Re-exported schemas
- Optional/nullable modifiers
- Alias schema declarations
- Error cases (unresolved references, missing annotations)

### 5.6 Build Configuration — Correct

`build.yaml`: `auto_apply: dependents`, `build_to: source`, generates `.g.dart` files. Standard `source_gen` `LibraryBuilder` configuration.

---

## 6. Error Messages & Developer Experience

### 6.1 SchemaError Subtypes

| Error Type | Use Case | Message Quality |
|-----------|----------|----------------|
| `TypeMismatchError` | Wrong type provided | "Expected {type}, got {type}" — **GOOD** |
| `SchemaConstraintsError` | Constraint violations | Lists all violations — **GOOD** |
| `SchemaNestedError` | Nested object failures | Wraps child errors — **GOOD** |
| `SchemaValidationError` | Generic validation failure | Custom message — **GOOD** |
| `SchemaTransformError` | Transform function failure | Includes cause + stack trace — **GOOD** |

### 6.2 Error Paths

Error paths are constructed via `SchemaContext.createChild()` with `pathSegment` parameters. Paths like `user.address.zipCode` are correctly built through the context chain.

### 6.3 Constraint Error Messages

Constraint messages include expected vs. actual values:
- String length: `"minLength"` / `"maxLength"` constraints with comparison operators
- Enum: Lists all allowed values + "Did you mean?" suggestions via Levenshtein distance
- Email: `'Invalid email format. Expected format like user@example.com, got "$v".'`

### 6.4 "Did You Mean?" Suggestions

`findClosestStringMatch()` in `string_utils.dart` uses Levenshtein distance with a configurable threshold. Only runs on strings 3–20 characters (performance guard). Excellent DX feature.

---

## 7. Performance

### 7.1 Existing Performance Tests

`packages/ack/test/performance/basic_performance_test.dart` exists but only tests:
- 10 levels of nesting
- 1000 iterations for throughput measurement

**Recommendation:** Add benchmarks for deeply nested objects (100+ levels), large lists (10K+ items), and generator build times for large models.

### 7.2 Nesting Depth

Validation is recursive with no depth limit. O(n) for depth n, but stack overflow risk for malicious input (see Security section).

### 7.3 Schema Construction

Immutable schemas use `copyWith()` for each fluent method call (e.g., `.minLength(2).maxLength(50).email()`). Each call allocates a new schema object. This is fine for schema construction (done once at startup) but should not be done in hot paths.

---

## 8. Documentation

### 8.1 Documentation Tests

Two test files covering overview and API docs examples:
- `test/documentation/overview_doc_examples_test.dart` — 227 lines, tests `docs/index.mdx`
- `test/documentation/api_docs_examples_test.dart` — 262 lines, tests API patterns

**Gap:** Only 2 of 13+ content pages have corresponding tests.

### 8.2 schemas_instructions.md Accuracy — FAIL

**Critical inaccuracies:**
- Line 19: Claims `validate`, `tryParse`, `parseOrThrow` exist — `validate`/`tryParse` are deprecated, `parseOrThrow` doesn't exist
- Line 49: Uses `validateOrThrow()` in example — method doesn't exist
- Line 74: Uses `parseOrThrow()` in example — method doesn't exist

### 8.3 llms.txt — Stale Version

References `1.0.0-beta.6` throughout. Current version is `1.0.0-beta.7`. Missing documentation for `parseAs()`/`safeParseAs()` methods added in beta.6.

### 8.4 README Files

| Package | Status | Issues |
|---------|--------|--------|
| Root | Good | Missing `ack_annotations` and `ack_json_schema_builder` from package list |
| `ack` | **EMPTY (0 bytes)** | **CRITICAL** — this is the pub.dev landing page |
| `ack_annotations` | Good | Stale beta.6 references; broken link to non-existent `MIGRATION.md` |
| `ack_generator` | Good | Stale beta.6 version references |
| `ack_firebase_ai` | Good | Clean |
| `ack_json_schema_builder` | Good | Clean |

### 8.5 docs.json Version

`"default": "0.2.0"` — severely stale, should be `1.0.0-beta.7` or `1.0.0`.

### 8.6 Orphaned Pages

4 documentation pages exist but aren't in the sidebar navigation:
- `docs/guides/common-recipes.mdx`
- `docs/guides/migration-v1.mdx`
- `docs/guides/creating-schema-converter-packages.md`
- `docs/guides/schema-converter-quickstart.md`

---

## 9. CI/CD & Release Pipeline

### 9.1 CI Configuration

The CI workflow delegates entirely to `btwld/dart-actions/.github/workflows/ci.yml@main`:
- **Risk:** Pinned to `@main`, not a SHA or tag — upstream breaking changes would silently break CI
- **Risk:** Flutter version uses `"stable"` — not pinned for reproducibility
- DCM linting is enabled

### 9.2 Release Workflow

- OIDC pub.dev authentication correctly configured (`permissions: id-token: write`)
- All 5 publishable packages listed
- Same `@main` pinning issue as CI

**Publish order in YAML:** `ack` → `ack_annotations` → `ack_generator` → `ack_json_schema_builder` → `ack_firebase_ai`. This is correct dependency order IF the external workflow publishes sequentially in list order.

### 9.3 Missing/Broken Scripts

- `ensure_analysis_options` melos script references `.scripts/ensure_analysis_options.sh` — **directory does not exist**
- `api_check.dart` only checks `ack` and `ack_generator` (not all 5 packages)

### 9.4 Analysis Options Inconsistency

| Package | Lint Base | DCM Rules | Strict Mode |
|---------|-----------|-----------|-------------|
| `ack` | `lints/recommended` | Yes (full config) | No |
| `ack_generator` | `lints/recommended` | No | No |
| `ack_firebase_ai` | `lints/recommended` | No | Yes |
| `ack_json_schema_builder` | `lints/recommended` | No | Yes |
| `ack_annotations` | **None** | No | No |

### 9.5 Format Check

The melos `format` script runs `dart format . --fix` (apply mode). There is no verifiable `--set-exit-if-changed` check in CI.

### 9.6 Unused Dependency

`very_good_analysis: ^9.0.0` is declared in root `pubspec.yaml` but no package references it.

---

## 10. Security & Robustness

### 10.1 Regex ReDoS Audit

| Pattern | Location | Risk |
|---------|----------|------|
| Email regex | `pattern_constraint.dart:92` | Low (domain portion has bounded backtracking) |
| UUID regex | `pattern_constraint.dart:104` | Safe (fixed quantifiers) |
| Hex color regex | `pattern_constraint.dart:114` | Safe |
| IPv4 regex | `string_ip_constraint.dart:9` | Safe |
| **IPv6 regex** | **`string_ip_constraint.dart:13`** | **MEDIUM — lacks `^$` anchors (correctness bug + perf)** |
| Timezone offset | `pattern_constraint.dart:196` | Safe |
| Time format | `pattern_constraint.dart:225` | Safe |
| User-supplied regex | `pattern_constraint.dart:67,173` | By design — should document ReDoS risk |

**IPv6 Bug:** The regex lacks `^` and `$` anchors, meaning:
1. `hasMatch()` finds substring matches — `"garbage::1garbage"` would incorrectly match
2. On long non-IPv6 strings, the engine attempts matching at every position × all 9+ alternation branches

### 10.2 Nested Input — Stack Overflow

No depth limit exists on recursive validation:
- `ObjectSchema.parseAndValidate()` recurses into child schemas
- `ListSchema.parseAndValidate()` recurses into item schema
- `cloneDefault()`, `deepEquals()`, `deepMerge()` all recurse without limits
- `list_unique_items_constraint.dart` explicitly warns: "Cyclic structures will cause stack overflow"

**Severity:** If the library validates untrusted input (API requests), an attacker can crash the application with deeply nested JSON.

### 10.3 Sensitive Data in Error Messages

Error messages routinely embed the full input value:
- `pattern_constraint.dart`: Email, UUID, URI, enum errors all include `got "$v"`
- `string_ip_constraint.dart`: IP errors include full input
- `schema_error.dart:48`: `toString()` includes `with value "${val}"`
- `schema_error.dart:36`: `toMap()` serializes raw `value` field
- `constraint.dart:98-101`: `buildContext()` stores `inputValue` and `stringValue`

**Risk:** If validation errors for passwords, API keys, or tokens are logged or returned in HTTP responses, sensitive values are exposed.

**Good example to follow:** `jsonString()` validator correctly avoids echoing input: `'Invalid JSON string format.'`

### 10.4 Dependencies

All clean. Core `ack` has only 2 dependencies (`meta`, `collection`) — both official Dart team packages. `json_schema_builder: ^0.1.3` is the only pre-1.0 third-party dependency (in `ack_json_schema_builder`).

---

## 11. Package Metadata (pub.dev Readiness)

### 11.1 Metadata Summary

| Field | ack | annotations | generator | firebase_ai | json_schema |
|-------|-----|-------------|-----------|-------------|-------------|
| `homepage` | Yes | **Missing** | **Missing** | **Missing** | **Missing** |
| `repository` | Yes | Yes | Yes | Yes | Yes |
| `issue_tracker` | Yes | **Missing** | Yes | Yes | Yes |
| `topics` | **Missing** | **Missing** | **Missing** | **Missing** | **Missing** |
| `description < 180` | Yes (36) | Yes (42) | Yes (47) | Yes (64) | Yes (56) |
| `LICENSE` | Yes | Yes | Yes | Yes | Yes |
| `README` | **EMPTY** | Yes | Yes | Yes | Yes |

### 11.2 Recommended Actions

1. Add `topics` to all packages (e.g., `validation`, `schema`, `dart`, `codegen`, `firebase`)
2. Add `homepage: https://docs.page/btwld/ack` to packages missing it
3. Add `issue_tracker` to `ack_annotations`
4. Create `packages/ack/README.md` content (most important — pub.dev landing page)

---

## Recommended Fix Priority

### Phase 1 — Must Fix Before 1.0.0 Tag

1. **Create `packages/ack/README.md`** with content from root README or dedicated package docs
2. **Fix IPv6 regex** — add `^` and `$` anchors in `string_ip_constraint.dart`
3. **Fix Map cast safety** in `ObjectSchema` and `DiscriminatedObjectSchema` — wrap `.cast()` in try-catch
4. **Fix `schemas_instructions.md`** — remove references to non-existent `validateOrThrow`/`parseOrThrow`
5. **Update `llms.txt`** version references to match current release
6. **Add `topics` to all pubspec.yaml files**
7. **Add `homepage` and `issue_tracker`** to packages missing them
8. **Clean up root CHANGELOG.md** — remove duplicates, add missing beta entries
9. **Decide on deprecated APIs** — remove or explicitly commit to keeping with timeline

### Phase 2 — Should Fix Before 1.0.0

10. **Fix DiscriminatedObjectSchema** null-vs-missing discriminator error message
11. **Document AnyOfSchema order dependency** in class documentation
12. **Update docs.json version** from `0.2.0` to `1.0.0`
13. **Link orphaned docs pages** in sidebar
14. **Add `ack_annotations` and `ack_json_schema_builder`** to root README package list
15. **Update inter-package version constraints** from `^1.0.0-beta.7` to `^1.0.0`
16. **Pin CI workflows** to SHA/tag instead of `@main`
17. **Fix/remove broken `ensure_analysis_options` script** reference

### Phase 3 — Nice to Have for 1.0.0

18. Document sensitive data in error messages (or add option to redact)
19. Add depth limit parameter to validation context
20. Standardize `analysis_options.yaml` across packages
21. Extend `api_check.dart` to cover all 5 packages
22. Remove unused `very_good_analysis` dependency
23. Add documentation tests for remaining docs pages
24. Add more performance benchmarks (deeply nested, large lists)
25. Fill CHANGELOG gaps for `ack_json_schema_builder` beta.2–3
26. Fix stale beta version references in `ack_annotations` and `ack_generator` READMEs

---

## Automated Verification Commands

```bash
# Run all tests
melos run ci

# JSON Schema conformance
melos run validate-jsonschema

# Generator tests
melos run test:gen

# Golden tests
melos run test:golden

# API compatibility check
melos run api-check v1.0.0-beta.7

# Dry-run publish all packages
for pkg in ack ack_annotations ack_generator ack_json_schema_builder ack_firebase_ai; do
  (cd packages/$pkg && dart pub publish --dry-run) || echo "FAILED: $pkg"
done

# Format check
melos exec -- "dart format . --output=none --set-exit-if-changed"

# Analyze with fatal infos
melos run analyze
```
