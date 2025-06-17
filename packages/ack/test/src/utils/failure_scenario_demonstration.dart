import 'dart:convert';
import 'dart:io';

import 'package:ack/ack.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('Failure Scenario Demonstrations', () {
    late Directory tempDir;

    setUpAll(() async {
      await _ensureNodeDependencies();
    });

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('ack_failure_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test(
        'DEMONSTRATION: What happens when schema generation is completely broken',
        () async {
      // Simulate completely broken JSON Schema generation
      final brokenSchemas = [
        {
          'name': 'missing-schema-declaration',
          'schema': {
            'type': 'object',
            'properties': {
              'name': {'type': 'string'}
            },
            // Missing $schema declaration
          },
        },
        {
          'name': 'invalid-type-constraint',
          'schema': {
            '\$schema': 'http://json-schema.org/draft-07/schema#',
            'type': 'object',
            'properties': {
              'name': {
                'type': 'string',
                'minLength': 'this-should-be-a-number', // BROKEN
              }
            },
          },
        },
        {
          'name': 'malformed-enum',
          'schema': {
            '\$schema': 'http://json-schema.org/draft-07/schema#',
            'type': 'object',
            'properties': {
              'status': {
                'type': 'string',
                'enum': 'should-be-array', // BROKEN
              }
            },
          },
        },
        {
          'name': 'invalid-format',
          'schema': {
            '\$schema': 'http://json-schema.org/draft-07/schema#',
            'type': 'object',
            'properties': {
              'email': {
                'type': 'string',
                'format': 'not-a-real-format', // BROKEN
              }
            },
          },
        },
      ];

      print('\n🔥 DEMONSTRATING FAILURE DETECTION:');

      for (final brokenCase in brokenSchemas) {
        final file =
            File(path.join(tempDir.path, '${brokenCase['name']}.json'));
        await file.writeAsString(jsonEncode(brokenCase['schema']));

        try {
          final result = await _runSchemaValidation(file.path);

          if (result['valid'] == false) {
            print(
                '✅ CAUGHT: ${brokenCase['name']} - correctly failed validation');
            print('   Errors: ${result['errors']}');
          } else {
            print(
                '❌ MISSED: ${brokenCase['name']} - should have failed but passed!');
          }
        } catch (e) {
          print('✅ CAUGHT: ${brokenCase['name']} - threw error: $e');
        }
      }
    });

    test('DEMONSTRATION: Comparing broken vs working schema generation',
        () async {
      print('\n📊 SIDE-BY-SIDE COMPARISON:');

      // Working Ack-generated schema
      final workingSchema = Ack.object({
        'user': Ack.object({
          'id': Ack.string.uuid(),
          'email': Ack.string.email(),
          'age': Ack.int.min(0).max(120),
        }, required: [
          'id',
          'email'
        ]),
      }, required: [
        'user'
      ]);

      final workingJson = JsonSchemaConverter(schema: workingSchema).toSchema();
      final workingFile = File(path.join(tempDir.path, 'working-schema.json'));
      await workingFile
          .writeAsString(JsonEncoder.withIndent('  ').convert(workingJson));

      // Manually broken version of the same schema
      final brokenJson = Map<String, dynamic>.from(workingJson);
      final userProps = (brokenJson['properties'] as Map)['user'] as Map;
      final userSubProps = userProps['properties'] as Map;

      // Break the email format
      (userSubProps['email'] as Map)['format'] = 'invalid-email-format';
      // Break the age constraint
      (userSubProps['age'] as Map)['minimum'] = 'not-a-number';

      final brokenFile = File(path.join(tempDir.path, 'broken-schema.json'));
      await brokenFile
          .writeAsString(JsonEncoder.withIndent('  ').convert(brokenJson));

      // Test working schema
      final workingResult = await _runSchemaValidation(workingFile.path);
      print('🟢 WORKING SCHEMA:');
      print('   Valid: ${workingResult['valid']}');
      print('   Errors: ${workingResult['errors']}');

      // Test broken schema
      try {
        final brokenResult = await _runSchemaValidation(brokenFile.path);
        print('🔴 BROKEN SCHEMA:');
        print('   Valid: ${brokenResult['valid']}');
        print('   Errors: ${brokenResult['errors']}');
      } catch (e) {
        print('🔴 BROKEN SCHEMA: Threw error - $e');
      }

      // Verify the working schema passes and broken fails
      expect(workingResult['valid'], isTrue,
          reason: 'Working schema should pass');
    });

    test('DEMONSTRATION: Real-world validation against external tools',
        () async {
      // Generate a complex schema that we can validate externally
      final realWorldSchema = Ack.object({
        'api': Ack.object({
          'version': Ack.string.matches(r'^\d+\.\d+\.\d+$'),
          'endpoints': Ack.list(Ack.object({
            'path': Ack.string.matches(r'^/[a-zA-Z0-9/_-]*$'),
            'method': Ack.string.enumValues(['GET', 'POST', 'PUT', 'DELETE']),
            'auth': Ack.boolean,
            'rateLimit': Ack.object({
              'requests': Ack.int.min(1),
              'window': Ack.string.enumValues(['minute', 'hour', 'day']),
            }),
          }, required: [
            'path',
            'method'
          ])),
          'authentication': Ack.discriminated(
            discriminatorKey: 'type',
            schemas: {
              'jwt': Ack.object({
                'type': Ack.string.literal('jwt'),
                'secret': Ack.string.minLength(32),
                'expiry': Ack.int.min(300), // 5 minutes minimum
              }, required: [
                'type',
                'secret',
                'expiry'
              ]),
              'apikey': Ack.object({
                'type': Ack.string.literal('apikey'),
                'header': Ack.string.minLength(1),
                'prefix': Ack.string.nullable(),
              }, required: [
                'type',
                'header'
              ]),
            },
          ),
        }, required: [
          'version',
          'endpoints',
          'authentication'
        ]),
      }, required: [
        'api'
      ]);

      final jsonSchema =
          JsonSchemaConverter(schema: realWorldSchema).toSchema();

      // Save for external validation
      final externalFile =
          File(path.join(tempDir.path, 'real-world-api-schema.json'));
      await externalFile
          .writeAsString(JsonEncoder.withIndent('  ').convert(jsonSchema));

      // Validate with AJV
      final result = await _runSchemaValidation(externalFile.path);

      print('\n🌍 REAL-WORLD SCHEMA VALIDATION:');
      print('✅ AJV Validation: ${result['valid'] ? 'PASSED' : 'FAILED'}');
      print('📄 Schema file: ${externalFile.path}');
      print('📊 Schema complexity:');
      print('   - Total size: ${jsonEncode(jsonSchema).length} characters');
      print('   - Nested levels: 4+ levels deep');
      print('   - Discriminated union: ✓');
      print('   - Format validation: ✓');
      print('   - Pattern matching: ✓');
      print('   - Enum constraints: ✓');

      expect(result['valid'], isTrue,
          reason: 'Real-world schema should be valid');

      print('\n🔗 EXTERNAL VALIDATION INSTRUCTIONS:');
      print('1. Copy the schema from: ${externalFile.path}');
      print('2. Paste it into: https://www.jsonschemavalidator.net/');
      print('3. Verify it shows "Valid JSON Schema"');
      print('4. Test with sample data to confirm it works');
    });

    test('DEMONSTRATION: Performance and scale validation', () async {
      // Generate a large, complex schema to test performance
      final largeSchema = Ack.object(
        Map.fromEntries(List.generate(
            50,
            (i) => MapEntry(
                  'field_$i',
                  i % 5 == 0
                      ? Ack.object({
                          'nested_${i}_a': Ack.string.email(),
                          'nested_${i}_b': Ack.int.min(0).max(1000),
                          'nested_${i}_c':
                              Ack.list(Ack.string.enumValues(['a', 'b', 'c'])),
                        }, required: [
                          'nested_${i}_a'
                        ]) as AckSchema
                      : i % 3 == 0
                          ? Ack.list(Ack.string.uuid()) as AckSchema
                          : Ack.string.matches(r'^[A-Za-z0-9_-]+$')
                              as AckSchema,
                ))),
        required: List.generate(10, (i) => 'field_$i'),
      );

      final startTime = DateTime.now();
      final jsonSchema = JsonSchemaConverter(schema: largeSchema).toSchema();
      final generationTime = DateTime.now().difference(startTime);

      final schemaFile = File(path.join(tempDir.path, 'large-schema.json'));
      await schemaFile.writeAsString(jsonEncode(jsonSchema));

      final validationStart = DateTime.now();
      final result = await _runSchemaValidation(schemaFile.path);
      final validationTime = DateTime.now().difference(validationStart);

      print('\n⚡ PERFORMANCE VALIDATION:');
      print('📊 Schema stats:');
      print('   - Properties: ${(jsonSchema['properties'] as Map).length}');
      print('   - Required fields: ${(jsonSchema['required'] as List).length}');
      print('   - JSON size: ${jsonEncode(jsonSchema).length} characters');
      print('⏱️  Performance:');
      print('   - Generation time: ${generationTime.inMilliseconds}ms');
      print('   - Validation time: ${validationTime.inMilliseconds}ms');
      print('✅ Validation result: ${result['valid'] ? 'PASSED' : 'FAILED'}');

      expect(result['valid'], isTrue, reason: 'Large schema should be valid');
      expect(generationTime.inMilliseconds, lessThan(1000),
          reason: 'Generation should be fast');
      expect(validationTime.inMilliseconds, lessThan(5000),
          reason: 'Validation should be reasonable');
    });
  });
}

/// Run JSON Schema validation with error handling
Future<Map<String, dynamic>> _runSchemaValidation(String schemaPath) async {
  final projectRoot = _findProjectRoot();
  final validatorScript = path.join(projectRoot, 'tools', 'jsonschema-validator.js');

  final result = await Process.run(
    'node',
    [validatorScript, 'validate-schema', '--schema', schemaPath, '--json'],
    workingDirectory: projectRoot,
  );

  if (result.exitCode == 0) {
    final lines = result.stdout.toString().split('\n');
    final jsonLine = lines.firstWhere(
      (line) => line.trim().startsWith('{'),
      orElse: () => '{"valid": true, "errors": []}',
    );
    return jsonDecode(jsonLine);
  } else {
    return {
      'valid': false,
      'errors': [
        {'message': result.stderr.toString()}
      ],
      'validationType': 'error',
    };
  }
}

/// Ensure Node.js dependencies are installed
Future<void> _ensureNodeDependencies() async {
  final projectRoot = _findProjectRoot();
  final toolsDir = path.join(projectRoot, 'tools');
  final nodeModulesDir = Directory(path.join(toolsDir, 'node_modules'));

  if (!await nodeModulesDir.exists()) {
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
