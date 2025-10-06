#!/usr/bin/env node

/**
 * Reference JSON Schema Fixture Generator
 *
 * Generates reference JSON Schema Draft-7 fixtures using Zod v4's native toJSONSchema() API.
 * These fixtures serve as the "source of truth" for testing Ack's JSON Schema generation.
 *
 * Approach:
 * 1. Define schemas using Zod (similar API to Ack)
 * 2. Convert to JSON Schema using Zod's native z.toJSONSchema()
 * 3. Validate with AJV to ensure Draft-7 compliance
 * 4. Write fixtures to test-fixtures/reference-schemas/
 */

const { z } = require("zod");
const Ajv = require("ajv");
const addFormats = require("ajv-formats");
const fs = require("fs");
const path = require("path");

console.log("🔧 Generating Zod-based reference JSON Schema fixtures...\n");

// Output directory
const outputDir = path.join(__dirname, "test-fixtures", "reference-schemas");
if (!fs.existsSync(outputDir)) {
  fs.mkdirSync(outputDir, { recursive: true });
}

// Configure AJV for validation (Draft 7)
const ajv = new Ajv({ strict: false, draft: "07" });
addFormats(ajv);

// Reference schemas using Zod - mirrors Ack's schema types
const referenceSchemas = {
  // ==================== String Schemas ====================
  "string-basic": z.string(),
  "string-nullable": z.string().nullable(),
  "string-with-default": z.string().default("default-value"),
  "string-with-description": z
    .string()
    .describe("A descriptive string field"),
  "string-minlength": z.string().min(5),
  "string-maxlength": z.string().max(50),
  "string-length-range": z.string().min(3).max(20),
  "string-email": z.string().email(),
  "string-url": z.string().url(),
  "string-uuid": z.string().uuid(),
  "string-pattern": z.string().regex(/^[A-Z][a-z]+/),
  "string-literal": z.literal("exact-value"),
  "string-email-required": z.string().email().min(5).max(100),
  "string-nullable-with-default": z.string().nullable().default("fallback"),

  // ==================== Integer Schemas ====================
  "integer-basic": z.number().int(),
  "integer-nullable": z.number().int().nullable(),
  "integer-with-default": z.number().int().default(42),
  "integer-with-description": z
    .number()
    .int()
    .describe("A numeric integer field"),
  "integer-min": z.number().int().min(0),
  "integer-max": z.number().int().max(100),
  "integer-range": z.number().int().min(1).max(10),
  "integer-positive": z.number().int().positive(),
  "integer-negative": z.number().int().negative(),
  "integer-nonnegative": z.number().int().nonnegative(),
  "integer-nonpositive": z.number().int().nonpositive(),
  "integer-age-example": z.number().int().min(0).max(120).default(0),

  // ==================== Double Schemas ====================
  "double-basic": z.number(),
  "double-nullable": z.number().nullable(),
  "double-with-default": z.number().default(3.14),
  "double-with-description": z.number().describe("A floating point number"),
  "double-min": z.number().min(0.0),
  "double-max": z.number().max(100.0),
  "double-range": z.number().min(0.0).max(1.0),
  "double-positive": z.number().positive(),
  "double-finite": z.number().finite(),
  "double-price-example": z.number().min(0.01).max(999999.99).default(0.0),

  // ==================== Boolean Schemas ====================
  "boolean-basic": z.boolean(),
  "boolean-nullable": z.boolean().nullable(),
  "boolean-with-default-true": z.boolean().default(true),
  "boolean-with-default-false": z.boolean().default(false),
  "boolean-with-description": z.boolean().describe("A flag indicating status"),

  // ==================== Any Schemas ====================
  "any-basic": z.any(),
  "any-nullable": z.any().nullable(),
  "any-with-default": z.any().default("default-any-value"),
  "any-with-description": z.any().describe("Accepts any value type"),

  // ==================== List/Array Schemas ====================
  "list-of-strings": z.array(z.string()),
  "list-of-integers": z.array(z.number().int()),
  "list-nullable": z.array(z.string()).nullable(),
  "list-with-description": z
    .array(z.string())
    .describe("A list of string values"),
  "list-minlength": z.array(z.string()).min(1),
  "list-maxlength": z.array(z.string()).max(10),
  "list-length-range": z.array(z.number().int()).min(2).max(5),
  "list-of-emails": z.array(z.string().email()),
  "list-of-objects": z.array(
    z.object({
      id: z.number().int(),
      name: z.string(),
    })
  ),

  // ==================== Object Schemas ====================
  "object-basic": z.object({}),
  "object-nullable": z.object({}).nullable(),
  "object-with-description": z
    .object({})
    .describe("An object with properties"),
  "object-simple-user": z.object({
    name: z.string(),
    age: z.number().int(),
  }),
  "object-required-fields": z.object({
    id: z.number().int(),
    email: z.string().email(),
    isActive: z.boolean().default(true),
  }),
  "object-optional-fields": z.object({
    name: z.string(),
    nickname: z.string().optional(),
    age: z.number().int().optional(),
  }),
  "object-nested": z.object({
    user: z.object({
      name: z.string(),
      email: z.string().email(),
    }),
    settings: z.object({
      theme: z.string().default("light"),
      notifications: z.boolean().default(true),
    }),
  }),
  "object-with-array": z.object({
    title: z.string(),
    tags: z.array(z.string()),
    ratings: z.array(z.number().int().min(1).max(5)),
  }),
  "object-additional-properties-allowed": z
    .object({
      name: z.string(),
    })
    .passthrough(),
  "object-comprehensive": z
    .object({
      id: z.number().int().positive(),
      email: z.string().email().min(5).max(100),
      name: z.string().min(2).max(50),
      age: z.number().int().min(0).max(120).nullable(),
      tags: z.array(z.string()).nullable(),
      isActive: z.boolean().default(true),
      metadata: z.any().optional(),
    })
    .describe("A comprehensive user object"),

  // ==================== AnyOf/Union Schemas ====================
  "anyof-string-or-integer": z.union([z.string(), z.number().int()]),
  "anyof-nullable": z.union([z.string(), z.number().int()]).nullable(),
  "anyof-with-description": z
    .union([z.string(), z.boolean()])
    .describe("Either a string or boolean value"),
  "anyof-multiple-types": z.union([
    z.string(),
    z.number().int(),
    z.boolean(),
    z.array(z.string()),
  ]),
  "anyof-objects": z.union([
    z.object({ type: z.literal("text"), content: z.string() }),
    z.object({ type: z.literal("number"), value: z.number().int() }),
  ]),

  // ==================== Discriminated Union Schemas ====================
  "discriminated-basic": z.discriminatedUnion("type", [
    z.object({ type: z.literal("user"), name: z.string(), email: z.string() }),
    z.object({ type: z.literal("admin"), name: z.string(), role: z.string() }),
  ]),
  "discriminated-nullable": z
    .discriminatedUnion("kind", [
      z.object({ kind: z.literal("text"), content: z.string() }),
      z.object({ kind: z.literal("image"), url: z.string().url() }),
    ])
    .nullable(),
  "discriminated-with-description": z
    .discriminatedUnion("eventType", [
      z.object({
        eventType: z.literal("click"),
        x: z.number().int(),
        y: z.number().int(),
      }),
      z.object({ eventType: z.literal("scroll"), delta: z.number().int() }),
    ])
    .describe("A discriminated event union"),
  "discriminated-complex": z.discriminatedUnion("paymentMethod", [
    z.object({
      paymentMethod: z.literal("card"),
      cardNumber: z.string().min(16).max(16),
      cvv: z.string().min(3).max(4),
      expiryDate: z.string(),
    }),
    z.object({
      paymentMethod: z.literal("bank"),
      accountNumber: z.string(),
      routingNumber: z.string(),
    }),
    z.object({
      paymentMethod: z.literal("crypto"),
      wallet: z.string(),
      currency: z.string(),
    }),
  ]),

  // ==================== Enum Schemas ====================
  "enum-user-role": z.enum(["admin", "user", "guest"]),
  "enum-status": z.enum(["active", "inactive", "pending"]),
  "enum-nullable": z.enum(["admin", "user", "guest"]).nullable(),
  "enum-with-default": z.enum(["admin", "user", "guest"]).default("user"),
  "enum-with-description": z
    .enum(["active", "inactive", "pending"])
    .describe("Status of the entity"),
};

// Generate fixtures
let successCount = 0;
let failCount = 0;
const generatedFiles = [];

for (const [name, zodSchema] of Object.entries(referenceSchemas)) {
  try {
    // Use Zod v4's NATIVE toJSONSchema - no external package needed!
    const jsonSchema = z.toJSONSchema(zodSchema, {
      target: "draft-7", // JSON Schema Draft 7
      unrepresentable: "any", // Convert unrepresentable types to {}
      cycles: "ref", // Use $ref for cycles
      reused: "inline", // Inline reused schemas
    });

    // Validate with AJV
    ajv.compile(jsonSchema);
    console.log(`✓ Validated: ${name}`);

    // Write fixture
    const filePath = path.join(outputDir, `${name}.json`);
    fs.writeFileSync(filePath, JSON.stringify(jsonSchema, null, 2));
    console.log(`  → Generated: ${name}.json`);

    generatedFiles.push({
      name,
      path: `test-fixtures/reference-schemas/${name}.json`,
      description: `Reference fixture for ${name.replace(/-/g, " ")}`,
    });

    successCount++;
  } catch (error) {
    console.error(`✗ Failed: ${name}`, error.message);
    failCount++;
  }
}

console.log(
  `\n✅ Generation complete: ${successCount} successful, ${failCount} failed`
);
console.log(`📁 Fixtures written to: ${outputDir}`);

// Create batch validation config
const configPath = path.join(
  __dirname,
  "test-fixtures",
  "reference-config.json"
);
const config = {
  schemas: generatedFiles,
};
fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
console.log(`📝 Batch config written to: ${configPath}`);
