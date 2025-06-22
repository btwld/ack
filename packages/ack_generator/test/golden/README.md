# Golden Tests Documentation

## Overview

Golden tests verify that the ACK Generator produces exactly the expected output by comparing generated code against "golden" reference files.

## Structure

- `test/golden_test.dart` - The test file that runs golden tests
- `test/golden/*.golden` - Golden reference files containing expected output

## Golden Files

1. **user_schema.dart.golden** - Simple schema with basic types
   - Tests string, integer, and nullable fields
   - Tests required field handling

2. **order_schema.dart.golden** - Complex nested schema
   - Tests nested model references (OrderItem in Order)
   - Tests list types
   - Tests DateTime handling

3. **product_with_metadata_schema.dart.golden** - Additional properties support
   - Tests `additionalProperties: true` in schema definition
   - Tests `additionalPropertiesField: 'metadata'` configuration
   - Tests metadata getter generation with known fields filtering
   - Tests exclusion of metadata field from schema properties
   - Compares schema with and without additional properties

## Running Golden Tests

```bash
# Run only golden tests
dart test test/golden_test.dart

# Run all tests including golden
dart test
```

## Updating Golden Files

If the generator output changes intentionally:

1. Run the generator manually to see new output
2. Update the `.golden` files with the new expected output
3. Ensure formatting matches exactly
4. Commit the updated golden files

## Key Features Tested

- Schema class generation
- Field type mapping
- Nullable field handling
- Required field lists
- Nested model references
- List type handling
- Custom type handling (DateTime → DateTimeSchema)
- Proper getter generation
- Constructor patterns
- Additional properties support and metadata field generation
- Field exclusion from schema properties
- Dynamic metadata getter with known fields filtering
