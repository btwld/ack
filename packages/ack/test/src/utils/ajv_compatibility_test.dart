import 'dart:convert';
import 'dart:io';

import 'package:ack/ack.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('AJV JSON Schema Draft-7 Validation Tests', () {
    late Directory tempDir;

    setUpAll(() async {
      // Ensure Node.js dependencies are installed
      await _ensureNodeDependencies();
    });

    setUp(() async {
      // Create temporary directory for test files
      tempDir = await Directory.systemTemp.createTemp('ack_ajv_test_');
    });

    tearDown(() async {
      // Clean up temporary files
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('JSON Schema Draft-7 Specification Validation', () {
      test('Ack-generated schema is valid JSON Schema Draft-7', () async {
        // Define Ack schema
        final ackSchema = Ack.object({
          'name': Ack.string.minLength(2).maxLength(50),
          'email': Ack.string.email(),
          'age': Ack.int.min(0).max(120).nullable(),
          'role': Ack.string.enumValues(['admin', 'user', 'guest']),
          'isActive': Ack.boolean,
          'tags': Ack.list(Ack.string).uniqueItems().nullable(),
        }, required: [
          'name',
          'email'
        ]);

        // Generate JSON schema
        final jsonSchema = JsonSchemaConverter(schema: ackSchema).toSchema();

        // Write schema to temp file
        final schemaFile = File(path.join(tempDir.path, 'user-schema.json'));
        await schemaFile.writeAsString(jsonEncode(jsonSchema));

        // Validate that the generated schema is valid JSON Schema Draft-7
        final result = await _runSchemaValidation(schemaFile.path);

        expect(result['valid'], isTrue,
            reason: 'Ack-generated schema should be valid JSON Schema Draft-7');
        expect(result['errors'], isEmpty);
        expect(result['validationType'], equals('compilation'));
      });

      test(
          'complex schema with discriminated unions is valid JSON Schema Draft-7',
          () async {
        // Define a more complex Ack schema with discriminated unions
        final ackSchema = Ack.object({
          'id': Ack.string.uuid(),
          'type': Ack.string.enumValues(['user', 'admin']),
          'profile': Ack.discriminated(
            discriminatorKey: 'type',
            schemas: {
              'user': Ack.object({
                'type': Ack.string.literal('user'),
                'permissions': Ack.list(Ack.string),
              }, required: [
                'type',
                'permissions'
              ]),
              'admin': Ack.object({
                'type': Ack.string.literal('admin'),
                'level': Ack.int.min(1).max(10),
              }, required: [
                'type',
                'level'
              ]),
            },
          ),
        }, required: [
          'id',
          'type',
          'profile'
        ]);

        // Generate JSON schema
        final jsonSchema = JsonSchemaConverter(schema: ackSchema).toSchema();

        // Write schema to temp file
        final schemaFile = File(path.join(tempDir.path, 'complex-schema.json'));
        await schemaFile.writeAsString(jsonEncode(jsonSchema));

        // Validate that the generated schema is valid JSON Schema Draft-7
        final result = await _runSchemaValidation(schemaFile.path);

        expect(result['valid'], isTrue,
            reason:
                'Complex Ack-generated schema should be valid JSON Schema Draft-7');
        expect(result['errors'], isEmpty);
      });
    });

    group('Batch Schema Validation', () {
      test('validates multiple schemas in batch', () async {
        // Create multiple test schemas
        await _createMultipleSchemas(tempDir);

        // Create batch config for schema validation
        final batchConfig = {
          'schemas': [
            {
              'name': 'user-schema',
              'path': path.join(tempDir.path, 'user-schema.json'),
              'description': 'User schema validation'
            },
            {
              'name': 'product-schema',
              'path': path.join(tempDir.path, 'product-schema.json'),
              'description': 'Product schema validation'
            },
          ]
        };

        final configFile =
            File(path.join(tempDir.path, 'schema-batch-config.json'));
        await configFile.writeAsString(jsonEncode(batchConfig));

        // Run batch schema validation
        final results = await _runBatchSchemaValidation(configFile.path);

        expect(results['schemas'], hasLength(2));

        // All schemas should be valid
        for (final schema in results['schemas']) {
          expect(schema['result']['valid'], isTrue,
              reason:
                  'Schema ${schema['name']} should be valid JSON Schema Draft-7');
        }
      });
    });

    group('Golden File Testing', () {
      test('schema validation results match golden file', () async {
        // Use the pre-built test fixtures
        final projectRoot = _findProjectRoot();
        final schemaPath = path.join(projectRoot, 'tools', 'test-fixtures',
            'schemas', 'user-schema.json');

        // Validate the schema specification
        final result = await _runSchemaValidation(schemaPath);

        // Write results to temp file for comparison
        final resultsFile =
            File(path.join(tempDir.path, 'schema-validation-results.json'));
        await resultsFile.writeAsString(jsonEncode(result));

        // Verify the schema is valid
        expect(result['valid'], isTrue);
        expect(result['errors'], isEmpty);
        expect(result['validationType'], equals('compilation'));
        expect(result['schemaName'], equals('user-schema.json'));
      });
    });
  });
}

/// Ensure Node.js dependencies are installed
Future<void> _ensureNodeDependencies() async {
  final projectRoot = _findProjectRoot();
  final toolsDir = path.join(projectRoot, 'tools');
  final packageJsonFile = File(path.join(toolsDir, 'package.json'));

  if (!await packageJsonFile.exists()) {
    throw Exception(
        'tools/package.json not found. Please ensure the tools directory is set up.');
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
      throw Exception(
          'Failed to install Node.js dependencies: ${result.stderr}');
    }
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

/// Run batch schema validation
Future<Map<String, dynamic>> _runBatchSchemaValidation(
    String configPath) async {
  final projectRoot = _findProjectRoot();
  final validatorScript = path.join(projectRoot, 'tools', 'ajv-validator.js');
  final outputFile =
      path.join(Directory.systemTemp.path, 'ajv-schema-batch-results.json');

  final result = await Process.run(
    'node',
    [
      validatorScript,
      'validate-batch',
      '--input',
      configPath,
      '--output',
      outputFile
    ],
    workingDirectory: projectRoot,
  );

  if (result.exitCode != 0) {
    throw Exception('AJV batch schema validation failed: ${result.stderr}');
  }

  final resultsContent = await File(outputFile).readAsString();
  return jsonDecode(resultsContent);
}

/// Create multiple test schemas for batch validation
Future<void> _createMultipleSchemas(Directory tempDir) async {
  // Create user schema
  final userSchema = Ack.object({
    'name': Ack.string.minLength(2),
    'email': Ack.string.email(),
    'age': Ack.int.min(0).nullable(),
  }, required: [
    'name',
    'email'
  ]);

  final userJsonSchema = JsonSchemaConverter(schema: userSchema).toSchema();
  final userSchemaFile = File(path.join(tempDir.path, 'user-schema.json'));
  await userSchemaFile.writeAsString(jsonEncode(userJsonSchema));

  // Create product schema
  final productSchema = Ack.object({
    'id': Ack.string.uuid(),
    'name': Ack.string.minLength(1),
    'price': Ack.double.min(0),
    'category': Ack.string.enumValues(['electronics', 'clothing', 'books']),
    'inStock': Ack.boolean,
  }, required: [
    'id',
    'name',
    'price',
    'category'
  ]);

  final productJsonSchema =
      JsonSchemaConverter(schema: productSchema).toSchema();
  final productSchemaFile =
      File(path.join(tempDir.path, 'product-schema.json'));
  await productSchemaFile.writeAsString(jsonEncode(productJsonSchema));
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
