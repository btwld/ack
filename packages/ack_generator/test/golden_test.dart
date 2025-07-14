import 'dart:io';

import 'package:ack_generator/builder.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'test_utils/test_assets.dart';

/// Helper function to validate generated code with dart analyze
Future<void> validateGeneratedCode(
    String generatedCode, String testName) async {
  // Create a temporary directory for analysis
  final tempDir = Directory.systemTemp.createTempSync('ack_generator_test_');

  try {
    // Create a temporary Dart file with the generated code
    final tempFile = File(p.join(tempDir.path, 'generated_test.dart'));

    // Add necessary imports and wrap the generated code
    final fullCode = '''
// Generated code for testing - $testName
import 'package:meta/meta.dart';

// Mock dependencies for analysis
abstract class SchemaModel {
  const SchemaModel();
  const SchemaModel.validated(Map<String, Object?> data);

  T getValue<T extends Object>(String key) => throw UnimplementedError();
  T? getValueOrNull<T extends Object>(String key) => throw UnimplementedError();
  Map<String, Object?> toMap() => throw UnimplementedError();

  dynamic parse(Object? input) => throw UnimplementedError();
  dynamic tryParse(Object? input) => throw UnimplementedError();
  dynamic createValidated(Map<String, Object?> data) => throw UnimplementedError();
}

class Ack {
  static const string = _StringSchema();
  static const double = _DoubleSchema();
  static const integer = _IntegerSchema();

  static _ObjectSchema object(Map<String, dynamic> properties, {bool additionalProperties = false}) =>
      _ObjectSchema();
}

class _StringSchema {
  const _StringSchema();
  _StringSchema nullable() => this;
}

class _DoubleSchema {
  const _DoubleSchema();
  _DoubleSchema nullable() => this;
}

class _IntegerSchema {
  const _IntegerSchema();
  _IntegerSchema nullable() => this;
}

class _ObjectSchema {
  const _ObjectSchema();
}

// Generated code under test:
$generatedCode
''';

    await tempFile.writeAsString(fullCode);

    // Run dart analyze on the temporary file
    final result = await Process.run(
      'dart',
      ['analyze', '--fatal-infos', tempFile.path],
      workingDirectory: tempDir.path,
    );

    if (result.exitCode != 0) {
      fail('Generated code has analysis issues:\n'
          'STDOUT: ${result.stdout}\n'
          'STDERR: ${result.stderr}\n'
          'Generated code:\n$generatedCode');
    }

    print('✅ Generated code for $testName passed dart analyze');
  } finally {
    // Clean up temporary directory
    try {
      tempDir.deleteSync(recursive: true);
    } catch (e) {
      // Ignore cleanup errors
    }
  }
}

void main() {
  group('Golden Tests', () {
    test('user schema golden test', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      // Note: This test now validates the new API format directly

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/user.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
class User {
  final String id;
  final String name;
  final String email;
  final int? age;
  
  User({
    required this.id,
    required this.name,
    required this.email,
    this.age,
  });
}
''',
        },
        outputs: {
          'test_pkg|lib/user.g.dart': decodedMatches(
            predicate<String>(
              (actual) {
                return actual.contains('final userSchema = Ack.object(') &&
                    actual.contains("'id': Ack.string()") &&
                    actual.contains("'name': Ack.string()") &&
                    actual.contains("'email': Ack.string()") &&
                    actual.contains("'age': Ack.integer().optional()");
              },
              'matches golden file content',
            ),
          ),
        },
      );
    });

    test('complex nested schema golden test', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/order.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
class OrderItem {
  final String productId;
  final int quantity;
  final double price;
  
  OrderItem({
    required this.productId,
    required this.quantity,
    required this.price,
  });
}

@AckModel()
class Order {
  final String id;
  final List<OrderItem> items;
  final DateTime createdAt;
  
  Order({
    required this.id,
    required this.items,
    required this.createdAt,
  });
}
''',
        },
        outputs: {
          'test_pkg|lib/order.g.dart': decodedMatches(
            predicate<String>(
              (actual) {
                return actual.contains('final orderItemSchema = Ack.object(') &&
                    actual.contains('final orderSchema = Ack.object(') &&
                    actual.contains("'productId': Ack.string()") &&
                    actual.contains("'quantity': Ack.integer()") &&
                    actual.contains("'price': Ack.double()");
              },
              'matches order golden file content',
            ),
          ),
        },
      );
    });

    test('additional properties schema golden test', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/product.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel(
  description: 'A product model with additional properties support',
  additionalProperties: true,
  additionalPropertiesField: 'metadata',
)
class Product {
  final String name;
  final double price;
  final String? description;
  final Map<String, dynamic> metadata;

  Product({
    required this.name,
    required this.price,
    this.description,
    this.metadata = const {},
  });
}

@AckModel(
  description: 'A simple product without additional properties',
)
class SimpleProduct {
  final String name;
  final double price;

  SimpleProduct({
    required this.name,
    required this.price,
  });
}
''',
        },
        outputs: {
          'test_pkg|lib/product.g.dart': decodedMatches(
            predicate<String>(
              (actual) {
                // Check Product schema with additional properties
                final hasProductSchema =
                    actual.contains('final productSchema = Ack.object(');

                // Check SimpleProduct schema without additional properties
                final hasSimpleProductSchema =
                    actual.contains('final simpleProductSchema = Ack.object(');

                // Check field definitions
                final hasProductFields = actual
                        .contains("'name': Ack.string()") &&
                    actual.contains("'price': Ack.double()") &&
                    actual.contains("'description': Ack.string().optional()");

                final hasSimpleProductFields =
                    actual.contains("'name': Ack.string()") &&
                        actual.contains("'price': Ack.double()");

                return hasProductSchema &&
                    hasSimpleProductSchema &&
                    hasProductFields &&
                    hasSimpleProductFields;
              },
              'matches additional properties golden file content',
            ),
          ),
        },
      );
    });
  });
}
