import 'dart:io';

import 'package:ack_generator/builder.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import 'utils/mock_ack_package.dart';

void main() {
  group('AckBuilder', () {
    test('generates correct output for user model', () async {
      await testGolden('user_model');
    });

    test('generates correct output for product model', () async {
      await testGolden('product_model');
    });

    test('generates correct output for nested models', () async {
      await testGolden('block_model');
    });

    test('generates correct output for sealed classes', () async {
      await testGolden('sealed_block_model');
    });

    test(
      'generates correct output for discriminated unions with sealed classes',
      () async {
        await testGolden('payment_method_model');
      },
    );

    test(
      'generates correct output for discriminated unions with abstract classes',
      () async {
        await testGolden('abstract_shape_model');
      },
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

      // Should throw InvalidGenerationSourceError for non-class elements
      expect(
        () => testBuilder(
          ackSchemaBuilder(BuilderOptions.empty),
          {
            'ack_generator|lib/invalid_enum.dart': input,
            ...getMockAckPackage(),
          },
          outputs: {},
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Generator cannot target'),
          ),
        ),
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
    reader: await PackageAssetReader.currentIsolate(),
  );

  if (generatedOutput.isEmpty) {
    throw Exception('No output generated for $name');
  }

  return generatedOutput;
}
