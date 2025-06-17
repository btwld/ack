#!/usr/bin/env node

/**
 * JSON Schema Draft-7 Validator for Ack
 *
 * This script validates that Ack-generated JSON schemas are valid JSON Schema Draft-7
 * specifications using industry-standard JSON Schema validation.
 *
 * Usage:
 *   node tools/jsonschema-validator.js validate-schema --schema schema.json [--output results.json]
 *   node tools/jsonschema-validator.js validate-batch --input batch-config.json [--output results.json]
 *
 * Batch config format:
 * {
 *   "schemas": [
 *     {
 *       "name": "user-schema",
 *       "path": "path/to/user-schema.json",
 *       "description": "User schema validation"
 *     },
 *     {
 *       "name": "product-schema",
 *       "path": "path/to/product-schema.json",
 *       "description": "Product schema validation"
 *     }
 *   ]
 * }
 */

const Ajv = require("ajv");
const addFormats = require("ajv-formats");
const fs = require("fs");
const path = require("path");
const { program } = require("commander");

// Configure JSON Schema validator with Draft 7 support
const ajv = new Ajv({
  strict: false,
  allErrors: true,
  verbose: true,
  draft: "07",
});

// Add format validators (email, date-time, uuid, etc.)
addFormats(ajv);

/**
 * Validate that a schema conforms to JSON Schema Draft-7 specification
 */
function validateSchemaSpecification(schema, schemaName = "schema") {
  try {
    // Validate against the JSON Schema Draft-7 meta-schema
    const isValidMetaSchema = ajv.validateSchema(schema);

    if (!isValidMetaSchema) {
      return {
        valid: false,
        errors: ajv.errors || [
          { message: "Schema does not conform to JSON Schema Draft-7" },
        ],
        schemaName,
        schema: schema,
        validationType: "meta-schema",
      };
    }

    // Try to compile the schema to ensure it's syntactically correct
    try {
      ajv.compile(schema);
      return {
        valid: true,
        errors: [],
        schemaName,
        schema: schema,
        validationType: "compilation",
      };
    } catch (compilationError) {
      return {
        valid: false,
        errors: [
          { message: `Schema compilation failed: ${compilationError.message}` },
        ],
        schemaName,
        schema: schema,
        validationType: "compilation",
        compilationError: true,
      };
    }
  } catch (error) {
    return {
      valid: false,
      errors: [{ message: `Schema validation error: ${error.message}` }],
      schemaName,
      schema: schema,
      validationType: "error",
      validationError: true,
    };
  }
}

/**
 * Load JSON file with error handling
 */
function loadJsonFile(filePath) {
  try {
    const content = fs.readFileSync(filePath, "utf8");
    return JSON.parse(content);
  } catch (error) {
    throw new Error(`Failed to load ${filePath}: ${error.message}`);
  }
}

/**
 * Validate a single JSON schema specification
 */
function runSchemaValidation(schemaPath, outputPath, options = {}) {
  const { silent = false, jsonOutput = false } = options;

  if (!silent) {
    console.log(`🔍 Validating JSON Schema specification: ${schemaPath}`);
  }

  const schema = loadJsonFile(schemaPath);
  const result = validateSchemaSpecification(schema, path.basename(schemaPath));

  const output = {
    timestamp: new Date().toISOString(),
    schemaPath,
    result,
  };

  if (outputPath) {
    fs.writeFileSync(outputPath, JSON.stringify(output, null, 2));
    if (!silent) {
      console.log(`📄 Results written to ${outputPath}`);
    }
  }

  if (jsonOutput) {
    // Output JSON for programmatic consumption
    console.log(JSON.stringify(result));
  } else if (!silent) {
    console.log(
      `✅ Schema ${result.valid ? "VALID" : "INVALID"} JSON Schema Draft-7`
    );
    if (!result.valid) {
      console.log("❌ Errors:", JSON.stringify(result.errors, null, 2));
    }
  }

  return output;
}

/**
 * Run batch schema validation from config file
 */
function runBatchSchemaValidation(configPath, outputPath) {
  console.log(`🔄 Running batch schema validation from ${configPath}`);

  const config = loadJsonFile(configPath);
  const results = {
    timestamp: new Date().toISOString(),
    configPath,
    schemas: [],
  };

  for (const schemaConfig of config.schemas) {
    console.log(`\n📋 Validating schema: ${schemaConfig.name}`);

    const schema = loadJsonFile(schemaConfig.path);
    const result = validateSchemaSpecification(schema, schemaConfig.name);

    const schemaResult = {
      name: schemaConfig.name,
      description: schemaConfig.description || "",
      path: schemaConfig.path,
      result: result,
    };

    console.log(
      `📊 Schema ${schemaConfig.name}: ${result.valid ? "VALID" : "INVALID"}`
    );
    if (!result.valid) {
      console.log(`❌ Errors:`, JSON.stringify(result.errors, null, 2));
    }

    results.schemas.push(schemaResult);
  }

  if (outputPath) {
    fs.writeFileSync(outputPath, JSON.stringify(results, null, 2));
    console.log(`📄 Batch results written to ${outputPath}`);
  }

  // Summary
  const totalSchemas = results.schemas.length;
  const validSchemas = results.schemas.filter((s) => s.result.valid).length;
  console.log(
    `\n🎯 Summary: ${validSchemas}/${totalSchemas} schemas are valid JSON Schema Draft-7`
  );

  return results;
}

// CLI setup
program
  .name("jsonschema-validator")
  .description("Validate Ack-generated JSON Schema Draft-7 specifications")
  .version("1.0.0");

program
  .command("validate-schema")
  .description("Validate a single JSON Schema Draft-7 specification")
  .requiredOption("-s, --schema <path>", "Path to JSON schema file")
  .option("-o, --output <path>", "Path to output results file")
  .option("--json", "Output result as JSON")
  .option("--silent", "Suppress console output")
  .action((options) => {
    try {
      const result = runSchemaValidation(options.schema, options.output, {
        jsonOutput: options.json,
        silent: options.silent,
      });
      process.exit(result.result.valid ? 0 : 1);
    } catch (error) {
      console.error("❌ Error:", error.message);
      process.exit(1);
    }
  });

program
  .command("validate-batch")
  .description("Run batch schema validation from config file")
  .requiredOption("-i, --input <path>", "Path to batch config JSON file")
  .option("-o, --output <path>", "Path to output results file")
  .action((options) => {
    try {
      const results = runBatchSchemaValidation(options.input, options.output);
      const allValid = results.schemas.every((s) => s.result.valid);
      process.exit(allValid ? 0 : 1);
    } catch (error) {
      console.error("❌ Error:", error.message);
      process.exit(1);
    }
  });

// Default command for backward compatibility
if (
  process.argv.length > 2 &&
  ![
    "validate-schema",
    "validate-batch",
    "--help",
    "-h",
    "--version",
    "-V",
  ].includes(process.argv[2])
) {
  // Legacy mode: node jsonschema-validator.js schema.json [output.json]
  const [, , schemaPath, outputPath] = process.argv;

  if (!schemaPath) {
    console.error(
      "❌ Usage: node jsonschema-validator.js <schema.json> [output.json]"
    );
    process.exit(1);
  }

  try {
    const result = runSchemaValidation(schemaPath, outputPath);
    process.exit(result.result.valid ? 0 : 1);
  } catch (error) {
    console.error("❌ Error:", error.message);
    process.exit(1);
  }
} else {
  program.parse();
}
