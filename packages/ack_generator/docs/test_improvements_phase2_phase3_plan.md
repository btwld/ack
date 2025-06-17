# ACK Generator Test Suite - Phase 2 & Phase 3 Implementation Plan

## Status Overview

✅ **Phase 1 COMPLETED** (40 minutes actual vs 1-2 hours estimated)
- ✅ Mock dependencies extracted to `test/utils/mock_ack_package.dart`
- ✅ Error handling tests added (missing annotations, invalid elements)
- ✅ `dart_test.yaml` configuration created
- ✅ All 8 tests passing with enhanced coverage

## Phase 2: Enhanced Testing Capabilities

**Priority**: Optional - Current coverage is excellent  
**Estimated Time**: 45 minutes (adjusted from original 1 hour based on Phase 1 results)  
**Value**: Medium - Adds robustness for edge cases

### 2.1 Builder Configuration Tests (20 minutes)

**Objective**: Verify builder behavior with different configurations and options

**Implementation Steps**:

1. **Create test group** (5 minutes)
   ```dart
   group('builder configuration', () {
     // Tests go here
   });
   ```

2. **Add BuilderOptions test** (10 minutes)
   ```dart
   test('handles custom BuilderOptions', () async {
     final customOptions = BuilderOptions({
       'generate_for': ['**/*.dart'],
       'exclude': ['**/*.g.dart'],
     });
     
     await testBuilder(
       ackSchemaBuilder(customOptions),
       {
         'ack_generator|lib/user_model.dart': await File('test/fixtures/user_model.dart').readAsString(),
         ...getMockAckPackage(),
       },
       outputs: {
         'ack_generator|lib/user_model.g.dart': isNotEmpty,
       },
     );
   });
   ```

3. **Add empty options test** (5 minutes)
   ```dart
   test('handles empty BuilderOptions', () async {
     final emptyOptions = BuilderOptions({});
     
     await testBuilder(
       ackSchemaBuilder(emptyOptions),
       {
         'ack_generator|lib/user_model.dart': await File('test/fixtures/user_model.dart').readAsString(),
         ...getMockAckPackage(),
       },
       outputs: {
         'ack_generator|lib/user_model.g.dart': isNotEmpty,
       },
     );
   });
   ```

**Acceptance Criteria**:
- ✅ Builder works with custom options
- ✅ Builder works with empty options
- ✅ No regression in existing functionality

### 2.2 Complex Scenario Tests (25 minutes)

**Objective**: Test edge cases and complex model structures

**Implementation Steps**:

1. **Create complex scenarios group** (5 minutes)
   ```dart
   group('complex scenarios', () {
     // Tests go here
   });
   ```

2. **Add deeply nested models test** (10 minutes)
   - Create fixture: `test/fixtures/deeply_nested_model.dart`
   ```dart
   import 'package:ack/ack.dart';
   
   part 'deeply_nested_model.g.dart';
   
   @Schema()
   class Level1 {
     final Level2 level2;
     Level1({required this.level2});
   }
   
   @Schema()
   class Level2 {
     final Level3 level3;
     Level2({required this.level3});
   }
   
   @Schema()
   class Level3 {
     final String value;
     Level3({required this.value});
   }
   ```
   
   - Add test:
   ```dart
   test('handles deeply nested models', () async {
     await testGolden('deeply_nested_model');
   });
   ```

3. **Add large model test** (10 minutes)
   - Create fixture with 15+ properties
   - Test generation performance and correctness
   ```dart
   test('handles models with many properties', () async {
     await testGolden('large_model');
   });
   ```

**Acceptance Criteria**:
- ✅ Deep nesting (3+ levels) generates correctly
- ✅ Large models (15+ properties) generate efficiently
- ✅ All dependencies are properly registered

## Phase 3: Developer Experience Improvements

**Priority**: Medium - High value for workflow improvement  
**Estimated Time**: 35 minutes (adjusted from original 1 hour)  
**Value**: High - Significantly improves development workflow

### 3.1 Golden File Update Tooling (20 minutes)

**Objective**: Streamline golden file management with dedicated tooling

**Implementation Steps**:

1. **Create tool directory and script** (15 minutes)
   - Create `tool/update_goldens.dart`:
   ```dart
   import 'dart:io';
   
   void main(List<String> args) async {
     final updateAll = args.contains('--all');
     final specificTest = args.where((arg) => !arg.startsWith('--')).firstOrNull;
     
     print('🔄 Updating golden files...');
     
     final testArgs = ['test'];
     if (!updateAll && specificTest != null) {
       testArgs.add('test/fixtures/$specificTest.dart');
     }
     
     final result = await Process.run(
       'dart',
       testArgs,
       environment: {...Platform.environment, 'UPDATE_GOLDEN': 'true'},
       workingDirectory: Directory.current.path,
     );
     
     if (result.exitCode != 0) {
       print('❌ Failed to update golden files');
       print(result.stderr);
       exit(1);
     }
     
     print('✅ Golden files updated successfully');
     
     // Show what changed
     final gitResult = await Process.run('git', ['diff', '--stat', 'test/golden/']);
     if (gitResult.stdout.toString().trim().isNotEmpty) {
       print('\n📝 Changed files:');
       print(gitResult.stdout);
     } else {
       print('\n✨ No changes to golden files');
     }
   }
   ```

2. **Test the tool** (5 minutes)
   ```bash
   # Test commands
   dart tool/update_goldens.dart --all
   dart tool/update_goldens.dart user_model
   ```

**Acceptance Criteria**:
- ✅ Tool updates all golden files with `--all` flag
- ✅ Tool updates specific test files when specified
- ✅ Tool shows git diff of changes
- ✅ Tool handles errors gracefully

### 3.2 Melos Integration (15 minutes)

**Objective**: Add convenient melos commands for generator testing

**Implementation Steps**:

1. **Add melos scripts** (10 minutes)
   - Update `melos.yaml` in project root:
   ```yaml
   scripts:
     # ... existing scripts ...
     
     test:gen:
       run: melos exec -c 1 -- dart test
       description: Run generator tests
       packageFilters:
         scope: ack_generator
         
     test:gen:watch:
       run: melos exec -c 1 -- dart test --watch
       description: Run generator tests in watch mode
       packageFilters:
         scope: ack_generator
         
     update-golden:
       run: cd packages/ack_generator && dart tool/update_goldens.dart
       description: Update golden test files
       
     update-golden:all:
       run: cd packages/ack_generator && dart tool/update_goldens.dart --all
       description: Update all golden test files
       
     test:golden:
       run: melos exec -c 1 -- dart test --tags=golden
       description: Run only golden tests
       packageFilters:
         dirExists: test/golden
   ```

2. **Test melos commands** (5 minutes)
   ```bash
   # Test commands
   melos test:gen
   melos update-golden:all
   melos test:golden
   ```

**Acceptance Criteria**:
- ✅ `melos test:gen` runs generator tests
- ✅ `melos update-golden` updates golden files
- ✅ `melos test:golden` runs golden tests specifically
- ✅ Commands work from project root

## Implementation Timeline

### Recommended Order (Total: 80 minutes)

1. **Phase 3.1 - Golden File Tooling** (20 min) - **HIGH PRIORITY**
   - Immediate workflow improvement
   - High value, low complexity
   - Independent of other changes

2. **Phase 3.2 - Melos Integration** (15 min) - **HIGH PRIORITY**  
   - Builds on Phase 3.1
   - Completes developer experience improvements
   - Easy to implement

3. **Phase 2.1 - Builder Configuration Tests** (20 min) - **MEDIUM PRIORITY**
   - Adds test robustness
   - Independent implementation
   - Good for comprehensive coverage

4. **Phase 2.2 - Complex Scenario Tests** (25 min) - **LOW PRIORITY**
   - Most complex to implement
   - Requires creating new fixtures
   - Lowest immediate value

## Dependencies

- **Phase 3.1** → **Phase 3.2**: Melos scripts depend on golden file tool
- **Phase 2.1** ↔ **Phase 2.2**: Independent of each other
- **All phases**: Independent of Phase 1 (already completed)

## Success Metrics

### Phase 2 Success Criteria:
- ✅ Builder configuration edge cases tested
- ✅ Complex model scenarios validated
- ✅ No performance regressions
- ✅ All existing tests continue to pass

### Phase 3 Success Criteria:
- ✅ Golden file updates streamlined (< 30 seconds)
- ✅ Melos commands work from any directory
- ✅ Developer workflow significantly improved
- ✅ Documentation updated with new commands

## Risk Assessment

**Low Risk**: All phases are optional enhancements to an already excellent test suite

**Mitigation Strategies**:
- Implement phases independently
- Test each phase thoroughly before proceeding
- Keep existing functionality unchanged
- Can abandon any phase without impact

## Next Steps

1. **Choose phases to implement** based on current priorities
2. **Start with Phase 3.1** for immediate workflow improvement
3. **Implement in recommended order** for maximum efficiency
4. **Test thoroughly** after each phase
5. **Update documentation** as phases are completed

## Detailed Implementation Examples

### Phase 2.2 - Large Model Fixture Example

**File**: `test/fixtures/large_model.dart`
```dart
import 'package:ack/ack.dart';

part 'large_model.g.dart';

@Schema(description: 'Large model with many properties for performance testing')
class LargeModel {
  @IsNotEmpty()
  final String field1;

  @IsEmail()
  final String field2;

  @MinLength(5)
  final String field3;

  final int field4;
  final double field5;
  final bool field6;
  final DateTime field7;

  @Nullable()
  final String? field8;

  @Required()
  final String? field9;

  final List<String> field10;
  final Map<String, dynamic> field11;

  @IsNotEmpty()
  final String field12;

  final int field13;
  final double field14;
  final bool field15;

  LargeModel({
    required this.field1,
    required this.field2,
    required this.field3,
    required this.field4,
    required this.field5,
    required this.field6,
    required this.field7,
    this.field8,
    this.field9,
    required this.field10,
    required this.field11,
    required this.field12,
    required this.field13,
    required this.field14,
    required this.field15,
  });
}
```

### Quick Start Commands

**Phase 3 Implementation**:
```bash
# Create tool directory
mkdir -p packages/ack_generator/tool

# Create golden file update tool
# (Copy code from Phase 3.1 above)

# Test the tool
cd packages/ack_generator
dart tool/update_goldens.dart --all

# Add melos scripts to project root melos.yaml
# (Copy scripts from Phase 3.2 above)

# Test melos integration
melos test:gen
melos update-golden:all
```

**Phase 2 Implementation**:
```bash
# Add builder configuration tests to test/generator_test.dart
# (Copy code from Phase 2.1 above)

# Create complex model fixtures
# (Copy fixtures from Phase 2.2 above)

# Run tests to verify
dart test
```

## File Structure After All Phases

```
packages/ack_generator/
├── docs/
│   └── test_improvements_phase2_phase3_plan.md  # This file
├── test/
│   ├── fixtures/
│   │   ├── user_model.dart                      # ✅ Existing
│   │   ├── product_model.dart                   # ✅ Existing
│   │   ├── block_model.dart                     # ✅ Existing
│   │   ├── sealed_block_model.dart              # ✅ Existing
│   │   ├── payment_method_model.dart            # ✅ Existing
│   │   ├── abstract_shape_model.dart            # ✅ Existing
│   │   ├── deeply_nested_model.dart             # 🆕 Phase 2.2
│   │   └── large_model.dart                     # 🆕 Phase 2.2
│   ├── golden/
│   │   ├── [existing golden files]             # ✅ Existing
│   │   ├── deeply_nested_model.golden           # 🆕 Phase 2.2
│   │   └── large_model.golden                   # 🆕 Phase 2.2
│   ├── utils/
│   │   └── mock_ack_package.dart                # ✅ Phase 1
│   └── generator_test.dart                      # ✅ Enhanced
├── tool/                                        # 🆕 Phase 3.1
│   └── update_goldens.dart                      # 🆕 Phase 3.1
└── dart_test.yaml                               # ✅ Phase 1
```

## Conclusion

This plan provides **practical, actionable steps** for enhancing an already excellent test suite. The **adjusted time estimates** (80 minutes total vs original 2-3 hours) reflect the learnings from Phase 1 implementation.

**Recommendation**: Implement **Phase 3 first** (35 minutes) for immediate workflow benefits, then consider Phase 2 based on specific testing needs.

**Total Value**: High-impact improvements with minimal time investment, building on the solid foundation established in Phase 1.
