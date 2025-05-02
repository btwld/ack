# Ack Example Package

This package demonstrates how to use the `ack` validation library and the `ack_generator` code generator package.

## Overview

The code within `lib/` showcases:

-   Defining model classes (`User`, `Address`).
-   Annotating models with `@Schema` and validation annotations (e.g., `@IsEmail`, `@MinLength`, `@Min`, `@Required`) for use with `ack_generator`.
-   Running `build_runner` to generate the `.schema.dart` files.
-   Using the generated schema classes (`UserSchema`, `AddressSchema`) to validate data maps.
-   Manually defining validation schemas using `Ack.string`, `Ack.int`, `Ack.object`, etc., for comparison.

## Running the Example

1.  **Bootstrap the Workspace:**
    Ensure you have bootstrapped the monorepo from the root directory:
    ```bash
    # From the root directory ../../
    melos bootstrap
    ```

2.  **Generate Code:**
    Navigate to the `example` directory and run the build runner:
    ```bash
    cd example
    dart run build_runner build --delete-conflicting-outputs
    ```
    *(Alternatively, run `melos build` from the root which might be configured in `melos.yaml`)*

3.  **Run Tests:**
    The tests in the `test/` directory execute the validation logic using both generated and manual schemas.
    ```bash
    # From the example directory
    dart test

    # Or run all workspace tests from the root directory ../../
    melos test
    ```

Explore the code in `lib/` and `test/` to understand the different ways to implement validation with Ack. 