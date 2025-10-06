# Ack Example Package

This package demonstrates how to use the `ack` validation library for schema-based data validation.

## Overview

The code within `lib/` showcases:

-   Defining validation schemas using the fluent `Ack` API
-   Validating complex nested data structures
-   Using different schema types (string, number, object, list, etc.)
-   Custom validation with refinements and transformations
-   Error handling and validation results

## Examples Included

- **Basic Schema Validation**: Simple string, number, and boolean validation
- **Object Validation**: Nested object structures with property validation
- **List Validation**: Array validation with item schemas
- **Custom Validation**: Using refinements for business logic validation
- **Union Types**: Using `anyOf` and discriminated unions
- **Flexible Schemas**: Using `AnySchema` for maximum flexibility

## Running the Example

1.  **Bootstrap the Workspace:**
    Ensure you have bootstrapped the monorepo from the root directory:
    ```bash
    # From the root directory ../../
    melos bootstrap
    ```

2.  **Run the Examples:**
    ```bash
    cd example
    dart run any_schema_example.dart
    ```

3.  **Run Tests:**
    The tests demonstrate various validation scenarios:
    ```bash
    # From the example directory
    dart test

    # Or run all workspace tests from the root directory ../../
    melos test
    ```

Explore the code in `lib/` and `test/` to understand different validation patterns with Ack schemas.