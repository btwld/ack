# Ack Fluent API Refactor Plan

This document outlines the plan to implement a fluent, Zod-inspired API for the Ack validation library. The work is broken down by schema type and is based on a detailed analysis of our current architecture and the capabilities of the Zod library.

---

### **Guiding Principles**

1.  **Universal Methods go on the Base Class**: Any capability that can apply to *any* schema (like making it nullable or adding a description) should be a method on the base `AckSchema`.
2.  **Specific Methods go in Extensions**: Capabilities that only make sense for a specific type (e.g., email validation for strings) should be implemented as extension methods on that specific schema class (`StringSchema`, `ListSchema`, etc.). This keeps the core classes clean.
3.  **Unsupported Features**: We will clearly mark features from Zod that we cannot or should not implement right now due to significant architectural differences (e.g., transformations, async validation).

---

### **1. `AckSchema` (Base Class Methods)**

These methods will be added directly to the `AckSchema<T>` class because they are universal.

| Method Signature | Zod Equivalent | Why Here? | Implementation Notes |
| :--- | :--- | :--- | :--- |
| `nullable()` | `.nullable()` | Makes any schema type nullable. This is the most fundamental and universal operation. | Already implemented via the `.nullable()` extension. No new work needed. |
| `default(T value)` | `.default(value)` | Sets a default value if the input is `null` or `undefined`. A universal concept. | Already implemented via the `defaultValue` constructor parameter. The `copyWith` pattern allows us to set it fluently. |
| `description(String text)` | `.describe(text)` | Adds a description for documentation/error message purposes. Universal. | Already implemented via the `description` constructor parameter. |

**Conclusion:** The most fundamental universal methods are already supported by our new architecture.

---

### **2. `StringSchema` Extensions**

These will be implemented in a new file: `lib/src/schemas/extensions/string_schema_extensions.dart`.

| Method Signature | Zod Equivalent | Why Here? | Support Level |
| :--- | :--- | :--- | :--- |
| `minLength(int n)` | `.min(n)` | String-specific length validation. | **Can Support Now** |
| `maxLength(int n)` | `.max(n)` | String-specific length validation. | **Can Support Now** |
| `length(int n)` | `.length(n)` | String-specific length validation. | **Can Support Now** |
| `email()` | `.email()` | String-specific format validation. | **Can Support Now** |
| `url()` | `.url()` | String-specific format validation. | **Can Support Now** |
| `uuid()` | `.uuid()` | String-specific format validation. | **Can Support Now** |
| `cuid()` | `.cuid()` | String-specific format validation. | **Can Support Now** (less common, maybe lower priority) |
| `datetime()` | `.datetime()` | String-specific format validation. | **Can Support Now** |
| `regex(RegExp re)` | `.regex(re)` | String-specific pattern matching. | **Can Support Now** |
| `startsWith(String s)` | `.startsWith(s)` | String-specific content validation. | **Can Support Now** |
| `endsWith(String s)` | `.endsWith(s)` | String-specific content validation. | **Can Support Now** |
| `trim()` | `.trim()` | **Transformation**. | **Cannot Support Now**. Our architecture validates, it doesn't transform the input value. |
| `toLowerCase()` | `.toLowerCase()` | **Transformation**. | **Cannot Support Now**. |
| `toUpperCase()` | `.toUpperCase()` | **Transformation**. | **Cannot Support Now**. |

---

### **3. `IntegerSchema` & `DoubleSchema` Extensions**

These will be in `lib/src/schemas/extensions/num_schema_extensions.dart`.

| Method Signature | Zod Equivalent | Why Here? | Support Level |
| :--- | :--- | :--- | :--- |
| `gt(num n)` / `greaterThan(num n)` | `.gt(n)` | Numeric comparison. | **Can Support Now** |
| `gte(num n)` / `min(num n)` | `.gte(n)` | Numeric comparison. | **Can Support Now** |
| `lt(num n)` / `lessThan(num n)` | `.lt(n)` | Numeric comparison. | **Can Support Now** |
| `lte(num n)` / `max(num n)` | `.lte(n)` | Numeric comparison. | **Can Support Now** |
| `isPositive()` | `.positive()` | Numeric sign check. | **Can Support Now** |
| `isNegative()` | `.negative()` | Numeric sign check. | **Can Support Now** |
| `isNonPositive()` | `.nonpositive()` | Numeric sign check. | **Can Support Now** |
| `isNonNegative()` | `.nonnegative()` | Numeric sign check. | **Can Support Now** |
| `multipleOf(num n)` / `step(num n)` | `.multipleOf(n)` | Numeric divisibility check. | **Can Support Now** |
| `finite()` | `.finite()` | Checks if a number is finite. | **Can Support Now** (More relevant for `DoubleSchema`) |
| `safe()` | `.safe()` | Checks if an integer is a "safe" integer. | **Can Support Now** (For `IntegerSchema`) |

---

### **4. `ListSchema` Extensions**

These will be in `lib/src/schemas/extensions/list_schema_extensions.dart`.

| Method Signature | Zod Equivalent | Why Here? | Support Level |
| :--- | :--- | :--- | :--- |
| `minLength(int n)` | `.min(n)` | List-specific length validation. | **Can Support Now** |
| `maxLength(int n)` | `.max(n)` | List-specific length validation. | **Can Support Now** |
| `length(int n)` | `.length(n)` | List-specific length validation. | **Can Support Now** |
| `nonempty()` | `.nonempty()` | A convenient shorthand for `.minLength(1)`. | **Can Support Now** |

---

### **5. `ObjectSchema` Extensions**

This is where things get more complex. Our `ObjectSchema` is powerful but doesn't have all of Zod's dynamic capabilities.

| Method Signature | Zod Equivalent | Why Here? | Support Level |
| :--- | :--- | :--- | :--- |
| `pick(List<String> keys)` | `.pick()` | **Structural Transformation**. | **Cannot Support Now**. This creates a *new* schema type by altering the properties. Our `copyWith` can't do this. |
| `omit(List<String> keys)` | `.omit()` | **Structural Transformation**. | **Cannot Support Now**. Same reason as `pick`. |
| `partial()` | `.partial()` | **Structural Transformation**. | **Cannot Support Now**. This changes the `required` status of all properties, which would require deep schema cloning. |
| `deepPartial()` | `.deepPartial()` | **Structural Transformation**. | **Cannot Support Now**. Even more complex than `partial`. |
| `merge(ObjectSchema other)` | `.merge()` | Combines two object schemas. | **Can Support Now (with limitations)**. We can implement a version of this that merges properties and `required` fields. |
| `passthrough()` | `.`passthrough()` | Allows unknown keys. | **Already Supported**. This is our `allowAdditionalProperties: true` flag. We could add a fluent method for it. |
| `strict()` | `.strict()` | Disallows unknown keys. | **Already Supported**. This is our `allowAdditionalProperties: false` flag. We could add a fluent method for it. |
| `catchall(AckSchema valueSchema)` | `.catchall()` | Validates all unknown keys against a schema. | **Cannot Support Now**. Our current implementation only checks for the *presence* of additional properties, not their *values*. |

---

### **6. Features We Cannot Support (The "Why")**

*   **Transformations (`.trim()`, `.toLowerCase()`, `.transform()`, `.refine()`)**:
    *   **Reason:** Our architecture has a clear separation of concerns: a schema's job is to **validate** an input and return a `SchemaResult` with either the original (but correctly typed) value or an error. It does not **mutate or transform** the input value. Zod's `.transform()` and `.refine()` fundamentally change the output value, which is a different paradigm. Supporting this would require a major redesign of the `parseAndValidate` flow.

*   **Structural Transformations (`.pick()`, `.omit()`, `.partial()`)**:
    *   **Reason:** These methods in Zod dynamically create *new* schema definitions at runtime by introspecting and cloning existing schemas. Our `copyWith` pattern is great for creating a modified *copy*, but it's not designed for this level of dynamic, structural alteration (e.g., removing keys from the `properties` map and the `requiredProperties` list simultaneously). It's possible, but would require significantly more complex logic in the `ObjectSchema`'s `copyWith` method.

*   **Asynchronous Validation (`.refineAsync()`)**:
    *   **Reason:** Our entire validation pipeline (`validate` -> `parseAndValidate` -> `SchemaResult`) is synchronous. Introducing `async` validation would require making the entire pipeline return `Future<SchemaResult>`, which is a massive and breaking change across the entire library. 