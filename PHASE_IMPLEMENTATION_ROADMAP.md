# Ack Framework Correctness Implementation Roadmap

## Overview
This document provides a comprehensive roadmap for implementing JSON Schema 2020-12 compliant validation in the Ack framework. The implementation follows a phased approach to minimize risk and ensure backward compatibility while progressively improving correctness.

## Executive Summary

### Current State ✅
- **Phase 1 COMPLETED**: Foundation with JsonType enum, path tracking, and enhanced error reporting
- Ack validation framework with strong Dart typing
- Code generation with `@Schema()` annotations
- Basic schema composition with `AnyOfSchema`

### Target State 🎯
- Full JSON Schema 2020-12 compliance
- Correct nullable/optional semantics
- Proper validation workflow order
- Advanced features: async validation, schema composition, conditional schemas
- Maintained Dart type safety and performance

## Phase Overview

| Phase | Focus | Duration | Risk Level | Dependencies |
|-------|-------|----------|------------|--------------|
| **Phase 1** ✅ | Foundation (JsonType, paths, errors) | 1 week | Low | None |
| **Phase 2** | Nullable/Optional Fix | 3 weeks | Medium | Phase 1 |
| **Phase 3** | Validation Workflow | 4 weeks | Medium | Phase 2 |
| **Phase 4** | Advanced Features | 4 weeks | High | Phase 3 |

## Detailed Phase Plans

### Phase 1: Foundation ✅ COMPLETED
**Files**: Complete implementation in codebase
**Status**: All features implemented and tested

#### ✅ Achievements
- Added `JsonType` enum with null as first-class type
- Enhanced `ValidationContext` with JSON path tracking
- Added `toErrorString()` method for better error messages
- Created `acceptedTypes` property for schema type mapping
- Maintained 100% backward compatibility

#### ✅ Verification
- Static analysis passes with no issues
- Core schema tests pass
- New path tracking functionality working
- Error messages include JSON paths

### Phase 2: Nullable/Optional Fix
**File**: [`phase_2_nullable_optional_fix.md`](./phase_2_nullable_optional_fix.md)
**Priority**: HIGH - Fixes fundamental semantic confusion

#### 🎯 Goals
Fix the core issue where `OptionalSchema` incorrectly forces `isNullable = true`, preventing the expression of "optional non-nullable" fields.

#### 🔧 Key Changes
1. **Separate Concerns**: Optional (field can be missing) ≠ Nullable (field can be null)
2. **Missing Field Detection**: Introduce `_missingFieldMarker` to distinguish missing vs null
3. **Explicit Nullable**: Add `.nullable()` extension for explicit null support
4. **Correct JSON Schema**: Generate proper `required` arrays and type specifications

#### 📊 Impact Assessment
- **Breaking Change**: `.optional()` will correctly reject null values
- **Migration**: Users need explicit `.nullable().optional()` for null + missing
- **Benefit**: Can express all 4 semantic cases correctly

### Phase 3: Validation Workflow
**File**: [`phase_3_validation_workflow.md`](./phase_3_validation_workflow.md)
**Priority**: HIGH - Establishes correct validation order

#### 🎯 Goals
Implement the correct validation pipeline order matching JSON Schema standards.

#### 🔧 Key Changes
1. **Correct Order**: Type check → null handling → defaults → conversion → constraints
2. **Centralized Type Validation**: Remove scattered type checking from `_onConvert`
3. **Null as Type**: Treat null as valid type, not special case
4. **Performance**: Early type errors prevent expensive conversions

#### 📊 Impact Assessment
- **Low Risk**: Mostly internal pipeline changes
- **Performance**: Significant improvement with early type validation
- **Foundation**: Enables schema composition in Phase 4

### Phase 4: Advanced Features (Simplified Core)
**File**: [`phase_4_advanced_features.md`](./phase_4_advanced_features.md)
**Priority**: MEDIUM - Adds advanced JSON Schema features

#### 🎯 Goals
Implement composition and unevaluated* with minimal, core‑only annotations, and keep sync validation; offer async/remote refs as optional extensions.

#### 🔧 Key Features
1. **Minimal Annotations**: Track evaluated properties/items in `ValidationContext`
2. **Schema Composition**: `allOf`/`anyOf`/`oneOf` (short‑circuit anyOf when annotations not needed)
3. **UnevaluatedProperties**: Enforce using context‑tracked keys
4. **Conditional Schemas**: `if`/`then`/`else`
5. **Schema References (Core)**: In‑memory `$ref` via `SchemaRegistry`
6. **Remote References (Optional)**: Separate plugin for HTTP/dynamic refs

#### 📊 Impact Assessment
- **High Value**: Enables complex validation patterns
- **Additive**: Backward compatible; sync validate() remains primary
- **Lean Core**: No automatic defaults; no built‑in HTTP to avoid duplicating other packages

## Implementation Strategy

### Development Approach
1. **Test-Driven**: Write failing tests first, then implement
2. **Incremental**: Small, focused commits with clear regression testing
3. **Documentation**: Update examples and API docs with each phase
4. **Performance**: Benchmark each change to ensure no regression

### Quality Gates
Each phase must pass:
- ✅ All existing tests continue to pass
- ✅ New functionality has 90%+ test coverage
- ✅ Static analysis (dart analyze) passes
- ✅ Performance benchmarks show no regression
- ✅ Documentation updated

### Risk Mitigation
1. **Feature Flags**: Allow gradual rollout of breaking changes
2. **Deprecation Warnings**: Give users time to migrate
3. **Rollback Plan**: Keep old implementations available
4. **User Communication**: Clear migration guides and examples

## Timeline and Milestones

### Q4 2025 – Q1 2026: Updated Plan
- Oct 2025: Phase 2 implementation + tests + migration docs
- Nov 2025: Phase 3 pipeline refactor + strict/permissive toggles
- Dec 2025–Jan 2026: Phase 4 (minimal annotations, composition, unevaluated*, conditionals, in‑memory refs)
- Feb 2026: Optional plugin for remote refs + perf pass + docs

## Success Criteria

### Technical Metrics
- [ ] Core JSON Schema 2020‑12 compliance for implemented keywords (incl. composition and unevaluated*)
- [ ] Performance within 10% of current implementation
- [ ] Zero breaking changes for correct API usage
- [ ] All four nullable/optional cases expressible

### User Experience Metrics
- [ ] Error messages 50% more helpful (user study)
- [ ] Migration completed with <5% user issues
- [ ] Advanced features adopted by 20% of users
- [ ] Documentation satisfaction >90%

## Team Coordination

### Roles and Responsibilities
- **Architect**: Design validation and oversee implementation
- **Developer**: Implement changes according to phase plans
- **QA**: Comprehensive testing and edge case validation
- **DevRel**: Documentation, migration guides, user communication

### Communication Plan
- **Weekly**: Progress updates and blocker resolution
- **Phase End**: Stakeholder review and approval to proceed
- **Release**: User communication and migration support

## Dependencies and Assumptions

### Technical Dependencies
- Dart 3.0+ features (switch expressions, pattern matching)
- Existing test infrastructure
- Build system compatibility

### External Dependencies
- User feedback on breaking changes
- Community validation of approach
- Performance requirements maintenance

### Assumptions
- Users value correctness over absolute backward compatibility
- Simpler core (no auto‑defaults, no built‑in HTTP) reduces duplication with `dart_schema_builder`
- Performance can be maintained throughout changes

## Conclusion

This roadmap provides a structured approach to evolving Ack into a fully JSON Schema 2020-12 compliant validation framework while maintaining its Dart-first philosophy and type safety benefits. The phased approach minimizes risk while delivering incremental value to users.

The foundation established in Phase 1 enables all subsequent improvements, and the detailed phase plans provide clear implementation guidance. Success depends on careful execution, comprehensive testing, and clear communication with users throughout the process.

---

**Next Steps**: Begin Phase 2 implementation with the nullable/optional semantics fix, starting with the missing field marker infrastructure outlined in `phase_2_nullable_optional_fix.md`.
