/// ACK - A comprehensive validation library for Dart
///
/// Inspired by Zod (TypeScript), provides type-safe schema validation
/// with a fluent API for runtime data validation and transformation.
library;

// Main API
export 'src/ack.dart';
// Constraints
export 'src/constraints/constraint.dart';
export 'src/constraints/datetime_constraint.dart';
// Context
export 'src/context.dart';
// Extensions
export 'src/schemas/extensions/ack_schema_extensions.dart';
export 'src/schemas/extensions/datetime_schema_extensions.dart';
export 'src/schemas/extensions/list_schema_extensions.dart';
export 'src/schemas/extensions/numeric_extensions.dart';
export 'src/schemas/extensions/object_schema_extensions.dart';
export 'src/schemas/extensions/string_schema_extensions.dart';
// JSON Schema
export 'src/json_schema.dart';
// Core schemas
export 'src/schemas/schema.dart';
export 'src/validation/ack_exception.dart';
export 'src/validation/schema_error.dart';
// Validation results
export 'src/validation/schema_result.dart';
