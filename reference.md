# Reference Code Analysis

## Context

**Language**: Dart 3.8 (SDK >=3.8.0 <4.0.0)
**Framework**: build_runner + source_gen + analyzer + code_builder
**Type**: Code generator (library)

## Domain

**Purpose**: Generate Ack schemas and extension types from annotated Dart models and schema variables.

**Core entities**:
- ModelInfo: analyzed model metadata for schema generation
- FieldInfo: field metadata for schema construction and typed getters
- SchemaAstAnalyzer: AST-based parser for @AckType schema variables

**Key actions**:
- Analyze @AckModel classes and @AckType schema variables
- Build schema variables (`Ack.object`, `Ack.discriminated`, etc.)
- Generate Dart 3 extension types for type-safe access

## Architecture

**Entry points**: `packages/ack_generator/lib/src/generator.dart`, `packages/ack_generator/lib/src/builder.dart`
**Layer structure**:
- Analyzer: element/AST analysis (`src/analyzer/*`)
- Models: analysis DTOs (`src/models/*`)
- Builders: code generation (`src/builders/*`)
- Validation: preflight checks (`src/validation/*`)

**Key modules**:
- `src/generator.dart`: orchestration and error reporting
- `src/analyzer/model_analyzer.dart`: class/field analysis
- `src/analyzer/schema_ast_analyzer.dart`: AST parsing for schema variables
- `src/builders/schema_builder.dart`: schema variable generation
- `src/builders/type_builder.dart`: extension type generation

## Conventions Detected

- Naming: PascalCase for models, camelCase for schema variables
- Errors: `InvalidGenerationSourceError` with actionable `todo`
- Structure: small analyzers/builders, DTOs for model/field metadata

---

## Findings

### src/analyzer/schema_ast_analyzer.dart — Prefixed Ack/schema references & list element chain parsing

**Signal type**: Clarity / Correctness
**Found at**: `packages/ack_generator/lib/src/analyzer/schema_ast_analyzer.dart`
**Initial observation**: Base Ack invocation detection only handles `SimpleIdentifier('Ack')`; prefixed imports (`ack.Ack`) and prefixed schema references (`schemas.userSchema`) are ignored. Top-level list schema element type parsing ignores method chains like `Ack.list(Ack.string().minLength(2))`.

**Questions & Research**:

| # | Question | Research Method | Answer |
|---|----------|-----------------|--------|
| 1 | Do tests cover prefixed imports or prefixed schema variable references? | Search tests for `as` imports / prefixed usage | No test coverage found. |
| 2 | Are prefixed imports encouraged or documented? | Scan docs & README | Not mentioned; examples use unprefixed `Ack`. |
| 3 | Is list element chain parsing for top-level `@AckType` list schemas currently expected to work? | Code review + test scan | Not covered by tests; current parser only handles direct `Ack.list(Ack.string())` and schema identifiers, not chained methods. |

**Decision**: Refactor AST parsing to recognize prefixed Ack targets and schema references, and to reuse method-chain logic for top-level list element types with a safe fallback.

**Action**: Add shared identifier helpers, update base-invocation detection, and resolve list element types via base Ack invocation or referenced schema variable analysis.

### src/builders/type_builder.dart — Set of custom types returns mismatched type

**Signal type**: Correctness
**Found at**: `packages/ack_generator/lib/src/builders/type_builder.dart`
**Initial observation**: `_resolveFieldType` returns `Set<CustomType>` for sets, while `_buildCollectionGetter` maps to `CustomTypeType`, producing a type mismatch.

**Questions & Research**:

| # | Question | Research Method | Answer |
|---|----------|-----------------|--------|
| 1 | Are there tests for sets of custom `@AckType` models? | Search tests for `Set<...>` of custom types | No tests found; existing tests cover primitive sets only. |
| 2 | Should sets mirror list behavior and return `Set<CustomTypeType>`? | Compare list handling in TypeBuilder | Yes, list types return `List<CustomTypeType>`; sets should follow the same rule. |

**Decision**: Align set return types with list behavior for custom element types.

**Action**: Update `_resolveFieldType` to return `Set<${elementType}Type>` when the element type is a custom `@AckType`.

### src/analyzer/model_analyzer.dart — Discriminated subtype mapping uses list index coupling

**Signal type**: Clarity / Consistency
**Found at**: `packages/ack_generator/lib/src/analyzer/model_analyzer.dart`
**Initial observation**: Subtype element lookup uses `elements[modelInfos.indexOf(subtype)]`, coupling ordering across lists and becoming fragile when schema variables are present.

**Questions & Research**:

| # | Question | Research Method | Answer |
|---|----------|-----------------|--------|
| 1 | Can schema variables or ordering changes cause incorrect subtype mapping? | Code review of generator flow | Yes — `modelInfos` includes schema variables; relying on list indices is brittle. |
| 2 | Is there a simpler, explicit mapping by class name? | Code sketch | Yes — build a `Map<String, ClassElement2>` keyed by class name. |

**Decision**: Remove ordering coupling and map elements by class name.

**Action**: Build `elementsByName` and use explicit lookups with clear errors when missing.

### src/builders/type_builder.dart — Discriminated safeParse return type inconsistent

**Signal type**: Clarity / Consistency
**Found at**: `packages/ack_generator/lib/src/builders/type_builder.dart`
**Initial observation**: Discriminated base `safeParse` returns `SchemaResult<Map<String, dynamic>>` while `parse` returns the sealed base type. Other extension types return `SchemaResult<Type>`.

**Questions & Research**:

| # | Question | Research Method | Answer |
|---|----------|-----------------|--------|
| 1 | Do docs or tests specify the safeParse return type for discriminated bases? | Docs scan | Docs say `TypeName.safeParse` returns `SchemaResult<TypeName>` for extension types; no discriminated-specific tests. |
| 2 | Can we return `SchemaResult<BaseType>` without re-parsing? | Code review | Yes — map validated data to subtype instance inside `onOk` using the discriminator value. |

**Decision**: Make discriminated `safeParse` consistent with other generated types by returning `SchemaResult<BaseType>`.

**Action**: Update `_buildDiscriminatedSafeParse` to map validated data to subtype instances and return `SchemaResult<BaseType>`.

### docs — Extension type behavior mismatch

**Signal type**: Documentation / Consistency
**Found at**: `docs/core-concepts/json-serialization.mdx`, `docs/core-concepts/typesafe-schemas.mdx`
**Initial observation**: Docs mention `toJson()` helpers and claim nested `@AckType` schema references return `Map<String, Object?>`, while code generates typed getters and no explicit `toJson()` method.

**Questions & Research**:

| # | Question | Research Method | Answer |
|---|----------|-----------------|--------|
| 1 | Is `toJson()` actually available via another extension, or should generator add it? | Search in `packages/ack` | No generic `toJson()` extension found on Map/primitive wrappers. |
| 2 | Which behavior is intended for nested `@AckType` references? | Compare docs vs tests | Tests generate typed getters; the docs note is outdated. |

**Decision**: Add `toJson()` to generated extension types and update the outdated doc note about nested `@AckType` references.

**Action**: Add `toJson()` methods to extension types (and discriminated base) and revise `docs/core-concepts/json-serialization.mdx`.


---

## Unresolved Questions


---

## Changes Made

| Finding | Action Taken | Files Changed |
|---------|--------------|---------------|
| Prefixed Ack/schema refs & list element chain parsing | Added identifier helpers, prefixed Ack support, and schema variable type resolution for top-level list schemas | `packages/ack_generator/lib/src/analyzer/schema_ast_analyzer.dart` |
| Set of custom types mismatch | Returned `Set<...Type>` for custom element sets | `packages/ack_generator/lib/src/builders/type_builder.dart` |
| Discriminated subtype mapping via list indices | Replaced index coupling with class-name map lookup | `packages/ack_generator/lib/src/analyzer/model_analyzer.dart` |
| Discriminated safeParse inconsistency | Returned `SchemaResult<BaseType>` with discriminator-based mapping | `packages/ack_generator/lib/src/builders/type_builder.dart` |
| toJson doc/code mismatch | Added `toJson()` to generated types; updated doc note on nested `@AckType` refs | `packages/ack_generator/lib/src/builders/type_builder.dart`, `docs/core-concepts/json-serialization.mdx` |
| Coverage for new list parsing behavior | Added regression tests for top-level list schemas and prefixed Ack | `packages/ack_generator/test/bugs/schema_variable_bugs_test.dart` |
