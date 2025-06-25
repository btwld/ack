# Change Log

All notable changes to this project will be documented in this file.
See [Conventional Commits](https://conventionalcommits.org) for commit guidelines.

## 2025-06-25

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`ack` - `v0.3.0-alpha.0`](#ack---v030-alpha0)
 - [`ack_example` - `v0.3.0-alpha.0`](#ack_example---v030-alpha0)

---

#### `ack` - `v0.3.0-alpha.0`

 - **REFACTOR**: simplify error handling and context management in validation classes. ([416bba23](https://github.com/btwld/ack/commit/416bba23b5f58cdc840be656e6c0f94769586d6f))
 - **REFACTOR**: update schema classes to use Constraint type for validation. ([00c1ebf6](https://github.com/btwld/ack/commit/00c1ebf683fae631984c9f72fa7b1952197f81fe))
 - **REFACTOR**: update schema classes for improved type handling and default value validation. ([8a3d1665](https://github.com/btwld/ack/commit/8a3d166549abaeb22a2ea3fd507d144d534ee164))
 - **REFACTOR**: enhance string constraints with JSON schema support. ([2c0f9755](https://github.com/btwld/ack/commit/2c0f9755b6b004ed8ab3182d55fff3d1028c6f70))
 - **REFACTOR**: enhance schema classes with refinements and improved validation handling. ([e4a82c83](https://github.com/btwld/ack/commit/e4a82c83d50a0bea2d6913c526d3cede60b77d82))
 - **REFACTOR**: enhance schema classes with improved type safety and nullability handling. ([190e4b6b](https://github.com/btwld/ack/commit/190e4b6b788866b1ecbba6f64cca259ec3e34aa7))
 - **REFACTOR**: enhance schema context and comparison constraints for improved clarity and functionality. ([7c315825](https://github.com/btwld/ack/commit/7c315825482e6ad7e1e10bbe494590b670f641ab))
 - **REFACTOR**: enhance schema classes with copy methods and improved validation handling. ([b99ae936](https://github.com/btwld/ack/commit/b99ae936f3db88208aa33400e8fea38136275d98))
 - **REFACTOR**: update validateValue methods to include SchemaContext for improved validation context. ([7842b384](https://github.com/btwld/ack/commit/7842b38431a5b6375896da9d2bc2dac1e9b58fd1))
 - **REFACTOR**: rename enumValues to enumString for consistency in pattern constraints. ([c6add4e9](https://github.com/btwld/ack/commit/c6add4e98d5fe74da1608fcbfbf4485d06d43e02))
 - **REFACTOR**: Improved json-schema support ([#9](https://github.com/btwld/ack/issues/9)). ([d4da5d94](https://github.com/btwld/ack/commit/d4da5d949a82a1ad5ab8000e97e897724aae5b60))
 - **REFACTOR**: consolidate constraint system and enhance validation pipeline ([#8](https://github.com/btwld/ack/issues/8)). ([e6161a39](https://github.com/btwld/ack/commit/e6161a390d21b15bd741d250c8c04def7ec60d5e))
 - **FEAT**: add comprehensive API documentation and extend schema capabilities. ([eaa77fc2](https://github.com/btwld/ack/commit/eaa77fc2b9338bf791ebc692926969af270e821e))
 - **FEAT**: introduce transformation capabilities in schema classes. ([0ec7e823](https://github.com/btwld/ack/commit/0ec7e82377f8c96b8a9e6660d23731eec5799b52))
 - **FEAT**: add PatternConstraint for custom pattern validation and refactor schemas for improved clarity. ([a1a88f84](https://github.com/btwld/ack/commit/a1a88f84130dd445dfee9c7c5d14e7307c916548))
 - **FEAT**: introduce comprehensive validation library with schemas and constraints. ([6fd97c4f](https://github.com/btwld/ack/commit/6fd97c4f8831c97ced097c4ff9bd9ce7d129ab3e))
 - **FEAT**: add enumValues method for consistent enum validation in StringSchema. ([bc682ba3](https://github.com/btwld/ack/commit/bc682ba3dd8ebb306e516e046d7385677caa2e02))
 - **FEAT**: add anyObject method to create ObjectSchema with additional properties. ([4fef6217](https://github.com/btwld/ack/commit/4fef62173deeb9ea302fb1d872cd850eda7d4df8))
 - **FEAT**: simplify API compatibility checking with Dart script ([#14](https://github.com/btwld/ack/issues/14)). ([d309f2c2](https://github.com/btwld/ack/commit/d309f2c2b83cd3414bee9462f514fba3a5467aee))
 - **FEAT**: prepare for 0.3.0-beta.1 release ([#11](https://github.com/btwld/ack/issues/11)). ([af70b357](https://github.com/btwld/ack/commit/af70b35774f762a32b9c74a50262c101f92e4795))
 - **FEAT**: Add discriminated union schema support with pattern matching ([#6](https://github.com/btwld/ack/issues/6)). ([9c9aff3c](https://github.com/btwld/ack/commit/9c9aff3c7b0301b695e0bd768a7f07b5583bd2fe))
 - **DOCS**: Fix API inconsistencies across all documentation ([#12](https://github.com/btwld/ack/issues/12)). ([2c57298b](https://github.com/btwld/ack/commit/2c57298b84436b5446fe5e532396e11841d31187))

#### `ack_example` - `v0.3.0-alpha.0`

 - **REFACTOR**: rename AckFileGenerator to AckSchemaGenerator and update related references. ([d05360a9](https://github.com/btwld/ack/commit/d05360a9077efbe3e8bc589ef87939faf100ce44))
 - **REFACTOR**: Improved json-schema support ([#9](https://github.com/btwld/ack/issues/9)). ([d4da5d94](https://github.com/btwld/ack/commit/d4da5d949a82a1ad5ab8000e97e897724aae5b60))
 - **REFACTOR**: consolidate constraint system and enhance validation pipeline ([#8](https://github.com/btwld/ack/issues/8)). ([e6161a39](https://github.com/btwld/ack/commit/e6161a390d21b15bd741d250c8c04def7ec60d5e))
 - **FEAT**: Add dart_mappable integration for seamless field name synchronization ([#10](https://github.com/btwld/ack/issues/10)). ([66adc71c](https://github.com/btwld/ack/commit/66adc71c8a5fcdacd99aabc7dfa4458fd1501e91))
 - **FEAT**: Add discriminated union schema support with pattern matching ([#6](https://github.com/btwld/ack/issues/6)). ([9c9aff3c](https://github.com/btwld/ack/commit/9c9aff3c7b0301b695e0bd768a7f07b5583bd2fe))

## 0.3.0-beta.1 (2025-06-19)

* See [release notes](https://github.com/btwld/ack/releases/tag/0.3.0-beta.1) for details.



## 2025-06-19

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`ack_example` - `v0.3.0-beta.1`](#ack_example---v030-beta1)

---

#### `ack_example` - `v0.3.0-beta.1`

 - **REFACTOR**: Improved json-schema support ([#9](https://github.com/btwld/ack/issues/9)). ([d4da5d94](https://github.com/btwld/ack/commit/d4da5d949a82a1ad5ab8000e97e897724aae5b60))
 - **REFACTOR**: consolidate constraint system and enhance validation pipeline ([#8](https://github.com/btwld/ack/issues/8)). ([e6161a39](https://github.com/btwld/ack/commit/e6161a390d21b15bd741d250c8c04def7ec60d5e))
 - **FEAT**: Add dart_mappable integration for seamless field name synchronization ([#10](https://github.com/btwld/ack/issues/10)). ([66adc71c](https://github.com/btwld/ack/commit/66adc71c8a5fcdacd99aabc7dfa4458fd1501e91))
 - **FEAT**: Add discriminated union schema support with pattern matching ([#6](https://github.com/btwld/ack/issues/6)). ([9c9aff3c](https://github.com/btwld/ack/commit/9c9aff3c7b0301b695e0bd768a7f07b5583bd2fe))


## 2025-06-19

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`ack` - `v0.3.0-beta.1`](#ack---v030-beta1)
 - [`ack_example` - `v0.3.0-beta.2`](#ack_example---v030-beta2)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `ack_example` - `v0.3.0-beta.2`

---

#### `ack` - `v0.3.0-beta.1`

 - **REFACTOR**: Improved json-schema support ([#9](https://github.com/btwld/ack/issues/9)). ([d4da5d94](https://github.com/btwld/ack/commit/d4da5d949a82a1ad5ab8000e97e897724aae5b60))
 - **REFACTOR**: consolidate constraint system and enhance validation pipeline ([#8](https://github.com/btwld/ack/issues/8)). ([e6161a39](https://github.com/btwld/ack/commit/e6161a390d21b15bd741d250c8c04def7ec60d5e))
 - **FEAT**: simplify API compatibility checking with Dart script ([#14](https://github.com/btwld/ack/issues/14)). ([d309f2c2](https://github.com/btwld/ack/commit/d309f2c2b83cd3414bee9462f514fba3a5467aee))
 - **FEAT**: prepare for 0.3.0-beta.1 release ([#11](https://github.com/btwld/ack/issues/11)). ([af70b357](https://github.com/btwld/ack/commit/af70b35774f762a32b9c74a50262c101f92e4795))
 - **FEAT**: Add discriminated union schema support with pattern matching ([#6](https://github.com/btwld/ack/issues/6)). ([9c9aff3c](https://github.com/btwld/ack/commit/9c9aff3c7b0301b695e0bd768a7f07b5583bd2fe))
 - **DOCS**: Fix API inconsistencies across all documentation ([#12](https://github.com/btwld/ack/issues/12)). ([2c57298b](https://github.com/btwld/ack/commit/2c57298b84436b5446fe5e532396e11841d31187))

## 0.3.0-beta.1 (2025-06-19)

* See [release notes](https://github.com/btwld/ack/releases/tag/0.3.0-beta.1) for details.



## 2025-06-19

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`ack_example` - `v0.3.0-beta.1`](#ack_example---v030-beta1)

---

#### `ack_example` - `v0.3.0-beta.1`

 - **REFACTOR**: Improved json-schema support ([#9](https://github.com/btwld/ack/issues/9)). ([d4da5d94](https://github.com/btwld/ack/commit/d4da5d949a82a1ad5ab8000e97e897724aae5b60))
 - **REFACTOR**: consolidate constraint system and enhance validation pipeline ([#8](https://github.com/btwld/ack/issues/8)). ([e6161a39](https://github.com/btwld/ack/commit/e6161a390d21b15bd741d250c8c04def7ec60d5e))
 - **FEAT**: Add dart_mappable integration for seamless field name synchronization ([#10](https://github.com/btwld/ack/issues/10)). ([66adc71c](https://github.com/btwld/ack/commit/66adc71c8a5fcdacd99aabc7dfa4458fd1501e91))
 - **FEAT**: Add discriminated union schema support with pattern matching ([#6](https://github.com/btwld/ack/issues/6)). ([9c9aff3c](https://github.com/btwld/ack/commit/9c9aff3c7b0301b695e0bd768a7f07b5583bd2fe))


## 2025-06-19

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`ack` - `v0.3.0-beta.1`](#ack---v030-beta1)
 - [`ack_example` - `v0.3.0-beta.2`](#ack_example---v030-beta2)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `ack_example` - `v0.3.0-beta.2`

---

#### `ack` - `v0.3.0-beta.1`

 - **REFACTOR**: Improved json-schema support ([#9](https://github.com/btwld/ack/issues/9)). ([d4da5d94](https://github.com/btwld/ack/commit/d4da5d949a82a1ad5ab8000e97e897724aae5b60))
 - **REFACTOR**: consolidate constraint system and enhance validation pipeline ([#8](https://github.com/btwld/ack/issues/8)). ([e6161a39](https://github.com/btwld/ack/commit/e6161a390d21b15bd741d250c8c04def7ec60d5e))
 - **FEAT**: simplify API compatibility checking with Dart script ([#14](https://github.com/btwld/ack/issues/14)). ([d309f2c2](https://github.com/btwld/ack/commit/d309f2c2b83cd3414bee9462f514fba3a5467aee))
 - **FEAT**: prepare for 0.3.0-beta.1 release ([#11](https://github.com/btwld/ack/issues/11)). ([af70b357](https://github.com/btwld/ack/commit/af70b35774f762a32b9c74a50262c101f92e4795))
 - **FEAT**: Add discriminated union schema support with pattern matching ([#6](https://github.com/btwld/ack/issues/6)). ([9c9aff3c](https://github.com/btwld/ack/commit/9c9aff3c7b0301b695e0bd768a7f07b5583bd2fe))
 - **DOCS**: Fix API inconsistencies across all documentation ([#12](https://github.com/btwld/ack/issues/12)). ([2c57298b](https://github.com/btwld/ack/commit/2c57298b84436b5446fe5e532396e11841d31187))

## 0.3.0-beta.1 (2025-06-19)

* See [release notes](https://github.com/btwld/ack/releases/tag/v0.3.0-beta.1) for details.



## 2025-06-19

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`ack_example` - `v0.3.0-beta.1`](#ack_example---v030-beta1)

---

#### `ack_example` - `v0.3.0-beta.1`

 - **REFACTOR**: Improved json-schema support ([#9](https://github.com/btwld/ack/issues/9)). ([d4da5d94](https://github.com/btwld/ack/commit/d4da5d949a82a1ad5ab8000e97e897724aae5b60))
 - **REFACTOR**: consolidate constraint system and enhance validation pipeline ([#8](https://github.com/btwld/ack/issues/8)). ([e6161a39](https://github.com/btwld/ack/commit/e6161a390d21b15bd741d250c8c04def7ec60d5e))
 - **FEAT**: Add dart_mappable integration for seamless field name synchronization ([#10](https://github.com/btwld/ack/issues/10)). ([66adc71c](https://github.com/btwld/ack/commit/66adc71c8a5fcdacd99aabc7dfa4458fd1501e91))
 - **FEAT**: Add discriminated union schema support with pattern matching ([#6](https://github.com/btwld/ack/issues/6)). ([9c9aff3c](https://github.com/btwld/ack/commit/9c9aff3c7b0301b695e0bd768a7f07b5583bd2fe))


## 2025-06-19

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`ack` - `v0.3.0-beta.1`](#ack---v030-beta1)
 - [`ack_example` - `v0.3.0-beta.2`](#ack_example---v030-beta2)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `ack_example` - `v0.3.0-beta.2`

---

#### `ack` - `v0.3.0-beta.1`

 - **REFACTOR**: Improved json-schema support ([#9](https://github.com/btwld/ack/issues/9)). ([d4da5d94](https://github.com/btwld/ack/commit/d4da5d949a82a1ad5ab8000e97e897724aae5b60))
 - **REFACTOR**: consolidate constraint system and enhance validation pipeline ([#8](https://github.com/btwld/ack/issues/8)). ([e6161a39](https://github.com/btwld/ack/commit/e6161a390d21b15bd741d250c8c04def7ec60d5e))
 - **FEAT**: simplify API compatibility checking with Dart script ([#14](https://github.com/btwld/ack/issues/14)). ([d309f2c2](https://github.com/btwld/ack/commit/d309f2c2b83cd3414bee9462f514fba3a5467aee))
 - **FEAT**: prepare for 0.3.0-beta.1 release ([#11](https://github.com/btwld/ack/issues/11)). ([af70b357](https://github.com/btwld/ack/commit/af70b35774f762a32b9c74a50262c101f92e4795))
 - **FEAT**: Add discriminated union schema support with pattern matching ([#6](https://github.com/btwld/ack/issues/6)). ([9c9aff3c](https://github.com/btwld/ack/commit/9c9aff3c7b0301b695e0bd768a7f07b5583bd2fe))
 - **DOCS**: Fix API inconsistencies across all documentation ([#12](https://github.com/btwld/ack/issues/12)). ([2c57298b](https://github.com/btwld/ack/commit/2c57298b84436b5446fe5e532396e11841d31187))

## 0.3.0-beta.1 (2025-06-18)

* See [release notes](https://github.com/btwld/ack/releases/tag/v0.3.0-beta.1) for details.



## 2025-06-18

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`ack_example` - `v0.3.0-beta.1`](#ack_example---v030-beta1)

---

#### `ack_example` - `v0.3.0-beta.1`

 - **REFACTOR**: Improved json-schema support ([#9](https://github.com/btwld/ack/issues/9)). ([d4da5d94](https://github.com/btwld/ack/commit/d4da5d949a82a1ad5ab8000e97e897724aae5b60))
 - **REFACTOR**: consolidate constraint system and enhance validation pipeline ([#8](https://github.com/btwld/ack/issues/8)). ([e6161a39](https://github.com/btwld/ack/commit/e6161a390d21b15bd741d250c8c04def7ec60d5e))
 - **FEAT**: Add dart_mappable integration for seamless field name synchronization ([#10](https://github.com/btwld/ack/issues/10)). ([66adc71c](https://github.com/btwld/ack/commit/66adc71c8a5fcdacd99aabc7dfa4458fd1501e91))
 - **FEAT**: Add discriminated union schema support with pattern matching ([#6](https://github.com/btwld/ack/issues/6)). ([9c9aff3c](https://github.com/btwld/ack/commit/9c9aff3c7b0301b695e0bd768a7f07b5583bd2fe))


## 2025-06-18

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`ack` - `v0.3.0-beta.1`](#ack---v030-beta1)
 - [`ack_example` - `v1.0.1`](#ack_example---v101)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `ack_example` - `v1.0.1`

---

#### `ack` - `v0.3.0-beta.1`

 - **REFACTOR**: Improved json-schema support ([#9](https://github.com/btwld/ack/issues/9)). ([d4da5d94](https://github.com/btwld/ack/commit/d4da5d949a82a1ad5ab8000e97e897724aae5b60))
 - **REFACTOR**: consolidate constraint system and enhance validation pipeline ([#8](https://github.com/btwld/ack/issues/8)). ([e6161a39](https://github.com/btwld/ack/commit/e6161a390d21b15bd741d250c8c04def7ec60d5e))
 - **FEAT**: prepare for 0.3.0-beta.1 release ([#11](https://github.com/btwld/ack/issues/11)). ([af70b357](https://github.com/btwld/ack/commit/af70b35774f762a32b9c74a50262c101f92e4795))
 - **FEAT**: Add discriminated union schema support with pattern matching ([#6](https://github.com/btwld/ack/issues/6)). ([9c9aff3c](https://github.com/btwld/ack/commit/9c9aff3c7b0301b695e0bd768a7f07b5583bd2fe))

## 0.2.0-beta.1 (2025-05-03)

* See [release notes](https://github.com/btwld/ack/releases/tag/v0.2.0-beta.1) for details.



## 2025-05-03

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`ack` - `v0.2.0-beta.1`](#ack---v020-beta1)

---

#### `ack` - `v0.2.0-beta.1`

 - Bump "ack" to `0.2.0-beta.1`.


## 2025-05-02

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`ack` - `v0.2.0`](#ack---v020)

---

#### `ack` - `v0.2.0`

 - Bump "ack" to 0.2.0 with improved SchemaModel API and enhanced string validation

