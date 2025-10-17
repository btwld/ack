import 'package:ack/ack.dart';
import 'package:firebase_ai/firebase_ai.dart' show Schema;

import 'converter.dart';

/// Extension methods for converting ACK schemas to Firebase AI format.
extension FirebaseAiSchemaExtension on AckSchema {
  /// Converts this ACK schema to Firebase AI (Gemini) Schema format.
  ///
  /// Returns a Firebase AI [Schema] instance for structured output
  /// generation.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final schema = Ack.object({
  ///   'name': Ack.string().minLength(2),
  ///   'age': Ack.integer().min(0).optional(),
  /// });
  ///
  /// final geminiSchema = schema.toFirebaseAiSchema();
  /// ```
  ///
  /// ## Limitations
  ///
  /// Some ACK features cannot be converted:
  /// - Custom refinements (`.refine()`) - validate after AI response
  /// - Regex patterns (`.matches()`) - use enum or validate after
  /// - Default values - not used by Firebase AI
  /// - Transformed schemas (`.transform()`) - convert underlying schema first
  /// - String length constraints - metadata not yet exposed by Firebase AI Schema
  ///
  /// ## Firebase AI Schema Format
  ///
  /// The returned [Schema] follows Firebase AI's schema format (a subset of
  /// OpenAPI 3.0). Key fields include:
  /// - `type`: The schema type (string, integer, number, boolean, object, array)
  /// - `properties`: For object types, map of property names to child schemas
  /// - `optionalProperties`: Keys that are optional (everything else is required)
  /// - `items`: For array types, the schema for array items
  /// - `enumValues`: For enum types, array of allowed values
  /// - `nullable`: Whether the value can be null
  /// - `description`: Human-readable description
  Schema toFirebaseAiSchema() {
    return FirebaseAiSchemaConverter.convert(this);
  }
}
