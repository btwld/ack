## 0.3.0-beta.1 (2025-06-18)

* See [release notes](https://github.com/btwld/ack/releases/tag/v0.3.0-beta.1) for details.


## 0.3.0-beta.1

 - **REFACTOR**: Improved json-schema support ([#9](https://github.com/btwld/ack/issues/9)). ([d4da5d94](https://github.com/btwld/ack/commit/d4da5d949a82a1ad5ab8000e97e897724aae5b60))
 - **REFACTOR**: consolidate constraint system and enhance validation pipeline ([#8](https://github.com/btwld/ack/issues/8)). ([e6161a39](https://github.com/btwld/ack/commit/e6161a390d21b15bd741d250c8c04def7ec60d5e))
 - **FEAT**: prepare for 0.3.0-beta.1 release ([#11](https://github.com/btwld/ack/issues/11)). ([af70b357](https://github.com/btwld/ack/commit/af70b35774f762a32b9c74a50262c101f92e4795))
 - **FEAT**: Add discriminated union schema support with pattern matching ([#6](https://github.com/btwld/ack/issues/6)). ([9c9aff3c](https://github.com/btwld/ack/commit/9c9aff3c7b0301b695e0bd768a7f07b5583bd2fe))

## 0.2.0-beta.1 (2025-05-03)

* See [release notes](https://github.com/btwld/ack/releases/tag/v0.2.0-beta.1) for details.

## 0.2.0

 - Bump "ack" to 0.2.0 with improved SchemaModel API and enhanced string validation

## 0.2.0

### Breaking Changes

- **SchemaModel API**: Completely redesigned the SchemaModel API for a more intuitive and streamlined experience
  - Changed constructor parameter from `Map<String, dynamic>` to `Object?` for better flexibility
  - Added automatic validation during construction
  - Added `isValid` getter and `getErrors()` method for easier error handling
  - Added abstract `getSchema()` method to define the schema
  - Removed `parse()`, `fromValidated()`, `validateMap()`, `validate()`, `createFromMap()`, and `initialize()` methods

### Improvements

- Improved error handling with more detailed error messages
- Better type safety with `Object?` instead of `dynamic`
- Simplified API with fewer methods and more intuitive usage
- **String Validation**: Enhanced string validation with improved methods
  - Changed `matches()` to validate full string patterns (anchored with ^ and $)
  - Added `contains()` method for partial string matching

## 0.1.2

- Improved error messages

## 0.1.1

-  Added deprecations

## 0.1.0

-  Error and exception improvements
-  Reworked validation and constraint workflows
-  Improved testing

## 0.0.2

-  Better JSON response parsing for OpenApiSchemaConverter

## 0.0.1

-  Initial version.