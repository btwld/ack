/// Firebase AI (Gemini) schema converter for ACK validation library.
///
/// Converts ACK validation schemas to Firebase AI Schema format for use with
/// Gemini structured output generation.
///
/// ## Usage
///
/// ```dart
/// import 'package:ack/ack.dart';
/// import 'package:ack_firebase_ai/ack_firebase_ai.dart';
/// import 'package:firebase_ai/firebase_ai.dart';
///
/// final schema = Ack.object({
///   'name': Ack.string().minLength(2),
///   'age': Ack.integer().min(0).optional(),
/// });
///
/// // Convert to Firebase AI format
/// final geminiSchema = schema.toFirebaseAiSchema();
///
/// // Use with Firebase AI SDK
/// final model = FirebaseAI.instance.generativeModel(
///   model: 'gemini-1.5-pro',
///   generationConfig: GenerationConfig(
///     responseMimeType: 'application/json',
///     responseSchema: geminiSchema,
///   ),
/// );
/// ```
///
/// ## Limitations
///
/// Some ACK features cannot be converted to Firebase AI format:
/// - Custom refinements (`.refine()`) - validate after AI response
/// - Regex patterns (`.matches()`) - use enum or validate after
/// - Default values - Firebase AI doesn't use them
/// - Transformed schemas (`.transform()`) - convert underlying schema first
/// - String length constraints - metadata not yet exposed by Firebase AI Schema
library;

export 'src/extension.dart';
