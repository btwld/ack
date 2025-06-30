# AI Agent Workflow for Test Coverage Improvement

## Overview
This document outlines the ideal process for AI agents to systematically improve test coverage, breaking down the work into manageable, verifiable chunks.

## Core Principles for AI Agent Work

### 1. **One PR Per Phase**
- Each phase from the test coverage plan becomes a separate PR
- Keeps changes focused and reviewable
- Allows for incremental progress

### 2. **Test-First Development**
- Write failing tests first
- Implement fixes if needed
- Verify tests pass
- Document any discovered issues

### 3. **Continuous Validation**
- Run existing tests before starting
- Run tests after each change
- Use `melos test` for full suite
- Use `dart test path/to/specific_test.dart` for focused testing

### 4. **Documentation Updates**
- Update test coverage documents as you go
- Add inline comments for complex test scenarios
- Update README if new patterns are introduced

---

## Ideal Workflow Per Phase

### Phase Structure
Each phase should follow this pattern:

```markdown
## Phase X: [Feature Name]

### 1. Setup (5 minutes)
- [ ] Create new branch: `test/phase-X-feature-name`
- [ ] Review current test files
- [ ] Run existing tests to ensure green baseline
- [ ] Create TODO checklist from test coverage plan

### 2. Implementation (1-3 hours)
- [ ] Create/update test files
- [ ] Write tests for each scenario
- [ ] Run tests frequently
- [ ] Fix any broken functionality discovered

### 3. Validation (30 minutes)
- [ ] Run full test suite
- [ ] Check coverage metrics
- [ ] Update test coverage documents
- [ ] Create PR with clear description

### 4. Handoff
- [ ] Summarize what was done
- [ ] List any discovered issues
- [ ] Suggest next steps
```

---

## Specific Workflow Examples

### Example 1: Phase 1 - Transformation Edge Cases

```markdown
## Session 1: Transformation Null Handling Tests

### Setup Commands
```bash
cd /Users/leofarias/Projects/ack
git checkout -b test/transformation-edge-cases
melos test  # Ensure baseline is green
```

### Work Plan
1. Open `/packages/ack/test/schemas/extensions/transform_extension_test.dart`
2. Add test group: "Null handling edge cases"
3. Implement tests:
   - Transformation returning null for non-nullable output
   - Nullable input to non-nullable output
   - Non-nullable input to nullable output
   - Null propagation through chain

### Test Template
```dart
group('Null handling edge cases', () {
  test('should throw when transform returns null for non-nullable output', () {
    final schema = Ack.string().transform<String>(
      (val) => null, // This should fail
    );
    
    expect(
      () => schema.parse('test'),
      throwsA(isA<SchemaTransformError>()),
    );
  });
  
  // More tests...
});
```

### Validation
- Run: `dart test packages/ack/test/schemas/extensions/transform_extension_test.dart`
- Update `/test_coverage_plan.md` to check off completed items
- Commit with message: "test: add transformation null handling edge case tests"
```

### Example 2: Phase 6 - Critical Code Generator Fixes

```markdown
## Session 1: Fix Enum Support in Code Generator

### Setup Commands
```bash
cd /Users/leofarias/Projects/ack
git checkout -b fix/generator-enum-support
melos test  # Baseline
cd packages/ack_generator
```

### Investigation First
1. Run failing enum test to understand the issue
2. Trace through the code generator flow
3. Identify where enum detection should happen

### Implementation Plan
1. Update `FieldAnalyzer` to detect enum types
2. Update `FieldBuilder` to generate appropriate schema
3. Update golden tests with enum examples
4. Run generator tests frequently

### Test-Driven Approach
```dart
// First, write the test that should pass
test('should generate schema for enum field', () {
  final field = analyzeField('''
    enum Status { active, inactive }
    class Model {
      final Status status;
    }
  ''');
  
  final schema = buildFieldSchema(field);
  expect(schema, contains('Ack.stringEnum'));
});
```

### Validation
- Run: `melos test` (in ack_generator)
- Run: `melos build` to test generation
- Create test model with enum to verify
```

---

## AI Agent Task Breakdown Strategy

### 1. **Chunking Strategy**
Break each phase into 2-3 hour sessions:
- Session 1: Basic cases (50% of tests)
- Session 2: Edge cases (30% of tests)  
- Session 3: Complex scenarios (20% of tests)

### 2. **Context Preservation**
At the end of each session:
```markdown
## Session Summary
- Completed: [list of test scenarios]
- Discovered issues: [any bugs found]
- TODO next session: [specific test cases]
- Key learnings: [patterns or insights]
```

### 3. **Handoff Template**
```markdown
## Handoff to Next Session/Agent

### Current State
- Branch: `test/phase-X-feature`
- Files modified: 
  - `/packages/ack/test/...`
- Tests added: 15 new test cases
- All tests passing: YES/NO

### Discovered Issues
1. [Issue description and location]
2. [Workaround if any]

### Next Steps
1. Continue with [specific test scenarios]
2. Address [any failing tests]
3. Update documentation

### Commands to Resume
```bash
git checkout test/phase-X-feature
melos test  # Verify state
# Continue from [specific file:line]
```
```

---

## Ideal AI Agent Capabilities

### 1. **Memory Management**
- Use `TodoWrite` to track test scenarios
- Mark items as `in_progress` when working
- Mark as `completed` when tests pass

### 2. **Incremental Progress**
- Commit after each working test group
- Use descriptive commit messages
- Push regularly for backup

### 3. **Error Recovery**
When encountering issues:
1. Document the exact error
2. Try to understand root cause
3. If blocked, document clearly and move to next item
4. Create TODO for human review

### 4. **Pattern Recognition**
- Look for similar test patterns in existing files
- Reuse test utilities and helpers
- Maintain consistency with project style

---

## Execution Order (Based on Priority)

### Week 1: Critical Fixes
1. **Day 1-2**: Phase 6.1 - Fix generator enum support
2. **Day 3-4**: Phase 6.1 - Fix generator generic types
3. **Day 5**: Phase 6.2 - Add Map/Set support

### Week 2: High Priority
1. **Day 1-2**: Phase 1 - Transformation edge cases
2. **Day 3-4**: Phase 2 - Complex object scenarios
3. **Day 5**: Phase 5.1 - JSON schema for extensions

### Week 3: Medium Priority
1. **Day 1-2**: Phase 3 - Advanced discriminated unions
2. **Day 3-4**: Phase 4 - Direct constraint testing
3. **Day 5**: Phase 7 - Integration tests

### Week 4: Polish
1. **Day 1-2**: Phase 8 - Documentation tests
2. **Day 3-4**: Performance benchmarks
3. **Day 5**: Update all documentation

---

## Success Metrics Per Session

### Quantitative
- Number of test cases added
- Coverage percentage increase
- All tests passing (green)

### Qualitative
- Edge cases covered
- Error messages improved
- Code patterns established

---

## Common Pitfalls to Avoid

1. **Don't Skip Investigation**
   - Always understand existing code first
   - Run existing tests before adding new ones

2. **Don't Over-Engineer**
   - Write simple, clear tests
   - Avoid complex test utilities unless needed

3. **Don't Ignore Failures**
   - If a test reveals a bug, document it
   - Either fix it or create clear TODO

4. **Don't Forget Context**
   - Update TodoWrite frequently
   - Leave clear handoff notes
   - Commit with descriptive messages

---

## Sample Session Prompt

When starting a new session, use this template:

```
Please help me implement Phase [X] from the test coverage plan:
[Paste specific phase details]

Let's start by:
1. Creating a new branch
2. Reviewing existing tests in [file]
3. Implementing the first batch of test cases
4. Running tests to ensure they work

Please use TodoWrite to track our progress and commit after each working group of tests.
```