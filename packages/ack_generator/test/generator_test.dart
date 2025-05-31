import 'dart:io';

import 'package:ack_generator/builder.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

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
    });

    test(
        'generates correct output for discriminated unions with abstract classes',
        () async {
      await testGolden('abstract_shape_model');
    });

    if (Platform.environment['UPDATE_GOLDEN'] == 'true') {
      print('Golden files updated. Review changes before committing.');
    }
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
      throw Exception('Golden file not found: test/golden/$name.golden\n'
          'Run with UPDATE_GOLDEN=true to create it.');
    }

    final expected = goldenFile.readAsStringSync();
    await testBuilder(
      ackSchemaBuilder(BuilderOptions.empty),
      {
        'ack_generator|lib/$name.dart': input,
        // Provide ack package dependency
        'ack|lib/ack.dart': '''
export 'src/annotations.dart';
export 'src/ack.dart';
export 'src/schema_model.dart';
export 'src/schema_registry.dart';
export 'src/json_schema_converter.dart';
export 'src/ack_exception.dart';
''',
        'ack|lib/src/annotations.dart': '''
class Schema {
  final String? description;
  final bool additionalProperties;
  final String? additionalPropertiesField;
  final String? discriminatedKey;
  final String? discriminatedValue;

  const Schema({
    this.description,
    this.additionalProperties = false,
    this.additionalPropertiesField,
    this.discriminatedKey,
    this.discriminatedValue,
  });
}

class IsEmail {
  const IsEmail();
}

class IsNotEmpty {
  const IsNotEmpty();
}

class Required {
  const Required();
}

class MinLength {
  final int length;
  const MinLength(this.length);
}

class Nullable {
  const Nullable();
}
''',
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
