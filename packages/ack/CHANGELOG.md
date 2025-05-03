## 0.2.0-beta.1 (2025-05-03)

* See [release notes](https://github.com/btwld/ack/releases/tag/v0.2.0-beta.1) for details.


## 0.2.0-beta.1

 - Bump "ack" to `0.2.0-beta.1`.

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