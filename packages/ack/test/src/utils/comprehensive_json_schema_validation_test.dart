import 'dart:convert';
import 'dart:io';

import 'package:ack/ack.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('Comprehensive JSON Schema Draft-7 Validation Tests', () {
    late Directory tempDir;

    setUpAll(() async {
      // Ensure Node.js dependencies are installed
      await _ensureNodeDependencies();
    });

    setUp(() async {
      // Create temporary directory for test files
      tempDir =
          await Directory.systemTemp.createTemp('ack_comprehensive_test_');
    });

    tearDown(() async {
      // Clean up temporary files
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('String Schema Validation', () {
      test('basic string schema generates valid JSON Schema Draft-7', () async {
        final schema = Ack.string;
        await _validateSchemaGeneration(schema, 'basic-string', tempDir);
      });

      test('string with length constraints generates valid JSON Schema Draft-7',
          () async {
        final schema = Ack.string.minLength(2).maxLength(50);
        await _validateSchemaGeneration(
            schema, 'string-length-constraints', tempDir);
      });

      test('string with email format generates valid JSON Schema Draft-7',
          () async {
        final schema = Ack.string.email();
        await _validateSchemaGeneration(schema, 'string-email-format', tempDir);
      });

      test('string with uuid format generates valid JSON Schema Draft-7',
          () async {
        final schema = Ack.string.uuid();
        await _validateSchemaGeneration(schema, 'string-uuid-format', tempDir);
      });

      test('string with date-time format generates valid JSON Schema Draft-7',
          () async {
        final schema = Ack.string.dateTime();
        await _validateSchemaGeneration(
            schema, 'string-datetime-format', tempDir);
      });

      test('string with enum values generates valid JSON Schema Draft-7',
          () async {
        final schema = Ack.string.enumValues(['admin', 'user', 'guest']);
        await _validateSchemaGeneration(schema, 'string-enum-values', tempDir);
      });

      test('string with regex pattern generates valid JSON Schema Draft-7',
          () async {
        final schema = Ack.string.matches(r'^[A-Z][a-z]+$');
        await _validateSchemaGeneration(
            schema, 'string-regex-pattern', tempDir);
      });

      test('nullable string generates valid JSON Schema Draft-7', () async {
        final schema = Ack.string.nullable();
        await _validateSchemaGeneration(schema, 'string-nullable', tempDir);
      });

      test('string with literal value generates valid JSON Schema Draft-7',
          () async {
        final schema = Ack.string.literal('user');
        await _validateSchemaGeneration(schema, 'string-literal', tempDir);
      });
    });

    group('Integer Schema Validation', () {
      test('basic integer schema generates valid JSON Schema Draft-7',
          () async {
        final schema = Ack.int;
        await _validateSchemaGeneration(schema, 'basic-integer', tempDir);
      });

      test(
          'integer with min/max constraints generates valid JSON Schema Draft-7',
          () async {
        final schema = Ack.int.min(0).max(120);
        await _validateSchemaGeneration(schema, 'integer-min-max', tempDir);
      });

      test('positive integer generates valid JSON Schema Draft-7', () async {
        final schema = Ack.int.positive();
        await _validateSchemaGeneration(schema, 'integer-positive', tempDir);
      });

      test('negative integer generates valid JSON Schema Draft-7', () async {
        final schema = Ack.int.negative();
        await _validateSchemaGeneration(schema, 'integer-negative', tempDir);
      });

      test('integer with multipleOf generates valid JSON Schema Draft-7',
          () async {
        final schema = Ack.int.multipleOf(5);
        await _validateSchemaGeneration(schema, 'integer-multiple-of', tempDir);
      });

      test('nullable integer generates valid JSON Schema Draft-7', () async {
        final schema = Ack.int.nullable();
        await _validateSchemaGeneration(schema, 'integer-nullable', tempDir);
      });
    });

    group('Double Schema Validation', () {
      test('basic double schema generates valid JSON Schema Draft-7', () async {
        final schema = Ack.double;
        await _validateSchemaGeneration(schema, 'basic-double', tempDir);
      });

      test(
          'double with min/max constraints generates valid JSON Schema Draft-7',
          () async {
        final schema = Ack.double.min(0.0).max(100.0);
        await _validateSchemaGeneration(schema, 'double-min-max', tempDir);
      });

      test('positive double generates valid JSON Schema Draft-7', () async {
        final schema = Ack.double.min(0.0);
        await _validateSchemaGeneration(schema, 'double-positive', tempDir);
      });

      test('double with multipleOf generates valid JSON Schema Draft-7',
          () async {
        final schema = Ack.double.multipleOf(0.5);
        await _validateSchemaGeneration(schema, 'double-multiple-of', tempDir);
      });
    });

    group('Boolean Schema Validation', () {
      test('basic boolean schema generates valid JSON Schema Draft-7',
          () async {
        final schema = Ack.boolean;
        await _validateSchemaGeneration(schema, 'basic-boolean', tempDir);
      });

      test('nullable boolean generates valid JSON Schema Draft-7', () async {
        final schema = Ack.boolean.nullable();
        await _validateSchemaGeneration(schema, 'boolean-nullable', tempDir);
      });
    });

    group('List Schema Validation', () {
      test('basic list schema generates valid JSON Schema Draft-7', () async {
        final schema = Ack.list(Ack.string);
        await _validateSchemaGeneration(schema, 'basic-list', tempDir);
      });

      test('list with item constraints generates valid JSON Schema Draft-7',
          () async {
        final schema =
            Ack.list(Ack.string.minLength(1)).minItems(1).maxItems(10);
        await _validateSchemaGeneration(
            schema, 'list-with-constraints', tempDir);
      });

      test('list with unique items generates valid JSON Schema Draft-7',
          () async {
        final schema = Ack.list(Ack.string).uniqueItems();
        await _validateSchemaGeneration(schema, 'list-unique-items', tempDir);
      });

      test('nested list generates valid JSON Schema Draft-7', () async {
        final schema = Ack.list(Ack.list(Ack.int));
        await _validateSchemaGeneration(schema, 'nested-list', tempDir);
      });
    });

    group('Object Schema Validation', () {
      test('basic object schema generates valid JSON Schema Draft-7', () async {
        final schema = Ack.object({
          'name': Ack.string,
          'age': Ack.int,
        });
        await _validateSchemaGeneration(schema, 'basic-object', tempDir);
      });

      test('object with required fields generates valid JSON Schema Draft-7',
          () async {
        final schema = Ack.object({
          'name': Ack.string,
          'email': Ack.string.email(),
          'age': Ack.int.nullable(),
        }, required: [
          'name',
          'email'
        ]);
        await _validateSchemaGeneration(
            schema, 'object-required-fields', tempDir);
      });

      test(
          'object with additionalProperties false generates valid JSON Schema Draft-7',
          () async {
        final schema = Ack.object({
          'name': Ack.string,
        }, additionalProperties: false);
        await _validateSchemaGeneration(
            schema, 'object-no-additional-props', tempDir);
      });

      test(
          'object with additionalProperties true generates valid JSON Schema Draft-7',
          () async {
        final schema = Ack.object({
          'name': Ack.string,
        }, additionalProperties: true);
        await _validateSchemaGeneration(
            schema, 'object-additional-props', tempDir);
      });

      test('nested object generates valid JSON Schema Draft-7', () async {
        final schema = Ack.object({
          'user': Ack.object({
            'name': Ack.string,
            'profile': Ack.object({
              'bio': Ack.string.nullable(),
              'avatar': Ack.string.uri().nullable(),
            }),
          }),
        });
        await _validateSchemaGeneration(schema, 'nested-object', tempDir);
      });

      test(
          'object with complex property types generates valid JSON Schema Draft-7',
          () async {
        final schema = Ack.object({
          'id': Ack.string.uuid(),
          'tags': Ack.list(Ack.string).uniqueItems(),
          'metadata': Ack.object({
            'created': Ack.string.dateTime(),
            'updated': Ack.string.dateTime().nullable(),
          }).nullable(),
          'status': Ack.string.enumValues(['active', 'inactive', 'pending']),
        }, required: [
          'id',
          'status'
        ]);
        await _validateSchemaGeneration(
            schema, 'object-complex-properties', tempDir);
      });
    });

    group('Discriminated Object Schema Validation', () {
      test('basic discriminated schema generates valid JSON Schema Draft-7',
          () async {
        final schema = Ack.discriminated(
          discriminatorKey: 'type',
          schemas: {
            'user': Ack.object({
              'type': Ack.string.literal('user'),
              'name': Ack.string,
            }, required: [
              'type',
              'name'
            ]),
            'admin': Ack.object({
              'type': Ack.string.literal('admin'),
              'level': Ack.int.min(1).max(10),
            }, required: [
              'type',
              'level'
            ]),
          },
        );
        await _validateSchemaGeneration(schema, 'basic-discriminated', tempDir);
      });

      test('complex discriminated schema generates valid JSON Schema Draft-7',
          () async {
        final schema = Ack.discriminated(
          discriminatorKey: 'kind',
          schemas: {
            'text': Ack.object({
              'kind': Ack.string.literal('text'),
              'content': Ack.string.minLength(1),
              'formatting': Ack.object({
                'bold': Ack.boolean,
                'italic': Ack.boolean,
              }).nullable(),
            }, required: [
              'kind',
              'content'
            ]),
            'image': Ack.object({
              'kind': Ack.string.literal('image'),
              'src': Ack.string.uri(),
              'alt': Ack.string.nullable(),
              'dimensions': Ack.object({
                'width': Ack.int.positive(),
                'height': Ack.int.positive(),
              }),
            }, required: [
              'kind',
              'src',
              'dimensions'
            ]),
            'list': Ack.object({
              'kind': Ack.string.literal('list'),
              'items': Ack.list(Ack.string).minItems(1),
              'ordered': Ack.boolean,
            }, required: [
              'kind',
              'items'
            ]),
          },
        );
        await _validateSchemaGeneration(
            schema, 'complex-discriminated', tempDir);
      });
    });

    group('Complex Integration Tests', () {
      test(
          'comprehensive schema with all types generates valid JSON Schema Draft-7',
          () async {
        final schema = Ack.object({
          // Basic types
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

          // Enums and patterns
          'role': Ack.string.enumValues(['admin', 'user', 'guest']),
          'status': Ack.string.enumValues(['active', 'inactive', 'pending']),

          // Arrays
          'tags': Ack.list(Ack.string).uniqueItems().maxItems(10),
          'scores': Ack.list(Ack.double.min(0.0).max(100.0)).nullable(),
          'permissions':
              Ack.list(Ack.string.enumValues(['read', 'write', 'admin'])),

          // Nested objects
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
              }, required: [
                'type',
                'value'
              ]),
              'number': Ack.object({
                'type': Ack.string.literal('number'),
                'value': Ack.double,
                'precision': Ack.int.min(0).max(10).nullable(),
              }, required: [
                'type',
                'value'
              ]),
              'boolean': Ack.object({
                'type': Ack.string.literal('boolean'),
                'value': Ack.boolean,
              }, required: [
                'type',
                'value'
              ]),
            },
          ),
        }, required: [
          'id',
          'name',
          'role',
          'status',
          'profile',
          'content'
        ]);

        await _validateSchemaGeneration(
            schema, 'comprehensive-all-types', tempDir);
      });
    });
  });
}

/// Validate that a schema generates valid JSON Schema Draft-7
Future<void> _validateSchemaGeneration(
    AckSchema schema, String testName, Directory tempDir) async {
  // Generate JSON schema - wrap non-object schemas in an object
  final Map<String, Object?> jsonSchema;
  if (schema is ObjectSchema) {
    jsonSchema = JsonSchemaConverter(schema: schema).toSchema();
  } else {
    // For non-object schemas, create a wrapper object schema
    final wrapperSchema = Ack.object({'value': schema});
    final fullSchema = JsonSchemaConverter(schema: wrapperSchema).toSchema();
    // Extract just the inner schema for validation
    final properties = fullSchema['properties'] as Map<String, Object?>;
    jsonSchema = {
      '\$schema': 'http://json-schema.org/draft-07/schema#',
      ...properties['value'] as Map<String, Object?>,
    };
  }

  // Write schema to temp file
  final schemaFile = File(path.join(tempDir.path, '$testName.json'));
  await schemaFile.writeAsString(jsonEncode(jsonSchema));

  // Validate using AJV
  final result = await _runSchemaValidation(schemaFile.path);

  expect(result['valid'], isTrue,
      reason:
          'Schema $testName should generate valid JSON Schema Draft-7. Errors: ${result['errors']}');
  expect(result['errors'], isEmpty);
  expect(result['validationType'], equals('compilation'));
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
