import 'dart:io';

import 'package:ack_generator/builder.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import 'utils/mock_ack_package.dart';

void main() {
  group('AckBuilder', () {
    test(
      'generates correct output for user model',
      () async {
        await testGolden('user_model');
      },
      tags: ['golden'],
    );

    test(
      'generates correct output for product model',
      () async {
        await testGolden('product_model');
      },
      tags: ['golden'],
    );

    test(
      'generates correct output for nested models',
      () async {
        await testGolden('block_model');
      },
      tags: ['golden'],
    );

    test(
      'generates correct output for sealed classes',
      () async {
        await testGolden('sealed_block_model');
      },
      tags: ['golden'],
    );

    test(
      'generates correct output for discriminated unions with sealed classes',
      () async {
        await testGolden('payment_method_model');
      },
      tags: ['golden'],
    );

    test(
      'generates correct output for discriminated unions with abstract classes',
      () async {
        await testGolden('abstract_shape_model');
      },
      tags: ['golden'],
    );

    if (Platform.environment['UPDATE_GOLDEN'] == 'true') {
      print('Golden files updated. Review changes before committing.');
    }
  });

  group('error handling', () {
    test('handles missing @Schema annotation gracefully', () async {
      const input = '''
        class InvalidModel {
          final String name;
          InvalidModel({required this.name});
        }
      ''';

      // Should not generate any output for classes without @Schema
      await testBuilder(
        ackSchemaBuilder(BuilderOptions.empty),
        {
          'ack_generator|lib/invalid.dart': input,
          ...getMockAckPackage(),
        },
        outputs: {},
      );
    });

    test('reports error for non-class elements with @Schema', () async {
      const input = '''
        import 'package:ack/ack.dart';

        @Schema()
        enum InvalidEnum { value1, value2 }
      ''';

      var foundError = false;
      
      // Should generate no output and report error for non-class elements
      await testBuilder(
        ackSchemaBuilder(BuilderOptions.empty),
        {
          'ack_generator|lib/invalid_enum.dart': input,
          ...getMockAckPackage(),
        },
        outputs: {},
        onLog: (log) {
          if (log.message.contains('Generator cannot target')) {
            foundError = true;
          }
        },
      );
      
      expect(foundError, isTrue, reason: 'Expected error message about "Generator cannot target" not found');
    });
  });

  group('builder configuration', () {
    test('handles custom BuilderOptions', () async {
      final customOptions = BuilderOptions({
        'generate_for': ['**/*.dart'],
        'exclude': ['**/*.g.dart'],
      });

      final inputFile = File('test/fixtures/user_model.dart');
      final input = inputFile.readAsStringSync();

      await testBuilder(
        ackSchemaBuilder(customOptions),
        {
          'ack_generator|lib/user_model.dart': input,
          ...getMockAckPackage(),
        },
        outputs: {
          'ack_generator|lib/user_model.g.dart': isNotEmpty,
        },
      );
    });

    test('handles empty BuilderOptions', () async {
      final emptyOptions = BuilderOptions({});

      final inputFile = File('test/fixtures/user_model.dart');
      final input = inputFile.readAsStringSync();

      await testBuilder(
        ackSchemaBuilder(emptyOptions),
        {
          'ack_generator|lib/user_model.dart': input,
          ...getMockAckPackage(),
        },
        outputs: {
          'ack_generator|lib/user_model.g.dart': isNotEmpty,
        },
      );
    });

    test('handles BuilderOptions with null values', () async {
      final nullOptions = BuilderOptions({
        'some_option': null,
        'another_option': '',
      });

      final inputFile = File('test/fixtures/product_model.dart');
      final input = inputFile.readAsStringSync();

      await testBuilder(
        ackSchemaBuilder(nullOptions),
        {
          'ack_generator|lib/product_model.dart': input,
          ...getMockAckPackage(),
        },
        outputs: {
          'ack_generator|lib/product_model.g.dart': isNotEmpty,
        },
      );
    });
  });

  group('complex scenarios', () {
    test(
      'handles deeply nested models',
      () async {
        await testGolden('deeply_nested_model');
      },
      tags: ['golden'],
    );

    test(
      'handles models with many properties',
      () async {
        await testGolden('large_model');
      },
      tags: ['golden'],
    );

    test('verifies deep nesting dependency registration', () async {
      final inputFile = File('test/fixtures/deeply_nested_model.dart');
      final input = inputFile.readAsStringSync();

      await testBuilder(
        ackSchemaBuilder(BuilderOptions.empty),
        {
          'ack_generator|lib/deeply_nested_model.dart': input,
          ...getMockAckPackage(),
        },
        outputs: {
          'ack_generator|lib/deeply_nested_model.g.dart':
              predicate<List<int>>((content) {
            final generated = String.fromCharCodes(content);
            return generated.contains('Level1Schema') &&
                generated.contains('Level2Schema') &&
                generated.contains('Level3Schema') &&
                generated.contains('Level4Schema') &&
                generated.contains('Level2Schema.ensureInitialize()') &&
                generated.contains('Level3Schema.ensureInitialize()') &&
                generated.contains('Level4Schema.ensureInitialize()');
          }),
        },
      );
    });

    test('verifies large model performance characteristics', () async {
      final stopwatch = Stopwatch()..start();

      final inputFile = File('test/fixtures/large_model.dart');
      final input = inputFile.readAsStringSync();

      await testBuilder(
        ackSchemaBuilder(BuilderOptions.empty),
        {
          'ack_generator|lib/large_model.dart': input,
          ...getMockAckPackage(),
        },
        outputs: {
          'ack_generator|lib/large_model.g.dart':
              predicate<List<int>>((content) {
            final generated = String.fromCharCodes(content);
            return generated.contains('LargeModelSchema') &&
                generated.contains('field1') &&
                generated.contains('field24') &&
                generated.contains('extraData');
          }),
        },
      );

      stopwatch.stop();

      // Should process large model efficiently (under 2 seconds)
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(2000),
        reason: 'Large model generation should complete in under 2 seconds',
      );
    });
  });
}

Future<void> testGolden(String name) async {
  final inputFile = File('test/fixtures/$name.dart');
  final goldenFile = File('test/golden/$name.golden');

  if (!inputFile.existsSync()) {
    throw Exception('Test fixture not found: test/fixtures/$name.dart');
  }

  final input = inputFile.readAsStringSync();

  if (Platform.environment['UPDATE_GOLDEN'] == 'true') {
    // Update mode - generate and save output
    final result = await runBuilder(name, input);
    await goldenFile.writeAsString(result);
    print('Updated golden file: $name.golden');
  } else {
    // Test mode - compare with expected
    if (!goldenFile.existsSync()) {
      throw Exception(
        'Golden file not found: test/golden/$name.golden\n'
        'Run with UPDATE_GOLDEN=true to create it.',
      );
    }

    final expected = goldenFile.readAsStringSync();
    await testBuilder(
      ackSchemaBuilder(BuilderOptions.empty),
      {
        'ack_generator|lib/$name.dart': input,
        ...getMockAckPackage(),
      },
      outputs: {'ack_generator|lib/$name.g.dart': expected},
    );
  }
}

// Helper to run builder and get output (for UPDATE_GOLDEN mode)
Future<String> runBuilder(String name, String input) async {
  var generatedOutput = '';

  await testBuilder(
    ackSchemaBuilder(BuilderOptions.empty),
    {'ack_generator|lib/$name.dart': input},
    outputs: {
      'ack_generator|lib/$name.g.dart': predicate<List<int>>((content) {
        generatedOutput = String.fromCharCodes(content);
        return true;
      }),
    },
  );

  if (generatedOutput.isEmpty) {
    throw Exception('No output generated for $name');
  }

  return generatedOutput;
}
