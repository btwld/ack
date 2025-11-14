import 'package:ack/ack.dart';
import 'package:ack_json_schema_builder/ack_json_schema_builder.dart';

void main() async {
  print('=== ACK JSON Schema Builder Converter Examples ===\n');

  // Example 1: Simple User Schema
  print('Example 1: User Schema');
  final userSchema = Ack.object({
    'name': Ack.string().minLength(2).maxLength(50),
    'email': Ack.string().email(),
    'age': Ack.integer().min(0).max(120).optional(),
  });

  final jsonSchema = userSchema.toJsonSchemaBuilder();
  print('Converted schema type: ${jsonSchema.runtimeType}');

  // Example 2: Nested Schema
  print('\nExample 2: Nested Blog Post Schema');
  final blogPostSchema = Ack.object({
    'title': Ack.string().minLength(1).maxLength(200),
    'content': Ack.string().minLength(10),
    'author': Ack.object({
      'name': Ack.string().minLength(2),
      'email': Ack.string().email(),
    }),
    'tags': Ack.list(Ack.string()).minLength(1).maxLength(10),
    'published': Ack.boolean().optional(),
  });

  blogPostSchema.toJsonSchemaBuilder();
  print('Converted nested schema successfully');

  // Example 3: Enum Schema
  print('\nExample 3: Enum Schema');
  final statusSchema = Ack.enumString(['draft', 'published', 'archived']);
  statusSchema.toJsonSchemaBuilder();
  print('Converted enum schema with values');

  // Example 4: Array Schema
  print('\nExample 4: Array Schema');
  final tagsSchema = Ack.list(
    Ack.string().minLength(1),
  ).minLength(1).maxLength(5);
  tagsSchema.toJsonSchemaBuilder();
  print('Converted array schema with constraints');

  print('\n=== Conversion Complete ===');
}
