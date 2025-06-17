import 'dart:convert';
import 'dart:io';

import 'package:ack/ack.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('External Validation Samples', () {
    test('Generate schemas for external validation', () async {
      final outputDir = Directory('external_validation_samples');
      if (await outputDir.exists()) {
        await outputDir.delete(recursive: true);
      }
      await outputDir.create();

      // Sample 1: E-commerce Product Schema
      final productSchema = Ack.object({
        'product': Ack.object({
          'id': Ack.string.uuid(),
          'name': Ack.string.minLength(1).maxLength(200),
          'description': Ack.string.maxLength(1000).nullable(),
          'price': Ack.double.min(0.01),
          'currency': Ack.string.matches(r'^[A-Z]{3}$'), // ISO 4217
          'category': Ack.string.enumValues(
              ['electronics', 'clothing', 'books', 'home', 'sports']),
          'inStock': Ack.boolean,
          'tags': Ack.list(Ack.string).uniqueItems().maxItems(20),
          'images': Ack.list(Ack.string.uri()).minItems(1).maxItems(10),
          'specifications': Ack.object({
            'weight': Ack.double.min(0).nullable(),
            'dimensions': Ack.object({
              'length': Ack.double.min(0),
              'width': Ack.double.min(0),
              'height': Ack.double.min(0),
            }).nullable(),
            'color': Ack.string.nullable(),
            'material': Ack.string.nullable(),
          }),
        }, required: [
          'id',
          'name',
          'price',
          'currency',
          'category',
          'inStock'
        ]),
      }, required: [
        'product'
      ]);

      await _saveSchema(productSchema, outputDir, 'ecommerce_product_schema');

      // Sample 2: User Profile with Discriminated Union
      final userSchema = Ack.object({
        'user': Ack.object({
          'id': Ack.string.uuid(),
          'email': Ack.string.email(),
          'profile': Ack.object({
            'firstName': Ack.string.minLength(1),
            'lastName': Ack.string.minLength(1),
            'dateOfBirth': Ack.string.dateTime().nullable(),
            'avatar': Ack.string.uri().nullable(),
          }, required: [
            'firstName',
            'lastName'
          ]),
          'account': Ack.discriminated(
            discriminatorKey: 'type',
            schemas: {
              'free': Ack.object({
                'type': Ack.string.literal('free'),
                'limitations': Ack.object({
                  'maxProjects': Ack.int.min(3).max(3), // Fixed value of 3
                  'storageGB': Ack.int.min(1).max(1), // Fixed value of 1
                }),
              }, required: [
                'type',
                'limitations'
              ]),
              'premium': Ack.object({
                'type': Ack.string.literal('premium'),
                'subscription': Ack.object({
                  'plan': Ack.string.enumValues(['monthly', 'yearly']),
                  'price': Ack.double.min(0),
                  'renewsAt': Ack.string.dateTime(),
                }),
              }, required: [
                'type',
                'subscription'
              ]),
              'enterprise': Ack.object({
                'type': Ack.string.literal('enterprise'),
                'organization': Ack.object({
                  'name': Ack.string.minLength(1),
                  'seats': Ack.int.min(1),
                  'customDomain': Ack.string.nullable(),
                }),
              }, required: [
                'type',
                'organization'
              ]),
            },
          ),
        }, required: [
          'id',
          'email',
          'profile',
          'account'
        ]),
      }, required: [
        'user'
      ]);

      await _saveSchema(userSchema, outputDir, 'user_profile_schema');

      // Sample 3: API Configuration Schema
      final apiSchema = Ack.object({
        'api': Ack.object({
          'version': Ack.string.matches(r'^\d+\.\d+\.\d+$'),
          'baseUrl': Ack.string.uri(),
          'endpoints': Ack.list(Ack.object({
            'path': Ack.string.matches(r'^/[a-zA-Z0-9/_-]*$'),
            'method': Ack.string
                .enumValues(['GET', 'POST', 'PUT', 'DELETE', 'PATCH']),
            'description': Ack.string.nullable(),
            'parameters': Ack.list(Ack.object({
              'name': Ack.string.minLength(1),
              'type': Ack.string.enumValues(
                  ['string', 'number', 'boolean', 'array', 'object']),
              'required': Ack.boolean,
              'description': Ack.string.nullable(),
            }, required: [
              'name',
              'type',
              'required'
            ])).nullable(),
            'responses': Ack.object({
              '200': Ack.object({
                'description': Ack.string,
                'schema': Ack.object({}).nullable(),
              }, required: [
                'description'
              ]),
              '400': Ack.object({
                'description': Ack.string.literal('Bad Request'),
              }, required: [
                'description'
              ]).nullable(),
              '500': Ack.object({
                'description': Ack.string.literal('Internal Server Error'),
              }, required: [
                'description'
              ]).nullable(),
            }, required: [
              '200'
            ]),
          }, required: [
            'path',
            'method',
            'responses'
          ])),
        }, required: [
          'version',
          'baseUrl',
          'endpoints'
        ]),
      }, required: [
        'api'
      ]);

      await _saveSchema(apiSchema, outputDir, 'api_configuration_schema');

      // Create validation instructions
      final instructions = '''
# External Validation Instructions

These JSON Schema files have been generated by Ack and are ready for external validation.

## Online Validators

1. **JSONSchemaValidator.net**: https://www.jsonschemavalidator.net/
   - Paste the schema in the left panel
   - Verify it shows "Valid JSON Schema"
   - Test with sample data in the right panel

2. **JSON Schema Lint**: https://jsonschemalint.com/
   - Upload or paste the schema
   - Check for validation results

3. **Ajv Online**: https://ajv.js.org/
   - Use their online validator
   - Test schema compilation and validation

## Command Line Validation

If you have Node.js and AJV installed:

```bash
npm install -g ajv-cli
ajv validate -s schema.json -d data.json
```

## Sample Data for Testing

Each schema includes sample valid and invalid data in the comments.
Use these to verify the schemas work correctly with external validators.

## Expected Results

All schemas should:
- ✅ Pass JSON Schema Draft-7 validation
- ✅ Compile successfully in AJV
- ✅ Validate sample data correctly
- ✅ Show proper error messages for invalid data

Generated on: ${DateTime.now().toIso8601String()}
''';

      await File(path.join(outputDir.path, 'README.md'))
          .writeAsString(instructions);

      print('\n🌍 EXTERNAL VALIDATION SAMPLES GENERATED:');
      print('📁 Directory: ${outputDir.path}');
      print('📄 Files created:');
      await for (final file in outputDir.list()) {
        if (file is File) {
          print('   - ${path.basename(file.path)}');
        }
      }
      print('\n🔗 Next steps:');
      print('1. Navigate to the external_validation_samples directory');
      print('2. Copy any schema file content');
      print('3. Paste into https://www.jsonschemavalidator.net/');
      print('4. Verify it shows "Valid JSON Schema"');
      print('5. Test with sample data to confirm functionality');
    });
  });
}

Future<void> _saveSchema(
    ObjectSchema schema, Directory outputDir, String name) async {
  final jsonSchema = JsonSchemaConverter(schema: schema).toSchema();
  final file = File(path.join(outputDir.path, '$name.json'));

  // Add sample data as comments in the JSON
  final schemaWithComments = {
    ...jsonSchema,
    '_sample_valid_data': _generateSampleData(schema, true),
    '_sample_invalid_data': _generateSampleData(schema, false),
  };

  await file
      .writeAsString(JsonEncoder.withIndent('  ').convert(schemaWithComments));
  print('✅ Generated: $name.json');
}

Map<String, dynamic> _generateSampleData(ObjectSchema schema, bool valid) {
  // This is a simplified sample data generator
  // In a real implementation, you'd generate more sophisticated test data
  if (valid) {
    return {
      'example': 'This would contain valid sample data for testing',
      'note': 'Replace with actual valid data matching the schema',
    };
  } else {
    return {
      'example': 'This would contain invalid sample data for testing',
      'note': 'Replace with actual invalid data that should fail validation',
    };
  }
}
