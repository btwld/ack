import 'dart:convert';
import 'dart:io';

import 'package:ack/ack.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('Constraint Coverage Summary', () {
    late Directory tempDir;
    
    setUpAll(() async {
      await _ensureNodeDependencies();
    });
    
    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('ack_coverage_test_');
    });
    
    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('comprehensive constraint coverage validation', () async {
      // Create a schema that uses every available constraint type
      final comprehensiveSchema = Ack.object({
        // String constraints - all types
        'basicString': Ack.string,
        'emailString': Ack.string.email(),
        'uuidString': Ack.string.uuid(),
        'dateTimeString': Ack.string.dateTime(),
        'uriString': Ack.string.uri(),
        'lengthString': Ack.string.minLength(2).maxLength(50),
        'patternString': Ack.string.matches(r'^[A-Z][a-z]+$'),
        'enumString': Ack.string.enumValues(['admin', 'user', 'guest']),
        'literalString': Ack.string.literal('fixed-value'),
        'nullableString': Ack.string.nullable(),
        'combinedString': Ack.string.email().maxLength(100),
        
        // Numeric constraints - all types
        'basicInt': Ack.int,
        'rangeInt': Ack.int.min(0).max(100),
        'multipleInt': Ack.int.multipleOf(5),
        'nullableInt': Ack.int.nullable(),
        'basicDouble': Ack.double,
        'rangeDouble': Ack.double.min(0.0).max(100.0),
        'multipleDouble': Ack.double.multipleOf(0.5),
        'nullableDouble': Ack.double.nullable(),
        'combinedNumeric': Ack.int.min(1).max(10).multipleOf(2),
        
        // Boolean constraints
        'basicBoolean': Ack.boolean,
        'nullableBoolean': Ack.boolean.nullable(),
        
        // Array constraints - all types
        'basicArray': Ack.list(Ack.string),
        'constrainedArray': Ack.list(Ack.string.minLength(1)).minItems(1).maxItems(10),
        'uniqueArray': Ack.list(Ack.string).uniqueItems(),
        'nullableArray': Ack.list(Ack.string).nullable(),
        'nestedArray': Ack.list(Ack.list(Ack.int)),
        'complexItemArray': Ack.list(Ack.string.email()).minItems(1).uniqueItems(),
        
        // Object constraints - all types
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
        
        // Discriminated union constraints
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
      }, required: ['basicString', 'basicInt', 'basicBoolean']);

      // Generate and validate the comprehensive schema
      final jsonSchema = JsonSchemaConverter(schema: comprehensiveSchema).toSchema();
      
      final schemaFile = File(path.join(tempDir.path, 'comprehensive-coverage.json'));
      await schemaFile.writeAsString(JsonEncoder.withIndent('  ').convert(jsonSchema));
      
      final result = await _runSchemaValidation(schemaFile.path);
      expect(result['valid'], isTrue, 
        reason: 'Comprehensive constraint coverage schema should be valid JSON Schema Draft-7');

      // Verify constraint coverage
      final constraintCoverage = _analyzeConstraintCoverage(jsonSchema);
      
      print('\n📊 CONSTRAINT COVERAGE ANALYSIS:');
      print('✅ Total properties: ${constraintCoverage['totalProperties']}');
      print('✅ String constraints: ${constraintCoverage['stringConstraints']}');
      print('✅ Numeric constraints: ${constraintCoverage['numericConstraints']}');
      print('✅ Array constraints: ${constraintCoverage['arrayConstraints']}');
      print('✅ Object constraints: ${constraintCoverage['objectConstraints']}');
      print('✅ Discriminated unions: ${constraintCoverage['discriminatedUnions']}');
      print('✅ Nullable types: ${constraintCoverage['nullableTypes']}');
      print('✅ Format validators: ${constraintCoverage['formatValidators']}');
      print('✅ Pattern validators: ${constraintCoverage['patternValidators']}');
      print('✅ Enum constraints: ${constraintCoverage['enumConstraints']}');
      print('✅ Length constraints: ${constraintCoverage['lengthConstraints']}');
      print('✅ Range constraints: ${constraintCoverage['rangeConstraints']}');
      print('✅ MultipleOf constraints: ${constraintCoverage['multipleOfConstraints']}');
      
      // Verify we have comprehensive coverage
      expect(constraintCoverage['totalProperties'], greaterThan(20));
      expect(constraintCoverage['stringConstraints'], greaterThan(8));
      expect(constraintCoverage['numericConstraints'], greaterThan(6));
      expect(constraintCoverage['arrayConstraints'], greaterThan(4));
      expect(constraintCoverage['objectConstraints'], greaterThan(4));
      expect(constraintCoverage['discriminatedUnions'], greaterThan(1));
      expect(constraintCoverage['nullableTypes'], greaterThan(3));
      expect(constraintCoverage['formatValidators'], greaterThan(3));
      expect(constraintCoverage['patternValidators'], greaterThan(0));
      expect(constraintCoverage['enumConstraints'], greaterThan(1));
      expect(constraintCoverage['lengthConstraints'], greaterThan(1));
      expect(constraintCoverage['rangeConstraints'], greaterThan(2));
      expect(constraintCoverage['multipleOfConstraints'], greaterThan(1));
      
      print('\n🎯 COVERAGE VERIFICATION: ALL CONSTRAINT TYPES COVERED ✅');
    });

    test('constraint validation performance benchmark', () async {
      final startTime = DateTime.now();
      
      // Generate multiple schemas with different constraint combinations
      final schemas = <String, ObjectSchema>{};
      
      for (int i = 0; i < 10; i++) {
        schemas['schema_$i'] = Ack.object({
          'field_${i}_string': Ack.string.email().maxLength(100),
          'field_${i}_int': Ack.int.min(0).max(1000).multipleOf(i + 1),
          'field_${i}_array': Ack.list(Ack.string.uuid()).minItems(1).maxItems(5),
          'field_${i}_object': Ack.object({
            'nested': Ack.string.matches(r'^[A-Z0-9]+$'),
          }, required: ['nested']),
        });
      }
      
      final generationTime = DateTime.now().difference(startTime);
      
      // Validate all schemas
      final validationStart = DateTime.now();
      int validSchemas = 0;
      
      for (final entry in schemas.entries) {
        final jsonSchema = JsonSchemaConverter(schema: entry.value).toSchema();
        final schemaFile = File(path.join(tempDir.path, '${entry.key}.json'));
        await schemaFile.writeAsString(jsonEncode(jsonSchema));
        
        final result = await _runSchemaValidation(schemaFile.path);
        if (result['valid'] == true) {
          validSchemas++;
        }
      }
      
      final validationTime = DateTime.now().difference(validationStart);
      
      print('\n⚡ PERFORMANCE BENCHMARK:');
      print('📊 Schemas generated: ${schemas.length}');
      print('⏱️  Generation time: ${generationTime.inMilliseconds}ms');
      print('⏱️  Validation time: ${validationTime.inMilliseconds}ms');
      print('✅ Valid schemas: $validSchemas/${schemas.length}');
      print('📈 Average per schema: ${(generationTime.inMilliseconds + validationTime.inMilliseconds) / schemas.length}ms');
      
      expect(validSchemas, equals(schemas.length));
      expect(generationTime.inMilliseconds, lessThan(1000));
      expect(validationTime.inMilliseconds, lessThan(10000));
    });
  });
}

/// Analyze constraint coverage in the generated JSON schema
Map<String, int> _analyzeConstraintCoverage(Map<String, dynamic> jsonSchema) {
  final coverage = <String, int>{
    'totalProperties': 0,
    'stringConstraints': 0,
    'numericConstraints': 0,
    'arrayConstraints': 0,
    'objectConstraints': 0,
    'discriminatedUnions': 0,
    'nullableTypes': 0,
    'formatValidators': 0,
    'patternValidators': 0,
    'enumConstraints': 0,
    'lengthConstraints': 0,
    'rangeConstraints': 0,
    'multipleOfConstraints': 0,
  };

  void analyzeProperties(Map<String, dynamic> properties) {
    for (final prop in properties.values) {
      if (prop is Map<String, dynamic>) {
        coverage['totalProperties'] = coverage['totalProperties']! + 1;
        
        // Check for nullable types
        if (prop['type'] is List) {
          coverage['nullableTypes'] = coverage['nullableTypes']! + 1;
        }
        
        // Check for string constraints
        if (prop['type'] == 'string' || (prop['type'] is List && (prop['type'] as List).contains('string'))) {
          coverage['stringConstraints'] = coverage['stringConstraints']! + 1;
          
          if (prop.containsKey('format')) coverage['formatValidators'] = coverage['formatValidators']! + 1;
          if (prop.containsKey('pattern')) coverage['patternValidators'] = coverage['patternValidators']! + 1;
          if (prop.containsKey('enum')) coverage['enumConstraints'] = coverage['enumConstraints']! + 1;
          if (prop.containsKey('minLength') || prop.containsKey('maxLength')) {
            coverage['lengthConstraints'] = coverage['lengthConstraints']! + 1;
          }
        }
        
        // Check for numeric constraints
        if (prop['type'] == 'integer' || prop['type'] == 'number' || 
            (prop['type'] is List && ((prop['type'] as List).contains('integer') || (prop['type'] as List).contains('number')))) {
          coverage['numericConstraints'] = coverage['numericConstraints']! + 1;
          
          if (prop.containsKey('minimum') || prop.containsKey('maximum')) {
            coverage['rangeConstraints'] = coverage['rangeConstraints']! + 1;
          }
          if (prop.containsKey('multipleOf')) {
            coverage['multipleOfConstraints'] = coverage['multipleOfConstraints']! + 1;
          }
        }
        
        // Check for array constraints
        if (prop['type'] == 'array' || (prop['type'] is List && (prop['type'] as List).contains('array'))) {
          coverage['arrayConstraints'] = coverage['arrayConstraints']! + 1;
        }
        
        // Check for object constraints
        if (prop['type'] == 'object') {
          coverage['objectConstraints'] = coverage['objectConstraints']! + 1;
          
          if (prop.containsKey('properties')) {
            analyzeProperties(prop['properties'] as Map<String, dynamic>);
          }
        }
        
        // Check for discriminated unions
        if (prop.containsKey('allOf')) {
          coverage['discriminatedUnions'] = coverage['discriminatedUnions']! + 1;
        }
      }
    }
  }

  if (jsonSchema.containsKey('properties')) {
    analyzeProperties(jsonSchema['properties'] as Map<String, dynamic>);
  }

  return coverage;
}

/// Run AJV schema validation
Future<Map<String, dynamic>> _runSchemaValidation(String schemaPath) async {
  final projectRoot = _findProjectRoot();
  final validatorScript = path.join(projectRoot, 'tools', 'ajv-validator.js');

  final result = await Process.run(
    'node',
    [validatorScript, 'validate-schema', '--schema', schemaPath, '--json'],
    workingDirectory: projectRoot,
  );

  if (result.exitCode != 0) {
    return {'valid': false, 'errors': [result.stderr.toString()]};
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
    final result = await Process.run('npm', ['install'], workingDirectory: toolsDir);
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
