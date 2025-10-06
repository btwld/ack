/// Edge case examples for schema variable type extraction
///
/// This file demonstrates complex scenarios that should work with @AckType:
/// - Lists with typed elements (List<String> not List<dynamic>)
/// - Nested schema references
/// - Complex method chains
/// - Optional and nullable combinations
///
/// These examples serve as both documentation and integration tests.

import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

part 'schema_types_edge_cases.g.dart';

// ============================================================================
// EDGE CASE 1: List Type Extraction
// ============================================================================

/// Schema with various list types
///
/// EXPECTED BEHAVIOR:
/// - tags field should be List<String>, not List<dynamic>
/// - scores field should be List<int>, not List<dynamic>
/// - flags field should be List<bool>, not List<dynamic>
@AckType()
final productSchema = Ack.object({
  'name': Ack.string(),
  'tags': Ack.list(Ack.string()), // Should generate: List<String> get tags
  'scores': Ack.list(Ack.integer()), // Should generate: List<int> get scores
  'flags': Ack.list(Ack.boolean()), // Should generate: List<bool> get flags
});

/// Schema with nested lists (matrix/grid data)
///
/// EXPECTED BEHAVIOR:
/// - matrix field should be List<List<int>>
@AckType()
final gridSchema = Ack.object({
  'name': Ack.string(),
  'matrix': Ack.list(
    Ack.list(Ack.integer()),
  ), // Should generate: List<List<int>> get matrix
});

// ============================================================================
// EDGE CASE 2: Nested Schema References
// ============================================================================

/// Simple address schema for composition
@AckType()
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
/// - Should generate: AddressType get address (or Map<String, dynamic>)
@AckType()
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
@AckType()
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
@AckType()
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
/// - optionalTags: List<String>?, isRequired=false
/// - requiredTags: List<String>, isRequired=true
@AckType()
final taggedItemSchema = Ack.object({
  'name': Ack.string(),
  'requiredTags': Ack.list(Ack.string()),
  'optionalTags': Ack.list(Ack.string()).optional(),
  'nullableTags': Ack.list(Ack.string()).nullable(),
});

/// Schema with list of nested objects (when we support it)
///
/// NOTE: This might not work initially if nested object refs in lists
/// aren't supported. It's documented here as a future enhancement.
///
/// EXPECTED BEHAVIOR (future):
/// - addresses: List<AddressType> or List<Map<String, dynamic>>
@AckType()
final contactListSchema = Ack.object({
  'name': Ack.string(),
  // Future: List of nested schema references
  // 'addresses': Ack.list(addressSchema),
});

// ============================================================================
// EDGE CASE 5: Empty and Minimal Schemas
// ============================================================================

/// Empty schema (edge case)
///
/// EXPECTED BEHAVIOR:
/// - Should generate extension type with no fields
/// - parse() and toJson() should still work
@AckType()
final emptySchema = Ack.object({});

/// Single field schema (minimal case)
@AckType()
final minimalSchema = Ack.object({'id': Ack.string()});

// ============================================================================
// EDGE CASE 6: Naming Variations
// ============================================================================

/// Schema with 'Schema' suffix (should generate NamedType)
@AckType()
final namedItemSchema = Ack.object({'name': Ack.string()});

/// Schema without 'Schema' suffix (should generate ItemType)
@AckType()
final item = Ack.object({'id': Ack.string()});

/// Schema with unusual name (should handle gracefully)
@AckType()
final myCustomSchema123 = Ack.object({'value': Ack.string()});
