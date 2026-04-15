import 'dart:io';

import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('Documentation Example Test Suite', () {
    group('Example Package Validation', () {
      const retainedExampleSources = [
        'args_getter_example.dart',
        'pet.dart',
        'schema_types_discriminated.dart',
        'schema_types_edge_cases.dart',
        'schema_types_primitives.dart',
        'schema_types_simple.dart',
        'schema_types_transforms.dart',
        'user_with_color.dart',
      ];
      const retainedGeneratedFiles = [
        'args_getter_example.g.dart',
        'pet.g.dart',
        'schema_types_discriminated.g.dart',
        'schema_types_edge_cases.g.dart',
        'schema_types_primitives.g.dart',
        'schema_types_simple.g.dart',
        'schema_types_transforms.g.dart',
        'user_with_color.g.dart',
      ];

      test('example package should exist and be properly structured', () {
        final exampleDir = Directory('../../example');
        expect(exampleDir.existsSync(), isTrue);

        expect(Directory('../../example/lib').existsSync(), isTrue);
        expect(Directory('../../example/test').existsSync(), isTrue);
      });

      test(
        'example package should have the full retained AckType source set',
        () async {
          final exampleLib = Directory('../../example/lib');
          final actualSources = <String>[];

          for (final entry in exampleLib.listSync()) {
            if (entry is! File || !entry.path.endsWith('.dart')) {
              continue;
            }

            final fileName = entry.uri.pathSegments.last;
            if (fileName.endsWith('.g.dart')) {
              continue;
            }

            final content = await entry.readAsString();
            if (content.contains('@AckType()')) {
              actualSources.add(fileName);
            }
          }

          actualSources.sort();
          expect(actualSources, retainedExampleSources);
        },
      );

      test('generated AckType example files should match the retained set', () {
        final actualGeneratedFiles =
            Directory('../../example/lib')
                .listSync()
                .whereType<File>()
                .map((file) => file.uri.pathSegments.last)
                .where((fileName) => fileName.endsWith('.g.dart'))
                .toList()
              ..sort();

        expect(actualGeneratedFiles, retainedGeneratedFiles);
      });
    });

    group('Example Code Compilation', () {
      test('example package should compile without major errors', () async {
        final result = await Process.run('dart', [
          'analyze',
        ], workingDirectory: '../../example');

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

    group('Build System Integration', () {
      test('build.yaml should be properly configured', () async {
        final buildFile = File('../../example/build.yaml');
        expect(buildFile.existsSync(), isTrue);

        final content = await buildFile.readAsString();
        expect(content, contains('ack_generator'));
      });

      test('pubspec.yaml should have correct dependencies', () async {
        final pubspecFile = File('../../example/pubspec.yaml');
        expect(pubspecFile.existsSync(), isTrue);

        final content = await pubspecFile.readAsString();
        expect(content, contains('ack:'));
        expect(content, contains('ack_generator:'));
        expect(content, contains('build_runner:'));
      });
    });

    group('Generated Code Quality', () {
      test('generated files should contain extension types', () async {
        final generatedFiles = [
          '../../example/lib/args_getter_example.g.dart',
          '../../example/lib/pet.g.dart',
          '../../example/lib/schema_types_simple.g.dart',
        ];

        for (final filePath in generatedFiles) {
          final content = await File(filePath).readAsString();
          expect(content, contains('// GENERATED CODE'));
          expect(content, contains('extension type'));
        }
      });

      test('README should describe AckType-based examples', () async {
        final readme = await File('../../example/README.md').readAsString();
        expect(readme, contains('@AckType'));
        expect(readme, isNot(contains('annotated classes')));
      });

      test('ack_annotations README documents runnable AckType setup', () async {
        final readme = await File(
          '../../packages/ack_annotations/README.md',
        ).readAsString();

        expect(readme, contains('ack_generator'));
        expect(readme, contains('build_runner'));
        expect(readme, contains("import 'package:ack/ack.dart'"));
      });

      test(
        'api reference links to the current discriminated schemas anchor',
        () async {
          final content = await File(
            '../../docs/api-reference/index.mdx',
          ).readAsString();

          expect(content, contains('#discriminated-schemas'));
          expect(
            content,
            isNot(
              contains('#ackdiscriminated-with-acktype-current-constraints'),
            ),
          );
        },
      );

      test('ack_annotations library has a library-level doc comment', () async {
        final content = await File(
          '../../packages/ack_annotations/lib/ack_annotations.dart',
        ).readAsString();

        expect(content.trimLeft(), startsWith('///'));
      });
    });

    group('Example Functionality', () {
      test(
        'args getter example should demonstrate passthrough access',
        () async {
          final content = await File(
            '../../example/lib/args_getter_example.dart',
          ).readAsString();

          expect(content, contains('@AckType()'));
          expect(content, contains('additionalProperties: true'));
        },
      );
    });

    group('Cross-Platform Compatibility', () {
      test('schema JSON roundtrip produces consistent output', () {
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
