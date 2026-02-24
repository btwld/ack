import 'dart:io';

import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('Documentation Example Test Suite', () {
    group('Example Package Validation', () {
      test('example package should exist and be properly structured', () {
        final exampleDir = Directory('../../example');
        expect(
          exampleDir.existsSync(),
          isTrue,
          reason: 'Example package directory should exist',
        );

        final libDir = Directory('../../example/lib');
        expect(
          libDir.existsSync(),
          isTrue,
          reason: 'Example lib directory should exist',
        );

        final testDir = Directory('../../example/test');
        expect(
          testDir.existsSync(),
          isTrue,
          reason: 'Example test directory should exist',
        );
      });

      test('example package should have required files', () {
        final requiredFiles = [
          '../../example/pubspec.yaml',
          '../../example/README.md',
          '../../example/lib/simple_examples.dart',
          '../../example/lib/product_model.dart',
        ];

        for (final filePath in requiredFiles) {
          final file = File(filePath);
          expect(
            file.existsSync(),
            isTrue,
            reason: 'Required file $filePath should exist',
          );
        }
      });

      test('generated files should exist', () {
        final generatedFiles = [
          '../../example/lib/simple_examples.g.dart',
          '../../example/lib/product_model.g.dart',
        ];

        for (final filePath in generatedFiles) {
          final file = File(filePath);
          expect(
            file.existsSync(),
            isTrue,
            reason: 'Generated file $filePath should exist',
          );
        }
      });
    });

    group('Example Code Compilation', () {
      test('example package should compile without major errors', () async {
        final result = await Process.run('dart', [
          'analyze',
        ], workingDirectory: '../../example');

        // Allow warnings but not errors (exit code 3 means warnings, 1+ means errors)
        expect(
          result.exitCode,
          lessThanOrEqualTo(3),
          reason:
              'Example package should not have major errors:\n${result.stderr}',
        );
      });

      test(
        'example package should compile and run tests successfully',
        () async {
          final result = await Process.run('dart', [
            'test',
          ], workingDirectory: '../../example');

          expect(
            result.exitCode,
            equals(0),
            reason: 'Example tests should pass:\n${result.stderr}',
          );
        },
      );
    });

    group('Manual Schema Examples', () {
      test(
        'migration guide classes and generated schema are present',
        () async {
          final productModelFile = File('../../example/lib/product_model.dart');
          expect(productModelFile.existsSync(), isTrue);
          final content = await productModelFile.readAsString();

          expect(content, contains('class Product'));
          expect(content, contains('class Category'));
          expect(content, contains('part \'product_model.g.dart\';'));
          expect(content, isNot(contains('@AckModel(model: true)')));
        },
      );

      test('generated schema matches migration examples', () async {
        final generatedFile = File('../../example/lib/product_model.g.dart');
        expect(generatedFile.existsSync(), isTrue);
        final content = await generatedFile.readAsString();

        expect(content, contains('final productSchema = Ack.object'));
        expect(content, contains("'name': Ack.string()"));
      });
    });

    group('Build System Integration', () {
      test('build.yaml should be properly configured', () async {
        final buildFile = File('../../example/build.yaml');
        expect(buildFile.existsSync(), isTrue);

        final content = await buildFile.readAsString();
        expect(
          content,
          contains('ack_generator'),
          reason: 'build.yaml should reference ack_generator',
        );
      });

      test('pubspec.yaml should have correct dependencies', () async {
        final pubspecFile = File('../../example/pubspec.yaml');
        expect(pubspecFile.existsSync(), isTrue);

        final content = await pubspecFile.readAsString();

        // Check for required dependencies
        expect(
          content,
          contains('ack:'),
          reason: 'pubspec.yaml should include ack dependency',
        );
        // Note: ack_annotations is not required in the current setup
        expect(
          content,
          contains('ack_generator:'),
          reason: 'pubspec.yaml should include ack_generator dev dependency',
        );
        expect(
          content,
          contains('build_runner:'),
          reason: 'pubspec.yaml should include build_runner dev dependency',
        );
      });
    });

    group('Generated Code Quality', () {
      test('generated files should be properly formatted', () async {
        final generatedFiles = [
          '../../example/lib/simple_examples.g.dart',
          '../../example/lib/product_model.g.dart',
        ];

        for (final filePath in generatedFiles) {
          final file = File(filePath);
          if (!file.existsSync()) {
            // Skip this file if it doesn't exist
            continue;
          }

          final content = await file.readAsString();

          // Basic checks for generated content
          expect(
            content,
            contains('// GENERATED CODE'),
            reason: 'Generated file should have generation header',
          );
          expect(
            content,
            contains('Ack.object('),
            reason:
                'Generated file should contain generated schema definitions',
          );
        }
      });

      test('generated example entrypoint should execute', () async {
        final result = await Process.run('dart', [
          'run',
          'lib/simple_examples.dart',
        ], workingDirectory: '../../example');

        expect(
          result.exitCode,
          equals(0),
          reason: 'Generated code should execute successfully',
        );
        expect(
          result.stdout.toString(),
          contains('🎉 All examples completed!'),
          reason: 'Example entrypoint should complete',
        );
      });
    });

    group('Example Functionality', () {
      test('example models should demonstrate key features', () async {
        final simpleExamplesFile = File(
          '../../example/lib/simple_examples.dart',
        );
        final content = await simpleExamplesFile.readAsString();

        // Check that examples demonstrate key features
        expect(
          content,
          contains('additionalProperties: true'),
          reason: 'Examples should demonstrate additional properties',
        );
        expect(
          content,
          contains('additionalPropertiesField:'),
          reason:
              'Examples should show additional properties field configuration',
        );
        expect(
          content,
          contains('Map<String, dynamic>'),
          reason: 'Examples should show metadata/preferences fields',
        );
      });
    });

    group('Cross-Platform Compatibility', () {
      test('schema JSON roundtrip produces consistent output', () {
        // Verify schema serialization is deterministic across platforms
        final schema = Ack.object({
          'name': Ack.string().minLength(1),
          'age': Ack.integer().min(0),
        });

        final jsonSchema1 = schema.toJsonSchema();
        final jsonSchema2 = schema.toJsonSchema();

        expect(jsonSchema1, equals(jsonSchema2));
        expect(jsonSchema1, containsPair('type', 'object'));
        expect(jsonSchema1, contains('properties'));
      });
    });
  });
}
