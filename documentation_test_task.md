# Documentation Testing Task List

This file tracks the progress of creating tests for all documentation examples across the Ack project.

## Introduction Group
- [ ] index.mdx (Overview)
  - [ ] Create test for basic concepts examples
  - [ ] Validate code snippets work as documented
  
- [ ] installation.mdx
  - [ ] Test installation code examples
  - [ ] Verify configuration snippets
  
- [ ] configuration.mdx
  - [ ] Test configuration options examples
  - [ ] Validate format configurations

## Schemas Group
- [ ] schema-types.mdx
  - [ ] Test basic schema type examples
  - [ ] Verify all schema type behaviors
  
- [x] schema-usage.mdx
  - [x] Basic Usage Example (Complete)
  - [x] Validation Example (Complete)
  - [x] Parsing Example (Complete)
  - [x] Model Conversion Example (Complete)
  - [x] JSON Serialization Example (Complete)
  - [x] Handling Additional Properties Example (Complete)
  - [x] Error Handling Example (Complete)
  - [x] Working with Nested Schemas Example (Complete)
  - [x] Custom Transformations Example (Complete)
  - [x] Integration with Forms Example (Complete)
  
- [ ] nested-model-handling.mdx
  - [ ] Test nested model creation examples
  - [ ] Verify nested model validation
  - [ ] Test recursive schemas
  
- [ ] json-serialization.mdx
  - [ ] Test serialization examples
  - [ ] Verify custom serialization
  - [ ] Test deserialization

## Validation Group
- [ ] built-in-validation.mdx
  - [ ] Test string validators (min/max length, regex, etc.)
  - [ ] Test number validators (min/max, integer, etc.)
  - [ ] Test object validators (required fields, etc.)
  - [ ] Test array validators (min/max items, etc.)
  
- [ ] custom-validation.mdx
  - [ ] Test creating custom validators
  - [ ] Test custom validation methods
  - [ ] Verify composition of validators
  
- [ ] error-handling.mdx
  - [ ] Test error message format
  - [ ] Test error handling patterns
  - [ ] Verify error details

## Advanced Group
- [ ] code-generation.mdx
  - [ ] Test code generation examples
  - [ ] Verify generated classes
  - [ ] Test integration with build system

## Reference Group
- [ ] api-reference.mdx
  - [ ] Validate API signatures
  - [ ] Test core API examples
  - [ ] Verify extension methods
  
- [ ] examples.mdx
  - [ ] Test all example snippets
  - [ ] Verify complex examples
  - [ ] Test real-world patterns

## Test Implementation Status
- [x] Schema Usage Tests (10/10 complete)
- [ ] All other documentation tests (0/12 files tested)

## Next Steps
1. Prioritize testing validation-related documentation pages (built-in-validation.mdx, custom-validation.mdx)
2. Create tests for core concepts (schema-types.mdx)
3. Develop tests for more advanced features
4. Document any discrepancies between documentation and implementation 