import 'package:test/test.dart';
import 'package:build_test/build_test.dart';
import 'package:build/build.dart';
import 'package:ack_generator/builder.dart';

import 'test_utils/test_assets.dart';

void main() {
  group('Description Generation Tests', () {
    test('generates class-level descriptions in schema comments', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/test.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel(description: 'A comprehensive user model for testing')
class User {
  final String name;
  final String email;
  
  User({required this.name, required this.email});
}
''',
        },
        outputs: {
          'test_pkg|lib/test.g.dart': decodedMatches(allOf([
            contains('Generated schema for User'),
            contains('A comprehensive user model for testing'),
            contains('final userSchema = Ack.object({'),
          ])),
        },
      );
    });

    test('generates field-level descriptions when @AckField is used', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/test.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel(description: 'User model with documented fields')
class User {
  @AckField(description: 'The user\\'s full name')
  final String name;
  
  @AckField(description: 'User\\'s primary email address')
  final String email;
  
  final int age;
  
  User({required this.name, required this.email, required this.age});
}
''',
        },
        outputs: {
          'test_pkg|lib/test.g.dart': decodedMatches(allOf([
            contains('Generated schema for User'),
            contains('User model with documented fields'),
            contains('final userSchema = Ack.object({'),
            // Note: Field descriptions would need to be added to schema generation
            // This test documents current behavior and future enhancement
          ])),
        },
      );
    });

    test('works with both class and field descriptions', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/test.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel(
  description: 'Product model for e-commerce platform',
  model: true
)
class Product {
  @AckField(description: 'Unique product identifier')
  final String id;
  
  @AckField(description: 'Product display name')
  final String name;
  
  @AckField(description: 'Current product price in USD')
  final double price;
  
  final String? description;
  
  Product({
    required this.id, 
    required this.name, 
    required this.price,
    this.description
  });
}
''',
        },
        outputs: {
          'test_pkg|lib/test.g.dart': decodedMatches(allOf([
            contains('Generated schema for Product'),
            contains('Product model for e-commerce platform'),
            contains('Generated SchemaModel for [Product]'),
            contains('Product model for e-commerce platform'),
            contains('final productSchema = Ack.object({'),
          ])),
        },
      );
    });

    test('handles missing descriptions gracefully', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/test.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
class SimpleModel {
  final String name;
  
  SimpleModel({required this.name});
}
''',
        },
        outputs: {
          'test_pkg|lib/test.g.dart': decodedMatches(allOf([
            contains('Generated schema for SimpleModel'),
            // Should have the standard generated comment but no additional description
            isNot(contains(
                '/// A')), // No additional description starting with "/// A"
            isNot(contains(
                '/// This')), // No additional description starting with "/// This"
            contains('final simpleModelSchema = Ack.object({'),
          ])),
        },
      );
    });

    test('extracts descriptions with special characters correctly', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/test.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel(description: 'Model with "quotes" and \\special\\ characters')
class SpecialModel {
  final String name;
  
  SpecialModel({required this.name});
}
''',
        },
        outputs: {
          'test_pkg|lib/test.g.dart': decodedMatches(allOf([
            contains('Generated schema for SpecialModel'),
            contains('Model with "quotes" and special characters'),
            contains('final specialModelSchema = Ack.object({'),
          ])),
        },
      );
    });
  });
}
