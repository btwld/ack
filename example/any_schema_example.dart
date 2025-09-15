import 'package:ack/ack.dart';

void main() {
  print('=== AnySchema Examples ===\n');

  // Basic any schema - accepts anything
  final anySchema = Ack.any();

  print('Basic AnySchema validation:');
  print('  42: ${anySchema.validate(42).getOrThrow()}');
  print('  "hello": ${anySchema.validate("hello").getOrThrow()}');
  print('  [1,2,3]: ${anySchema.validate([1, 2, 3]).getOrThrow()}');
  print('  {"a": 1}: ${anySchema.validate({"a": 1}).getOrThrow()}');
  print('  true: ${anySchema.validate(true).getOrThrow()}');
  print('  3.14: ${anySchema.validate(3.14).getOrThrow()}');

  // Null handling
  print('\nNull handling:');
  final nullResult = anySchema.validate(null);
  print(
      '  null (non-nullable): ${nullResult.isFail ? "REJECTED" : "ACCEPTED"}');

  // With nullable support
  final nullableAny = Ack.any().nullable();
  final nullableResult = nullableAny.validate(null);
  print('  null (nullable): ${nullableResult.isOk ? "ACCEPTED" : "REJECTED"}');

  // With default value
  print('\nWith default value:');
  final withDefault = Ack.any().withDefault("fallback");
  print(
      '  null input with default: ${withDefault.validate(null).getOrThrow()}');
  print('  42 input with default: ${withDefault.validate(42).getOrThrow()}');

  // With refinements for custom validation
  print('\nWith refinements:');
  final refinedAny = Ack.any().refine((value) => value.toString().length > 3,
      message: "String representation must be longer than 3 characters");

  print(
      '  "hello" (length > 3): ${refinedAny.validate("hello").isOk ? "PASS" : "FAIL"}');
  print(
      '  "hi" (length <= 3): ${refinedAny.validate("hi").isOk ? "PASS" : "FAIL"}');
  print(
      '  12345 (length > 3): ${refinedAny.validate(12345).isOk ? "PASS" : "FAIL"}');
  print(
      '  42 (length <= 3): ${refinedAny.validate(42).isOk ? "PASS" : "FAIL"}');

  // JSON Schema generation
  print('\nJSON Schema generation:');
  final describedSchema =
      Ack.any().withDescription("Accepts any value").withDefault("fallback");

  print('  JSON Schema: ${describedSchema.toJsonSchema()}');

  // Use cases
  print('\n=== Use Cases ===');

  // 1. Dynamic configuration
  print('\n1. Dynamic configuration:');
  final configSchema = Ack.object({
    'name': Ack.string(),
    'version': Ack.string(),
    'settings': Ack.any(), // Accept any configuration structure
  });

  final config1 = {
    'name': 'MyApp',
    'version': '1.0.0',
    'settings': {'theme': 'dark', 'debug': true}
  };

  final config2 = {
    'name': 'MyApp',
    'version': '1.0.0',
    'settings': ['feature1', 'feature2', 'feature3']
  };

  print(
      '  Config with object settings: ${configSchema.validate(config1).isOk ? "VALID" : "INVALID"}');
  print(
      '  Config with array settings: ${configSchema.validate(config2).isOk ? "VALID" : "INVALID"}');

  // 2. API endpoints with flexible payloads
  print('\n2. Flexible API payload:');
  final apiSchema = Ack.object({
    'action': Ack.string(),
    'timestamp': Ack.string(),
    'payload': Ack.any(), // Accept any payload structure
  });

  final apiCall = {
    'action': 'user_update',
    'timestamp': '2024-01-01T00:00:00Z',
    'payload': {
      'userId': 123,
      'changes': {'name': 'John', 'email': 'john@example.com'}
    }
  };

  print(
      '  API call validation: ${apiSchema.validate(apiCall).isOk ? "VALID" : "INVALID"}');

  // 3. Migration scenarios
  print('\n3. Migration scenario:');
  final legacySchema = Ack.object({
    'id': Ack.string(),
    'data': Ack.any(), // Legacy data can be anything
  }).refine((obj) => obj['id'] != null && (obj['id'] as String).isNotEmpty,
      message: "ID must not be empty");

  final legacyData = {
    'id': 'legacy-123',
    'data': 'some old string format' // Could be string, object, array, etc.
  };

  print(
      '  Legacy data validation: ${legacySchema.validate(legacyData).isOk ? "VALID" : "INVALID"}');
}
