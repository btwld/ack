import 'dart:convert';
import 'dart:io';

import 'package:ack/ack.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('Test Authenticity Verification', () {
    late Directory tempDir;

    setUpAll(() async {
      await _ensureNodeDependencies();
    });

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('ack_authenticity_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('PROOF: Tests fail when JSON Schema generation is broken', () async {
      // Create a deliberately broken JSON schema by manually constructing invalid JSON
      final brokenSchema = {
        '\$schema': 'http://json-schema.org/draft-07/schema#',
        'type': 'object',
        'properties': {
          'name': {
            'type': 'string',
            'minLength':
                'invalid-should-be-number', // BROKEN: string instead of number
          },
          'age': {
            'type': 'integer',
            'minimum': 'also-invalid', // BROKEN: string instead of number
          },
        },
        'invalidProperty': 'this-should-not-exist', // BROKEN: invalid property
      };

      // Write broken schema to file
      final brokenFile = File(path.join(tempDir.path, 'broken-schema.json'));
      await brokenFile.writeAsString(jsonEncode(brokenSchema));

      // Validate with AJV - this should FAIL
      final result = await _runSchemaValidation(brokenFile.path);

      // PROOF: The test correctly identifies broken schemas
      expect(result['valid'], isFalse,
          reason: 'Broken schema should fail validation');
      expect(result['errors'], isNotEmpty,
          reason: 'Should have validation errors');

      print('✅ PROOF: Broken schema correctly failed validation');
      print('Errors found: ${result['errors']}');
    });

    test('PROOF: Tests pass when JSON Schema generation is correct', () async {
      // Generate a real schema using Ack
      final ackSchema = Ack.object({
        'name': Ack.string.minLength(2),
        'age': Ack.int.min(0),
      }, required: [
        'name'
      ]);

      final jsonSchema = JsonSchemaConverter(schema: ackSchema).toSchema();

      // Write real schema to file
      final realFile = File(path.join(tempDir.path, 'real-schema.json'));
      await realFile.writeAsString(jsonEncode(jsonSchema));

      // Validate with AJV - this should PASS
      final result = await _runSchemaValidation(realFile.path);

      // PROOF: Real Ack-generated schemas pass validation
      expect(result['valid'], isTrue,
          reason: 'Real Ack schema should pass validation');
      expect(result['errors'], isEmpty,
          reason: 'Should have no validation errors');

      print('✅ PROOF: Real Ack schema correctly passed validation');
      print('Generated schema: ${jsonEncode(jsonSchema)}');
    });

    test('PROOF: Tests detect missing required JSON Schema properties',
        () async {
      // Create schema missing required properties
      final incompleteSchema = {
        // Missing $schema declaration
        'properties': {
          'name': {
            'type': 'string',
          },
        },
        // Missing 'type': 'object'
      };

      final incompleteFile =
          File(path.join(tempDir.path, 'incomplete-schema.json'));
      await incompleteFile.writeAsString(jsonEncode(incompleteSchema));

      final result = await _runSchemaValidation(incompleteFile.path);

      // PROOF: Missing properties are detected
      expect(result['valid'], isFalse, reason: 'Incomplete schema should fail');

      print('✅ PROOF: Incomplete schema correctly failed validation');
      print('Errors: ${result['errors']}');
    });

    test('PROOF: Tests validate actual JSON Schema Draft-7 compliance',
        () async {
      // Test with a schema that looks valid but violates Draft-7 rules
      final nonCompliantSchema = {
        '\$schema': 'http://json-schema.org/draft-07/schema#',
        'type': 'object',
        'properties': {
          'value': {
            'type': 'string',
            'format': 'non-existent-format', // Invalid format
          },
        },
        'patternProperties': {
          'invalid-regex-[': {
            // Invalid regex pattern
            'type': 'string'
          }
        }
      };

      final nonCompliantFile =
          File(path.join(tempDir.path, 'non-compliant-schema.json'));
      await nonCompliantFile.writeAsString(jsonEncode(nonCompliantSchema));

      final result = await _runSchemaValidation(nonCompliantFile.path);

      // PROOF: Draft-7 violations are detected
      expect(result['valid'], isFalse,
          reason: 'Non-compliant schema should fail');

      print('✅ PROOF: Non-compliant schema correctly failed validation');
      print('Errors: ${result['errors']}');
    });
  });
}

/// Run JSON Schema validation
Future<Map<String, dynamic>> _runSchemaValidation(String schemaPath) async {
  final projectRoot = _findProjectRoot();
  final validatorScript = path.join(projectRoot, 'tools', 'jsonschema-validator.js');

  final result = await Process.run(
    'node',
    [validatorScript, 'validate-schema', '--schema', schemaPath, '--json'],
    workingDirectory: projectRoot,
  );

  if (result.exitCode != 0) {
    throw Exception('JSON Schema validation failed: ${result.stderr}');
  }

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
  final nodeModulesDir = Directory(path.join(toolsDir, 'node_modules'));

  if (!await nodeModulesDir.exists()) {
    print('Installing Node.js dependencies...');
    final result =
        await Process.run('npm', ['install'], workingDirectory: toolsDir);
    if (result.exitCode != 0) {
      throw Exception(
          'Failed to install Node.js dependencies: ${result.stderr}');
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
