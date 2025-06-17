import 'dart:convert';
import 'dart:io';

import 'package:ack/ack.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('JSON Schema Golden File Tests', () {
    late Directory tempDir;
    late Directory goldenDir;
    
    setUpAll(() async {
      // Ensure Node.js dependencies are installed
      await _ensureNodeDependencies();
      
      // Create golden files directory
      goldenDir = Directory('test/golden/json_schema');
      if (!await goldenDir.exists()) {
        await goldenDir.create(recursive: true);
      }
    });
    
    setUp(() async {
      // Create temporary directory for test files
      tempDir = await Directory.systemTemp.createTemp('ack_golden_test_');
    });
    
    tearDown(() async {
      // Clean up temporary files
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('Schema Type Golden Files', () {
      test('string schema with all constraints matches golden file', () async {
        final schema = Ack.object({
          'basicString': Ack.string,
          'emailString': Ack.string.email(),
          'uuidString': Ack.string.uuid(),
          'dateTimeString': Ack.string.dateTime(),
          'uriString': Ack.string.uri(),
          'enumString': Ack.string.enumValues(['admin', 'user', 'guest']),
          'patternString': Ack.string.matches(r'^[A-Z][a-z]+$'),
          'lengthString': Ack.string.minLength(2).maxLength(50),
          'literalString': Ack.string.literal('fixed-value'),
          'nullableString': Ack.string.nullable(),
        }, required: ['basicString', 'emailString']);
        
        await _validateGoldenFile(schema, 'string_constraints_schema');
      });

      test('numeric schemas with constraints match golden file', () async {
        final schema = Ack.object({
          'basicInt': Ack.int,
          'rangeInt': Ack.int.min(0).max(100),
          'positiveInt': Ack.int.min(1),
          'negativeInt': Ack.int.max(-1),
          'multipleInt': Ack.int.multipleOf(5),
          'nullableInt': Ack.int.nullable(),
          'basicDouble': Ack.double,
          'rangeDouble': Ack.double.min(0.0).max(100.0),
          'multipleDouble': Ack.double.multipleOf(0.5),
          'nullableDouble': Ack.double.nullable(),
        });
        
        await _validateGoldenFile(schema, 'numeric_constraints_schema');
      });

      test('array schemas with constraints match golden file', () async {
        final schema = Ack.object({
          'basicArray': Ack.list(Ack.string),
          'constrainedArray': Ack.list(Ack.string.minLength(1)).minItems(1).maxItems(10),
          'uniqueArray': Ack.list(Ack.string).uniqueItems(),
          'nestedArray': Ack.list(Ack.list(Ack.int)),
          'objectArray': Ack.list(Ack.object({
            'id': Ack.string.uuid(),
            'name': Ack.string,
          }, required: ['id', 'name'])),
          'nullableArray': Ack.list(Ack.string).nullable(),
        });
        
        await _validateGoldenFile(schema, 'array_constraints_schema');
      });

      test('object schemas with constraints match golden file', () async {
        final schema = Ack.object({
          'basicObject': Ack.object({
            'name': Ack.string,
            'age': Ack.int,
          }),
          'requiredObject': Ack.object({
            'name': Ack.string,
            'email': Ack.string.email(),
            'age': Ack.int.nullable(),
          }, required: ['name', 'email']),
          'strictObject': Ack.object({
            'name': Ack.string,
          }, additionalProperties: false),
          'flexibleObject': Ack.object({
            'name': Ack.string,
          }, additionalProperties: true),
          'nestedObject': Ack.object({
            'user': Ack.object({
              'profile': Ack.object({
                'bio': Ack.string.nullable(),
                'avatar': Ack.string.uri().nullable(),
              }),
            }),
          }),
        });
        
        await _validateGoldenFile(schema, 'object_constraints_schema');
      });

      test('discriminated union schemas match golden file', () async {
        final schema = Ack.object({
          'simpleUnion': Ack.discriminated(
            discriminatorKey: 'type',
            schemas: {
              'user': Ack.object({
                'type': Ack.string.literal('user'),
                'name': Ack.string,
              }, required: ['type', 'name']),
              'admin': Ack.object({
                'type': Ack.string.literal('admin'),
                'level': Ack.int.min(1).max(10),
              }, required: ['type', 'level']),
            },
          ),
          'complexUnion': Ack.discriminated(
            discriminatorKey: 'kind',
            schemas: {
              'text': Ack.object({
                'kind': Ack.string.literal('text'),
                'content': Ack.string.minLength(1),
                'metadata': Ack.object({
                  'author': Ack.string,
                  'created': Ack.string.dateTime(),
                }).nullable(),
              }, required: ['kind', 'content']),
              'image': Ack.object({
                'kind': Ack.string.literal('image'),
                'src': Ack.string.uri(),
                'dimensions': Ack.object({
                  'width': Ack.int.min(1),
                  'height': Ack.int.min(1),
                }),
              }, required: ['kind', 'src', 'dimensions']),
            },
          ),
        });
        
        await _validateGoldenFile(schema, 'discriminated_union_schema');
      });

      test('comprehensive schema with all features matches golden file', () async {
        final schema = Ack.object({
          // Basic types with constraints
          'id': Ack.string.uuid(),
          'name': Ack.string.minLength(2).maxLength(100),
          'age': Ack.int.min(0).max(150).nullable(),
          'score': Ack.double.min(0.0).max(100.0),
          'active': Ack.boolean,
          
          // String formats
          'email': Ack.string.email(),
          'website': Ack.string.uri().nullable(),
          'created': Ack.string.dateTime(),
          'phone': Ack.string.matches(r'^\+?[\d\s\-\(\)]+$').nullable(),
          
          // Enums
          'role': Ack.string.enumValues(['admin', 'user', 'guest']),
          'status': Ack.string.enumValues(['active', 'inactive', 'pending']),
          
          // Arrays with constraints
          'tags': Ack.list(Ack.string).uniqueItems().maxItems(10),
          'scores': Ack.list(Ack.double.min(0.0).max(100.0)).nullable(),
          'permissions': Ack.list(Ack.string.enumValues(['read', 'write', 'admin'])),
          
          // Complex nested structures
          'profile': Ack.object({
            'bio': Ack.string.maxLength(500).nullable(),
            'avatar': Ack.string.uri().nullable(),
            'preferences': Ack.object({
              'theme': Ack.string.enumValues(['light', 'dark']),
              'notifications': Ack.boolean,
              'language': Ack.string.matches(r'^[a-z]{2}(-[A-Z]{2})?$'),
            }),
          }),
          
          // Discriminated union
          'content': Ack.discriminated(
            discriminatorKey: 'type',
            schemas: {
              'text': Ack.object({
                'type': Ack.string.literal('text'),
                'value': Ack.string.minLength(1),
                'formatting': Ack.object({
                  'bold': Ack.boolean,
                  'italic': Ack.boolean,
                }).nullable(),
              }, required: ['type', 'value']),
              'number': Ack.object({
                'type': Ack.string.literal('number'),
                'value': Ack.double,
                'precision': Ack.int.min(0).max(10).nullable(),
              }, required: ['type', 'value']),
              'list': Ack.object({
                'type': Ack.string.literal('list'),
                'items': Ack.list(Ack.string).minItems(1),
                'ordered': Ack.boolean,
              }, required: ['type', 'items']),
            },
          ),
        }, required: ['id', 'name', 'role', 'status', 'profile', 'content']);
        
        await _validateGoldenFile(schema, 'comprehensive_schema');
      });
    });
  });
}

/// Validate schema against golden file and AJV
Future<void> _validateGoldenFile(ObjectSchema schema, String testName) async {
  // Generate JSON schema
  final jsonSchema = JsonSchemaConverter(schema: schema).toSchema();
  final jsonString = JsonEncoder.withIndent('  ').convert(jsonSchema);
  
  // Golden file path
  final goldenFile = File('test/golden/json_schema/$testName.json');
  
  // Check if golden file exists
  if (await goldenFile.exists()) {
    // Compare with existing golden file
    final expectedContent = await goldenFile.readAsString();
    expect(jsonString, equals(expectedContent), 
      reason: 'Generated schema should match golden file for $testName');
  } else {
    // Create new golden file
    await goldenFile.writeAsString(jsonString);
    print('Created new golden file: ${goldenFile.path}');
  }
  
  // Validate with AJV that the schema is valid JSON Schema Draft-7
  final tempFile = File('${Directory.systemTemp.path}/$testName.json');
  await tempFile.writeAsString(jsonString);
  
  final result = await _runSchemaValidation(tempFile.path);
  expect(result['valid'], isTrue, 
    reason: 'Golden file schema $testName should be valid JSON Schema Draft-7. Errors: ${result['errors']}');
  
  // Clean up temp file
  if (await tempFile.exists()) {
    await tempFile.delete();
  }
}

/// Run AJV schema validation for a single JSON schema specification
Future<Map<String, dynamic>> _runSchemaValidation(String schemaPath) async {
  final projectRoot = _findProjectRoot();
  final validatorScript = path.join(projectRoot, 'tools', 'ajv-validator.js');

  final result = await Process.run(
    'node',
    [validatorScript, 'validate-schema', '--schema', schemaPath, '--json'],
    workingDirectory: projectRoot,
  );

  if (result.exitCode != 0) {
    throw Exception('AJV schema validation failed: ${result.stderr}');
  }

  // Parse the validation result from stdout
  final lines = result.stdout.toString().split('\n');
  final jsonLine = lines.firstWhere(
    (line) => line.trim().startsWith('{'),
    orElse: () => '{"valid": false, "errors": []}',
  );

  return jsonDecode(jsonLine);
}

/// Ensure Node.js dependencies are installed
Future<void> _ensureNodeDependencies() async {
  final projectRoot = _findProjectRoot();
  final toolsDir = path.join(projectRoot, 'tools');
  final packageJsonFile = File(path.join(toolsDir, 'package.json'));

  if (!await packageJsonFile.exists()) {
    throw Exception('tools/package.json not found. Please ensure the tools directory is set up.');
  }

  final nodeModulesDir = Directory(path.join(toolsDir, 'node_modules'));
  if (!await nodeModulesDir.exists()) {
    print('Installing Node.js dependencies...');
    final result = await Process.run(
      'npm',
      ['install'],
      workingDirectory: toolsDir,
    );

    if (result.exitCode != 0) {
      throw Exception('Failed to install Node.js dependencies: ${result.stderr}');
    }
  }
}

/// Find the project root directory
String _findProjectRoot() {
  var current = Directory.current;
  while (current.path != current.parent.path) {
    final melosFile = File(path.join(current.path, 'melos.yaml'));
    if (melosFile.existsSync()) {
      return current.path;
    }
    current = current.parent;
  }
  throw Exception('Could not find project root (melos.yaml not found)');
}
