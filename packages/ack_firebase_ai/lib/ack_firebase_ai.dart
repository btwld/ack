/// Firebase AI (Gemini) schema converter for ACK validation library.
///
/// Converts ACK validation schemas to Firebase AI's map-based JSON Schema
/// format for structured output generation with Gemini 2.5+ models.
library;

import 'package:ack/ack.dart';

/// Extension methods for converting ACK schemas to Firebase AI format.
extension FirebaseAiResponseJsonSchemaExtension on AckSchema {
  /// Converts this ACK schema for Firebase AI's `responseJsonSchema` field.
  Map<String, Object?> toFirebaseAiResponseJsonSchema() {
    return toSchemaModel().toJsonSchema();
  }
}
