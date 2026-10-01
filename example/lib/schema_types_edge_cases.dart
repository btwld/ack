/// Edge case examples for schema variable type extraction
///
/// This file demonstrates complex scenarios that should work with @Schemable:
/// - Lists with typed elements (`List<String>` not `List<dynamic>`)
/// - Nested schema references
/// - Complex method chains
/// - Optional and nullable combinations
///
/// These examples serve as both documentation and integration tests.
library;

import 'package:ack/ack.dart';

part 'schema_types_edge_cases.ack.dart';
part 'schema_types_edge_cases.ack.g.dart';

// ============================================================================
// EDGE CASE 1: List Type Extraction
// ============================================================================

/// Schema with various list types
///
/// EXPECTED BEHAVIOR:
/// - tags field should be `List<String>`, not `List<dynamic>`
/// - scores field should be `List<int>`, not `List<dynamic>`
/// - flags field should be `List<bool>`, not `List<dynamic>`
@Schemable()
final productSchema = Ack.object({
  'name': Ack.string(),
  'tags': Ack.list(Ack.string()), // Generates: final List<String> tags
  'scores': Ack.list(Ack.integer()), // Generates: final List<int> scores
  'flags': Ack.list(Ack.boolean()), // Generates: final List<bool> flags
});

/// Schema with nested lists (matrix/grid data)
///
/// EXPECTED BEHAVIOR:
/// - matrix field should be `List<List<int>>`
@Schemable()
final gridSchema = Ack.object({
  'name': Ack.string(),
  'matrix': Ack.list(
    Ack.list(Ack.integer()),
  ), // Generates: final List<List<int>> matrix
});

// ============================================================================
// EDGE CASE 2: Nested Schema References
// ============================================================================

/// Simple address schema for composition
@Schemable()
final addressSchema = Ack.object({
  'street': Ack.string(),
  'city': Ack.string(),
  'zipCode': Ack.string(),
  'country': Ack.string(),
});

/// Schema that references another schema variable
///
/// EXPECTED BEHAVIOR:
/// - address field should NOT be null/missing
/// - Generates: `final Address address`
@Schemable()
final personSchema = Ack.object({
  'name': Ack.string(),
  'email': Ack.string(),
  'address': addressSchema, // Reference to another schema
  'age': Ack.integer(),
});

/// Schema with multiple nested references
///
/// EXPECTED BEHAVIOR:
/// - Both homeAddress and workAddress fields should be present
@Schemable()
final employeeSchema = Ack.object({
  'name': Ack.string(),
  'employeeId': Ack.string(),
  'homeAddress': addressSchema, // First reference
  'workAddress': addressSchema, // Second reference to same schema
});

// ============================================================================
// EDGE CASE 3: Complex Method Chains
// ============================================================================

/// Schema with various modifier combinations
///
/// EXPECTED BEHAVIOR:
/// - optionalField: isRequired=false, isNullable=false
/// - nullableField: isRequired=true, isNullable=true
/// - optionalNullable: isRequired=false, isNullable=true
/// - requiredField: isRequired=true, isNullable=false
@Schemable()
final modifierSchema = Ack.object({
  'requiredField': Ack.string(),
  'optionalField': Ack.string().optional(),
  'nullableField': Ack.string().nullable(),
  'optionalNullable': Ack.string().optional().nullable(),
  'nullableOptional': Ack.string().nullable().optional(), // Different order
});

// ============================================================================
// EDGE CASE 4: Mixed Complex Scenarios
// ============================================================================

/// Schema combining lists and optional modifiers
///
/// EXPECTED BEHAVIOR:
/// - optionalTags: `List<String>?`, isRequired=false
/// - requiredTags: `List<String>`, isRequired=true
@Schemable()
final taggedItemSchema = Ack.object({
  'name': Ack.string(),
  'requiredTags': Ack.list(Ack.string()),
  'optionalTags': Ack.list(Ack.string()).optional(),
  'nullableTags': Ack.list(Ack.string()).nullable(),
});

/// Schema with list of nested objects
///
/// EXPECTED BEHAVIOR:
/// - addresses: `List<Address>` (eager list with typed elements)
@Schemable()
final contactListSchema = Ack.object({
  'name': Ack.string(),
  'addresses': Ack.list(addressSchema),
});

// ============================================================================
// EDGE CASE 5: Empty and Minimal Schemas
// ============================================================================

/// Empty schema (edge case)
///
/// EXPECTED BEHAVIOR:
/// Generates an immutable model with no stored schema fields.
/// - parse() should still work
@Schemable()
final emptySchema = Ack.object({});

/// Single field schema (minimal case)
@Schemable()
final minimalSchema = Ack.object({'id': Ack.string()});

// ============================================================================
// EDGE CASE 6: Naming Variations
// ============================================================================

/// Schema with 'Schema' suffix (generates `NamedItem`)
@Schemable()
final namedItemSchema = Ack.object({'name': Ack.string()});

/// Schema without 'Schema' suffix (generates `Item`)
@Schemable()
final item = Ack.object({'id': Ack.string()});

/// Schema with unusual name (should handle gracefully)
@Schemable()
final myCustomSchema123 = Ack.object({'value': Ack.string()});
