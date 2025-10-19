// ignore_for_file: unused_local_variable

import 'package:ack/ack.dart';
import 'package:ack_firebase_ai/ack_firebase_ai.dart';

void main() {
  print('=== ACK Firebase AI Converter Examples ===\n');

  // Example 1: Simple User Schema
  print('Example 1: Simple User Schema');
  final userSchema = Ack.object({
    'name': Ack.string().minLength(2).maxLength(50),
    'email': Ack.string().email(),
    'age': Ack.integer().min(0).max(120).optional(),
  });

  final geminiUserSchema = userSchema.toFirebaseAiSchema();
  final userJson = geminiUserSchema.toJson();
  print('Generated schema keys: ${userJson.keys.join(", ")}');
  print('Required fields: ${userJson['required']}');
  print('');

  // Example 2: Blog Post with Nested Objects
  print('Example 2: Blog Post Schema');
  final blogSchema = Ack.object({
    'title': Ack.string().minLength(5).maxLength(100),
    'content': Ack.string().minLength(10),
    'author': Ack.object({
      'name': Ack.string(),
      'email': Ack.string().email(),
    }),
    'tags': Ack.list(Ack.string()).minLength(1).maxLength(5),
    'published': Ack.boolean(),
  });

  final geminiBlogSchema = blogSchema.toFirebaseAiSchema();
  print('Generated blog schema type: ${geminiBlogSchema.type}');
  print('Number of properties: ${geminiBlogSchema.properties?.length ?? 0}');
  print('');

  // Example 3: Product Catalog
  print('Example 3: Product Catalog Schema');
  final productSchema = Ack.object({
    'id': Ack.string().uuid(),
    'name': Ack.string().minLength(1).maxLength(100),
    'description': Ack.string().optional(),
    'price': Ack.double().positive(),
    'currency': Ack.enumString(['USD', 'EUR', 'GBP']),
    'inStock': Ack.boolean(),
    'tags': Ack.list(Ack.string()).maxLength(10).optional(),
  });

  final geminiProductSchema = productSchema.toFirebaseAiSchema();
  print('Product schema required fields: ${geminiProductSchema.toJson()['required']}');
  print('');

  // Example 4: Validating AI Response
  print('Example 4: Semantic Validation');
  final simpleSchema = Ack.object({
    'message': Ack.string().minLength(1),
    'count': Ack.integer().min(0),
  });

  final geminiSimpleSchema = simpleSchema.toFirebaseAiSchema();

  // Simulate AI response
  final aiResponse = {
    'message': 'Hello, World!',
    'count': 42,
  };

  // Validate with ACK
  final result = simpleSchema.safeParse(aiResponse);
  if (result.isOk) {
    print('✅ AI response is valid!');
    print('Message: ${aiResponse['message']}');
    print('Count: ${aiResponse['count']}');
  } else {
    print('❌ AI response failed validation');
    print('Error: ${result.getError()}');
  }
  print('');

  // Example 5: Constraints Preserved
  print('Example 5: Constraint Preservation');
  final constrainedSchema = Ack.string().minLength(5).maxLength(20);
  final geminiConstrainedSchema = constrainedSchema.toFirebaseAiSchema();

  // Test valid data
  final validString = 'hello world';
  final isValid = constrainedSchema.safeParse(validString).isOk;
  print('String "$validString" is valid: $isValid');
  final constrainedJson = geminiConstrainedSchema.toJson();
  print('Gemini schema exposes minLength key: ${constrainedJson.containsKey("minLength")}');
  print('Gemini schema exposes maxLength key: ${constrainedJson.containsKey("maxLength")}');

  // Test invalid data
  final tooShort = 'hi';
  final isTooShortValid = constrainedSchema.safeParse(tooShort).isOk;
  print('String "$tooShort" is valid: $isTooShortValid (constraint enforced)');
  print('');

  print('=== All Examples Complete ===');
}
