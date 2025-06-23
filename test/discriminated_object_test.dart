import 'package:ack/ack.dart';

void main() {
  // Define schemas for different types
  final catSchema = Ack.object({
    'type': Ack.string(),
    'meow': Ack.boolean(),
  }, required: ['type', 'meow']);

  final dogSchema = Ack.object({
    'type': Ack.string(),
    'bark': Ack.boolean(),
  }, required: ['type', 'bark']);

  // Create a discriminated schema
  final animalSchema = Ack.discriminated(
    discriminatorKey: 'type',
    schemas: {
      'cat': catSchema,
      'dog': dogSchema,
    },
  );

  // Test 1: Basic usage
  print('Test 1: Basic usage');
  final catResult = animalSchema.validate({'type': 'cat', 'meow': true});
  print('Cat validation: ${catResult.isOk}'); // Should be true

  final dogResult = animalSchema.validate({'type': 'dog', 'bark': false});
  print('Dog validation: ${dogResult.isOk}'); // Should be true

  // Test 2: Using fluent methods
  print('\nTest 2: Using fluent methods');
  
  // Create a nullable version
  final nullableAnimalSchema = animalSchema.nullable();
  print('Nullable schema created: ${nullableAnimalSchema.isNullable}'); // Should be true
  
  // Test null value
  final nullResult = nullableAnimalSchema.validate(null);
  print('Null validation: ${nullResult.isOk}'); // Should be true

  // Test 3: Add description
  print('\nTest 3: Add description');
  final describedSchema = animalSchema.withDescription('An animal discriminated by type');
  print('Description: ${describedSchema.description}'); // Should print the description

  // Test 4: Add default value
  print('\nTest 4: Add default value');
  final defaultCat = {'type': 'cat', 'meow': true};
  final schemaWithDefault = animalSchema.withDefault(defaultCat);
  print('Default value: ${schemaWithDefault.defaultValue}'); // Should print the default cat

  // Test 5: Chain multiple fluent methods
  print('\nTest 5: Chain multiple fluent methods');
  final fullyConfiguredSchema = animalSchema
      .nullable()
      .withDescription('Nullable animal schema')
      .withDefault(defaultCat);
  
  print('Is nullable: ${fullyConfiguredSchema.isNullable}');
  print('Description: ${fullyConfiguredSchema.description}');
  print('Default: ${fullyConfiguredSchema.defaultValue}');

  // Test 6: Validation errors
  print('\nTest 6: Validation errors');
  final invalidResult = animalSchema.validate({'type': 'bird', 'fly': true});
  print('Invalid type validation: ${invalidResult.isOk}'); // Should be false
  
  final missingDiscriminator = animalSchema.validate({'meow': true});
  print('Missing discriminator validation: ${missingDiscriminator.isOk}'); // Should be false
}