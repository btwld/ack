import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('Validate All Golden JSON Schemas', () {
    late Directory goldenDir;

    setUpAll(() async {
      // Ensure Node.js dependencies are installed
      await _ensureNodeDependencies();

      goldenDir = Directory('test/golden/json_schema');
      if (!await goldenDir.exists()) {
        throw Exception(
            'Golden schema directory not found. Run json_schema_golden_test.dart first.');
      }
    });

    test('all golden JSON schemas are valid JSON Schema Draft-7', () async {
      final goldenFiles = await goldenDir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.json'))
          .cast<File>()
          .toList();

      expect(goldenFiles, isNotEmpty,
          reason: 'Should have golden schema files');

      // Create batch config for all golden files with absolute paths
      final projectRoot = _findProjectRoot();
      final batchConfig = {
        'schemas': goldenFiles
            .map((file) => {
                  'name': path.basenameWithoutExtension(file.path),
                  'path': path.join(projectRoot, 'packages', 'ack',
                      path.relative(file.path, from: Directory.current.path)),
                  'description':
                      'Golden file validation for ${path.basenameWithoutExtension(file.path)}',
                })
            .toList(),
      };

      // Write batch config to temp file
      final tempDir =
          await Directory.systemTemp.createTemp('ack_golden_validation_');
      final configFile =
          File(path.join(tempDir.path, 'golden-batch-config.json'));
      await configFile.writeAsString(jsonEncode(batchConfig));

      try {
        // Run batch validation
        final results = await _runBatchSchemaValidation(configFile.path);

        // Verify all schemas are valid
        expect(results['schemas'], hasLength(goldenFiles.length));

        for (final schema in results['schemas']) {
          final schemaName = schema['name'];
          final result = schema['result'];

          expect(result['valid'], isTrue,
              reason:
                  'Golden schema $schemaName should be valid JSON Schema Draft-7. Errors: ${result['errors']}');
          expect(result['errors'], isEmpty);
          expect(result['validationType'], equals('compilation'));
        }

        print(
            '✅ All ${goldenFiles.length} golden schemas are valid JSON Schema Draft-7!');

        // Print summary
        for (final file in goldenFiles) {
          final name = path.basenameWithoutExtension(file.path);
          print('  ✓ $name.json');
        }
      } finally {
        // Clean up temp directory
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });

    test('golden schemas contain expected JSON Schema features', () async {
      final goldenFiles = await goldenDir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.json'))
          .cast<File>()
          .toList();

      for (final file in goldenFiles) {
        final content = await file.readAsString();
        final schema = jsonDecode(content) as Map<String, dynamic>;
        final fileName = path.basenameWithoutExtension(file.path);

        // All schemas should have $schema declaration
        expect(schema['\$schema'],
            equals('http://json-schema.org/draft-07/schema#'),
            reason: 'Schema $fileName should declare JSON Schema Draft-7');

        // All schemas should have type
        expect(schema['type'], isNotNull,
            reason: 'Schema $fileName should have a type');

        // Verify specific features based on schema type
        if (fileName.contains('string')) {
          _validateStringFeatures(schema, fileName);
        } else if (fileName.contains('numeric')) {
          _validateNumericFeatures(schema, fileName);
        } else if (fileName.contains('array')) {
          _validateArrayFeatures(schema, fileName);
        } else if (fileName.contains('object')) {
          _validateObjectFeatures(schema, fileName);
        } else if (fileName.contains('discriminated')) {
          _validateDiscriminatedFeatures(schema, fileName);
        } else if (fileName.contains('comprehensive')) {
          _validateComprehensiveFeatures(schema, fileName);
        }
      }
    });
  });
}

void _validateStringFeatures(Map<String, dynamic> schema, String fileName) {
  final properties = schema['properties'] as Map<String, dynamic>?;
  expect(properties, isNotNull, reason: 'String schema should have properties');

  // Check for format validation
  final hasFormatValidation = properties!.values
      .any((prop) => prop is Map && prop.containsKey('format'));
  expect(hasFormatValidation, isTrue,
      reason: 'String schema should include format validation');

  // Check for pattern validation
  final hasPatternValidation = properties.values
      .any((prop) => prop is Map && prop.containsKey('pattern'));
  expect(hasPatternValidation, isTrue,
      reason: 'String schema should include pattern validation');

  // Check for enum validation
  final hasEnumValidation =
      properties.values.any((prop) => prop is Map && prop.containsKey('enum'));
  expect(hasEnumValidation, isTrue,
      reason: 'String schema should include enum validation');
}

void _validateNumericFeatures(Map<String, dynamic> schema, String fileName) {
  final properties = schema['properties'] as Map<String, dynamic>?;
  expect(properties, isNotNull,
      reason: 'Numeric schema should have properties');

  // Check for min/max constraints
  final hasMinMax = properties!.values.any((prop) =>
      prop is Map &&
      (prop.containsKey('minimum') || prop.containsKey('maximum')));
  expect(hasMinMax, isTrue,
      reason: 'Numeric schema should include min/max constraints');

  // Check for multipleOf constraints (optional)
  final hasMultipleOf = properties.values
      .any((prop) => prop is Map && prop.containsKey('multipleOf'));
  // Note: multipleOf is optional, so we just check if it exists when present
  if (hasMultipleOf) {
    print('  ✓ Found multipleOf constraints in $fileName');
  }
}

void _validateArrayFeatures(Map<String, dynamic> schema, String fileName) {
  final properties = schema['properties'] as Map<String, dynamic>?;
  expect(properties, isNotNull, reason: 'Array schema should have properties');

  // Check for items definition
  final hasItems = properties!.values
      .any((prop) => prop is Map && prop.containsKey('items'));
  expect(hasItems, isTrue,
      reason: 'Array schema should include items definition');

  // Check for uniqueItems
  final hasUniqueItems = properties.values
      .any((prop) => prop is Map && prop.containsKey('uniqueItems'));
  expect(hasUniqueItems, isTrue,
      reason: 'Array schema should include uniqueItems constraint');
}

void _validateObjectFeatures(Map<String, dynamic> schema, String fileName) {
  final properties = schema['properties'] as Map<String, dynamic>?;
  expect(properties, isNotNull, reason: 'Object schema should have properties');

  // Check for additionalProperties
  final hasAdditionalProperties = schema.containsKey('additionalProperties');
  expect(hasAdditionalProperties, isTrue,
      reason: 'Object schema should specify additionalProperties');

  // Check for required fields (optional)
  final hasRequired = schema.containsKey('required');
  if (hasRequired) {
    print('  ✓ Found required fields in $fileName');
  }
}

void _validateDiscriminatedFeatures(
    Map<String, dynamic> schema, String fileName) {
  final properties = schema['properties'] as Map<String, dynamic>?;
  expect(properties, isNotNull,
      reason: 'Discriminated schema should have properties');

  // Check for allOf structure (discriminated unions use allOf with if/then)
  final hasAllOf = properties!.values
      .any((prop) => prop is Map && prop.containsKey('allOf'));
  expect(hasAllOf, isTrue,
      reason: 'Discriminated schema should use allOf structure');
}

void _validateComprehensiveFeatures(
    Map<String, dynamic> schema, String fileName) {
  final properties = schema['properties'] as Map<String, dynamic>?;
  expect(properties, isNotNull,
      reason: 'Comprehensive schema should have properties');

  // Should have all major features
  _validateStringFeatures(schema, fileName);
  _validateNumericFeatures(schema, fileName);
  _validateArrayFeatures(schema, fileName);
  _validateObjectFeatures(schema, fileName);
  _validateDiscriminatedFeatures(schema, fileName);
}

/// Run batch schema validation
Future<Map<String, dynamic>> _runBatchSchemaValidation(
    String configPath) async {
  final projectRoot = _findProjectRoot();
  final validatorScript = path.join(projectRoot, 'tools', 'ajv-validator.js');
  final outputFile =
      path.join(Directory.systemTemp.path, 'golden-validation-results.json');

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
