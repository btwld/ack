# Ack Project Roadmap

This document outlines the current status and planned improvements for the Ack project packages.

## ack_generator Package

### Current Status

We've successfully implemented and tested the ack_generator for validating Dart models using JSON Schema validation. Here's what we've accomplished:

1. Created annotated Product and Category models with validation rules
2. Added build_runner configuration to generate schema files
3. Implemented a custom validator as a workaround for schema file issues
4. Created two types of tests:
   - Direct model validation tests that work reliably
   - Build_runner tests that verify code generation
5. Streamlined imports to avoid implementation details leaking into generated code
6. Reduced the code size by removing unused methods and constructors

### Key Findings

1. The schema generator correctly produces schema files that define validation rules
2. The generated schema files have some issues with constructor methods
3. Using a custom validator is more reliable than using the generated schemas directly
4. The build_test package is effective for testing code generation

### TODO List

#### Fix Schema Generation Issues

- [x] Address constructor conflicts in generated schema files
- [x] Fix the `_validated` constructor that's causing compilation errors
- [x] Remove unused factory constructors like `fromValidated`
- [x] Resolve issues with numeric value validations (Min, Max annotations)
- [x] Fix pattern validation for string fields

#### Enhance Testing

- [x] Update builder_test.dart to fix linter errors about too many arguments
- [x] Create more robust tests for different validation scenarios
- [ ] Add tests for complex nested model validations
- [ ] Create tests for array/list validations

#### Improve Validation Logic

- [x] Add proper warning suppression for unused fields like `_init`
- [x] Cleanup the schema generator output by removing unused code
- [ ] Enhance the custom validator to support all annotation types
- [ ] Add support for validating lists/arrays of models
- [ ] Implement more sophisticated number validations
- [ ] Add custom error messages for validation failures

#### Documentation

- [x] Document all available validation annotations
- [x] Create examples for common validation scenarios 
- [x] Add a troubleshooting guide for common issues
- [x] Update README with clear installation and usage instructions

#### Code Quality Improvements

- [x] Fix the `tryParse` method generation to include proper closing braces
- [x] Export necessary classes like `SchemaRegistry` from main package
- [x] Remove implementation imports from generated code
- [x] Remove unused methods like `toOpenApiSpecString`

## ack Package

### Current Status

The core ack package provides the validation engine that powers the schema validation. 

### TODO List

#### Schema Model Improvements

- [x] Fix the SchemaModel._validated constructor implementation
- [x] Remove unused constructors and methods
- [ ] Ensure proper inheritance in generated schema classes
- [ ] Improve error handling for validation failures
- [ ] Add more detailed error reporting

#### Validation Enhancements

- [ ] Add support for additional validation types
- [ ] Improve performance of validation for complex objects
- [ ] Add async validation support
- [ ] Create better error aggregation for nested validations

#### Documentation

- [ ] Improve API documentation with more examples
- [ ] Create a developer guide for extending the validation system
- [ ] Document best practices for using the validation system

## Overall Project

### Package Structure

- [x] Organize code to better separate generation from validation
- [x] Review and optimize imports in generated files
- [x] Consider simplifying the schema class structure
- [ ] Ensure proper error handling in the generator

### Performance & Optimization

- [ ] Measure and improve build time for large models
- [ ] Add benchmarks for validation performance
- [ ] Optimize validation for frequently validated models
- [ ] Consider incremental build optimization

### Community & Adoption

- [ ] Create more real-world examples
- [ ] Publish articles about using the validation system
- [ ] Develop integration examples with popular frameworks
- [ ] Create migration guides from other validation systems

By prioritizing the schema generation fixes and testing improvements, we've created a more robust validation system that's easier to use and maintain. Recent cleanup efforts have removed unused code and improved the codebase, making it more maintainable and efficient. 